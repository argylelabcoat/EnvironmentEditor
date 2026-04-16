Ah, my apologies! The file generation tool sometimes leaves the file stranded in my backend environment rather than delivering it properly to the chat interface. 

Here is the full markdown specification directly in our chat so you can easily copy and paste it into your editor:

```markdown
# Technical Specification: OpenEnvEd
**A Cross-Platform Environment Editor (Open-Source RapidEE Alternative)**

## 1. Overview & Goals
**OpenEnvEd** is an open-source, cross-platform utility designed to view, edit, and manage system and user environment variables. It serves as a modern, safe, and native replacement for RapidEE, built using **Lazarus and the Free Pascal Compiler (FPC)**.

### Primary Objectives:
* **Native GUI:** Utilize Lazarus Component Library (LCL) for native look-and-feel (WinAPI, GTK3/Qt5, Cocoa).
* **Cross-Platform:** Support Windows 10/11, macOS, and major Linux distributions.
* **Path Validation:** Real-time visual feedback for dead, broken, or duplicate paths.
* **Safety:** Built-in backup/restore mechanisms and undo history.
* **Portability:** Provide a single-executable distribution requiring no installation.

---

## 2. Core Features
* **Dual Tree/List View:** Visually separate System and User variables.
* **Smart Variable Inspector:** Automatically detect if a variable is a path list (e.g., `PATH`, `CLASSPATH`) and display it as an editable, reorderable list rather than a single long string.
* **Real-time Diagnostics:**
    * 🔴 **Red:** Path/File does not exist.
    * 🟡 **Yellow:** Duplicate entry in the path.
    * 🔵 **Blue:** Overridden variable (User variable shadows a System variable).
* **Privilege Elevation:** Read-only mode by default for system variables; prompt for UAC/sudo when saving system-wide changes.
* **Backup & Import/Export:** Export environment states to `.json` or `.env` formats.

---

## 3. Architecture & OS Abstraction

Because environment variables are handled fundamentally differently across OSes, the core logic must be strictly decoupled from the UI.

### The `IEnvProvider` Interface
```pascal
type
  IEnvProvider = interface
    function LoadUserVariables: TStringList;
    function LoadSystemVariables: TStringList;
    function SaveUserVariables(Vars: TStringList): Boolean;
    function SaveSystemVariables(Vars: TStringList): Boolean;
    procedure BroadcastEnvironmentChange;
  end;
```

### OS Implementations
1.  **Windows (`TWinEnvProvider`)**
    * Reads/Writes to `HKCU\Environment` (User) and `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment` (System) via `TRegistry`.
    * Broadcasts changes using `SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, ...)` so apps recognize the new variables without a reboot.
2.  **Linux / Unix (`TUnixEnvProvider`)**
    * **User:** Parses and safely modifies `~/.bashrc`, `~/.zshrc`, or `~/.profile`.
    * **System:** Modifies `/etc/environment` or `/etc/profile.d/`.
    * *Challenge:* Preserving comments and surrounding shell scripts during write-back.
3.  **macOS (`TMacEnvProvider`)**
    * Uses `/usr/libexec/path_helper` concepts or edits `~/.zprofile` / `~/.zshenv`.

---

## 4. Test-Driven Development (TDD) Strategy

TDD is critical for a tool that edits system-breaking configurations. We will use **FPCUnit**, the standard xUnit testing framework in Free Pascal.

### Testing Layers:
1.  **String/Path Manipulation (Unit Tests)**
    * Test splitting `PATH` strings by OS delimiters (`;` on Windows, `:` on Unix).
    * Test duplicate detection algorithms.
    * Test relative-to-absolute path resolution.
2.  **Validation Engine (Unit Tests)**
    * Mock the file system interface. Test that `TPathValidator.Validate('/fake/path')` returns `psNotFound`.
3.  **OS Providers (Integration Tests)**
    * **Windows:** Create a temporary registry hive, populate it, read it via `TWinEnvProvider`, modify it, and assert the changes in the registry.
    * **Unix:** Feed `TUnixEnvProvider` a mock `.bashrc` string with comments and aliases. Assert that injecting a new `export VAR=val` does not corrupt the rest of the shell script.
4.  **UI State Tests**
    * Test that the Undo/Redo stack pushes and pops states correctly.

---

## 5. Code Quality, Linting, & Analysis

To ensure a maintainable open-source codebase, the following FPC/Lazarus tools and standards must be integrated.

### 5.1 Compiler Directives (Strict Mode)
All Pascal units must start with modern strict directives:
```pascal
{$mode objfpc}{$H+} // Modern object pascal, long strings
{$J-}               // Typed constants are truly read-only
{$WARN 5024 on}     // Warn on uninitialized variables
{$WARN 4031 on}     // Warn on unreachable code
```

### 5.2 Memory Leak Analysis (Heaptrc)
Crashes in system utilities are unacceptable. FPC's built-in memory manager, `heaptrc`, will be enabled in Debug builds.
* **Implementation:** Add `-gh` to the compiler options.
* **Enforcement:** Integration tests will fail if `heaptrc` reports unfreed memory blocks at process exit.

### 5.3 Linting & Formatting
* **Formatter:** Use `ptop` (Pascal source formatter) or the built-in Lazarus JCF (JEDI Code Format) to enforce a unified coding style (e.g., standard indentation, `begin`/`end` alignment).
* Provide a `.jcf` profile in the repository root so all contributors use the same formatting rules.

### 5.4 Continuous Integration (CI/CD)
Use **GitHub Actions** to automate the build and test pipeline.
* **Action:** `gpascal/setup-lazarus@v2`
* **Pipeline Steps:**
    1.  Checkout Code.
    2.  Setup Lazarus (Latest stable).
    3.  Build CLI Test Runner (`lazbuild -B Tests.lpi`).
    4.  Execute Tests (FPCUnit generates an XML report).
    5.  Build GUI Application (`lazbuild -B OpenEnvEd.lpi` for Windows, Linux, macOS).
    6.  Upload Artifacts.

---

## 6. Milestones & Phases

* **Phase 1: Core Engine & CLI**
    * Implement OS Providers, Path string parsing, and validation logic.
    * Achieve 90%+ code coverage on the core logic using FPCUnit.
* **Phase 2: UI Prototyping**
    * Build the main form in Lazarus.
    * Implement VirtualTreeView (using `VirtualTrees` package) for high-performance rendering of variables.
* **Phase 3: Integration & Polish**
    * Connect UI to the Core Engine.
    * Implement row painting (Red/Yellow/Blue).
    * Implement the Backup/Restore system.
* **Phase 4: Release**
    * Finalize CI/CD pipeline.
    * Publish v1.0 binaries for Win/Mac/Linux.
```