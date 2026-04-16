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
  private
    FUserProfilePath: string;
    FSystemPathsFile: string;
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
    property SystemPathsFile: string read FSystemPathsFile write FSystemPathsFile;
  end;

implementation

constructor TMacEnvProvider.Create;
begin
  inherited Create;
  FUserProfilePath := GetEnvironmentVariable('HOME') + '/.zprofile';
  if not FileExists(FUserProfilePath) then
    FUserProfilePath := GetEnvironmentVariable('HOME') + '/.zshenv';
  FSystemPathsFile := '/etc/paths';
end;

function TMacEnvProvider.LoadUserVariables: TStringList;
var
  Lines: TStringList;
  I: Integer;
  Key, Value: string;
  Profile: string;
begin
  Result := TStringList.Create;
  Lines := TStringList.Create;
  try
    Profile := FUserProfilePath;
    if not FileExists(Profile) then
      if FileExists(GetEnvironmentVariable('HOME') + '/.zshenv') then
        Profile := GetEnvironmentVariable('HOME') + '/.zshenv';

    if FileExists(Profile) then
      Lines.LoadFromFile(Profile);
    for I := 0 to Lines.Count - 1 do
    begin
      if ParseExportLine(Lines[I], Key, Value) then
        Result.Add(Key + '=' + Value);
    end;
  finally
    Lines.Free;
  end;
end;

function TMacEnvProvider.LoadSystemVariables: TStringList;
var
  Lines: TStringList;
  PathValue: string;
  I: Integer;
begin
  Result := TStringList.Create;
  Lines := TStringList.Create;
  try
    if FileExists(FSystemPathsFile) then
      Lines.LoadFromFile(FSystemPathsFile);
    PathValue := '';
    for I := 0 to Lines.Count - 1 do
    begin
      if Trim(Lines[I]) <> '' then
      begin
        if PathValue <> '' then
          PathValue := PathValue + ':';
        PathValue := PathValue + Trim(Lines[I]);
      end;
    end;
    if PathValue <> '' then
      Result.Add('PATH=' + PathValue);
  finally
    Lines.Free;
  end;
end;

function TMacEnvProvider.SaveUserVariables(Vars: TStringList): Boolean;
var
  Content: string;
  I: Integer;
  SL: TStringList;
  Profile: string;
begin
  Result := False;
  Profile := FUserProfilePath;
  if not FileExists(Profile) then
    if FileExists(GetEnvironmentVariable('HOME') + '/.zshenv') then
      Profile := GetEnvironmentVariable('HOME') + '/.zshenv';

  SL := TStringList.Create;
  try
    if FileExists(Profile) then
      SL.LoadFromFile(Profile);
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
      SL.SaveToFile(Profile);
      Result := True;
    except
      Result := False;
    end;
  finally
    SL.Free;
  end;
end;

function TMacEnvProvider.SaveSystemVariables(Vars: TStringList): Boolean;
var
  SL: TStringList;
  I: Integer;
  Key, Value: string;
  PathValue: string;
begin
  Result := False;
  PathValue := '';
  for I := 0 to Vars.Count - 1 do
  begin
    Key := Vars.Names[I];
    Value := Vars.ValueFromIndex[I];
    if UpperCase(Key) = 'PATH' then
    begin
      PathValue := Value;
      Break;
    end;
  end;

  if PathValue = '' then
  begin
    Result := True;
    Exit;
  end;

  SL := TStringList.Create;
  try
    try
      SL.Text := StringReplace(PathValue, ':', LineEnding, [rfReplaceAll]);
      SL.SaveToFile(FSystemPathsFile);
      Result := True;
    except
      Result := False;
    end;
  finally
    SL.Free;
  end;
end;

procedure TMacEnvProvider.BroadcastEnvironmentChange;
begin
end;

class function TMacEnvProvider.ParseExportLine(const ALine: string; out AKey, AValue: string): Boolean;
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

class function TMacEnvProvider.InjectExport(const AContent, AKey, AValue: string): string;
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
