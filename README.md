# ci-demo

A minimal Python project that shows how **Continuous Integration (CI)** works,
and a pattern that stops CI from failing again and again:

> **Every check lives in one script, `ci.sh`. You, a git hook, and GitHub all run that same script.**

If `./ci.sh` passes on your laptop, CI passes on GitHub. If CI fails on GitHub,
`./ci.sh` shows you the same error on your laptop.

---

## Quick start

Requirements: [uv](https://docs.astral.sh/uv/) and git.

```bash
uv sync                                # install Python 3.12 + dependencies from uv.lock
./ci.sh                                # run every CI check locally
git config core.hooksPath .githooks    # once per clone: run ci.sh before every git push
```

Expected output of `./ci.sh`:

```
All checks passed!          ← ruff lint
3 files already formatted   ← ruff format
3 passed in 0.01s           ← pytest
CI passed
```

---

## What's in here

```
.
├── calc.py                     app code (add, divide)
├── test_calc.py                tests for calc.py
├── ci.sh                       ★ the single source of truth for all checks
├── .github/workflows/ci.yml    GitHub Actions: runs ci.sh on every push / PR
├── .githooks/pre-push          git hook: runs ci.sh before every git push
├── pyproject.toml              project metadata + dev dependencies (pytest, ruff)
├── uv.lock                     exact pinned versions of every dependency
├── .python-version             Python version (3.12) used locally AND in CI
└── docs/
    ├── what-is-ci.md           CI vs CD, explained from zero
    ├── how-it-works.md         step-by-step: what happens when you push
    ├── fixing-failing-ci.md    playbook for repos whose CI is already red
    └── adapting.md             reusing this pattern in Node / other projects
```

---

## How it works (short version)

```
                    ┌──────────────────────────┐
  you type ───────▶ │                          │
  ./ci.sh           │         ./ci.sh          │
                    │                          │
  git push ───────▶ │  1. uv sync --locked     │
  (pre-push hook)   │  2. ruff check           │
                    │  3. ruff format --check  │
  GitHub Actions ─▶ │  4. pytest               │
  (ci.yml)          │                          │
                    └──────────────────────────┘
```

1. **`ci.sh`** runs four checks and stops at the first failure (`set -euo pipefail`).
2. **`.githooks/pre-push`** runs `ci.sh` when you `git push`. If it fails, the push is cancelled, so broken code never reaches GitHub.
3. **`.github/workflows/ci.yml`** starts a fresh Linux machine on GitHub, installs uv, and runs `ci.sh`. It also catches anything that skipped the hook (another machine, `--no-verify`, edits made on github.com).
4. **`.python-version` + `uv.lock`** make GitHub's machine install exactly the same Python and package versions you have locally.

Full walkthrough: [docs/how-it-works.md](docs/how-it-works.md).

---

## Try breaking it

| Do this | Which check fails |
|---|---|
| Change `a + b` to `a - b` in `calc.py` | pytest |
| Add `import os` (unused) to `calc.py` | ruff lint |
| Write `def add(a,b):` (no space) | ruff format |
| Add a package to `pyproject.toml` by hand without running `uv lock` | `uv sync --locked` |

Run `./ci.sh` after each one and read the error. That is exactly the email GitHub
would have sent you. Undo the change and run it again to get back to green.

To auto-fix lint and formatting: `uv run ruff check --fix . && uv run ruff format .`

---

## Common commands

| Task | Command |
|---|---|
| Run all checks | `./ci.sh` |
| Run only tests | `uv run pytest` |
| Add a dependency | `uv add <package>` (dev-only: `uv add --dev <package>`) |
| Push without running checks (emergencies only) | `git push --no-verify` |

---

## Learn more

- New to CI? Start with [docs/what-is-ci.md](docs/what-is-ci.md)
- What runs where, step by step: [docs/how-it-works.md](docs/how-it-works.md)
- Your existing repo's CI is red: [docs/fixing-failing-ci.md](docs/fixing-failing-ci.md)
- Using this in a Node/JS or other project: [docs/adapting.md](docs/adapting.md)
