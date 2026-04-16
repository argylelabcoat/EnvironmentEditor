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
  private
    FUserProfilePath: string;
    FSystemEnvironmentPath: string;
  public
    constructor Create;
    function LoadUserVariables: TStringList;
    function LoadSystemVariables: TStringList;
    function SaveUserVariables(Vars: TStringList): Boolean;
    function SaveSystemVariables(Vars: TStringList): Boolean;
    procedure BroadcastEnvironmentChange;
    class function ParseExportLine(const ALine: string; out AKey, AValue: string): Boolean;
    class function InjectExport(const AContent, AKey, AValue: string): string;
    property UserProfilePath: string read FUserProfilePath write FUserProfilePath;
    property SystemEnvironmentPath: string read FSystemEnvironmentPath write FSystemEnvironmentPath;
  end;

implementation

constructor TUnixEnvProvider.Create;
begin
  inherited Create;
  FUserProfilePath := GetEnvironmentVariable('HOME') + '/.bashrc';
  FSystemEnvironmentPath := '/etc/environment';
end;

function TUnixEnvProvider.LoadUserVariables: TStringList;
var
  Lines: TStringList;
  I: Integer;
  Key, Value: string;
begin
  Result := TStringList.Create;
  Lines := TStringList.Create;
  try
    if FileExists(FUserProfilePath) then
      Lines.LoadFromFile(FUserProfilePath);
    for I := 0 to Lines.Count - 1 do
    begin
      if ParseExportLine(Lines[I], Key, Value) then
        Result.Add(Key + '=' + Value);
    end;
  finally
    Lines.Free;
  end;
end;

function TUnixEnvProvider.LoadSystemVariables: TStringList;
var
  Lines: TStringList;
  I: Integer;
  Line, Key, Value: string;
  PosEq: Integer;
begin
  Result := TStringList.Create;
  Lines := TStringList.Create;
  try
    if FileExists(FSystemEnvironmentPath) then
      Lines.LoadFromFile(FSystemEnvironmentPath);
    for I := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[I]);
      if (Line = '') or Line.StartsWith('#') then
        Continue;
      PosEq := Pos('=', Line);
      if PosEq > 0 then
      begin
        Key := Copy(Line, 1, PosEq - 1);
        Value := Copy(Line, PosEq + 1, Length(Line));
        if Value.StartsWith('"') and Value.EndsWith('"') and (Length(Value) > 1) then
          Value := Copy(Value, 2, Length(Value) - 2);
        Result.Add(Key + '=' + Value);
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function TUnixEnvProvider.SaveUserVariables(Vars: TStringList): Boolean;
var
  Content: string;
  I: Integer;
  SL: TStringList;
begin
  Result := False;
  SL := TStringList.Create;
  try
    if FileExists(FUserProfilePath) then
      SL.LoadFromFile(FUserProfilePath);
    Content := SL.Text;
  finally
    SL.Free;
  end;

  for I := 0 to Vars.Count - 1 do
    Content := InjectExport(Content, Vars.Names[I], Vars.ValueFromIndex[I]);

  SL := TStringList.Create;
  try
    try
      SL.Text := Content;
      SL.SaveToFile(FUserProfilePath);
      Result := True;
    except
      Result := False;
    end;
  finally
    SL.Free;
  end;
end;

function TUnixEnvProvider.SaveSystemVariables(Vars: TStringList): Boolean;
var
  Lines: TStringList;
  I, J: Integer;
  Key, Value: string;
  PosEq: Integer;
  Found: Boolean;
begin
  Result := False;
  Lines := TStringList.Create;
  try
    if FileExists(FSystemEnvironmentPath) then
      Lines.LoadFromFile(FSystemEnvironmentPath);

    for I := 0 to Vars.Count - 1 do
    begin
      Key := Vars.Names[I];
      Value := Vars.ValueFromIndex[I];
      Found := False;
      for J := 0 to Lines.Count - 1 do
      begin
        PosEq := Pos('=', Lines[J]);
        if (PosEq > 0) and (Trim(Copy(Lines[J], 1, PosEq - 1)) = Key) then
        begin
          Lines[J] := Key + '="' + Value + '"';
          Found := True;
          Break;
        end;
      end;
      if not Found then
        Lines.Add(Key + '="' + Value + '"');
    end;

    try
      Lines.SaveToFile(FSystemEnvironmentPath);
      Result := True;
    except
      Result := False;
    end;
  finally
    Lines.Free;
  end;
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
