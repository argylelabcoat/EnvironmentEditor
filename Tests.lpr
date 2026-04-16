program Tests;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

uses
  Classes, SysUtils, consoletestrunner, testregistry, testpathutils, testvalidator, testwinenvprovider, testunixenvprovider, testmacenvprovider;

var
  App: TTestRunner;

begin
  App := TTestRunner.Create(nil);
  try
    App.Initialize;
    App.Run;
  finally
    App.Free;
  end;
end.
