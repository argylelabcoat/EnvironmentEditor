# OpenEnvEd Phase 3: Integration & Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect the UI to the Core Engine, implement diagnostic row painting (Red/Yellow/Blue), and integrate Backup/Restore into the GUI.

**Architecture:** The GUI form owns a single `IEnvProvider` instance and uses `TUndoManager` and `TBackupManager` for state management. Painting uses VirtualTreeView's `OnBeforeCellPaint` event.

**Tech Stack:** Free Pascal Compiler (FPC), Lazarus LCL, VirtualTrees.

---

## Task 13: Connect UI to Core Engine

**Files:**
- Modify: `src/gui/mainform.pas`
- Modify: `src/gui/mainform.lfm`

- [ ] **Step 1: Add core dependencies to mainform**

Modify `src/gui/mainform.pas` `uses` clause to include:
```pascal
uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, VirtualTrees, envproviderintf, undomanager, backupmanager;
```

- [ ] **Step 2: Add provider and manager fields**

Add to `TMainForm` private section:
```pascal
  private
    FProvider: IEnvProvider;
    FUndoManager: TUndoManager;
    FBackupManager: TBackupManager;
    FUserVars: TStringList;
    FSystemVars: TStringList;
    procedure LoadVariables;
    procedure SaveVariables;
```

- [ ] **Step 3: Implement LoadVariables and FormCreate initialization**

Modify `FormCreate`:
```pascal
procedure TMainForm.FormCreate(Sender: TObject);
begin
  InitTrees;
  Caption := 'OpenEnvEd';
  Width := 1024;
  Height := 768;

  FUndoManager := TUndoManager.Create;
  FBackupManager := TBackupManager.Create(GetAppConfigDir(False) + 'backup.env');
  FUserVars := TStringList.Create;
  FSystemVars := TStringList.Create;

  {$IFDEF MSWINDOWS}
  FProvider := TWinEnvProvider.Create;
  {$ELSEIF DEFINED(DARWIN)}
  FProvider := TMacEnvProvider.Create;
  {$ELSE}
  FProvider := TUnixEnvProvider.Create;
  {$ENDIF}

  LoadVariables;
end;
```

Add `LoadVariables`:
```pascal
procedure TMainForm.LoadVariables;
var
  Loaded: TStringList;
begin
  Loaded := FProvider.LoadUserVariables;
  try
    FUserVars.Assign(Loaded);
  finally
    Loaded.Free;
  end;

  Loaded := FProvider.LoadSystemVariables;
  try
    FSystemVars.Assign(Loaded);
  finally
    Loaded.Free;
  end;

  PopulateTree(FUserTree, FUserVars);
  PopulateTree(FSystemTree, FSystemVars);
end;
```

- [ ] **Step 4: Add FormDestroy cleanup**

Add `FormDestroy` to published section:
```pascal
  published
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
```

Implement:
```pascal
procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FUserVars.Free;
  FSystemVars.Free;
  FUndoManager.Free;
  FBackupManager.Free;
end;
```

- [ ] **Step 5: Add OnDestroy to LFM**

Modify `src/gui/mainform.lfm`: add `OnDestroy = FormDestroy` to the `MainForm` object:
```lfm
object MainForm: TMainForm
  ...
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  ...
```

- [ ] **Step 6: Build and verify**

Run:
```bash
lazbuild -B OpenEnvEd.lpi
```

Expected: Build succeeds with exit code `0`.

- [ ] **Step 7: Run JCF**

```bash
jcf src/gui/mainform.pas
```

- [ ] **Step 8: Commit**

```bash
git add src/gui/mainform.pas src/gui/mainform.lfm
git commit -m "feat(gui): wire provider and load user/system variables into trees"
```

---

## Task 14: Row Painting (Diagnostics Colors)

**Files:**
- Modify: `src/gui/mainform.pas`
- Modify: `src/utils/validator.pas`

- [ ] **Step 1: Add validator to mainform uses**

Modify `src/gui/mainform.pas` uses clause to include `validator`.

- [ ] **Step 2: Add OnBeforeCellPaint handlers**

Add to `TMainForm` private section:
```pascal
    procedure UserTreeBeforeCellPaint(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
    procedure SystemTreeBeforeCellPaint(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
```

Implement:
```pascal
procedure TMainForm.UserTreeBeforeCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
var
  Data: PEnvNodeData;
begin
  Data := Sender.GetNodeData(Node);
  if not Assigned(Data) then
    Exit;
  case Data^.Status of
    1: TargetCanvas.Brush.Color := RGB(255, 200, 200); // Red-ish: not found
    2: TargetCanvas.Brush.Color := RGB(255, 255, 200); // Yellow-ish: duplicate
    3: TargetCanvas.Brush.Color := RGB(200, 220, 255); // Blue-ish: overridden
    else Exit;
  end;
  TargetCanvas.FillRect(CellRect);
end;

procedure TMainForm.SystemTreeBeforeCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
var
  Data: PEnvNodeData;
begin
  Data := Sender.GetNodeData(Node);
  if not Assigned(Data) then
    Exit;
  case Data^.Status of
    1: TargetCanvas.Brush.Color := RGB(255, 200, 200);
    2: TargetCanvas.Brush.Color := RGB(255, 255, 200);
    else Exit;
  end;
  TargetCanvas.FillRect(CellRect);
end;
```

- [ ] **Step 3: Wire events in InitTrees**

