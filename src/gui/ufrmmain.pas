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
    BtnAdd: TButton;
    BtnDelete: TButton;
    Splitter1: TSplitter;
    StatusBar: TStatusBar;
    UserTree: TListView;
    SystemTree: TListView;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnUndoClick(Sender: TObject);
    procedure BtnRedoClick(Sender: TObject);
    procedure BtnBackupClick(Sender: TObject);
    procedure BtnAddClick(Sender: TObject);
    procedure BtnDeleteClick(Sender: TObject);
    procedure UserTreeDblClick(Sender: TObject);
  private
    FUserVars: TStringList;
    FSystemVars: TStringList;
    FUserOrigins: TStringList;
    FSystemOrigins: TStringList;
    FProvider: IEnvProvider;
    FUndoManager: TUndoManager;
    FBackupManager: TBackupManager;
    procedure InitTrees;
    procedure LoadVariables;
    procedure PopulateTree(ATree: TListView; AVars: TStringList; AOrigins: TStringList);
    procedure RefreshDiagnostics;
    procedure UserTreeCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure EditVariable(const CurrentName, CurrentValue: string; out NewName, NewValue: string; out Accepted: Boolean);
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
  FUserOrigins := TStringList.Create;
  FSystemOrigins := TStringList.Create;
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
  BtnAdd.OnClick := @BtnAddClick;
  BtnDelete.OnClick := @BtnDeleteClick;
  UserTree.OnDblClick := @UserTreeDblClick;

  LoadVariables;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FUserVars.Free;
  FSystemVars.Free;
  FUserOrigins.Free;
  FSystemOrigins.Free;
  FUndoManager.Free;
  FBackupManager.Free;
end;

procedure TMainForm.InitTrees;
begin
  UserTree.ViewStyle := vsReport;
  UserTree.Columns.Add.Caption := 'Name';
  UserTree.Columns.Add.Caption := 'Value';
  UserTree.Columns.Add.Caption := 'Origin';
  UserTree.Columns[0].Width := 200;
  UserTree.Columns[1].Width := 300;
  UserTree.Columns[2].Width := 250;
  UserTree.Align := alLeft;
  UserTree.Width := ClientWidth div 2 - Splitter1.Width div 2;
  UserTree.OnCustomDrawItem := @UserTreeCustomDrawItem;

  SystemTree.ViewStyle := vsReport;
  SystemTree.Columns.Add.Caption := 'Name';
  SystemTree.Columns.Add.Caption := 'Value';
  SystemTree.Columns.Add.Caption := 'Origin';
  SystemTree.Columns[0].Width := 200;
  SystemTree.Columns[1].Width := 300;
  SystemTree.Columns[2].Width := 250;
  SystemTree.Align := alClient;
end;

procedure TMainForm.LoadVariables;
var
  UserLoaded: TStringList;
  SystemLoaded: TStringList;
  UserOriginsLoaded: TStringList;
  SystemOriginsLoaded: TStringList;
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

  UserOriginsLoaded := FProvider.LoadUserVariableOrigins;
  try
    FUserOrigins.Assign(UserOriginsLoaded);
  finally
    UserOriginsLoaded.Free;
  end;

  SystemOriginsLoaded := FProvider.LoadSystemVariableOrigins;
  try
    FSystemOrigins.Assign(SystemOriginsLoaded);
  finally
    SystemOriginsLoaded.Free;
  end;

  PopulateTree(UserTree, FUserVars, FUserOrigins);
  PopulateTree(SystemTree, FSystemVars, FSystemOrigins);
  RefreshDiagnostics;
end;

procedure TMainForm.PopulateTree(ATree: TListView; AVars: TStringList; AOrigins: TStringList);
var
  I: Integer;
  Item: TListItem;
  Key: string;
  Origin: string;
begin
  ATree.Items.Clear;
  for I := 0 to AVars.Count - 1 do
  begin
    Item := ATree.Items.Add;
    Key := AVars.Names[I];
    Item.Caption := Key;
    Item.SubItems.Add(AVars.ValueFromIndex[I]);
    if Assigned(AOrigins) then
      Origin := AOrigins.Values[Key]
    else
      Origin := '';
    Item.SubItems.Add(Origin);
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
    PopulateTree(UserTree, FUserVars, FUserOrigins);
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
    PopulateTree(UserTree, FUserVars, FUserOrigins);
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

