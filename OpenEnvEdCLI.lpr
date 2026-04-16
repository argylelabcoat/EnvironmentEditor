unit openenvcli;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
Classes, SysUtils;

procedure RunCLI;

implementation

uses
envproviderintf, unixenvprovider, macenvprovider;

procedure RunCLI;
var
Provider: IEnvProvider;
UserVars: TStringList;
begin
  {$IFDEF MSWINDOWS}
Provider := TWinEnvProvider.Create;
  {$ENDIF}
  {$IF DEFINED(DARWIN)}
Provider := TMacEnvProvider.Create;
  {$ENDIF}
  {$IF DEFINED(UNIX) AND NOT DEFINED(DARWIN)}
Provider := TUnixEnvProvider.Create;
  {$ENDIF}

UserVars := Provider.LoadUserVariables;
try
Writeln('User environment variables:');
if UserVars.Count = 0 then
Writeln('  (none)')
else
Writeln(UserVars.Text);
finally
UserVars.Free;
end;
end;

end.