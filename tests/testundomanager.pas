unit undomanager;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
Classes, SysUtils, Contnrs;

type
TUndoManager = class
private
FStack: TObjectList;
FIndex: Integer;
public
constructor Create;
destructor Destroy; override;
procedure Push(AState: TStringList);
function Undo: TStringList;
function Redo: TStringList;
function CanUndo: Boolean;
function CanRedo: Boolean;
end;

implementation

constructor TUndoManager.Create;
begin
inherited Create;
FStack := TObjectList.Create(True);
FIndex := -1;
end;

destructor TUndoManager.Destroy;
begin
FStack.Free;
inherited Destroy;
end;

procedure TUndoManager.Push(AState: TStringList);
var
CopyState: TStringList;
I: Integer;
begin
while FStack.Count - 1 > FIndex do
FStack.Delete(FStack.Count - 1);
CopyState := TStringList.Create;
for I := 0 to AState.Count - 1 do
CopyState.Add(AState[I]);
FStack.Add(CopyState);
FIndex := FStack.Count - 1;
end;

function TUndoManager.Undo: TStringList;
begin
if FIndex >= 0 then
begin
Result := TStringList.Create;
Result.Assign(TStringList(FStack[FIndex]));
Dec(FIndex);
end
else
begin
Result := TStringList.Create;
end;
end;

function TUndoManager.Redo: TStringList;
begin
if FIndex < FStack.Count - 1 then
begin
Inc(FIndex);
Result := TStringList.Create;
Result.Assign(TStringList(FStack[FIndex]));
end
else
begin
Result := TStringList.Create;
end;
end;

function TUndoManager.CanUndo: Boolean;
begin
Result := FIndex >= 0;
end;

function TUndoManager.CanRedo: Boolean;
begin
Result := FIndex < FStack.Count - 1;
end;

end.