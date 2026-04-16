# AGENTS.md — OpenEnvEd Development Standards

> **Applies to:** All AI agents and human contributors working on OpenEnvEd, a Free Pascal / Lazarus cross-platform environment editor.

---

## 1. Mandatory Compiler Directives

Every `.pas` unit MUST begin with these exact directives, in this order, before any `uses` or `interface` section:

```pascal
{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}
```

**Do not omit, reorder, or wrap these in `{$IFDEF}` blocks.** If a unit genuinely requires an exception, document it in a comment directly above the directive block and get explicit human approval.

---

## 2. Memory Safety (Heaptrc)

Debug builds MUST enable FPC's built-in leak detector (`heaptrc`).

* **Project file setting:** Add `-gh` to the "Custom Options" of every `.lpi` (GUI, CLI, and Tests).
* **Test enforcement:** The test runner must exit with code `0`. Any unfreed blocks reported by `heaptrc` constitute a test failure.
* **Agent action:** After writing or modifying any unit that allocates objects, strings, or dynamic arrays, run the full test suite and verify `heaptrc` reports `0 unfreed memory blocks`.

---

## 3. Code Formatting & Linting

* **Formatter:** Use JEDI Code Format (JCF) with the repository's `jcf-format.cfg` profile.
* **Before every commit:** Run JCF on all modified `.pas` files.
* **Style rules encoded in `jcf-format.cfg`:**
  * Indentation: 2 spaces (no tabs).
  * `begin`/`end` alignment: `begin` goes on its own line, aligned with the statement that owns it.
  * Maximum line length: 100 characters.
  * Keyword casing: lowercase (`function`, `procedure`, `if`, `then`).
  * Type naming: `T` prefix for types, `I` prefix for interfaces, `E` prefix for exceptions (PascalCase).
  * Variable naming: camelCase for locals, no hungarian notation.
  * Class fields: prefix with `F` (e.g., `FRegistry`).

**Agent action:** If `jcf-format.cfg` does not exist, create it as the very first task before writing any Pascal code.

---

## 4. Test-Driven Development (TDD) Workflow

We use **FPCUnit**. Every code change follows this exact loop:

1. **Write the failing test first.** The test must compile but fail.
2. **Run the test.** Confirm it fails for the expected reason.
3. **Write the minimal production code** to make the test pass.
4. **Run the test.** Confirm it passes.
5. **Run JCF** on modified files.
6. **Run the full test suite** and confirm `0` heaptrc leaks.
7. **Commit.**

**No production code may be written without a preceding failing test**, except for:
* Pure data-structure declarations (records, enums).
* Empty interface definitions that are required for compilation.
* Boilerplate project files (`.lpi`, `.lpr`).

---

## 5. Unit Test Requirements

### 5.1 Test File Naming
* One test unit per production unit.
* Name: `test<ProductionUnitName>.pas` (e.g., `testpathutils.pas` for `pathutils.pas`).
* Location: `tests/test<name>.pas`

### 5.2 Test Class Template
Every test unit must inherit from `TTestCase` and register itself:

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
  end;

implementation

procedure TTestPathUtils.TestSplitPath_Windows;
var
  Actual: TStringList;
begin
  Actual := SplitPath('C:\Windows;C:\Users', ';');
  try
    AssertEquals(2, Actual.Count);
    AssertEquals('C:\Windows', Actual[0]);
    AssertEquals('C:\Users', Actual[1]);
  finally
    Actual.Free;
  end;
end;

initialization
  RegisterTest(TTestPathUtils);
end.
```

### 5.3 Coverage Expectation
Core logic units (providers, path utils, validator, backup, undo) must have **≥ 90 % statement coverage**.

---

## 6. File & Directory Organization

```
OpenEnvEd/
├── src/
│   ├── providers/      # IEnvProvider + OS implementations
│   ├── utils/          # Path parsing, validation helpers
│   ├── core/           # Backup, undo, business logic
│   ├── cli/            # CLI entry point
│   └── gui/            # LCL forms and UI logic
├── tests/              # FPCUnit test units
├── docs/               # Design docs and plans
├── jcf-format.cfg      # JCF profile (required)
├── OpenEnvEd.lpi       # GUI project
├── OpenEnvEdCLI.lpi    # CLI project
├── Tests.lpi           # Test runner project
└── .github/
    └── workflows/
        └── ci.yml      # GitHub Actions pipeline
```

* Keep UI logic out of providers.
* Keep OS-specific code out of utils.
* Never place business logic in `.lpr` files.

---

## 7. Interface & Type Stability

* Once a public method or interface method is committed, changing its signature requires updating **all call sites, all mocks, all tests, and the relevant documentation** in the same commit.
* Prefer adding new overloaded methods over breaking existing signatures.
* Document breaking changes in the commit message body.

---

## 8. CI/CD Compliance

The GitHub Actions pipeline (`gpascal/setup-lazarus@v2`) must remain green. Agents must:

1. Ensure `lazbuild -B Tests.lpi` succeeds locally before pushing.
2. Ensure the test executable returns `0`.
3. Ensure `lazbuild -B OpenEnvEd.lpi` succeeds for the primary target OS.

---

## 9. Commit Message Format

```
<type>(<scope>): <short summary>

<body>
```

* **type:** `feat`, `fix`, `test`, `refactor`, `chore`, `docs`
* **scope:** `provider`, `gui`, `cli`, `utils`, `core`, `ci`, `tests`
* **short summary:** Imperative mood, max 50 chars, no period.
* **body:** Explain *why* the change was made, not just what changed.

---

## 10. Red Flags — Stop and Re-read This Doc If You...

* Are about to write a `.pas` file without the strict directive block.
* Are about to skip writing a test because the code "is too simple."
* Are about to commit without running JCF.
* Are about to mix UI code into an OS provider.
* Are about to use `try` without `finally` when allocating objects.
* Are about to ignore a `heaptrc` warning.

---

## 11. Quality Checklist (Agent Must Verify Before Claiming Done)

- [ ] All new `.pas` files start with the exact strict directive block.
- [ ] `-gh` is present in all `.lpi` debug configurations.
- [ ] JCF has been run on all modified `.pas` files.
- [ ] Every new public function/class has a corresponding FPCUnit test.
- [ ] Full test suite passes with `0 unfreed memory blocks`.
- [ ] No UI code in `providers/`, `utils/`, or `core/`.
- [ ] Commit messages follow the format in Section 9.
