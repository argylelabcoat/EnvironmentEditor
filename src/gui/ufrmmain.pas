unit ufrmmain;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls;

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
  private
    FUserVars: TStringList;
    FSystemVars: TStringList;
    procedure InitTrees;
    procedure PopulateTree(ATree: TListView; AVars: TStringList);
  public
  end;

var
  MainForm: TMainForm;

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
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FUserVars.Free;
  FSystemVars.Free;
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

  SystemTree.ViewStyle := vsReport;
  SystemTree.Columns.Add.Caption := 'Name';
  SystemTree.Columns.Add.Caption := 'Value';
  SystemTree.Columns[0].Width := 200;
  SystemTree.Columns[1].Width := 400;
  SystemTree.Align := alClient;
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

end.