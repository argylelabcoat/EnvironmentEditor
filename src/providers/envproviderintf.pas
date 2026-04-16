unit envproviderintf;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes;

type
  IEnvProvider = interface
    ['{B5E4A3F2-1C2D-4E3F-8A9B-0C1D2E3F4A5B}']
    function LoadUserVariables: TStringList;
    function LoadSystemVariables: TStringList;
    function SaveUserVariables(Vars: TStringList): Boolean;
    function SaveSystemVariables(Vars: TStringList): Boolean;
    procedure BroadcastEnvironmentChange;
  end;

implementation

end.