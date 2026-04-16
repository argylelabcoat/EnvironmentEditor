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
    FSystemPathsDir: string;
    FSearchPaths: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    function LoadUserVariables: TStringList;
    function LoadSystemVariables: TStringList;
    function LoadUserVariableOrigins: TStringList;
    function LoadSystemVariableOrigins: TStringList;
    function SaveUserVariables(Vars: TStringList): Boolean;
    function SaveSystemVariables(Vars: TStringList): Boolean;
    procedure BroadcastEnvironmentChange;
    class function ParseExportLine(const ALine: string; out AKey, AValue: string): Boolean;
    class function InjectExport(const AContent, AKey, AValue: string): string;
    property UserProfilePath: string read FUserProfilePath write FUserProfilePath;
    property SystemPathsFile: string read FSystemPathsFile write FSystemPathsFile;
    property SystemPathsDir: string read FSystemPathsDir write FSystemPathsDir;
    property SearchPaths: TStringList read FSearchPaths;
  end;

implementation

constructor TMacEnvProvider.Create;
begin
  inherited Create;
  FSearchPaths := TStringList.Create;
  FSearchPaths.Add(GetEnvironmentVariable('HOME') + '/.zshrc');
  FSearchPaths.Add(GetEnvironmentVariable('HOME') + '/.zprofile');
  FSearchPaths.Add(GetEnvironmentVariable('HOME') + '/.zshenv');
  FSearchPaths.Add(GetEnvironmentVariable('HOME') + '/.bash_profile');
  FSearchPaths.Add(GetEnvironmentVariable('HOME') + '/.bashrc');
  FSearchPaths.Add(GetEnvironmentVariable('HOME') + '/.profile');

  FUserProfilePath := FSearchPaths[0];
  if not FileExists(FUserProfilePath) then
    FUserProfilePath := FSearchPaths[1];
  if not FileExists(FUserProfilePath) then
    FUserProfilePath := FSearchPaths[2];

  FSystemPathsFile := '/etc/paths';
  FSystemPathsDir := '/etc/paths.d/';
end;

destructor TMacEnvProvider.Destroy;
begin
  FSearchPaths.Free;
  inherited Destroy;
end;

function TMacEnvProvider.LoadUserVariables: TStringList;
var
  Lines: TStringList;
  I, J: Integer;
  Key, Value: string;
begin
  Result := TStringList.Create;
  Lines := TStringList.Create;
  try
    for J := 0 to FSearchPaths.Count - 1 do
    begin
      if FileExists(FSearchPaths[J]) then
      begin
        Lines.Clear;
        Lines.LoadFromFile(FSearchPaths[J]);
        for I := 0 to Lines.Count - 1 do
        begin
          if ParseExportLine(Lines[I], Key, Value) then
            Result.Values[Key] := Value;
        end;
      end;
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
  SearchRec: TSearchRec;
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

    if FindFirst(FSystemPathsDir + '*', faAnyFile, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          Lines.Clear;
          Lines.LoadFromFile(FSystemPathsDir + SearchRec.Name);
          for I := 0 to Lines.Count - 1 do
          begin
            if Trim(Lines[I]) <> '' then
            begin
              if PathValue <> '' then
                PathValue := PathValue + ':';
              PathValue := PathValue + Trim(Lines[I]);
            end;
          end;
        end;
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;

    if PathValue <> '' then
      Result.Add('PATH=' + PathValue);
  finally
    Lines.Free;
  end;
end;

function TMacEnvProvider.LoadUserVariableOrigins: TStringList;
var
  Lines: TStringList;
  I, J: Integer;
  Key, Value: string;
  Origin: string;
begin
  Result := TStringList.Create;
  Lines := TStringList.Create;
  try
    for J := 0 to FSearchPaths.Count - 1 do
    begin
      if FileExists(FSearchPaths[J]) then
      begin
        Lines.Clear;
        Lines.LoadFromFile(FSearchPaths[J]);
        Origin := FSearchPaths[J];
        for I := 0 to Lines.Count - 1 do
        begin
          if ParseExportLine(Lines[I], Key, Value) then
            Result.Values[Key] := Origin;
        end;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function TMacEnvProvider.LoadSystemVariableOrigins: TStringList;
var
  HasPathsD: Boolean;
  SearchRec: TSearchRec;
  Origin: string;
begin
  Result := TStringList.Create;
  HasPathsD := False;
  if FindFirst(FSystemPathsDir + '*', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        HasPathsD := True;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;

  Origin := FSystemPathsFile;
  if HasPathsD then
    Origin := Origin + '(.d)';

  if FileExists(FSystemPathsFile) or HasPathsD then
    Result.Add('PATH=' + Origin);
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
