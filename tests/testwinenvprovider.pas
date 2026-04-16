unit testwinenvprovider;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, envproviderintf, winenvprovider;

type
  TTestWinEnvProvider = class(TTestCase)
  published
    procedure TestCreate;
    procedure TestInterfaceImplemented;
    procedure TestLoadUserVariableOrigins;
    procedure TestLoadSystemVariableOrigins;
  end;

implementation

procedure TTestWinEnvProvider.TestCreate;
var
  Provider: TWinEnvProvider;
begin
  Provider := TWinEnvProvider.Create;
  try
    AssertNotNull(Provider);
  finally
    Provider.Free;
  end;
end;

procedure TTestWinEnvProvider.TestInterfaceImplemented;
var
  Provider: IEnvProvider;
begin
  Provider := TWinEnvProvider.Create;
  AssertNotNull(Pointer(Provider));
end;

procedure TTestWinEnvProvider.TestLoadUserVariableOrigins;
var
  Provider: TWinEnvProvider;
  Origins: TStringList;
begin
  Provider := TWinEnvProvider.Create;
  try
    Origins := Provider.LoadUserVariableOrigins;
    try
      {$IFNDEF MSWINDOWS}
      AssertEquals(0, Origins.Count);
      {$ENDIF}
    finally
      Origins.Free;
    end;
  finally
    Provider.Free;
  end;
end;

procedure TTestWinEnvProvider.TestLoadSystemVariableOrigins;
var
  Provider: TWinEnvProvider;
  Origins: TStringList;
begin
  Provider := TWinEnvProvider.Create;
  try
    Origins := Provider.LoadSystemVariableOrigins;
    try
      {$IFNDEF MSWINDOWS}
      AssertEquals(0, Origins.Count);
      {$ENDIF}
    finally
      Origins.Free;
    end;
  finally
    Provider.Free;
  end;
end;

initialization
  RegisterTest(TTestWinEnvProvider);
end.