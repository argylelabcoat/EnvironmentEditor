unit testunixenvprovider;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, envproviderintf, unixenvprovider;

type
  TTestUnixEnvProvider = class(TTestCase)
  published
    procedure TestCreate;
    procedure TestParseExportLine;
    procedure TestInjectExport;
    procedure TestPreserveComments;
    procedure TestLoadUserVariables;
    procedure TestLoadSystemVariables;
    procedure TestSaveUserVariables;
    procedure TestLoadUserVariableOrigins;
    procedure TestLoadSystemVariableOrigins;
  end;

implementation

procedure TTestUnixEnvProvider.TestCreate;
var
  Provider: TUnixEnvProvider;
begin
  Provider := TUnixEnvProvider.Create;
  try
    AssertNotNull(Provider);
  finally
    Provider.Free;
  end;
end;

procedure TTestUnixEnvProvider.TestParseExportLine;
var
  Key, Value: string;
  Result: Boolean;
begin
  Result := TUnixEnvProvider.ParseExportLine('export PATH=/usr/bin', Key, Value);
  AssertTrue(Result);
  AssertEquals('PATH', Key);
  AssertEquals('/usr/bin', Value);
end;

procedure TTestUnixEnvProvider.TestInjectExport;
var
  Content: string;
  ResultContent: string;
begin
  Content := '# bashrc' + LineEnding + 'export HOME=/home/user' + LineEnding;
  ResultContent := TUnixEnvProvider.InjectExport(Content, 'PATH', '/usr/bin');
  AssertTrue(Pos('export PATH=/usr/bin', ResultContent) > 0);
  AssertTrue(Pos('# bashrc', ResultContent) > 0);
end;

procedure TTestUnixEnvProvider.TestPreserveComments;
var
  Content: string;
  ResultContent: string;
begin
  Content := '# comment' + LineEnding + 'alias ls="ls --color"' + LineEnding;
  ResultContent := TUnixEnvProvider.InjectExport(Content, 'FOO', 'bar');
  AssertTrue(Pos('# comment', ResultContent) > 0);
  AssertTrue(Pos('alias ls=', ResultContent) > 0);
end;

procedure TTestUnixEnvProvider.TestLoadUserVariables;
var
  Provider: TUnixEnvProvider;
  Vars: TStringList;
  TempFile: string;
  Content: TStringList;
begin
  TempFile := GetTempFileName;
  Content := TStringList.Create;
  try
    Content.Add('# bashrc comment');
    Content.Add('export PATH=/usr/local/bin:/usr/bin');
    Content.Add('export EDITOR=vim');
    Content.SaveToFile(TempFile);
  finally
    Content.Free;
  end;

  Provider := TUnixEnvProvider.Create;
  try
    Provider.UserProfilePath := TempFile;
    Vars := Provider.LoadUserVariables;
    try
      AssertEquals(2, Vars.Count);
      AssertEquals('PATH', Vars.Names[0]);
      AssertEquals('/usr/local/bin:/usr/bin', Vars.ValueFromIndex[0]);
      AssertEquals('EDITOR', Vars.Names[1]);
      AssertEquals('vim', Vars.ValueFromIndex[1]);
    finally
      Vars.Free;
    end;
  finally
    Provider.Free;
    DeleteFile(TempFile);
  end;
end;

procedure TTestUnixEnvProvider.TestLoadSystemVariables;
var
  Provider: TUnixEnvProvider;
  Vars: TStringList;
  TempFile: string;
  Content: TStringList;
begin
  TempFile := GetTempFileName;
  Content := TStringList.Create;
  try
    Content.Add('PATH="/usr/local/bin:/usr/bin:/bin"');
    Content.Add('JAVA_HOME="/usr/lib/jvm/default"');
    Content.SaveToFile(TempFile);
  finally
    Content.Free;
  end;

  Provider := TUnixEnvProvider.Create;
  try
    Provider.SystemEnvironmentPath := TempFile;
    Vars := Provider.LoadSystemVariables;
    try
      AssertEquals(2, Vars.Count);
      AssertEquals('PATH', Vars.Names[0]);
      AssertEquals('/usr/local/bin:/usr/bin:/bin', Vars.ValueFromIndex[0]);
      AssertEquals('JAVA_HOME', Vars.Names[1]);
      AssertEquals('/usr/lib/jvm/default', Vars.ValueFromIndex[1]);
    finally
      Vars.Free;
    end;
  finally
    Provider.Free;
    DeleteFile(TempFile);
  end;
end;

procedure TTestUnixEnvProvider.TestSaveUserVariables;
var
  Provider: TUnixEnvProvider;
  Vars: TStringList;
  TempFile: string;
  ResultContent: TStringList;
begin
  TempFile := GetTempFileName;
  Vars := TStringList.Create;
  try
    Vars.Add('PATH=/usr/local/bin');
    Vars.Add('EDITOR=vim');

    Provider := TUnixEnvProvider.Create;
    try
      Provider.UserProfilePath := TempFile;
      AssertTrue(Provider.SaveUserVariables(Vars));
      ResultContent := TStringList.Create;
      try
        ResultContent.LoadFromFile(TempFile);
        AssertTrue(Pos('export PATH=/usr/local/bin', ResultContent.Text) > 0);
        AssertTrue(Pos('export EDITOR=vim', ResultContent.Text) > 0);
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

procedure TTestUnixEnvProvider.TestLoadUserVariableOrigins;
var
  Provider: TUnixEnvProvider;
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

  Provider := TUnixEnvProvider.Create;
  try
    Provider.UserProfilePath := TempFile;
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

procedure TTestUnixEnvProvider.TestLoadSystemVariableOrigins;
var
  Provider: TUnixEnvProvider;
  Origins: TStringList;
  TempFile: string;
  Content: TStringList;
begin
  TempFile := GetTempFileName;
  Content := TStringList.Create;
  try
    Content.Add('PATH="/usr/local/bin:/usr/bin:/bin"');
    Content.Add('JAVA_HOME="/usr/lib/jvm/default"');
    Content.SaveToFile(TempFile);
  finally
    Content.Free;
  end;

  Provider := TUnixEnvProvider.Create;
  try
    Provider.SystemEnvironmentPath := TempFile;
    Origins := Provider.LoadSystemVariableOrigins;
    try
      AssertEquals(2, Origins.Count);
      AssertEquals(TempFile, Origins.Values['PATH']);
      AssertEquals(TempFile, Origins.Values['JAVA_HOME']);
    finally
      Origins.Free;
    end;
  finally
    Provider.Free;
    DeleteFile(TempFile);
  end;
end;

initialization
  RegisterTest(TTestUnixEnvProvider);
end.