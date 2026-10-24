#!/usr/bin/env bash
# The ONE place CI checks live. GitHub runs this, the pre-push hook runs this, you run this.
# If it passes on your laptop, it passes in CI.
set -euo pipefail

uv sync --locked            # fails if pyproject.toml and uv.lock disagree
uv run ruff check .         # lint
uv run ruff format --check . # formatting
uv run pytest -q            # tests
echo "CI passed"