procedure TMainForm.EditVariable(const CurrentName, CurrentValue: string; out NewName, NewValue: string; out Accepted: Boolean);
var
  Dlg: TForm;
  EdName, EdValue: TEdit;
  LblName, LblValue: TLabel;
  BtnOK, BtnCancel: TButton;
  NameResult, ValueResult: string;
begin
  Dlg := TForm.CreateNew(nil);
  try
    Dlg.Caption := 'Edit Variable';
    Dlg.Width := 400;
    Dlg.Height := 180;
    Dlg.Position := poScreenCenter;
    Dlg.BorderStyle := bsDialog;

    LblName := TLabel.Create(Dlg);
    LblName.Parent := Dlg;
    LblName.Left := 16;
    LblName.Top := 16;
    LblName.Caption := 'Name:';

    EdName := TEdit.Create(Dlg);
    EdName.Parent := Dlg;
    EdName.Left := 80;
    EdName.Top := 12;
    EdName.Width := 280;
    EdName.Text := CurrentName;

    LblValue := TLabel.Create(Dlg);
    LblValue.Parent := Dlg;
    LblValue.Left := 16;
    LblValue.Top := 56;
    LblValue.Caption := 'Value:';

    EdValue := TEdit.Create(Dlg);
    EdValue.Parent := Dlg;
    EdValue.Left := 80;
    EdValue.Top := 52;
    EdValue.Width := 280;
    EdValue.Text := CurrentValue;

    BtnOK := TButton.Create(Dlg);
    BtnOK.Parent := Dlg;
    BtnOK.Caption := 'OK';
    BtnOK.ModalResult := mrOK;
    BtnOK.Left := 200;
    BtnOK.Top := 100;
    BtnOK.Default := True;

    BtnCancel := TButton.Create(Dlg);
    BtnCancel.Parent := Dlg;
    BtnCancel.Caption := 'Cancel';
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Left := 290;
    BtnCancel.Top := 100;

    if Dlg.ShowModal = mrOK then
    begin
      NameResult := Trim(EdName.Text);
      ValueResult := EdValue.Text;
      NewName := NameResult;
      NewValue := ValueResult;
      Accepted := NameResult <> '';
    end
    else
      Accepted := False;
  finally
    Dlg.Free;
  end;
end;

procedure TMainForm.UserTreeDblClick(Sender: TObject);
var
  Item: TListItem;
  OrigName, OrigValue: string;
  NewName, NewValue: string;
  Accepted: Boolean;
  Idx: Integer;
begin
  if UserTree.Selected = nil then
    Exit;
  Item := UserTree.Selected;
  OrigName := Item.Caption;
  OrigValue := Item.SubItems[0];

  EditVariable(OrigName, OrigValue, NewName, NewValue, Accepted);
  if not Accepted then
    Exit;

  FUndoManager.PushState(FUserVars);
  Idx := FUserVars.IndexOfName(OrigName);
  if Idx >= 0 then
    FUserVars.Delete(Idx);
  FUserVars.Add(NewName + '=' + NewValue);
  FProvider.SaveUserVariables(FUserVars);
  LoadVariables;
end;

procedure TMainForm.BtnAddClick(Sender: TObject);
var
  NewName, NewValue: string;
  Accepted: Boolean;
begin
  EditVariable('', '', NewName, NewValue, Accepted);
  if not Accepted then
    Exit;

  FUndoManager.PushState(FUserVars);
  FUserVars.Values[NewName] := NewValue;
  FProvider.SaveUserVariables(FUserVars);
  LoadVariables;
end;

procedure TMainForm.BtnDeleteClick(Sender: TObject);
var
  Item: TListItem;
  Idx: Integer;
begin
  if UserTree.Selected = nil then
    Exit;
  Item := UserTree.Selected;
  Idx := FUserVars.IndexOfName(Item.Caption);
  if Idx < 0 then
    Exit;

  FUndoManager.PushState(FUserVars);
  FUserVars.Delete(Idx);
  FProvider.SaveUserVariables(FUserVars);
  LoadVariables;
end;

end.
