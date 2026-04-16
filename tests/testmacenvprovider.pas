unit testmacenvprovider;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, envproviderintf, macenvprovider;

type
  TTestMacEnvProvider = class(TTestCase)
  published
    procedure TestCreate;
    procedure TestInterfaceImplemented;
    procedure TestLoadUserVariables;
    procedure TestLoadUserVariables_MultipleFiles;
    procedure TestLoadSystemVariables;
    procedure TestLoadSystemVariables_WithPathsD;
    procedure TestSaveUserVariables;
    procedure TestLoadUserVariableOrigins;
    procedure TestLoadSystemVariableOrigins;
    procedure TestLoadSystemVariableOrigins_WithPathsD;
  end;

implementation

procedure TTestMacEnvProvider.TestCreate;
var
  Provider: TMacEnvProvider;
begin
  Provider := TMacEnvProvider.Create;
  try
    AssertNotNull(Provider);
  finally
    Provider.Free;
  end;
end;

procedure TTestMacEnvProvider.TestInterfaceImplemented;
var
  Provider: IEnvProvider;
begin
  Provider := TMacEnvProvider.Create;
  AssertNotNull(Pointer(Provider));
end;

procedure TTestMacEnvProvider.TestLoadUserVariables;
var
  Provider: TMacEnvProvider;
  Vars: TStringList;
  TempFile: string;
  Content: TStringList;
begin
  TempFile := GetTempFileName;
  Content := TStringList.Create;
  try
    Content.Add('# zprofile comment');
    Content.Add('export PATH=/usr/local/bin:/usr/bin');
    Content.Add('export HOME=/Users/test');
    Content.SaveToFile(TempFile);
  finally
    Content.Free;
  end;

  Provider := TMacEnvProvider.Create;
  try
    Provider.UseShellEvaluation := False;
    Provider.SearchPaths.Clear;
    Provider.SearchPaths.Add(TempFile);
    Vars := Provider.LoadUserVariables;
    try
      AssertEquals(2, Vars.Count);
      AssertEquals('PATH', Vars.Names[0]);
      AssertEquals('/usr/local/bin:/usr/bin', Vars.ValueFromIndex[0]);
      AssertEquals('HOME', Vars.Names[1]);
      AssertEquals('/Users/test', Vars.ValueFromIndex[1]);
    finally
      Vars.Free;
    end;
  finally
    Provider.Free;
    DeleteFile(TempFile);
  end;
end;

procedure TTestMacEnvProvider.TestLoadUserVariables_MultipleFiles;
var
  Provider: TMacEnvProvider;
  Vars: TStringList;
  TempFileA, TempFileB: string;
  Content: TStringList;
begin
  TempFileA := GetTempDir(False) + 'testmac_multi_a_' + IntToStr(Random(MaxInt)) + '.tmp';
  TempFileB := GetTempDir(False) + 'testmac_multi_b_' + IntToStr(Random(MaxInt)) + '.tmp';
  Content := TStringList.Create;
  try
    Content.Add('export VAR_A=alpha');
    Content.Add('export SHARED=first');
    Content.SaveToFile(TempFileA);
    Content.Clear;
    Content.Add('export VAR_B=beta');
    Content.Add('export SHARED=second');
    Content.SaveToFile(TempFileB);
  finally
    Content.Free;
  end;

  Provider := TMacEnvProvider.Create;
  try
    Provider.UseShellEvaluation := False;
    Provider.SearchPaths.Clear;
    Provider.SearchPaths.Add(TempFileA);
    Provider.SearchPaths.Add(TempFileB);
    Vars := Provider.LoadUserVariables;
    try
      AssertEquals('alpha', Vars.Values['VAR_A']);
      AssertEquals('beta', Vars.Values['VAR_B']);
      AssertEquals('second', Vars.Values['SHARED']);
      AssertEquals(3, Vars.Count);
    finally
      Vars.Free;
    end;
  finally
    Provider.Free;
    DeleteFile(TempFileA);
    DeleteFile(TempFileB);
  end;
end;

procedure TTestMacEnvProvider.TestLoadSystemVariables;
var
  Provider: TMacEnvProvider;
  Vars: TStringList;
  TempFile: string;
  Content: TStringList;
begin
  TempFile := GetTempFileName;
  Content := TStringList.Create;
  try
    Content.Add('/usr/local/bin');
    Content.Add('/usr/bin');
    Content.Add('/bin');
    Content.SaveToFile(TempFile);
  finally
    Content.Free;
  end;

  Provider := TMacEnvProvider.Create;
  try
    Provider.SystemPathsFile := TempFile;
    Provider.SystemPathsDir := GetTempDir(False) + 'nonexistent_' + IntToStr(Random(MaxInt)) + '/';
    Vars := Provider.LoadSystemVariables;
    try
      AssertEquals(1, Vars.Count);
      AssertEquals('PATH', Vars.Names[0]);
      AssertEquals('/usr/local/bin:/usr/bin:/bin', Vars.ValueFromIndex[0]);
    finally
      Vars.Free;
    end;
  finally
    Provider.Free;
    DeleteFile(TempFile);
  end;
end;

procedure TTestMacEnvProvider.TestLoadSystemVariables_WithPathsD;
var
  Provider: TMacEnvProvider;
  Vars: TStringList;
  TempPathsFile: string;
  TempPathsDir: string;
  Content: TStringList;
