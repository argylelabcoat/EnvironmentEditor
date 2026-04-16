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

- **Double-click** a user variable to edit its name and value.
- **Add** — click the Add button to create a new user variable.
- **Delete** — select a user variable and click Delete to remove it.
- **Undo / Redo** — revert or re-apply changes.
- **Backup** — save the current state of all variables to a file.

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

#### What does "Inherited" mean? (macOS)

On macOS, many variables come from the login shell environment rather than an explicit `export` line in a profile file. These are marked **Inherited**.

**Editing an Inherited variable** adds or updates an `export` line in your primary shell profile (`~/.zshrc` by default, falling back to `~/.zshenv`). This creates an explicit override that shadows the inherited value in future shell sessions.

**Deleting an Inherited variable** removes its explicit entry from `~/.zshrc` if one exists, but cannot remove the underlying source (e.g. `launchd`, `path_helper`, or system defaults). The variable may reappear on the next load if the shell still provides it.

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

## Development Standards

See [`AGENTS.md`](AGENTS.md) for contributor guidelines, including:
- Mandatory compiler directives
- Heaptrc leak detection in debug builds
- JEDI Code Format (JCF) profile requirements
- Test-driven development workflow with FPCUnit

## License

See the project repository for license information.
