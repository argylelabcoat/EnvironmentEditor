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

initialization
  RegisterTest(TTestMacEnvProvider);
end.