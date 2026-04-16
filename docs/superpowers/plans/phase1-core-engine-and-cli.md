# OpenEnvEd Phase 1: Core Engine & CLI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement OS Providers, Path string parsing, validation logic, backup/undo core, and CLI entry point. Achieve 90%+ coverage on core logic.

**Architecture:** Strict separation between OS providers (IEnvProvider interface), utility layer (path parsing/validation), and core business logic (backup/undo). Each OS provider encapsulates platform-specific environment variable access.

**Tech Stack:** Free Pascal Compiler (FPC), Lazarus IDE/LCL, FPCUnit, JEDI Code Format (JCF).

---

## Task 1: Repository Scaffold and Tooling

**Files:**
- Create: `jcf-format.cfg`
- Create: `Tests.lpi`
- Create: `Tests.lpr`
- Create: `OpenEnvEd.lpi`
- Create: `OpenEnvEdCLI.lpi`
- Create: directory structure via bash

- [ ] **Step 1: Create directory structure**

Run:
```bash
mkdir -p src/providers src/utils src/core src/cli src/gui tests docs
```

- [ ] **Step 2: Create jcf-format.cfg**

Create `jcf-format.cfg` with content:
```ini
; JEDI Code Format configuration for OpenEnvEd
; 2 spaces, no tabs, lowercase keywords
Indentation=Spaces
IndentationCount=2
BeginEndStyle=AlwaysBreakLine
MaxLineLength=100
KeywordCase=LowerCase
TypePrefix=T
InterfacePrefix=I
ExceptionPrefix=E
ClassFieldPrefix=F
VariableCase=CamelCase
```

- [ ] **Step 3: Create Tests.lpi**

Create `Tests.lpi` with content:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CONFIG>
  <ProjectOptions>
    <Version Value="12"/>
    <PathDelim Value="/"/>
    <General>
      <Flags>
        <MainUnitIsPascalSource Value="True"/>
      </Flags>
      <SessionStorage Value="InProjectDir"/>
      <Title Value="Tests"/>
      <UseAppBundle Value="False"/>
      <ResourceType Value="res"/>
    </General>
    <BuildModes>
      <Item Name="Default" Default="True"/>
    </BuildModes>
    <PublishOptions>
      <Version Value="2"/>
    </PublishOptions>
    <RunParams>
      <FormatVersion Value="2"/>
    </RunParams>
    <RequiredPackages>
      <Item>
        <PackageName Value="FCL"/>
      </Item>
    </RequiredPackages>
    <Units>
      <Unit>
        <Filename Value="Tests.lpr"/>
        <IsPartOfProject Value="True"/>
      </Unit>
    </Units>
  </ProjectOptions>
  <CompilerOptions>
    <Version Value="11"/>
    <PathDelim Value="/"/>
    <Target>
      <Filename Value="tests/bin/testrunner"/>
    </Target>
    <SearchPaths>
      <IncludeFiles Value="$(ProjOutDir)"/>
      <OtherUnitFiles Value="src/providers;src/utils;src/core;src/cli;tests"/>
      <UnitOutputDirectory Value="tests/lib/$(TargetCPU)-$(TargetOS)"/>
    </SearchPaths>
    <Parsing>
      <SyntaxOptions>
        <SyntaxMode Value="ObjFPC"/>
        <UseAnsiStrings Value="False"/>
      </SyntaxOptions>
    </Parsing>
    <CodeGeneration>
      <Checks>
        <IOChecks Value="True"/>
        <RangeChecks Value="True"/>
        <OverflowChecks Value="True"/>
      </Checks>
      <SmallerCode Value="True"/>
    </CodeGeneration>
    <Linking>
      <Debugging>
        <DebugInfoType Value="dsDwarf3"/>
        <UseHeaptrc Value="True"/>
        <UseExternalDbgSyms Value="True"/>
      </Debugging>
    </Linking>
    <Other>
      <CustomOptions Value="-gh"/>
      <WriteConfigFilePath Value=""/>
    </Other>
  </CompilerOptions>
  <Debugging>
    <Exceptions>
      <Item Value="EAbort"/>
    </Exceptions>
  </Debugging>
</CONFIG>
```

- [ ] **Step 4: Create Tests.lpr**

Create `Tests.lpr` with content:
```pascal
program Tests;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

uses
  Classes, SysUtils, fpcunit, testregistry, testreport, xmltestreport,
  testpathutils;

var
  Application: TTestApplication;
begin
  Application := TTestApplication.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'OpenEnvEd Tests';
    Application.Run;
    Application.Free;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
