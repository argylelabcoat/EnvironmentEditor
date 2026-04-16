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

initialization
  RegisterTest(TTestUnixEnvProvider);
end.