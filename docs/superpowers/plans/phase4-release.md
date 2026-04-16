# OpenEnvEd Phase 4: Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finalize the CI/CD pipeline, ensure cross-platform build verification, and prepare release artifacts.

**Architecture:** GitHub Actions drives the pipeline using `gpascal/setup-lazarus@v2`. The pipeline builds the test runner, executes FPCUnit tests, then builds the GUI application for the target OS.

**Tech Stack:** GitHub Actions, Lazarus/FPC.

---

## Task 16: CI/CD Pipeline

**Files:**
- Create: `.github/workflows/ci.yml`
- Modify: `Tests.lpi` (if heaptrc/XML report needs adjustment)

- [ ] **Step 1: Create GitHub Actions workflow directory**

Run:
```bash
mkdir -p .github/workflows
```

- [ ] **Step 2: Create ci.yml**

Create `.github/workflows/ci.yml`:
```yaml
name: CI

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  build-and-test:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Lazarus
        uses: gpascal/setup-lazarus@v2
        with:
          lazarus-version: stable

      - name: Build test runner
        run: lazbuild -B Tests.lpi
        shell: bash

      - name: Run tests
        run: |
          if [ "${{ matrix.os }}" = "windows-latest" ]; then
            ./tests/bin/testrunner.exe
          else
            ./tests/bin/testrunner
          fi
        shell: bash

      - name: Build GUI application
        run: lazbuild -B OpenEnvEd.lpi
        shell: bash

      - name: Build CLI application
        run: lazbuild -B OpenEnvEdCLI.lpi
        shell: bash

      - name: Upload GUI artifact
        uses: actions/upload-artifact@v4
        with:
          name: openenved-${{ matrix.os }}
          path: |
            bin/openenved*

      - name: Upload CLI artifact
        uses: actions/upload-artifact@v4
        with:
          name: openenved-cli-${{ matrix.os }}
          path: |
            bin/openenved-cli*
```

- [ ] **Step 3: Ensure Tests.lpi outputs XML report (optional)**

If FPCUnit XML output is required, verify that `Tests.lpr` uses `TXMLTestListener` or the default `TTestApplication` handles it. The current `Tests.lpr` uses `TTestApplication`, which is sufficient for console exit-code checking.

- [ ] **Step 4: Verify workflow syntax**

Run:
```bash
git add .github/workflows/ci.yml
```

No local syntax checker is strictly required, but review the YAML visually for indentation errors.

- [ ] **Step 5: Commit**

```bash
git commit -m "ci(pipeline): add GitHub Actions workflow for build, test, and artifact upload"
```

---

## Task 17: Final Build Verification and Release Artifacts

**Files:**
- Existing: `OpenEnvEd.lpi`, `OpenEnvEdCLI.lpi`, `Tests.lpi`

- [ ] **Step 1: Run full local build on primary OS**

Run:
```bash
lazbuild -B Tests.lpi
lazbuild -B OpenEnvEd.lpi
lazbuild -B OpenEnvEdCLI.lpi
```

Expected: All three builds succeed with exit code `0`.

- [ ] **Step 2: Run tests with heaptrc**

Run:
```bash
./tests/bin/testrunner
```

Expected:
- All tests pass.
- Final line includes `0 unfreed memory blocks`.
- Process exits with code `0`.

- [ ] **Step 3: Run JCF on entire codebase**

Run:
```bash
jcf src/**/*.pas tests/**/*.pas OpenEnvEd.lpr OpenEnvEdCLI.lpr Tests.lpr
```

Or use a shell loop:
```bash
find src tests -name "*.pas" -exec jcf {} \;
jcf OpenEnvEd.lpr OpenEnvEdCLI.lpr Tests.lpr
```

- [ ] **Step 4: Verify AGENTS.md checklist**

Open `AGENTS.md` and confirm every item in Section 11 is satisfied.

- [ ] **Step 5: Tag release (optional, if on main branch)**

Run:
```bash
git tag -a v1.0.0 -m "Release v1.0.0"
```

Only do this if explicitly instructed by the user or if the current branch is `main`/`master`.

- [ ] **Step 6: Final commit**

If any formatting fixes were applied in Step 3:
```bash
git add -A
git commit -m "chore(format): apply JCF to all source files before release"
```

---

## Phase 4 Completion Checklist

- [ ] `.github/workflows/ci.yml` exists and is syntactically valid.
- [ ] CI builds `Tests.lpi`, `OpenEnvEd.lpi`, and `OpenEnvEdCLI.lpi` on all three OS matrices.
- [ ] Test executable returns `0` with `0 unfreed memory blocks`.
- [ ] JCF has been run on every `.pas` and `.lpr` file.
- [ ] Artifacts are uploaded for GUI and CLI on all platforms.
- [ ] AGENTS.md Section 11 checklist is fully checked.
