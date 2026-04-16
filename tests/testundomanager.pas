unit testundomanager;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, undomanager;

type
  TTestUndoManager = class(TTestCase)
  published
    procedure TestPushAndPop;
    procedure TestCanUndoRedo;
  end;

implementation

procedure TTestUndoManager.TestPushAndPop;
var
  Manager: TUndoManager;
  State1, State2: TStringList;
  Popped: TStringList;
begin
  Manager := TUndoManager.Create;
  try
    State1 := TStringList.Create;
    try
      State1.Add('PATH=/usr/bin');
      Manager.Push(State1);
    finally
      State1.Free;
    end;

    State2 := TStringList.Create;
    try
      State2.Add('PATH=/usr/local/bin');
      Manager.Push(State2);
    finally
      State2.Free;
    end;

    Popped := Manager.Undo;
    try
      AssertEquals('PATH=/usr/local/bin', Popped[0]);
    finally
      Popped.Free;
    end;
  finally
    Manager.Free;
  end;
end;

procedure TTestUndoManager.TestCanUndoRedo;
var
  Manager: TUndoManager;
  State: TStringList;
begin
  Manager := TUndoManager.Create;
  try
    AssertFalse(Manager.CanUndo);
    State := TStringList.Create;
    try
      State.Add('X=1');
      Manager.Push(State);
    finally
      State.Free;
    end;
    AssertTrue(Manager.CanUndo);
    Manager.Undo.Free;
    AssertTrue(Manager.CanRedo);
  finally
    Manager.Free;
  end;
end;

initialization
  RegisterTest(TTestUndoManager);
end.