begin
  TempPathsFile := GetTempFileName;
  TempPathsDir := GetTempDir(False) + 'testpaths_' + IntToStr(Random(MaxInt)) + '/';
  ForceDirectories(TempPathsDir);
  Content := TStringList.Create;
  try
    Content.Add('/usr/local/bin');
    Content.SaveToFile(TempPathsFile);
    Content.Clear;
    Content.Add('/opt/homebrew/bin');
    Content.SaveToFile(TempPathsDir + 'homebrew');
    Content.Clear;
    Content.Add('/usr/local/go/bin');
    Content.SaveToFile(TempPathsDir + 'go');
  finally
    Content.Free;
  end;

  Provider := TMacEnvProvider.Create;
  try
    Provider.SystemPathsFile := TempPathsFile;
    Provider.SystemPathsDir := TempPathsDir;
    Vars := Provider.LoadSystemVariables;
    try
      AssertEquals(1, Vars.Count);
      AssertEquals('PATH', Vars.Names[0]);
      AssertEquals('/usr/local/bin:/usr/local/go/bin:/opt/homebrew/bin',
        Vars.ValueFromIndex[0]);
    finally
      Vars.Free;
    end;
  finally
    Provider.Free;
    DeleteFile(TempPathsFile);
    DeleteFile(TempPathsDir + 'homebrew');
    DeleteFile(TempPathsDir + 'go');
    RemoveDir(TempPathsDir);
  end;
end;

procedure TTestMacEnvProvider.TestSaveUserVariables;
var
  Provider: TMacEnvProvider;
  Vars: TStringList;
  TempFile: string;
  ResultContent: TStringList;
begin
  TempFile := GetTempFileName;
  Vars := TStringList.Create;
  try
    Vars.Add('PATH=/usr/local/bin');
    Vars.Add('HOME=/Users/test');

    Provider := TMacEnvProvider.Create;
    try
      Provider.UserProfilePath := TempFile;
      AssertTrue(Provider.SaveUserVariables(Vars));
      ResultContent := TStringList.Create;
      try
        ResultContent.LoadFromFile(TempFile);
        AssertTrue(Pos('export PATH=/usr/local/bin', ResultContent.Text) > 0);
        AssertTrue(Pos('export HOME=/Users/test', ResultContent.Text) > 0);
      finally
        ResultContent.Free;
      end;
    finally
      Provider.Free;
    end;
  finally
    Vars.Free;
    DeleteFile(TempFile);
  end;
end;

procedure TTestMacEnvProvider.TestLoadUserVariableOrigins;
var
  Provider: TMacEnvProvider;
  Origins: TStringList;
  TempFile: string;
  Content: TStringList;
begin
  TempFile := GetTempFileName;
  Content := TStringList.Create;
  try
    Content.Add('export PATH=/usr/local/bin');
    Content.SaveToFile(TempFile);
  finally
    Content.Free;
  end;

  Provider := TMacEnvProvider.Create;
  try
    Provider.UseShellEvaluation := False;
    Provider.SearchPaths.Clear;
    Provider.SearchPaths.Add(TempFile);
    Origins := Provider.LoadUserVariableOrigins;
    try
      AssertEquals(1, Origins.Count);
      AssertEquals(TempFile, Origins.Values['PATH']);
    finally
      Origins.Free;
    end;
  finally
    Provider.Free;
    DeleteFile(TempFile);
  end;
end;

procedure TTestMacEnvProvider.TestLoadSystemVariableOrigins;
var
  Provider: TMacEnvProvider;
  Origins: TStringList;
  TempFile: string;
  Content: TStringList;
begin
  TempFile := GetTempFileName;
  Content := TStringList.Create;
  try
    Content.Add('/usr/local/bin');
    Content.SaveToFile(TempFile);
  finally
    Content.Free;
  end;

  Provider := TMacEnvProvider.Create;
  try
    Provider.SystemPathsFile := TempFile;
    Provider.SystemPathsDir := GetTempDir(False) + 'nonexistent_' + IntToStr(Random(MaxInt)) + '/';
    Origins := Provider.LoadSystemVariableOrigins;
    try
      AssertEquals(1, Origins.Count);
      AssertEquals(TempFile, Origins.Values['PATH']);
    finally
      Origins.Free;
    end;
  finally
    Provider.Free;
    DeleteFile(TempFile);
  end;
end;

procedure TTestMacEnvProvider.TestLoadSystemVariableOrigins_WithPathsD;
var
  Provider: TMacEnvProvider;
  Origins: TStringList;
  TempPathsFile: string;
  TempPathsDir: string;
  Content: TStringList;
begin
  TempPathsFile := GetTempFileName;
  TempPathsDir := GetTempDir(False) + 'testpathsorig_' + IntToStr(Random(MaxInt)) + '/';
  ForceDirectories(TempPathsDir);
  Content := TStringList.Create;
  try
    Content.Add('/usr/local/bin');
    Content.SaveToFile(TempPathsFile);
    Content.Clear;
    Content.Add('/opt/homebrew/bin');
    Content.SaveToFile(TempPathsDir + 'homebrew');
  finally
    Content.Free;
  end;

  Provider := TMacEnvProvider.Create;
  try
    Provider.SystemPathsFile := TempPathsFile;
    Provider.SystemPathsDir := TempPathsDir;
    Origins := Provider.LoadSystemVariableOrigins;
    try
      AssertEquals(1, Origins.Count);
      AssertEquals(TempPathsFile + '(.d)', Origins.Values['PATH']);
    finally
      Origins.Free;
    end;
  finally
    Provider.Free;
    DeleteFile(TempPathsFile);
    DeleteFile(TempPathsDir + 'homebrew');
    RemoveDir(TempPathsDir);
  end;
end;

initialization
  RegisterTest(TTestMacEnvProvider);
end.