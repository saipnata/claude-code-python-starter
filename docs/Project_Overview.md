# Project Overview

## What this is

A **GitHub repo template** (starter pack) for Python/FastAPI projects that are built
using Claude Code. It encodes best practices for CLAUDE.md structure, folder architecture,
slash commands, skills, hooks, and subagents — so developers get a production-grade
Claude Code setup from day one instead of discovering patterns through trial and error.

## Who it's for

- **Primary:** PangeaTech internal team — used as the starting point for all new
  Python/FastAPI backend projects
- **Secondary:** Open-source community — will be published as a public GitHub template
  repo for any developer using Claude Code with Python

## The core philosophy

Claude Code's power lies in configuration, not prompting. The developers shipping
2-3x faster aren't writing better prompts — they're maintaining structured CLAUDE.md
files, using hooks for deterministic guardrails, leveraging subagents for context
isolation, and running disciplined workflows. This template encodes those patterns
structurally so they're inherited, not learned.

## What we've built so far

### 1. CLAUDE.md — Project memory template
- Standard weight (~85 lines), Python/FastAPI specific
- Covers: commands, architecture tree, dependency flow rules, boundary rules,
  code style, testing conventions, important rules
- Uses `<app_name>` as the replaceable package name placeholder
- Designed to evolve per-project via the self-improvement loop

### 2. /init-project — Slash command for first-time setup
- Lives in `.claude/commands/init-project.md`
- Developer clones the template, runs `/init-project` in Claude Code
- Claude asks for project name, description, Python version (all at once)
- Scaffolds the full folder structure with `__init__.py` files
- Generates the FastAPI app factory pattern:
  - `main.py` → thin entry point
  - `infra/api/app.py` → factory with lifespan, middleware, router registration
  - `infra/api/v1/router.py` → single registry for all route groups
- Generates `pyproject.toml`, `.env.example`, `.gitignore`, `.pre-commit-config.yaml`
- Generates `config/settings.py` with pydantic-settings
- Generates `tests/conftest.py` with app factory and TestClient fixtures
- Replaces all placeholders in CLAUDE.md
- Runs `uv sync` and `git init`

### 3. CLAUDE_MD_RATIONALE.md — Companion learning doc
- Explains WHY each section of CLAUDE.md is ordered and structured the way it is
- Covers the dependency flow rationale, app factory pattern, what's excluded and why
- Meant to be read once then deleted from actual projects

## Architecture decisions

### Folder structure
```
src/<app_name>/
├── core/features/        # Domain layer — product capabilities (thin: routes + services)
├── orchestration/        # User-facing workflow coordination
├── integrations/         # External service clients (one package per service)
├── agents/               # AI agent definitions (workers, masters)
├── modules/              # Shared library — business-agnostic, reusable
├── config/               # App settings via pydantic-settings
├── telemetry/            # Logging, metrics, observability, evals
├── infra/                # App infrastructure — DB setup, FastAPI app factory, middleware
│   ├── database/
│   └── api/
│       └── v1/
└── data_definitions/     # ALL Pydantic schemas, enums, constants (single source of truth)
```

### Dependency flow
```
infra/api → orchestration → core/features → integrations
                          ↘               ↗
                       data_definitions
                             ↑
                          modules (imports from NOTHING internal)
```

### Key boundary rules
- **modules/** is fully standalone — NEVER imports from other internal packages
- **data_definitions/** is the single source of truth for all schemas and types
- **core/features/** does NOT define its own schemas — references data_definitions/
- **orchestration/** coordinates features and integrations for user-facing workflows
- **integrations/** wraps external services — one package per service
- **infra/** is the base layer — no business logic, everything depends on it

### Route registration pattern
- Features and orchestrations define their own `router.py` files
- ALL routers get mounted in `infra/api/v1/router.py` (single registry)
- User-facing routes come from orchestration/, system routes from core/features/
- Not every feature needs a router — some are pure services called internally

## What's planned next

### Slash commands
- `/new-feature` — scaffolds a new feature or orchestration package with the right
  structure and wires it into the v1 router

### Skills (auto-invoked by Claude)
- `api-conventions` — enforces route registration pattern, schema sourcing from
  data_definitions/, and consistent endpoint structure whenever Claude writes API code

### Hooks (deterministic automation)
- `settings.json` with PostToolUse hooks for auto-formatting (ruff)
- PreToolUse hooks for branch protection and file guards

### Subagents
- Pre-commit agent for lint/test enforcement
- Code reviewer agent
- Security scanner agent

### Future scope
- JavaScript/TypeScript variant (separate thread)
- GitHub Actions workflow for Claude Code PR review
- MCP server configurations for common dev tools

## File inventory

```
claude-code-starter/
├── CLAUDE.md                              # Template with placeholders
├── .claude/
│   └── commands/
│       └── init-project.md                # First-time project setup
└── docs/
    ├── PROJECT_OVERVIEW.md                # This file
    └── CLAUDE_MD_RATIONALE.md             # Design rationale (delete after reading)
```