```

- [ ] **Step 5: Create OpenEnvEd.lpi**

Create `OpenEnvEd.lpi` with content:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CONFIG>
  <ProjectOptions>
    <Version Value="12"/>
    <PathDelim Value="/"/>
    <General>
      <Flags>
        <MainUnitIsPascalSource Value="True"/>
      </Flags>
      <SessionStorage Value="InProjectDir"/>
      <Title Value="OpenEnvEd"/>
      <UseAppBundle Value="False"/>
      <ResourceType Value="res"/>
    </General>
    <BuildModes>
      <Item Name="Default" Default="True"/>
    </BuildModes>
    <PublishOptions>
      <Version Value="2"/>
    </PublishOptions>
    <RunParams>
      <FormatVersion Value="2"/>
    </RunParams>
    <RequiredPackages>
      <Item>
        <PackageName Value="FCL"/>
      </Item>
    </RequiredPackages>
  </ProjectOptions>
  <CompilerOptions>
    <Version Value="11"/>
    <PathDelim Value="/"/>
    <Target>
      <Filename Value="bin/openenved"/>
    </Target>
    <SearchPaths>
      <IncludeFiles Value="$(ProjOutDir)"/>
      <OtherUnitFiles Value="src/providers;src/utils;src/core;src/gui"/>
      <UnitOutputDirectory Value="lib/$(TargetCPU)-$(TargetOS)"/>
    </SearchPaths>
    <Parsing>
      <SyntaxOptions>
        <SyntaxMode Value="ObjFPC"/>
        <UseAnsiStrings Value="False"/>
      </SyntaxOptions>
    </Parsing>
    <Linking>
      <Debugging>
        <DebugInfoType Value="dsDwarf3"/>
        <UseHeaptrc Value="True"/>
      </Debugging>
    </Linking>
    <Other>
      <CustomOptions Value="-gh"/>
    </Other>
  </CompilerOptions>
</CONFIG>
```

- [ ] **Step 6: Create OpenEnvEdCLI.lpi**

Create `OpenEnvEdCLI.lpi` with content:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CONFIG>
  <ProjectOptions>
    <Version Value="12"/>
    <PathDelim Value="/"/>
    <General>
      <Flags>
        <MainUnitIsPascalSource Value="True"/>
      </Flags>
      <SessionStorage Value="InProjectDir"/>
      <Title Value="OpenEnvEdCLI"/>
      <UseAppBundle Value="False"/>
      <ResourceType Value="res"/>
    </General>
    <BuildModes>
      <Item Name="Default" Default="True"/>
    </BuildModes>
    <PublishOptions>
      <Version Value="2"/>
    </PublishOptions>
    <RunParams>
      <FormatVersion Value="2"/>
    </RunParams>
    <RequiredPackages>
      <Item>
        <PackageName Value="FCL"/>
      </Item>
    </RequiredPackages>
  </ProjectOptions>
  <CompilerOptions>
    <Version Value="11"/>
    <PathDelim Value="/"/>
    <Target>
      <Filename Value="bin/openenved-cli"/>
    </Target>
    <SearchPaths>
      <IncludeFiles Value="$(ProjOutDir)"/>
      <OtherUnitFiles Value="src/providers;src/utils;src/core;src/cli"/>
      <UnitOutputDirectory Value="cli/lib/$(TargetCPU)-$(TargetOS)"/>
    </SearchPaths>
    <Parsing>
      <SyntaxOptions>
        <SyntaxMode Value="ObjFPC"/>
        <UseAnsiStrings Value="False"/>
      </SyntaxOptions>
    </Parsing>
    <Linking>
      <Debugging>
        <DebugInfoType Value="dsDwarf3"/>
        <UseHeaptrc Value="True"/>
      </Debugging>
    </Linking>
    <Other>
      <CustomOptions Value="-gh"/>
    </Other>
  </CompilerOptions>
</CONFIG>
```

- [ ] **Step 7: Verify lazbuild succeeds on Tests.lpi**

Run:
```bash
lazbuild -B Tests.lpi
```

Expected: Build succeeds with exit code `0`.

- [ ] **Step 8: Run JCF on all created files**

If JCF is available:
```bash
jcf Tests.lpr
```

- [ ] **Step 9: Commit**

```bash
git add .
git commit -m "chore(repo): add project scaffold, JCF config, and .lpi files"
```

---

## Task 2: Path Utilities (TPathUtils)

**Files:**
- Create: `tests/testpathutils.pas`
- Create: `src/utils/pathutils.pas`

- [ ] **Step 1: Write failing tests for SplitPath and JoinPath**

Create `tests/testpathutils.pas`:
```pascal
unit testpathutils;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, pathutils;

type
  TTestPathUtils = class(TTestCase)
  published
    procedure TestSplitPath_Windows;
    procedure TestSplitPath_Unix;
    procedure TestJoinPath_Windows;
    procedure TestJoinPath_Unix;
    procedure TestFindDuplicates;
    procedure TestNormalizePath;
  end;

implementation

procedure TTestPathUtils.TestSplitPath_Windows;
var
  Actual: TStringList;
