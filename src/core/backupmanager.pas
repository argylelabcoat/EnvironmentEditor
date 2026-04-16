unit backupmanager;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, fpjson, jsonparser;

type
  TBackupManager = class
  private
    FBackupFile: string;
  public
    constructor Create(const ABackupFile: string);
    function Backup(Vars: TStringList): Boolean;
    function Restore: TStringList;
    function ExportToJson(Vars: TStringList; const AFileName: string): Boolean;
  end;

implementation

constructor TBackupManager.Create(const ABackupFile: string);
begin
  inherited Create;
  FBackupFile := ABackupFile;
end;

function TBackupManager.Backup(Vars: TStringList): Boolean;
begin
  try
    Vars.SaveToFile(FBackupFile);
    Result := True;
  except
    Result := False;
  end;
end;

function TBackupManager.Restore: TStringList;
begin
  Result := TStringList.Create;
  if FileExists(FBackupFile) then
    Result.LoadFromFile(FBackupFile);
end;

function TBackupManager.ExportToJson(Vars: TStringList; const AFileName: string): Boolean;
var
  Json: TJSONObject;
  I: Integer;
  PosEq: Integer;
  Key, Value: string;
  JsonString: string;
  F: TFileStream;
begin
  Result := False;
  Json := TJSONObject.Create;
  try
    for I := 0 to Vars.Count - 1 do
    begin
      PosEq := Pos('=', Vars[I]);
      if PosEq > 0 then
      begin
        Key := Copy(Vars[I], 1, PosEq - 1);
        Value := Copy(Vars[I], PosEq + 1, Length(Vars[I]));
        Json.Add(Key, Value);
      end;
    end;
    try
      JsonString := Json.FormatJSON;
      F := TFileStream.Create(AFileName, fmCreate);
      try
        F.Write(JsonString[1], Length(JsonString));
      finally
        F.Free;
      end;
      Result := True;
    except
      Result := False;
    end;
  finally
    Json.Free;
  end;
end;

end.