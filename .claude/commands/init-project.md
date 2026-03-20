# Initialize Project

You are setting up a new Python/FastAPI project from the starter template.
Walk the developer through this step by step. Be conversational but efficient.

## Step 1: Gather project details

Ask the developer for the following (all in one prompt, not one at a time):

- **Project name** — used for the package folder under `src/` (must be valid Python
  identifier: lowercase, underscores, no hyphens). Example: `sonorca`, `commind`, `zephyr`
- **One-line description** — what the project does in one sentence
- **Python version** — minimum version (default: 3.12)

Wait for their response before proceeding.

## Step 2: Scaffold the folder structure

Create the full directory tree with `__init__.py` files:

```
src/<project_name>/
├── __init__.py
├── main.py
├── core/
│   ├── __init__.py
│   └── features/
│       └── __init__.py
├── orchestration/
│   └── __init__.py
├── integrations/
│   └── __init__.py
├── agents/
│   └── __init__.py
├── modules/
│   └── __init__.py
├── config/
│   ├── __init__.py
│   └── settings.py
├── telemetry/
│   └── __init__.py
├── infra/
│   ├── __init__.py
│   ├── database/
│   │   └── __init__.py
│   └── api/
│       ├── __init__.py
│       ├── app.py
│       └── v1/
│           ├── __init__.py
│           └── router.py
└── data_definitions/
    └── __init__.py
tests/
├── __init__.py
├── conftest.py
├── unit/
│   └── __init__.py
├── integration/
│   └── __init__.py
└── e2e/
    └── __init__.py
docs/
├── api/
├── architecture/
└── development/
scripts/
```

## Step 3: Generate file contents

All generated files should use the project name provided by the developer.
Replace `<project_name>` with their actual project name in all code below.

---

**src/<project_name>/main.py** — Thin entry point. Uvicorn points here.
```python
"""<one_line_description>"""

from <project_name>.infra.api.app import create_app

app = create_app()
```

---

**src/<project_name>/infra/api/app.py** — App factory. Assembles everything.
```python
from contextlib import asynccontextmanager
from collections.abc import AsyncGenerator

from fastapi import FastAPI

from <project_name>.config.settings import settings


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    # Startup: DB connections, cache warmup, telemetry init
    yield
    # Shutdown: close connections, flush telemetry


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        lifespan=lifespan,
    )

    _register_middleware(app)
    _register_routers(app)

    return app


def _register_middleware(app: FastAPI) -> None:
    """Register CORS, auth middleware, request logging, etc."""
    pass


def _register_routers(app: FastAPI) -> None:
    """Mount all API version routers."""
    from <project_name>.infra.api.v1.router import v1_router

    app.include_router(v1_router, prefix="/api/v1")
```

---

**src/<project_name>/infra/api/v1/router.py** — Single registry for all v1 routes.
```python
"""
API v1 route registry.

All routers — whether from orchestration/ (user-facing) or core/features/
(system/internal) — are mounted here. This is the single source of truth
for what routes are active.
"""

from fastapi import APIRouter

v1_router = APIRouter()

# ── User-facing routes (orchestration) ──────────────────────────────
# As orchestration workflows are built, mount their routers here:
# from <project_name>.orchestration.auth.router import router as auth_router
# v1_router.include_router(auth_router, prefix="/auth", tags=["auth"])

# ── System/internal routes (features) ──────────────────────────────
# Only add feature routers if they need direct HTTP access:
# from <project_name>.core.features.rag.router import router as rag_router
# v1_router.include_router(rag_router, prefix="/internal/rag", tags=["internal"])
```

---

**src/<project_name>/config/settings.py** — App configuration via environment.
```python
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    app_name: str = "<project_name>"
    debug: bool = False

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
```

---

**tests/conftest.py** — Shared test configuration and fixtures.
```python
"""Shared test fixtures and configuration."""

import pytest
from fastapi.testclient import TestClient

from <project_name>.infra.api.app import create_app


@pytest.fixture
def app():
    """Create a fresh app instance for testing."""
    return create_app()


@pytest.fixture
def client(app):
    """Test client for making API requests."""
    return TestClient(app)
```

---

## Step 4: Update CLAUDE.md

In the existing CLAUDE.md file, replace all placeholders:
- `{{PROJECT_NAME}}` → the project name (title case with spaces)
- `{{ONE_LINE_DESCRIPTION}}` → their description
- `{{PYTHON_VERSION}}` → their Python version
- `<app_name>` → their project name (the Python package name)
- `{{path}}` → `tests/unit/test_example.py` (a sensible default)

## Step 5: Generate pyproject.toml

Create `pyproject.toml` with:

```toml
[project]
name = "<project_name>"
version = "0.1.0"
description = "<one_line_description>"
requires-python = ">=<python_version>"
dependencies = [
    "fastapi>=0.115.0",
    "uvicorn[standard]>=0.30.0",
    "pydantic>=2.0.0",
    "pydantic-settings>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "ruff>=0.8.0",
    "mypy>=1.0.0",
    "httpx>=0.27.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/<project_name>"]

[tool.ruff]
target-version = "py<python_version_short>"
line-length = 88

[tool.ruff.lint]
select = ["E", "F", "I", "N", "UP", "B", "SIM"]

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["src"]

[tool.mypy]
python_version = "<python_version>"
strict = true
```

Replace `<python_version_short>` with the version without the dot (e.g., `312` for `3.12`).

## Step 6: Generate config files

**.env.example:**
```
APP_NAME=<project_name>
DEBUG=false
```

**.gitignore:** Generate a standard Python .gitignore that includes:
- `__pycache__/`, `*.pyc`, `.mypy_cache/`, `.ruff_cache/`, `.pytest_cache/`
- `.env`, `.venv/`, `venv/`
- `dist/`, `build/`, `*.egg-info/`
- `.claude/settings.local.json`

**.pre-commit-config.yaml:**
```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

## Step 7: Initialize the project

Run these commands in order:
1. `uv sync` — install dependencies
2. `git init` (only if `.git/` doesn't already exist)
3. Report what was created

## Step 8: Summary

Tell the developer:
- What was created (folder count, file count)
- Remind them to run `uv sync` if it failed (network issues, etc.)
- Suggest next steps: "Create your first feature with `/new-feature`" or
  "Start building in `src/<project_name>/core/features/`"
- Mention they can customize CLAUDE.md as the project evolves