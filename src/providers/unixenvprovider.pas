unit unixenvprovider;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, envproviderintf;

type
  TUnixEnvProvider = class(TInterfacedObject, IEnvProvider)
  public
    function LoadUserVariables: TStringList;
    function LoadSystemVariables: TStringList;
    function SaveUserVariables(Vars: TStringList): Boolean;
    function SaveSystemVariables(Vars: TStringList): Boolean;
    procedure BroadcastEnvironmentChange;
    class function ParseExportLine(const ALine: string; out AKey, AValue: string): Boolean;
    class function InjectExport(const AContent, AKey, AValue: string): string;
  end;

implementation

function TUnixEnvProvider.LoadUserVariables: TStringList;
begin
  Result := TStringList.Create;
end;

function TUnixEnvProvider.LoadSystemVariables: TStringList;
begin
  Result := TStringList.Create;
end;

function TUnixEnvProvider.SaveUserVariables(Vars: TStringList): Boolean;
begin
  Result := True;
end;

function TUnixEnvProvider.SaveSystemVariables(Vars: TStringList): Boolean;
begin
  Result := True;
end;

procedure TUnixEnvProvider.BroadcastEnvironmentChange;
begin
end;

class function TUnixEnvProvider.ParseExportLine(const ALine: string; out AKey, AValue: string): Boolean;
var
  PosEq: Integer;
  S: string;
begin
  S := Trim(ALine);
  Result := S.StartsWith('export ');
  if not Result then
    Exit;
  S := Trim(S.Substring(7));
  PosEq := Pos('=', S);
  if PosEq > 0 then
  begin
    AKey := Copy(S, 1, PosEq - 1);
    AValue := Copy(S, PosEq + 1, Length(S));
  end
  else
  begin
    AKey := S;
    AValue := '';
  end;
end;

class function TUnixEnvProvider.InjectExport(const AContent, AKey, AValue: string): string;
var
  Lines: TStringList;
  I: Integer;
  Found: Boolean;
  Prefix: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := AContent;
    Found := False;
    Prefix := 'export ' + AKey + '=';
    for I := 0 to Lines.Count - 1 do
    begin
      if Trim(Lines[I]).StartsWith(Prefix) then
      begin
        Lines[I] := Prefix + AValue;
        Found := True;
        Break;
      end;
    end;
    if not Found then
      Lines.Add(Prefix + AValue);
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