Modify `InitTrees` to assign:
```pascal
  FUserTree.OnBeforeCellPaint := @UserTreeBeforeCellPaint;
  FSystemTree.OnBeforeCellPaint := @SystemTreeBeforeCellPaint;
```

- [ ] **Step 4: Add diagnostic refresh method**

Add to `TMainForm` private section:
```pascal
    procedure RefreshDiagnostics;
```

Implement:
```pascal
procedure TMainForm.RefreshDiagnostics;
var
  Node: PVirtualNode;
  Data: PEnvNodeData;
  Validator: TPathValidator;
  Paths: TStringList;
  Results: TStringList;
  I: Integer;
  PathVal: string;
begin
  Validator := TPathValidator.Create;
  try
    { User tree diagnostics }
    Node := FUserTree.GetFirst;
    while Assigned(Node) do
    begin
      Data := FUserTree.GetNodeData(Node);
      if Assigned(Data) and Data^.IsPathList then
      begin
        Paths := TPathUtils.SplitPath(Data^.Value, PathDelim);
        try
          Results := Validator.ValidateList(Paths);
          try
            for I := 0 to Paths.Count - 1 do
            begin
              PathVal := Paths[I];
              if Results.IndexOfName(PathVal) >= 0 then
              begin
                if StrToIntDef(Results.Values[PathVal], 0) = Ord(psDuplicate) then
                  Data^.Status := 2
                else if StrToIntDef(Results.Values[PathVal], 0) = Ord(psNotFound) then
                  Data^.Status := 1;
              end;
            end;
          finally
            Results.Free;
          end;
        finally
          Paths.Free;
        end;
      end;
      Node := FUserTree.GetNext(Node);
    end;

    { Override detection: if user var name exists in system vars }
    Node := FUserTree.GetFirst;
    while Assigned(Node) do
    begin
      Data := FUserTree.GetNodeData(Node);
      if Assigned(Data) and (FSystemVars.IndexOfName(Data^.Name) >= 0) then
        Data^.Status := 3;
      Node := FUserTree.GetNext(Node);
    end;
  finally
    Validator.Free;
  end;

  FUserTree.Invalidate;
  FSystemTree.Invalidate;
end;
```

Also add `pathutils` to the `uses` clause.

- [ ] **Step 5: Call RefreshDiagnostics after LoadVariables**

Modify `LoadVariables` to call `RefreshDiagnostics` at the end.

- [ ] **Step 6: Build and verify**

Run:
```bash
lazbuild -B OpenEnvEd.lpi
```

Expected: Build succeeds with exit code `0`.

- [ ] **Step 7: Run JCF**

```bash
jcf src/gui/mainform.pas
```

- [ ] **Step 8: Commit**

```bash
git add src/gui/mainform.pas
git commit -m "feat(gui): add diagnostic row coloring for invalid, duplicate, and overridden paths"
```

---

## Task 15: Backup/Restore UI Integration

**Files:**
- Modify: `src/gui/mainform.pas`
- Modify: `src/gui/mainform.lfm`

- [ ] **Step 1: Add button click handlers**

Add to `TMainForm` published section:
```pascal
    procedure BtnUndoClick(Sender: TObject);
    procedure BtnRedoClick(Sender: TObject);
    procedure BtnBackupClick(Sender: TObject);
```

Implement:
```pascal
procedure TMainForm.BtnUndoClick(Sender: TObject);
var
  State: TStringList;
begin
  if not FUndoManager.CanUndo then
    Exit;
  State := FUndoManager.Undo;
  try
    FUserVars.Assign(State);
    PopulateTree(FUserTree, FUserVars);
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
    PopulateTree(FUserTree, FUserVars);
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
```

- [ ] **Step 2: Wire events in LFM**

Modify `src/gui/mainform.lfm` to add click handlers:
```lfm
    object BtnUndo: TButton
      ...
      OnClick = BtnUndoClick
      ...
    end
    object BtnRedo: TButton
      ...
      OnClick = BtnRedoClick
      ...
    end
    object BtnBackup: TButton
      ...
      OnClick = BtnBackupClick
      ...
    end
```

- [ ] **Step 3: Push initial state to undo manager**

Modify `LoadVariables` to push the initial loaded state:
```pascal
procedure TMainForm.LoadVariables;
...
begin
  ...
  PopulateTree(FUserTree, FUserVars);
  PopulateTree(FSystemTree, FSystemVars);
  RefreshDiagnostics;
  FUndoManager.Push(FUserVars);
end;
```

- [ ] **Step 4: Build and verify**

Run:
```bash
lazbuild -B OpenEnvEd.lpi
```

Expected: Build succeeds with exit code `0`.

- [ ] **Step 5: Run JCF**

```bash
jcf src/gui/mainform.pas
```

- [ ] **Step 6: Commit**

```bash
git add src/gui/mainform.pas src/gui/mainform.lfm
git commit -m "feat(gui): integrate undo, redo, and backup buttons"
```

---

## Phase 3 Completion Checklist

- [ ] `lazbuild -B OpenEnvEd.lpi` succeeds.
- [ ] GUI runs without heaptrc leaks.
- [ ] VirtualTreeView displays user and system variables.
- [ ] Rows paint with correct diagnostic colors.
- [ ] Backup button writes a backup file.
- [ ] JCF has been run on all modified `.pas` files.
- [ ] Commit messages follow the format in AGENTS.md.
