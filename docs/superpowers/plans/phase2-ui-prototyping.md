# OpenEnvEd Phase 2: UI Prototyping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the main GUI form in Lazarus with a VirtualTreeView for high-performance rendering of environment variables.

**Architecture:** The GUI layer lives in `src/gui/` and depends only on `src/core/` and `src/providers/` via well-defined interfaces. No OS-specific code in the GUI units.

**Tech Stack:** Free Pascal Compiler (FPC), Lazarus LCL, VirtualTrees package.

---

## Task 11: GUI Project Setup and Main Form

**Files:**
- Modify: `OpenEnvEd.lpi`
- Create: `OpenEnvEd.lpr`
- Create: `src/gui/mainform.pas`
- Create: `src/gui/mainform.lfm`

- [ ] **Step 1: Create main program file OpenEnvEd.lpr**

Create `OpenEnvEd.lpr`:
```pascal
program OpenEnvEd;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

uses
  Interfaces,
  Forms,
  mainform;

begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
```

- [ ] **Step 2: Update OpenEnvEd.lpi to reference the program and GUI units**

Modify `OpenEnvEd.lpi`: insert the following inside `<ProjectOptions>` before `</ProjectOptions>`:
```xml
    <Units>
      <Unit>
        <Filename Value="OpenEnvEd.lpr"/>
        <IsPartOfProject Value="True"/>
      </Unit>
      <Unit>
        <Filename Value="src/gui/mainform.pas"/>
        <IsPartOfProject Value="True"/>
        <ComponentName Value="MainForm"/>
        <HasResources Value="True"/>
        <ResourceBaseClass Value="Form"/>
      </Unit>
    </Units>
```

Also ensure `OpenEnvEd.lpi` includes the VirtualTrees package. Add under `<RequiredPackages>`:
```xml
      <Item>
        <PackageName Value="virtualtreeview_package"/>
      </Item>
```

- [ ] **Step 3: Create src/gui/mainform.pas**

Create `src/gui/mainform.pas`:
```pascal
unit mainform;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, VirtualTrees;

type
  TMainForm = class(TForm)
    BottomPanel: TPanel;
    BtnUndo: TButton;
    BtnRedo: TButton;
    BtnBackup: TButton;
    Splitter1: TSplitter;
    StatusBar: TStatusBar;
    procedure FormCreate(Sender: TObject);
  private
    FUserTree: TVirtualStringTree;
    FSystemTree: TVirtualStringTree;
    procedure InitTrees;
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
end;

procedure TMainForm.InitTrees;
begin
  FUserTree := TVirtualStringTree.Create(Self);
  FUserTree.Parent := Self;
  FUserTree.Align := alLeft;
  FUserTree.Width := ClientWidth div 2 - Splitter1.Width div 2;
  FUserTree.Header.Options := FUserTree.Header.Options + [hoVisible];
  FUserTree.Header.Columns.Add.Text := 'User Variables';
  FUserTree.Header.Columns[0].Width := FUserTree.Width;

  FSystemTree := TVirtualStringTree.Create(Self);
  FSystemTree.Parent := Self;
  FSystemTree.Align := alClient;
  FSystemTree.Header.Options := FSystemTree.Header.Options + [hoVisible];
  FSystemTree.Header.Columns.Add.Text := 'System Variables';
  FSystemTree.Header.Columns[0].Width := FSystemTree.Width;
end;

end.
```

- [ ] **Step 4: Create src/gui/mainform.lfm**

Create `src/gui/mainform.lfm`:
```lfm
object MainForm: TMainForm
  Left = 0
  Height = 768
  Top = 0
  Width = 1024
  Caption = 'OpenEnvEd'
  ClientHeight = 768
  ClientWidth = 1024
  OnCreate = FormCreate
  LCLVersion = '3.0.0.1'
  object BottomPanel: TPanel
    Left = 0
    Height = 41
    Top = 727
    Width = 1024
    Align = alBottom
    BevelOuter = bvNone
    ClientHeight = 41
    ClientWidth = 1024
    TabOrder = 0
    object BtnUndo: TButton
      Left = 8
      Height = 25
      Top = 8
      Width = 75
      Caption = 'Undo'
      TabOrder = 0
    end
    object BtnRedo: TButton
      Left = 88
      Height = 25
      Top = 8
      Width = 75
      Caption = 'Redo'
      TabOrder = 1
    end
    object BtnBackup: TButton
      Left = 168
      Height = 25
      Top = 8
      Width = 75
      Caption = 'Backup'
      TabOrder = 2
    end
  end
  object Splitter1: TSplitter
    Cursor = crHSplit
    Left = 508
    Height = 727
    Top = 0
    Width = 5
  end
  object StatusBar: TStatusBar
    Left = 0
    Height = 23
    Top = 745
    Width = 1024
    Panels = <>
    SimplePanel = False
  end
end
```

- [ ] **Step 5: Build GUI project**

Run:
```bash
lazbuild -B OpenEnvEd.lpi
```

Expected: Build succeeds with exit code `0`.

