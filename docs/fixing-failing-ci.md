# Fixing a repo whose CI keeps failing

## The root cause

When CI fails over and over, it's almost never bad luck. It's this:

> **CI is the first place your checks ever run.**

You push, CI runs something you never ran locally, it fails, you get an email,
you push a guess, it fails again. The fix isn't "debug harder". It's making sure
CI never runs anything you haven't already run.

## Step 1: read the log (2 minutes)

1. GitHub repo → **Actions** tab → click the failed run.
2. Click the job, then the step with the red ❌.
3. Scroll to the **bottom**. The real error is almost always in the last 10–20 lines.

Or from the terminal:

```bash
gh run list --limit 5
gh run view <run-id> --log-failed
```

## Step 2: match the error

| Error in the log looks like | Cause | Fix |
|---|---|---|
| `ModuleNotFoundError` / `Cannot find module` | Package installed on your laptop but not listed in the project | `uv add <pkg>` / `npm install <pkg>`, commit the lock file |
| `lockfile needs to be updated` / `npm ci` lock mismatch | Lock file out of date or not committed | `uv lock` / `npm install`, commit the lock file |
| `no tests ran` / exit code 5 | Workflow runs pytest but there are no tests | Add one real test, or remove the test step |
| `ruff` / `eslint` / `flake8` errors | Linter from a template you never ran | Run it locally and fix, or delete the step if you don't want it |
| `Permission denied: ./script.sh` | Script not executable in git | `git update-index --chmod=+x script.sh` |
| `KeyError: 'API_KEY'` / 401 / auth errors | Tests need a secret CI doesn't have | Mock the API in tests, or add the secret under Settings → Secrets → Actions |
| `SyntaxError` / unsupported feature only in CI | Different Python/Node version in CI | Pin it: `.python-version` / `.nvmrc`, and make CI use it |
| `No such file or directory` | File is in `.gitignore`, never committed, or path case differs (macOS doesn't care, Linux does) | Commit it, or fix the casing |
| `npm run build` fails, TS errors | Build only ever ran in dev mode locally | Run `npm run build` locally |

## Step 3: make it impossible to happen again

1. **Write a `ci.sh`** with exactly the commands the workflow runs. Run it locally until it's green.
2. **Make the workflow call only `ci.sh`.** Replace the steps after setup with `- run: ./ci.sh`.
3. **Add the pre-push hook**: copy `.githooks/pre-push`, then run `git config core.hooksPath .githooks`.
4. **Pin versions**: commit the lock file and a `.python-version` / `.nvmrc`.
5. Push. If it's green locally, it's green on GitHub.

## Step 4: delete checks you don't want

If a check came from a template and you don't care about it, **remove it**.
A CI that's always red is worse than no CI: you learn to ignore the emails, and
then you also ignore the one that matters. Start with a single check that
passes (even just "does it install"), and add more once that's reliably green.

## Checklist for each repo

- [ ] Opened the latest failed run and read the error
- [ ] `ci.sh` exists and passes locally
- [ ] Workflow only does checkout → setup → `./ci.sh`
- [ ] Lock file committed, language version pinned
- [ ] Tests don't need real API keys
- [ ] Pre-push hook enabled (`git config core.hooksPath .githooks`)
- [ ] Latest push is green ✅
