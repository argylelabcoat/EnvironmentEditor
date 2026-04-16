unit testbackupmanager;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, backupmanager;

type
  TTestBackupManager = class(TTestCase)
  published
    procedure TestBackupAndRestore;
    procedure TestExportToJson;
  end;

implementation

procedure TTestBackupManager.TestBackupAndRestore;
var
  Manager: TBackupManager;
  Original: TStringList;
  Restored: TStringList;
  FileName: string;
begin
  FileName := GetTempFileName;
  Manager := TBackupManager.Create(FileName);
  try
    Original := TStringList.Create;
    try
      Original.Add('PATH=/usr/bin');
      Original.Add('HOME=/home/user');
      AssertTrue(Manager.Backup(Original));
      Restored := Manager.Restore;
      try
        AssertEquals(2, Restored.Count);
        AssertEquals('PATH=/usr/bin', Restored[0]);
      finally
        Restored.Free;
      end;
    finally
      Original.Free;
    end;
  finally
    Manager.Free;
    if FileExists(FileName) then
      DeleteFile(FileName);
  end;
end;

procedure TTestBackupManager.TestExportToJson;
var
  Manager: TBackupManager;
  Vars: TStringList;
  JsonPath: string;
begin
  JsonPath := GetTempFileName + '.json';
  Manager := TBackupManager.Create(GetTempFileName);
  try
    Vars := TStringList.Create;
    try
      Vars.Add('PATH=/usr/bin');
      AssertTrue(Manager.ExportToJson(Vars, JsonPath));
      AssertTrue(FileExists(JsonPath));
    finally
      Vars.Free;
    end;
  finally
    Manager.Free;
    if FileExists(JsonPath) then
      DeleteFile(JsonPath);
  end;
end;

initialization
  RegisterTest(TTestBackupManager);
end.