- [ ] **Step 6: Run JCF on GUI files**

```bash
jcf src/gui/mainform.pas OpenEnvEd.lpr
```

- [ ] **Step 7: Commit**

```bash
git add OpenEnvEd.lpr src/gui/mainform.pas src/gui/mainform.lfm OpenEnvEd.lpi
git commit -m "feat(gui): add main form with split tree layout and toolbar"
```

---

## Task 12: Virtual Tree View for Variables

**Files:**
- Modify: `src/gui/mainform.pas`
- Modify: `src/gui/mainform.lfm`

- [ ] **Step 1: Define tree node record type**

Modify `src/gui/mainform.pas` interface section. Add after the `uses` clause and before the type declaration:
```pascal
type
  PEnvNodeData = ^TEnvNodeData;
  TEnvNodeData = record
    Name: string;
    Value: string;
    IsPathList: Boolean;
    Status: Integer; // 0=valid, 1=not found, 2=duplicate, 3=overridden
  end;
```

- [ ] **Step 2: Add OnGetText event handlers**

Add two private methods to `TMainForm`:
```pascal
  private
    procedure UserTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure SystemTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
```

And implement them in the `implementation` section:
```pascal
procedure TMainForm.UserTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
var
  Data: PEnvNodeData;
begin
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) then
    CellText := Data^.Name;
end;

procedure TMainForm.SystemTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
var
  Data: PEnvNodeData;
begin
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) then
    CellText := Data^.Name;
end;
```

- [ ] **Step 3: Wire events in InitTrees**

Modify `InitTrees` to connect the event handlers:
```pascal
procedure TMainForm.InitTrees;
begin
  FUserTree := TVirtualStringTree.Create(Self);
  FUserTree.Parent := Self;
  FUserTree.Align := alLeft;
  FUserTree.Width := ClientWidth div 2 - Splitter1.Width div 2;
  FUserTree.Header.Options := FUserTree.Header.Options + [hoVisible];
  FUserTree.Header.Columns.Add.Text := 'Name';
  FUserTree.Header.Columns[0].Width := FUserTree.Width div 2;
  FUserTree.Header.Columns.Add.Text := 'Value';
  FUserTree.Header.Columns[1].Width := FUserTree.Width div 2;
  FUserTree.TreeOptions.PaintOptions := FUserTree.TreeOptions.PaintOptions +
    [toShowHorzGridLines, toShowVertGridLines];
  FUserTree.OnGetText := @UserTreeGetText;

  FSystemTree := TVirtualStringTree.Create(Self);
  FSystemTree.Parent := Self;
  FSystemTree.Align := alClient;
  FSystemTree.Header.Options := FSystemTree.Header.Options + [hoVisible];
  FSystemTree.Header.Columns.Add.Text := 'Name';
  FSystemTree.Header.Columns[0].Width := FSystemTree.Width div 2;
  FSystemTree.Header.Columns.Add.Text := 'Value';
  FSystemTree.Header.Columns[1].Width := FSystemTree.Width div 2;
  FSystemTree.TreeOptions.PaintOptions := FSystemTree.TreeOptions.PaintOptions +
    [toShowHorzGridLines, toShowVertGridLines];
  FSystemTree.OnGetText := @SystemTreeGetText;
end;
```

- [ ] **Step 4: Add Populate method**

Add a public method to `TMainForm`:
```pascal
  public
    procedure PopulateTree(ATree: TVirtualStringTree; AVars: TStringList);
```

Implement it:
```pascal
procedure TMainForm.PopulateTree(ATree: TVirtualStringTree; AVars: TStringList);
var
  I: Integer;
  Node: PVirtualNode;
  Data: PEnvNodeData;
begin
  ATree.Clear;
  for I := 0 to AVars.Count - 1 do
  begin
    Node := ATree.AddChild(nil);
    Data := ATree.GetNodeData(Node);
    if Assigned(Data) then
    begin
      Data^.Name := AVars.Names[I];
      Data^.Value := AVars.ValueFromIndex[I];
      Data^.IsPathList := Pos(PathDelim, Data^.Value) > 0;
      Data^.Status := 0;
    end;
  end;
end;
```

- [ ] **Step 5: Build and verify GUI**

Run:
```bash
lazbuild -B OpenEnvEd.lpi
```

Expected: Build succeeds with exit code `0`.

- [ ] **Step 6: Run JCF**

```bash
jcf src/gui/mainform.pas
```

- [ ] **Step 7: Commit**

```bash
git add src/gui/mainform.pas src/gui/mainform.lfm
git commit -m "feat(gui): add VirtualTreeView nodes with name/value columns"
```

---

## Phase 2 Completion Checklist

- [ ] `lazbuild -B OpenEnvEd.lpi` succeeds.
- [ ] `OpenEnvEd.lpi` has `-gh` in debug options.
- [ ] `src/gui/mainform.pas` starts with the strict directive block.
- [ ] GUI compiles and runs without heaptrc leaks.
- [ ] No OS-specific code exists in `src/gui/`.
- [ ] JCF has been run on all modified `.pas` files.
