# OpenEnvEd

A cross-platform environment variable editor for Windows, macOS, and Linux.

## Overview

OpenEnvEd provides both a GUI and CLI interface for viewing and modifying user and system environment variables. It tracks variable origins, validates PATH entries, and supports undo/redo and backups.

## Supported Platforms

- **Windows** — edits Registry keys (`HKCU\Environment` and `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment`)
- **macOS** — edits shell profile files (`~/.zshrc`, `~/.bash_profile`, etc.) and `/etc/paths` with `/etc/paths.d/`
- **Linux** — edits `~/.bashrc` and `/etc/environment`

## Building

The project is written in Free Pascal and uses the Lazarus LCL for the GUI.

### Requirements

- Free Pascal Compiler (FPC) 3.2+
- Lazarus IDE (for GUI builds)

### Build commands

```bash
# GUI application
lazbuild -B OpenEnvEd.lpi

# CLI application
lazbuild -B OpenEnvEdCLI.lpi

# Test suite
lazbuild -B Tests.lpi
# or compile directly:
fpc -Mobjfpc -Sh -gh -Fusrc/providers -Fusrc/utils -Fusrc/core -Futests -FUtests/lib -FEtests/bin Tests.lpr
./tests/bin/Tests -a
```

## GUI Usage

Launch the GUI application (`bin/OpenEnvEd` or `bin/OpenEnvEd.app` on macOS).

The window is split into two panels:
- **Left** — User variables
- **Right** — System variables

Each variable shows:
- **Name** — the variable key
- **Value** — the current value
- **Origin** — where the variable was defined

### Editing Variables

User variables can be edited, added, or deleted. System variables are read-only in the current version.

- **Double-click** a user variable to edit its name and value.
- **Add** — click the Add button to create a new user variable.
- **Delete** — select a user variable and click Delete to remove it.
- **Undo / Redo** — revert or re-apply changes.
- **Backup** — save the current state of all variables to a file.

### What Edit / Add / Delete Does on Each Platform

#### macOS

OpenEnvEd reads the current user environment by launching your login shell and capturing its output. This shows the fully resolved values of all variables, including those built up by `path_helper`, `launchd`, and profile scripts.

**Edit** — updates or adds an `export KEY="value"` line in your primary shell profile (`~/.zshrc` by default, falling back to `~/.zshenv`). If the variable originally came from the shell environment (shown as `Inherited` in the Origin column), editing it creates a new explicit definition that will override the inherited value in future sessions.

**Add** — appends a new `export KEY="value"` line to `~/.zshrc`.

**Delete** — removes the `export` line for that key from `~/.zshrc`. If the variable was inherited from the shell environment rather than defined in a profile, it may reappear the next time OpenEnvEd loads because the shell still provides it.

#### Linux

**Edit** — updates or adds an `export KEY=value` line in `~/.bashrc`.

**Add** — appends a new `export KEY=value` line to `~/.bashrc`.

**Delete** — removes the `export` line for that key from `~/.bashrc`.

#### Windows

**Edit** — updates or creates the value under the registry key `HKCU\Environment`.

**Add** — creates a new string value under `HKCU\Environment`.

**Delete** — removes the value from `HKCU\Environment`.

### Origin Column

The Origin column shows the source of each variable:

| Platform | Typical Origins |
|----------|-----------------|
| macOS user | `~/.zshrc`, `~/.bash_profile`, `Inherited` |
| macOS system | `/etc/paths`, `/etc/paths(.d)` |
| Linux user | `~/.bashrc` |
| Linux system | `/etc/environment` |
| Windows user | `Registry: HKCU\Environment` |
| Windows system | `Registry: HKLM\...\Environment` |

## CLI Usage

The CLI application (`bin/openenved-cli`) is a work in progress. Run it without arguments to see available commands.

## Architecture

```
src/
  providers/   — IEnvProvider interface + OS implementations
  utils/       — Path parsing, validation helpers
  core/        — Backup and undo managers
  gui/         — LCL forms and UI logic
  cli/         — CLI entry point
tests/         — FPCUnit test units
```

## License

See the project repository for license information.
