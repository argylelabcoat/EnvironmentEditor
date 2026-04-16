unit winenvprovider;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, envproviderintf;

type
  TWinEnvProvider = class(TInterfacedObject, IEnvProvider)
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
  end;

implementation

{$IFDEF MSWINDOWS}
uses
  Registry, Windows;

constructor TWinEnvProvider.Create;
begin
  inherited Create;
  FUserRoot := HKEY_CURRENT_USER;
  FSystemRoot := HKEY_LOCAL_MACHINE;
end;

function TWinEnvProvider.LoadUserVariables: TStringList;
var
  Reg: TRegistry;
begin
  Result := TStringList.Create;
  Reg := TRegistry.Create;
  try
    Reg.RootKey := FUserRoot;
    if Reg.OpenKeyReadOnly('Environment') then
    begin
      Reg.GetValueNames(Result);
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

function TWinEnvProvider.LoadSystemVariables: TStringList;
var
  Reg: TRegistry;
begin
  Result := TStringList.Create;
  Reg := TRegistry.Create;
  try
    Reg.RootKey := FSystemRoot;
    if Reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Control\Session Manager\Environment') then
    begin
      Reg.GetValueNames(Result);
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

function TWinEnvProvider.LoadUserVariableOrigins: TStringList;
var
  Reg: TRegistry;
  Names: TStringList;
  I: Integer;
  Origin: string;
begin
  Result := TStringList.Create;
  Names := TStringList.Create;
  try
    Reg := TRegistry.Create;
    try
      Reg.RootKey := FUserRoot;
      Origin := 'Registry: HKCU\Environment';
      if Reg.OpenKeyReadOnly('Environment') then
      begin
        Reg.GetValueNames(Names);
        Reg.CloseKey;
      end;
    finally
      Reg.Free;
    end;
    for I := 0 to Names.Count - 1 do
      Result.Values[Names[I]] := Origin;
  finally
    Names.Free;
  end;
end;

function TWinEnvProvider.LoadSystemVariableOrigins: TStringList;
var
  Reg: TRegistry;
  Names: TStringList;
  I: Integer;
  Origin: string;
begin
  Result := TStringList.Create;
  Names := TStringList.Create;
  try
    Reg := TRegistry.Create;
    try
      Reg.RootKey := FSystemRoot;
      Origin := 'Registry: HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment';
      if Reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Control\Session Manager\Environment') then
      begin
        Reg.GetValueNames(Names);
        Reg.CloseKey;
      end;
    finally
      Reg.Free;
    end;
    for I := 0 to Names.Count - 1 do
      Result.Values[Names[I]] := Origin;
  finally
    Names.Free;
  end;
end;

function TWinEnvProvider.SaveUserVariables(Vars: TStringList): Boolean;
begin
  Result := True;
end;

function TWinEnvProvider.SaveSystemVariables(Vars: TStringList): Boolean;
begin
  Result := True;
end;

procedure TWinEnvProvider.BroadcastEnvironmentChange;
var
  Result: DWORD;
begin
  SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0, LPARAM(PChar('Environment')),
    SMTO_ABORTIFHUNG, 5000, @Result);
end;

destructor TWinEnvProvider.Destroy;
begin
  inherited Destroy;
end;
{$ELSE}
constructor TWinEnvProvider.Create;
begin
  inherited Create;
end;

function TWinEnvProvider.LoadUserVariables: TStringList;
begin
  Result := TStringList.Create;
end;

function TWinEnvProvider.LoadSystemVariables: TStringList;
begin
  Result := TStringList.Create;
end;

function TWinEnvProvider.LoadUserVariableOrigins: TStringList;
begin
  Result := TStringList.Create;
end;

function TWinEnvProvider.LoadSystemVariableOrigins: TStringList;
begin
  Result := TStringList.Create;
end;

function TWinEnvProvider.SaveUserVariables(Vars: TStringList): Boolean;
begin
  Result := False;
end;

function TWinEnvProvider.SaveSystemVariables(Vars: TStringList): Boolean;
begin
  Result := False;
end;

procedure TWinEnvProvider.BroadcastEnvironmentChange;
begin
end;

destructor TWinEnvProvider.Destroy;
begin
  inherited Destroy;
end;
{$ENDIF}

end.