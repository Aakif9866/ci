# Using this pattern in other projects

The pattern is the same in any language. Only two things change: the setup
step in the workflow, and the commands inside `ci.sh`.

```
.github/workflows/ci.yml   checkout → install toolchain → ./ci.sh
.githooks/pre-push         exec ./ci.sh
ci.sh                      your project's checks
```

Copy `.githooks/pre-push` unchanged, then pick your stack below.

## Python (uv), as in this repo

```bash
# ci.sh
set -euo pipefail
uv sync --locked
uv run ruff check .
uv run ruff format --check .
uv run pytest -q
```

```yaml
# workflow steps
- uses: actions/checkout@v4
- uses: astral-sh/setup-uv@v6
- run: ./ci.sh
```

## Node / React / Next.js

```bash
# ci.sh
set -euo pipefail
npm ci              # like uv sync --locked: exact install from package-lock.json
npm run lint
npm test --if-present
npm run build
```

```yaml
# workflow steps
- uses: actions/checkout@v4
- uses: actions/setup-node@v4
  with:
    node-version-file: .nvmrc   # create it: node -v > .nvmrc
    cache: npm
- run: ./ci.sh
```

Only include scripts that exist in your `package.json`. `npm run lint` with no
`lint` script fails.

## Projects that need secrets (AI / API apps)

Keep the default `ci.sh` free of real API calls. Mock them in tests so CI never
needs a key. If you really need an integration test:

1. Add the key under repo **Settings → Secrets and variables → Actions**.
2. Pass it to the step:

```yaml
- run: ./ci.sh
  env:
    OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
```

3. Make those tests skip when the key is missing, so `ci.sh` still passes locally and on forks:

```python
import os

import pytest


@pytest.mark.skipif(not os.getenv("OPENAI_API_KEY"), reason="no API key")
def test_real_call(): ...
```

## Setting it up in an existing repo

```bash
cp /path/to/ci-demo/.githooks/pre-push .githooks/pre-push   # mkdir -p .githooks first
# write ci.sh for your stack (see above)
chmod +x ci.sh .githooks/pre-push
./ci.sh                                   # get it green locally first
git config core.hooksPath .githooks
git add ci.sh .githooks .github && git commit -m "ci: run checks via ci.sh"
git push                                  # hook runs, then GitHub runs
```