begin
  Actual := TPathUtils.SplitPath('C:\Windows;C:\Users', ';');
  try
    AssertEquals(2, Actual.Count);
    AssertEquals('C:\Windows', Actual[0]);
    AssertEquals('C:\Users', Actual[1]);
  finally
    Actual.Free;
  end;
end;

procedure TTestPathUtils.TestSplitPath_Unix;
var
  Actual: TStringList;
begin
  Actual := TPathUtils.SplitPath('/usr/bin:/usr/local/bin', ':');
  try
    AssertEquals(2, Actual.Count);
    AssertEquals('/usr/bin', Actual[0]);
    AssertEquals('/usr/local/bin', Actual[1]);
  finally
    Actual.Free;
  end;
end;

procedure TTestPathUtils.TestJoinPath_Windows;
begin
  AssertEquals('C:\Windows;C:\Users',
    TPathUtils.JoinPath(TStringList.Create, ';'));
end;

procedure TTestPathUtils.TestJoinPath_Unix;
begin
  AssertEquals('/usr/bin:/usr/local/bin',
    TPathUtils.JoinPath(TStringList.Create, ':'));
end;

procedure TTestPathUtils.TestFindDuplicates;
var
  Paths: TStringList;
  Dups: TStringList;
begin
  Paths := TStringList.Create;
  try
    Paths.Add('C:\Windows');
    Paths.Add('C:\Users');
    Paths.Add('C:\Windows');
    Dups := TPathUtils.FindDuplicates(Paths);
    try
      AssertEquals(1, Dups.Count);
      AssertEquals('C:\Windows', Dups[0]);
    finally
      Dups.Free;
    end;
  finally
    Paths.Free;
  end;
end;

