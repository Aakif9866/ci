# How it works

This project has two safety nets, and both run the same script:

1. **Locally**: the git pre-push hook runs `ci.sh` before your code leaves your laptop.
2. **On GitHub**: the workflow runs `ci.sh` again on a clean machine.

## What happens when you `git push`

```
 you: git push
   │
   ▼
 ┌─────────────── your laptop ───────────────┐
 │ git runs .githooks/pre-push                │
 │   └─▶ ./ci.sh                              │
 │         fail? ──▶ push CANCELLED, fix it   │
 │         pass? ──▶ push continues           │
 └────────────────────────────────────────────┘
   │
   ▼
 ┌─────────────── GitHub ────────────────────┐
 │ push event triggers .github/workflows/ci.yml │
 │   1. start a fresh ubuntu-latest VM          │
 │   2. actions/checkout   → copy your code      │
 │   3. setup-uv           → install uv          │
 │   4. ./ci.sh            → same checks again   │
 │        ✅ green tick  or  ❌ red X + email    │
 └──────────────────────────────────────────────┘
```

Why run the checks twice? The hook is fast feedback, but it can be skipped:
`git push --no-verify`, a clone where the hook isn't turned on, or edits made
directly on github.com. GitHub is the check nobody can skip.

---

## The pieces, file by file

### `ci.sh`: the checks

```bash
set -euo pipefail
uv sync --locked
uv run ruff check .
uv run ruff format --check .
uv run pytest -q
echo "CI passed"
```

| Line | What it does | Why |
|---|---|---|
| `set -euo pipefail` | Stop at the first command that fails, and return its exit code | Without it, the script would keep going and could report success after a failure |
| `uv sync --locked` | Install the exact versions in `uv.lock`. **Fail** if `uv.lock` doesn't match `pyproject.toml` | Catches "I added a package but didn't update or commit the lock file" |
| `ruff check .` | Lint: unused imports, undefined names, common bugs | Cheap and fast, catches real bugs |
| `ruff format --check .` | Fail if any file isn't formatted. Doesn't change files | Keeps style consistent without arguments |
| `pytest -q` | Run every `test_*.py` file | Checks the code actually gives the right answers |

**This is the only file you edit to change what CI checks.** Want type checking?
Add `uv run mypy .` here and it runs locally, in the hook, and on GitHub at once.

### `.github/workflows/ci.yml`: GitHub's copy

```yaml
on:
  push:
  pull_request:
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v6
      - run: ./ci.sh
```

- `on: push / pull_request`: run on every push to any branch, and on every pull request.
- `runs-on: ubuntu-latest`: a brand-new Linux VM every time. Nothing from your laptop exists on it: no `.venv`, no `.env`, no globally installed packages. **This is why "works on my machine" fails here.**
- `actions/checkout`: copies the commit you pushed onto the VM.
- `astral-sh/setup-uv`: installs `uv`. When `ci.sh` then runs `uv sync`, uv reads `.python-version` and downloads Python 3.12 itself.
- `run: ./ci.sh`: everything else is in the script. The YAML has no logic, so there's nothing in it that can fail differently from your laptop.

### `.githooks/pre-push`: the local gate

```bash
exec ./ci.sh
```

Git runs any executable file named `pre-push` in its hooks folder before each
push. If it exits non-zero, the push is cancelled.

Git normally looks for hooks in `.git/hooks/`, which **isn't committed**. That's
why the hook lives in `.githooks/` (committed), and each clone points git at it once:

```bash
git config core.hooksPath .githooks
```

This setting is stored in `.git/config` on your machine only, so every new clone
needs to run it once.

### `.python-version` + `uv.lock`: same environment everywhere

| File | Pins | Without it |
|---|---|---|
| `.python-version` | Python version (`3.12`) | CI might use a different Python and fail on syntax or behaviour differences |
| `uv.lock` | Exact version of every package, including sub-dependencies | CI installs whatever is newest today, and a new release can break you overnight with no code change |

Always commit both. Update them with `uv add <pkg>` / `uv lock`, never by hand.

---

## Executable permissions (a classic CI failure)

`ci.sh` and `pre-push` must be executable, or CI fails with `Permission denied`.
Git stores this permission bit, so it works as long as it was set when you
committed. If it gets lost (common when committing from Windows):

```bash
git update-index --chmod=+x ci.sh .githooks/pre-push
git commit -m "make scripts executable"
```

Next: [fixing-failing-ci.md](fixing-failing-ci.md), applying this to repos whose CI is already red.
