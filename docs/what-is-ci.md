# What is CI?

## The problem CI solves

You change some code. Did you break something? You could check by hand every
time, but you'll forget, especially on small "this can't break anything" changes.

**Continuous Integration (CI)** is a robot that checks every change for you,
automatically, every time you push.

## CI/CD: two halves of one pipeline

```
 git push ──▶ [ CI: is it broken? ] ──pass──▶ [ CD: ship it ] ──▶ users
                     │
                     fail
                     ▼
              ❌ email / red X on GitHub
```

| | CI (Continuous Integration) | CD (Continuous Delivery / Deployment) |
|---|---|---|
| Question it answers | "Does this code still work?" | "Get it to users." |
| Runs | On every push and pull request | Usually only after CI passes on `main` |
| Typical steps | Install dependencies, lint, format check, test, build | Build image, upload, deploy to a server or host |
| A failure means | Your code or project setup has a problem | Deploy config, credentials, or the server has a problem |

- **Continuous Delivery**: the code is always ready to deploy, and a human presses the button.
- **Continuous Deployment**: no button. Every green build on `main` goes live.

This project does **CI only**. CD is a step you add after CI, once CI is reliably green.

## The checks CI usually runs

| Check | What it catches | In this project |
|---|---|---|
| **Install** | Missing or mismatched dependencies ("works on my machine") | `uv sync --locked` |
| **Lint** | Bugs a tool can spot without running the code: unused imports, undefined names | `ruff check` |
| **Format** | Inconsistent style, so diffs stay clean | `ruff format --check` |
| **Test** | Code that runs but gives the wrong answer | `pytest` |
| **Build** | Code that doesn't compile or bundle (JS, TS, Go, Rust...) | none, Python doesn't need it |

## Words you'll see

| Term | Meaning |
|---|---|
| **Workflow** | A YAML file in `.github/workflows/` that tells GitHub what to run and when |
| **Trigger** (`on:`) | The event that starts a workflow: `push`, `pull_request`, a schedule... |
| **Job** | A group of steps that run on one machine |
| **Runner** | The machine that runs a job. `ubuntu-latest` is a fresh Linux VM from GitHub |
| **Step** | One command (`run:`) or one reusable action (`uses:`) |
| **Action** | A reusable step someone published, e.g. `actions/checkout` |
| **Exit code** | Every command returns a number when it finishes. `0` = success, anything else = failure. This is all CI looks at |
| **Green / red** | All steps exited `0` / at least one didn't |

The most important line: **CI doesn't understand your code. It only checks
whether every command exited with code 0.** A "failing CI" is always one
specific command that returned a non-zero exit code, and the log shows which one.

Next: [how-it-works.md](how-it-works.md), what happens in this project when you push.
