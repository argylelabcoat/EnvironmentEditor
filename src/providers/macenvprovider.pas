unit macenvprovider;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, envproviderintf;

type
  TMacEnvProvider = class(TInterfacedObject, IEnvProvider)
  public
    function LoadUserVariables: TStringList;
    function LoadSystemVariables: TStringList;
    function SaveUserVariables(Vars: TStringList): Boolean;
    function SaveSystemVariables(Vars: TStringList): Boolean;
    procedure BroadcastEnvironmentChange;
  end;

implementation

function TMacEnvProvider.LoadUserVariables: TStringList;
begin
  Result := TStringList.Create;
end;

function TMacEnvProvider.LoadSystemVariables: TStringList;
begin
  Result := TStringList.Create;
end;

function TMacEnvProvider.SaveUserVariables(Vars: TStringList): Boolean;
begin
  Result := True;
end;

function TMacEnvProvider.SaveSystemVariables(Vars: TStringList): Boolean;
begin
  Result := True;
end;

procedure TMacEnvProvider.BroadcastEnvironmentChange;
begin
end;

end.