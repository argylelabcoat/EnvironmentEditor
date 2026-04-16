unit ufrmmain;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, envproviderintf, undomanager, backupmanager, pathutils, validator,
  macenvprovider;

type
  TMainForm = class(TForm)
    BottomPanel: TPanel;
    BtnUndo: TButton;
    BtnRedo: TButton;
    BtnBackup: TButton;
    Splitter1: TSplitter;
    StatusBar: TStatusBar;
    UserTree: TListView;
    SystemTree: TListView;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnUndoClick(Sender: TObject);
    procedure BtnRedoClick(Sender: TObject);
    procedure BtnBackupClick(Sender: TObject);
  private
    FUserVars: TStringList;
    FSystemVars: TStringList;
    FProvider: IEnvProvider;
    FUndoManager: TUndoManager;
    FBackupManager: TBackupManager;
    procedure InitTrees;
    procedure LoadVariables;
    procedure PopulateTree(ATree: TListView; AVars: TStringList);
    procedure RefreshDiagnostics;
    procedure UserTreeCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
  public
  end;

var
  frmMain: TMainForm;

implementation

{$R *.lfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  InitTrees;
  Caption := 'OpenEnvEd';
  Width := 1024;
  Height := 768;
  FUserVars := TStringList.Create;
  FSystemVars := TStringList.Create;
  FUndoManager := TUndoManager.Create;
  FBackupManager := TBackupManager.Create(GetAppConfigDir(False) + 'backup.env');

  {$IFDEF MSWINDOWS}
  FProvider := TWinEnvProvider.Create;
  {$ELSE}
  {$IFDEF DARWIN}
  FProvider := TMacEnvProvider.Create;
  {$ELSE}
  FProvider := TUnixEnvProvider.Create;
  {$ENDIF}
  {$ENDIF}

  BtnUndo.OnClick := @BtnUndoClick;
  BtnRedo.OnClick := @BtnRedoClick;
  BtnBackup.OnClick := @BtnBackupClick;

  LoadVariables;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FUserVars.Free;
  FSystemVars.Free;
  FUndoManager.Free;
  FBackupManager.Free;
end;

procedure TMainForm.InitTrees;
begin
  UserTree.ViewStyle := vsReport;
  UserTree.Columns.Add.Caption := 'Name';
  UserTree.Columns.Add.Caption := 'Value';
  UserTree.Columns[0].Width := 200;
  UserTree.Columns[1].Width := 400;
  UserTree.Align := alLeft;
  UserTree.Width := ClientWidth div 2 - Splitter1.Width div 2;
  UserTree.OnCustomDrawItem := @UserTreeCustomDrawItem;

  SystemTree.ViewStyle := vsReport;
  SystemTree.Columns.Add.Caption := 'Name';
  SystemTree.Columns.Add.Caption := 'Value';
  SystemTree.Columns[0].Width := 200;
  SystemTree.Columns[1].Width := 400;
  SystemTree.Align := alClient;
end;

procedure TMainForm.LoadVariables;
var
  UserLoaded: TStringList;
  SystemLoaded: TStringList;
begin
  UserLoaded := FProvider.LoadUserVariables;
  try
    FUserVars.Assign(UserLoaded);
  finally
    UserLoaded.Free;
  end;

  SystemLoaded := FProvider.LoadSystemVariables;
  try
    FSystemVars.Assign(SystemLoaded);
  finally
    SystemLoaded.Free;
  end;

  PopulateTree(UserTree, FUserVars);
  PopulateTree(SystemTree, FSystemVars);
  RefreshDiagnostics;
end;

procedure TMainForm.PopulateTree(ATree: TListView; AVars: TStringList);
var
  I: Integer;
  Item: TListItem;
begin
  ATree.Items.Clear;
  for I := 0 to AVars.Count - 1 do
  begin
    Item := ATree.Items.Add;
    Item.Caption := AVars.Names[I];
    Item.SubItems.Add(AVars.ValueFromIndex[I]);
  end;
end;

procedure TMainForm.RefreshDiagnostics;
var
  I: Integer;
  Paths: TStringList;
  Validator: TPathValidator;
  Status: TPathStatus;
begin
  Validator := TPathValidator.Create;
  try
    for I := 0 to UserTree.Items.Count - 1 do
    begin
      if Pos(PathDelim, UserTree.Items[I].SubItems.Text) > 0 then
      begin
        Paths := TPathUtils.SplitPath(UserTree.Items[I].SubItems.Text, PathDelim);
        try
          if Paths.Count > 0 then
          begin
            Status := Validator.Validate(Paths[0]);
            UserTree.Items[I].Data := Pointer(Succ(Ord(Status)));
          end;
        finally
          Paths.Free;
        end;
      end
      else
        UserTree.Items[I].Data := Pointer(Ord(psValid));
    end;
  finally
    Validator.Free;
  end;
end;

procedure TMainForm.UserTreeCustomDrawItem(Sender: TCustomListView; Item: TListItem;
  State: TCustomDrawState; var DefaultDraw: Boolean);
var
  Status: TPathStatus;
begin
  Status := TPathStatus(PtrUInt(Item.Data) - 1);
  case Status of
    psNotFound: UserTree.Canvas.Brush.Color := RGBToColor(255, 200, 200);
    psDuplicate: UserTree.Canvas.Brush.Color := RGBToColor(255, 255, 200);
    else DefaultDraw := True;
  end;
end;

procedure TMainForm.BtnUndoClick(Sender: TObject);
var
  State: TStringList;
begin
  if not FUndoManager.CanUndo then
    Exit;
  State := FUndoManager.Undo;
  try
    FUserVars.Assign(State);
    PopulateTree(UserTree, FUserVars);
    RefreshDiagnostics;
  finally
    State.Free;
  end;
end;

procedure TMainForm.BtnRedoClick(Sender: TObject);
var
  State: TStringList;
begin
  if not FUndoManager.CanRedo then
    Exit;
  State := FUndoManager.Redo;
  try
    FUserVars.Assign(State);
    PopulateTree(UserTree, FUserVars);
    RefreshDiagnostics;
  finally
    State.Free;
  end;
end;

procedure TMainForm.BtnBackupClick(Sender: TObject);
var
  AllVars: TStringList;
begin
  AllVars := TStringList.Create;
  try
    AllVars.AddStrings(FUserVars);
    AllVars.AddStrings(FSystemVars);
    if FBackupManager.Backup(AllVars) then
      StatusBar.SimpleText := 'Backup saved.'
    else
      StatusBar.SimpleText := 'Backup failed.';
  finally
    AllVars.Free;
  end;
end;

end.
