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
    procedure TestLoadSystemVariables;
    procedure TestSaveUserVariables;
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
    Provider.UserProfilePath := TempFile;
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

initialization
  RegisterTest(TTestMacEnvProvider);
end.