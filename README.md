# Claude Code Starter Pack — Python / FastAPI

A production-grade starter template for Python/FastAPI projects built with [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Ships with a structured CLAUDE.md, slash commands for project setup and planning, auto-invoked skills for API conventions and testing patterns, and deterministic hooks for formatting and safety guardrails.

**The philosophy:** Claude Code's power lies in configuration, not prompting. This template encodes the patterns that make the difference between "Claude keeps getting things wrong" and "Claude one-shots it every time."

---

## Quick Start

```bash
# 1. Create a new repo from this template (or clone it)
gh repo create my-project --template your-org/claude-code-starter-python
cd my-project

# 2. Open Claude Code
claude

# 3. Run the setup command
> /init-project
```

Claude will ask for your project name, description, and Python version — then scaffold everything: folder structure, FastAPI app factory, pyproject.toml, and test configuration. Your CLAUDE.md placeholders get replaced automatically.

---

## What's Included

### CLAUDE.md — Project Memory

The template ships with a ~85-line CLAUDE.md optimized for Python/FastAPI projects. It covers commands, architecture, dependency flow rules, code style, and testing conventions. After running `/init-project`, all placeholders are replaced with your project details.

**The self-improvement loop:** When Claude makes a mistake, correct it and say *"Update CLAUDE.md so you don't make that mistake again."* Over weeks, your CLAUDE.md evolves into a project-specific operating manual. This is the single highest-leverage Claude Code practice.

### Slash Commands

| Command | What It Does |
|---------|-------------|
| `/init-project` | First-time project setup. Scaffolds folders, generates app factory, wires up pyproject.toml, replaces CLAUDE.md placeholders. Run once. |
| `/plan` | Creates an implementation plan before coding. Outputs to `plans/<feature>.md`. Claude reads all skills before planning, then implements after you approve. |
| `/test-report` | Runs the test suite and generates a structured `test_report.md` with results organized by source file (unit) and UX journey (e2e). |

### Skills (Auto-Invoked)

Skills are instructions Claude follows automatically when it detects relevant work. You don't invoke them — Claude pulls them in based on what you're doing.

| Skill | Triggers When | What It Enforces |
|-------|--------------|-----------------|
| **api-conventions** | Creating/modifying routes, routers, endpoints | Routes in orchestration/ or core/features/ only. All routers registered in `infra/api/v1/router.py`. Thin handlers. MCP-ready descriptions on every route and schema field. |
| **service-patterns** | Writing business logic, service classes, integration clients | OOP where it adds value, functions where it doesn't. Abstract base classes for all integration clients. No god classes, no god methods. Services instantiate their own dependencies. |
| **data-modeling** | Working in data_definitions/ or creating Pydantic models | All schemas in data_definitions/. `Field(description=...)` on every field. Base model inheritance for shared fields. `StrEnum` for enums. Naming: `<Domain><Action><Type>`. |
| **testing-patterns** | Writing or modifying test files | AAA pattern. Mock data in JSON files under `mock_data/`. Unit tests at method level, e2e at workflow level. Production environment guard. |
| **planning** | Asking to build a multi-file feature | Nudges you to plan before coding. Checks `plans/` for existing approved plans. Won't re-plan if an approved plan exists. |

### Hooks (Deterministic)

Hooks fire automatically on specific events — no LLM judgment involved.

| Hook | Event | What It Does |
|------|-------|-------------|
| **Production guard** | Before any `pytest` command | Blocks test execution if `APP_ENV=production`. Exit code 2 = hard block. |
| **Auto-format** | After any file edit | Runs `ruff format` on the changed file silently. |

### Architecture

The template uses a layered architecture with strict dependency rules:

```
src/<app_name>/
├── core/features/        # Domain layer — product capabilities
├── orchestration/        # User-facing workflow coordination
├── integrations/         # External service clients (one per service)
├── agents/               # AI agent definitions
├── modules/              # Shared library — business-agnostic, reusable
├── config/               # App settings (pydantic-settings)
├── telemetry/            # Logging, metrics, observability
├── infra/                # App infrastructure
│   ├── database/         #   DB setup, session management
│   └── api/              #   FastAPI app factory, middleware
│       └── v1/           #   Route registry (single source of truth)
└── data_definitions/     # ALL Pydantic schemas, enums, constants
```

**Dependency flow — Claude enforces this automatically:**

```
infra/api → orchestration → core/features → integrations
                          ↘               ↗
                       data_definitions
                             ↑
                          modules (imports from NOTHING internal)
```

---

## File Structure

```
├── CLAUDE.md                              # Project memory (edit as project evolves)
├── .claude/
│   ├── settings.json                      # Hooks and permissions
│   ├── hooks/
│   │   └── block-tests-in-prod.sh         # Production test guard
│   ├── commands/
│   │   ├── init-project.md                # /init-project
│   │   ├── plan.md                        # /plan
│   │   └── test-report.md                 # /test-report
│   └── skills/
│       ├── api-conventions/SKILL.md       # Route and endpoint patterns
│       ├── service-patterns/SKILL.md      # Business logic and OOP patterns
│       ├── data-modeling/SKILL.md         # Pydantic schema conventions
│       ├── testing-patterns/SKILL.md      # Test writing conventions
│       └── planning/SKILL.md              # Plan-before-code enforcement
├── plans/                                 # Feature plans (created via /plan)
├── docs/
│   ├── PROJECT_OVERVIEW.md                # Full project context for Claude
│   └── CLAUDE_MD_RATIONALE.md             # Why CLAUDE.md is structured this way
└── (src/, tests/, pyproject.toml, etc.)   # Created by /init-project
```

---

## Typical Workflow

```
1.  Clone template, run /init-project
2.  "Build a document upload feature"
3.  → Planning skill nudges: "Want me to plan first?"
4.  → You say yes, Claude creates plans/document_upload.md
5.  → You review, request changes, approve
6.  → Claude implements: schemas → clients → services → routes → tests
7.  → Run /test-report to verify coverage
8.  → Claude makes a mistake? "Update CLAUDE.md so this doesn't happen again"
9.  Repeat from step 2
```

---

## Customization

**CLAUDE.md** is meant to evolve. The template gives you a starting point — your project-specific rules, gotchas, and conventions should be added over time.

**Skills** can be modified to match your team's patterns. Edit the SKILL.md files directly. Add new skills by creating a folder in `.claude/skills/<name>/SKILL.md`.

**Hooks** can be extended in `.claude/settings.json`. Common additions: branch protection (block edits on main), auto-test after edits, file guards for sensitive configs.

**Commands** can be added by creating `.md` files in `.claude/commands/`. The filename becomes the command name.

---

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- [uv](https://docs.astral.sh/uv/) for Python package management
- Python 3.12+ (configurable during `/init-project`)

---

## Further Reading

- `docs/CLAUDE_MD_RATIONALE.md` — Why the CLAUDE.md template is structured the way it is
- `docs/PROJECT_OVERVIEW.md` — Full project context and architecture decisions
- [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices) — Official Anthropic documentation
- [Using CLAUDE.md Files](https://claude.com/blog/using-claude-md-files) — Anthropic's guide to CLAUDE.md

---

## Contributing

Found a pattern that works well? A skill that catches a common mistake? PRs welcome. The goal is to encode what works so every new project starts with the best setup possible.

## License

MIT