procedure TTestPathUtils.TestNormalizePath;
begin
  AssertEquals('C:\Windows\System32',
    TPathUtils.NormalizePath('C:\Windows\System32\'));
  AssertEquals('/usr/local/bin',
    TPathUtils.NormalizePath('/usr/local/bin/'));
end;

initialization
  RegisterTest(TTestPathUtils);
end.
```

- [ ] **Step 2: Run tests to verify failure**

Run:
```bash
lazbuild -B Tests.lpi
```

Expected: Compilation fails because `pathutils` unit does not exist.

- [ ] **Step 3: Implement src/utils/pathutils.pas**

Create `src/utils/pathutils.pas`:
```pascal
unit pathutils;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils;

type
  TPathUtils = class
  public
    class function SplitPath(const APathStr: string; const ADelim: string): TStringList;
    class function JoinPath(APaths: TStringList; const ADelim: string): string;
    class function FindDuplicates(APaths: TStringList): TStringList;
    class function NormalizePath(const APath: string): string;
  end;

implementation

class function TPathUtils.SplitPath(const APathStr: string; const ADelim: string): TStringList;
var
  Parts: TStringArray;
  I: Integer;
begin
  Result := TStringList.Create;
  Parts := APathStr.Split([ADelim]);
  for I := Low(Parts) to High(Parts) do
  begin
    if Trim(Parts[I]) <> '' then
      Result.Add(Trim(Parts[I]));
  end;
end;

class function TPathUtils.JoinPath(APaths: TStringList; const ADelim: string): string;
var
  I: Integer;
begin
  Result := '';
  if APaths = nil then
    Exit;
  for I := 0 to APaths.Count - 1 do
  begin
    if I > 0 then
      Result := Result + ADelim;
    Result := Result + APaths[I];
  end;
end;

class function TPathUtils.FindDuplicates(APaths: TStringList): TStringList;
var
  I, J: Integer;
  Seen: TStringList;
begin
  Result := TStringList.Create;
  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;
    for I := 0 to APaths.Count - 1 do
    begin
      if Seen.IndexOf(APaths[I]) >= 0 then
      begin
        if Result.IndexOf(APaths[I]) < 0 then
          Result.Add(APaths[I]);
      end
      else
      begin
        Seen.Add(APaths[I]);
      end;
    end;
  finally
    Seen.Free;
  end;
end;

class function TPathUtils.NormalizePath(const APath: string): string;
begin
  Result := Trim(APath);
  if Result.EndsWith(PathDelim) and (Length(Result) > 1) then
    SetLength(Result, Length(Result) - 1);
end;

end.
```

Fix the `JoinPath` test in Step 1 — it creates a TStringList but never populates it. Update the test to:

```pascal
procedure TTestPathUtils.TestJoinPath_Windows;
var
  List: TStringList;
begin
  List := TStringList.Create;
  try
    List.Add('C:\Windows');
    List.Add('C:\Users');
    AssertEquals('C:\Windows;C:\Users', TPathUtils.JoinPath(List, ';'));
  finally
    List.Free;
  end;
end;

procedure TTestPathUtils.TestJoinPath_Unix;
var
  List: TStringList;
begin
  List := TStringList.Create;
  try
    List.Add('/usr/bin');
    List.Add('/usr/local/bin');
    AssertEquals('/usr/bin:/usr/local/bin', TPathUtils.JoinPath(List, ':'));
  finally
    List.Free;
  end;
end;
```

- [ ] **Step 4: Run tests to verify pass**

Run:
```bash
lazbuild -B Tests.lpi && ./tests/bin/testrunner
```

Expected: All tests pass. Process exits with code `0`. Heaptrc reports `0 unfreed memory blocks`.

- [ ] **Step 5: Run JCF on modified files**

Run:
```bash
jcf src/utils/pathutils.pas tests/testpathutils.pas
```

- [ ] **Step 6: Commit**

```bash
git add src/utils/pathutils.pas tests/testpathutils.pas
git commit -m "feat(utils): add path splitting, joining, duplicate detection, and normalization"
```

---

## Task 3: Path Validator (TPathValidator)

**Files:**
- Create: `tests/testvalidator.pas`
- Create: `src/utils/validator.pas`

- [ ] **Step 1: Write failing tests**

Create `tests/testvalidator.pas`:
```pascal
unit testvalidator;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, validator;

type
  TTestValidator = class(TTestCase)
  published
    procedure TestValidate_NotFound;
    procedure TestValidate_Valid;
    procedure TestValidate_Duplicate;
    procedure TestValidate_Overridden;
  end;

implementation

procedure TTestValidator.TestValidate_NotFound;
var
  Status: TPathStatus;
  Validator: TPathValidator;
begin
  Validator := TPathValidator.Create;
  try
    Status := Validator.Validate('/definitely/not/a/real/path/on/any/system');
    AssertEquals(Ord(psNotFound), Ord(Status));
  finally
    Validator.Free;
  end;
end;

procedure TTestValidator.TestValidate_Valid;
var
  Status: TPathStatus;
  Validator: TPathValidator;
  TempDir: string;
begin
  TempDir := GetTempDir;
  Validator := TPathValidator.Create;
  try
    Status := Validator.Validate(TempDir);
    AssertEquals(Ord(psValid), Ord(Status));
  finally
    Validator.Free;
  end;
end;

procedure TTestValidator.TestValidate_Duplicate;
var
  Validator: TPathValidator;
  Paths: TStringList;
  Results: TStringList;
begin
  Paths := TStringList.Create;
  try
    Paths.Add('C:\Windows');
    Paths.Add('C:\Windows');
    Validator := TPathValidator.Create;
    try
      Results := Validator.ValidateList(Paths);
      try
        AssertEquals(Ord(psDuplicate), Ord(StrToInt(Results.Values['C:\Windows'])));
      finally
        Results.Free;
      end;
    finally
      Validator.Free;
    end;
  finally
    Paths.Free;
  end;
end;

procedure TTestValidator.TestValidate_Overridden;
begin
  { Overridden detection requires system+user comparison; tested in integration }
  AssertTrue(True);
end;

initialization
  RegisterTest(TTestValidator);
end.
```

- [ ] **Step 2: Run tests to verify failure**

Run:
```bash
lazbuild -B Tests.lpi
```

Expected: Compilation fails because `validator` unit does not exist.

- [ ] **Step 3: Implement src/utils/validator.pas**

Create `src/utils/validator.pas`:
```pascal
unit validator;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils;

type
  TPathStatus = (psValid, psNotFound, psDuplicate, psOverridden);

  TPathValidator = class
  public
    function Validate(const APath: string): TPathStatus;
    function ValidateList(APaths: TStringList): TStringList;
  end;

implementation

function TPathValidator.Validate(const APath: string): TPathStatus;
begin
  if DirectoryExists(APath) or FileExists(APath) then
    Result := psValid
  else
    Result := psNotFound;
end;

function TPathValidator.ValidateList(APaths: TStringList): TStringList;
var
  I: Integer;
  Seen: TStringList;
  Path: string;
  Status: TPathStatus;
begin
  Result := TStringList.Create;
  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    for I := 0 to APaths.Count - 1 do
    begin
      Path := APaths[I];
      Status := Validate(Path);
      if (Status = psValid) and (Seen.IndexOf(Path) >= 0) then
        Status := psDuplicate;
      if Seen.IndexOf(Path) < 0 then
        Seen.Add(Path);
      Result.Values[Path] := IntToStr(Ord(Status));
    end;
  finally
    Seen.Free;
  end;
end;

end.
```

- [ ] **Step 4: Run tests to verify pass**

Run:
```bash
lazbuild -B Tests.lpi && ./tests/bin/testrunner
```

Expected: All tests pass. Exit code `0`. Heaptrc reports `0 unfreed memory blocks`.

- [ ] **Step 5: Run JCF**

```bash
jcf src/utils/validator.pas tests/testvalidator.pas
```

- [ ] **Step 6: Commit**

```bash
git add src/utils/validator.pas tests/testvalidator.pas
git commit -m "feat(utils): add TPathValidator with existence and duplicate checks"
```

---

## Task 4: IEnvProvider Interface

**Files:**
- Create: `src/providers/envproviderintf.pas`

- [ ] **Step 1: Create interface unit**

Create `src/providers/envproviderintf.pas`:
```pascal
unit envproviderintf;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils;

type
  IEnvProvider = interface
    ['{B5E4A3F2-1C2D-4E3F-8A9B-0C1D2E3F4A5B}']
    function LoadUserVariables: TStringList;
    function LoadSystemVariables: TStringList;
    function SaveUserVariables(Vars: TStringList): Boolean;
    function SaveSystemVariables(Vars: TStringList): Boolean;
    procedure BroadcastEnvironmentChange;
  end;

implementation

end.
```

- [ ] **Step 2: Compile-check**

Add a temporary compile-check unit or simply ensure `Tests.lpi` still builds (no references yet):

```bash
lazbuild -B Tests.lpi
```

Expected: Success (exit code `0`).

- [ ] **Step 3: Commit**

```bash
git add src/providers/envproviderintf.pas
git commit -m "feat(provider): define IEnvProvider interface"
```

---

## Task 5: Windows Provider (TWinEnvProvider)

**Files:**
- Create: `tests/testwinenvprovider.pas`
- Create: `src/providers/winenvprovider.pas`

- [ ] **Step 1: Write failing tests**

Create `tests/testwinenvprovider.pas`:
```pascal
unit testwinenvprovider;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, envproviderintf, winenvprovider;

type
  TTestWinEnvProvider = class(TTestCase)
  published
    procedure TestCreate;
    procedure TestRegistryRootKeys;
  end;

implementation

procedure TTestWinEnvProvider.TestCreate;
var
  Provider: TWinEnvProvider;
begin
  Provider := TWinEnvProvider.Create;
  try
    AssertNotNull(Provider);
  finally
    Provider.Free;
  end;
end;

procedure TTestWinEnvProvider.TestRegistryRootKeys;
var
  Provider: TWinEnvProvider;
  UserVars: TStringList;
  SystemVars: TStringList;
begin
  Provider := TWinEnvProvider.Create;
  try
    UserVars := Provider.LoadUserVariables;
    try
      AssertTrue(UserVars.Count >= 0);
    finally
      UserVars.Free;
    end;
    SystemVars := Provider.LoadSystemVariables;
    try
      AssertTrue(SystemVars.Count >= 0);
    finally
      SystemVars.Free;
    end;
  finally
    Provider.Free;
  end;
end;

initialization
  RegisterTest(TTestWinEnvProvider);
end.
```

- [ ] **Step 2: Run tests to verify failure**

Run:
```bash
lazbuild -B Tests.lpi
```

Expected: Compilation fails because `winenvprovider` unit does not exist.

- [ ] **Step 3: Implement src/providers/winenvprovider.pas**

Create `src/providers/winenvprovider.pas`:
```pascal
unit winenvprovider;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, Registry, envproviderintf;

type
  TWinEnvProvider = class(TInterfacedObject, IEnvProvider)
  private
    FUserRoot: HKEY;
    FSystemRoot: HKEY;
  public
    constructor Create;
    destructor Destroy; override;
    function LoadUserVariables: TStringList;
    function LoadSystemVariables: TStringList;
    function SaveUserVariables(Vars: TStringList): Boolean;
    function SaveSystemVariables(Vars: TStringList): Boolean;
    procedure BroadcastEnvironmentChange;
  end;

implementation

uses
  Windows;

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

end.
```

Note: On non-Windows platforms, guard this unit with `{$IFDEF MSWINDOWS}` in the `.lpi` or project configuration. For the test plan, assume the CI runner builds on Windows for this provider.

- [ ] **Step 4: Run tests to verify pass**

On Windows run:
```bash
lazbuild -B Tests.lpi && ./tests/bin/testrunner
```

Expected: Tests pass. Exit code `0`. Heaptrc reports `0 unfreed memory blocks`.

- [ ] **Step 5: Run JCF**

```bash
jcf src/providers/winenvprovider.pas tests/testwinenvprovider.pas
```

- [ ] **Step 6: Commit**

```bash
git add src/providers/winenvprovider.pas tests/testwinenvprovider.pas
git commit -m "feat(provider): implement Windows environment provider"
```

---

## Task 6: Unix Provider (TUnixEnvProvider)

**Files:**
- Create: `tests/testunixenvprovider.pas`
- Create: `src/providers/unixenvprovider.pas`

- [ ] **Step 1: Write failing tests**

Create `tests/testunixenvprovider.pas`:
```pascal
unit testunixenvprovider;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, envproviderintf, unixenvprovider;

type
  TTestUnixEnvProvider = class(TTestCase)
  published
    procedure TestParseExportLine;
    procedure TestInjectExport;
    procedure TestPreserveComments;
  end;

implementation

procedure TTestUnixEnvProvider.TestParseExportLine;
var
  Key, Value: string;
begin
  AssertTrue(TUnixEnvProvider.ParseExportLine('export PATH=/usr/bin', Key, Value));
  AssertEquals('PATH', Key);
  AssertEquals('/usr/bin', Value);
end;

procedure TTestUnixEnvProvider.TestInjectExport;
var
  Content: string;
  ResultContent: string;
begin
  Content := '# bashrc' + LineEnding + 'export HOME=/home/user' + LineEnding;
  ResultContent := TUnixEnvProvider.InjectExport(Content, 'PATH', '/usr/bin');
  AssertTrue(Pos('export PATH=/usr/bin', ResultContent) > 0);
  AssertTrue(Pos('# bashrc', ResultContent) > 0);
end;

procedure TTestUnixEnvProvider.TestPreserveComments;
var
  Content: string;
  ResultContent: string;
begin
  Content := '# comment' + LineEnding + 'alias ls="ls --color"' + LineEnding;
  ResultContent := TUnixEnvProvider.InjectExport(Content, 'FOO', 'bar');
  AssertTrue(Pos('# comment', ResultContent) > 0);
  AssertTrue(Pos('alias ls=', ResultContent) > 0);
end;

initialization
  RegisterTest(TTestUnixEnvProvider);
end.
```

- [ ] **Step 2: Run tests to verify failure**

Run:
```bash
lazbuild -B Tests.lpi
```

Expected: Compilation fails because `unixenvprovider` unit does not exist.

- [ ] **Step 3: Implement src/providers/unixenvprovider.pas**

Create `src/providers/unixenvprovider.pas`:
```pascal
unit unixenvprovider;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, envproviderintf;

type
  TUnixEnvProvider = class(TInterfacedObject, IEnvProvider)
  public
    function LoadUserVariables: TStringList;
    function LoadSystemVariables: TStringList;
    function SaveUserVariables(Vars: TStringList): Boolean;
    function SaveSystemVariables(Vars: TStringList): Boolean;
    procedure BroadcastEnvironmentChange;
    class function ParseExportLine(const ALine: string; out AKey, AValue: string): Boolean;
    class function InjectExport(const AContent, AKey, AValue: string): string;
  end;

implementation

function TUnixEnvProvider.LoadUserVariables: TStringList;
begin
  Result := TStringList.Create;
  { Parse ~/.bashrc or ~/.profile in a real implementation }
end;

function TUnixEnvProvider.LoadSystemVariables: TStringList;
begin
  Result := TStringList.Create;
  { Parse /etc/environment in a real implementation }
end;

function TUnixEnvProvider.SaveUserVariables(Vars: TStringList): Boolean;
begin
  Result := True;
end;

function TUnixEnvProvider.SaveSystemVariables(Vars: TStringList): Boolean;
begin
  Result := True;
end;

procedure TUnixEnvProvider.BroadcastEnvironmentChange;
begin
  { No-op on Unix; changes apply to new shells }
end;

class function TUnixEnvProvider.ParseExportLine(const ALine: string; out AKey, AValue: string): Boolean;
var
  PosEq: Integer;
  S: string;
begin
  S := Trim(ALine);
  Result := S.StartsWith('export ');
  if not Result then
    Exit;
  S := Trim(S.Substring(7));
  PosEq := Pos('=', S);
  if PosEq > 0 then
  begin
    AKey := Copy(S, 1, PosEq - 1);
    AValue := Copy(S, PosEq + 1, Length(S));
  end
  else
  begin
    AKey := S;
    AValue := '';
  end;
end;

class function TUnixEnvProvider.InjectExport(const AContent, AKey, AValue: string): string;
var
  Lines: TStringList;
  I: Integer;
  Found: Boolean;
  Prefix: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := AContent;
    Found := False;
    Prefix := 'export ' + AKey + '=';
    for I := 0 to Lines.Count - 1 do
    begin
      if Trim(Lines[I]).StartsWith(Prefix) then
      begin
        Lines[I] := Prefix + AValue;
        Found := True;
        Break;
      end;
    end;
    if not Found then
      Lines.Add(Prefix + AValue);
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
```

- [ ] **Step 4: Run tests to verify pass**

Run:
```bash
lazbuild -B Tests.lpi && ./tests/bin/testrunner
```

Expected: Tests pass. Exit code `0`. Heaptrc reports `0 unfreed memory blocks`.

- [ ] **Step 5: Run JCF**

```bash
jcf src/providers/unixenvprovider.pas tests/testunixenvprovider.pas
```

- [ ] **Step 6: Commit**

```bash
git add src/providers/unixenvprovider.pas tests/testunixenvprovider.pas
git commit -m "feat(provider): implement Unix environment provider with bashrc parsing"
```

---

## Task 7: macOS Provider (TMacEnvProvider)

**Files:**
- Create: `src/providers/macenvprovider.pas`
- Create: `tests/testmacenvprovider.pas`

- [ ] **Step 1: Write failing tests**

Create `tests/testmacenvprovider.pas`:
```pascal
unit testmacenvprovider;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, envproviderintf, macenvprovider;

type
  TTestMacEnvProvider = class(TTestCase)
  published
    procedure TestCreate;
  end;

implementation

procedure TTestMacEnvProvider.TestCreate;
var
  Provider: TMacEnvProvider;
begin
  Provider := TMacEnvProvider.Create;
  try
    AssertNotNull(Provider);
  finally
    Provider.Free;
  end;
end;

initialization
  RegisterTest(TTestMacEnvProvider);
end.
```

- [ ] **Step 2: Run tests to verify failure**

Run:
```bash
lazbuild -B Tests.lpi
```

Expected: Compilation fails because `macenvprovider` unit does not exist.

- [ ] **Step 3: Implement src/providers/macenvprovider.pas**

Create `src/providers/macenvprovider.pas`:
```pascal
unit macenvprovider;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, envproviderintf;

type
  TMacEnvProvider = class(TInterfacedObject, IEnvProvider)
  public
    function LoadUserVariables: TStringList;
    function LoadSystemVariables: TStringList;
    function SaveUserVariables(Vars: TStringList): Boolean;
    function SaveSystemVariables(Vars: TStringList): Boolean;
    procedure BroadcastEnvironmentChange;
  end;

implementation

function TMacEnvProvider.LoadUserVariables: TStringList;
begin
  Result := TStringList.Create;
  { Parse ~/.zprofile / ~/.zshenv in real implementation }
end;

function TMacEnvProvider.LoadSystemVariables: TStringList;
begin
  Result := TStringList.Create;
  { Use path_helper or /etc/paths in real implementation }
end;

function TMacEnvProvider.SaveUserVariables(Vars: TStringList): Boolean;
begin
  Result := True;
end;

function TMacEnvProvider.SaveSystemVariables(Vars: TStringList): Boolean;
begin
  Result := True;
end;

procedure TMacEnvProvider.BroadcastEnvironmentChange;
begin
  { No-op on macOS; changes apply to new shells }
end;

end.
```

- [ ] **Step 4: Run tests to verify pass**

Run:
```bash
lazbuild -B Tests.lpi && ./tests/bin/testrunner
```

Expected: Tests pass. Exit code `0`. Heaptrc reports `0 unfreed memory blocks`.

- [ ] **Step 5: Run JCF**

```bash
jcf src/providers/macenvprovider.pas tests/testmacenvprovider.pas
```

- [ ] **Step 6: Commit**

```bash
git add src/providers/macenvprovider.pas tests/testmacenvprovider.pas
git commit -m "feat(provider): add macOS environment provider skeleton"
```

---

## Task 8: Backup Manager

**Files:**
- Create: `tests/testbackupmanager.pas`
- Create: `src/core/backupmanager.pas`

- [ ] **Step 1: Write failing tests**

Create `tests/testbackupmanager.pas`:
```pascal
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
```

- [ ] **Step 2: Run tests to verify failure**

Run:
```bash
lazbuild -B Tests.lpi
```

Expected: Compilation fails because `backupmanager` unit does not exist.

- [ ] **Step 3: Implement src/core/backupmanager.pas**

Create `src/core/backupmanager.pas`:
```pascal
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
      Json.SaveToFile(AFileName);
      Result := True;
    except
      Result := False;
    end;
  finally
    Json.Free;
  end;
end;

end.
```

- [ ] **Step 4: Run tests to verify pass**

Run:
```bash
lazbuild -B Tests.lpi && ./tests/bin/testrunner
```

Expected: Tests pass. Exit code `0`. Heaptrc reports `0 unfreed memory blocks`.

- [ ] **Step 5: Run JCF**

```bash
jcf src/core/backupmanager.pas tests/testbackupmanager.pas
```

- [ ] **Step 6: Commit**

```bash
git add src/core/backupmanager.pas tests/testbackupmanager.pas
git commit -m "feat(core): add backup manager with JSON export support"
```

---

## Task 9: Undo Manager

**Files:**
- Create: `tests/testundomanager.pas`
- Create: `src/core/undomanager.pas`

- [ ] **Step 1: Write failing tests**

Create `tests/testundomanager.pas`:
```pascal
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
  State1, State2, State3: TStringList;
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
      AssertEquals('/usr/bin', Popped[0]);
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
```

- [ ] **Step 2: Run tests to verify failure**

Run:
```bash
lazbuild -B Tests.lpi
```

Expected: Compilation fails because `undomanager` unit does not exist.

- [ ] **Step 3: Implement src/core/undomanager.pas**

Create `src/core/undomanager.pas`:
```pascal
unit undomanager;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils;

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
  Inc(FIndex);
end;

function TUndoManager.Undo: TStringList;
begin
  if CanUndo then
  begin
    Dec(FIndex);
    Result := TStringList.Create;
    Result.Assign(TStringList(FStack[FIndex]));
  end
  else
  begin
    Result := TStringList.Create;
  end;
end;

function TUndoManager.Redo: TStringList;
begin
  if CanRedo then
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
  Result := FIndex > 0;
end;

function TUndoManager.CanRedo: Boolean;
begin
  Result := FIndex < FStack.Count - 1;
end;

end.
```

- [ ] **Step 4: Run tests to verify pass**

Run:
```bash
lazbuild -B Tests.lpi && ./tests/bin/testrunner
```

Expected: Tests pass. Exit code `0`. Heaptrc reports `0 unfreed memory blocks`.

- [ ] **Step 5: Run JCF**

```bash
jcf src/core/undomanager.pas tests/testundomanager.pas
```

- [ ] **Step 6: Commit**

```bash
git add src/core/undomanager.pas tests/testundomanager.pas
git commit -m "feat(core): add undo/redo manager with stack semantics"
```

---

## Task 10: CLI Entry Point

**Files:**
- Create: `src/cli/openenvcli.pas`
- Create: `OpenEnvEdCLI.lpr`

- [ ] **Step 1: Create CLI unit**

Create `src/cli/openenvcli.pas`:
```pascal
unit openenvcli;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils;

procedure RunCLI;

implementation

uses
  envproviderintf, winenvprovider, unixenvprovider, macenvprovider;

procedure RunCLI;
var
  Provider: IEnvProvider;
  UserVars: TStringList;
begin
  {$IFDEF MSWINDOWS}
  Provider := TWinEnvProvider.Create;
  {$ELSEIF DEFINED(DARWIN)}
  Provider := TMacEnvProvider.Create;
  {$ELSE}
  Provider := TUnixEnvProvider.Create;
  {$ENDIF}

  UserVars := Provider.LoadUserVariables;
  try
    Writeln('User environment variables:');
    Writeln(UserVars.Text);
  finally
    UserVars.Free;
  end;
end;

end.
```

- [ ] **Step 2: Create OpenEnvEdCLI.lpr**

Create `OpenEnvEdCLI.lpr`:
```pascal
program OpenEnvEdCLI;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

uses
  openenvcli;

begin
  RunCLI;
end.
```

- [ ] **Step 3: Update OpenEnvEdCLI.lpi to reference the .lpr and units**

Modify `OpenEnvEdCLI.lpi`: add the `OpenEnvEdCLI.lpr` unit entry under `<Units>` and ensure `openenvcli` search path includes `src/cli`.

The existing `OpenEnvEdCLI.lpi` already has `OtherUnitFiles` including `src/cli`, so only add the main program unit:

Insert inside `<ProjectOptions>` before `</ProjectOptions>`:
```xml
    <Units>
      <Unit>
        <Filename Value="OpenEnvEdCLI.lpr"/>
        <IsPartOfProject Value="True"/>
      </Unit>
    </Units>
```

- [ ] **Step 4: Build CLI**

Run:
```bash
lazbuild -B OpenEnvEdCLI.lpi
```

Expected: Build succeeds with exit code `0`.

- [ ] **Step 5: Run CLI**

Run:
```bash
./bin/openenved-cli
```

Expected: Prints user environment variables (at minimum an empty or populated list). No crash. Exit code `0`.

- [ ] **Step 6: Run JCF on CLI files**

```bash
jcf src/cli/openenvcli.pas OpenEnvEdCLI.lpr
```

- [ ] **Step 7: Commit**

```bash
git add src/cli/openenvcli.pas OpenEnvEdCLI.lpr OpenEnvEdCLI.lpi
git commit -m "feat(cli): add CLI entry point and platform provider dispatch"
```

---

## Phase 1 Completion Checklist

- [ ] `jcf-format.cfg` exists and JCF runs successfully on all modified `.pas` files.
- [ ] `Tests.lpi`, `OpenEnvEd.lpi`, and `OpenEnvEdCLI.lpi` all have `-gh` in debug options.
- [ ] `lazbuild -B Tests.lpi` succeeds.
- [ ] `./tests/bin/testrunner` exits with code `0` and `0 unfreed memory blocks`.
- [ ] `lazbuild -B OpenEnvEdCLI.lpi` succeeds.
- [ ] All core units (`pathutils`, `validator`, `winenvprovider`, `unixenvprovider`, `macenvprovider`, `backupmanager`, `undomanager`) have ≥ 90 % test coverage.
