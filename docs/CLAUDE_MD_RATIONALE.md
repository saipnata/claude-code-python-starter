# CLAUDE.md — Design Rationale

This document explains **why** the CLAUDE.md template is structured the way it is.
Read this once, then delete it from your project — it's a learning aid, not a config file.

---

## Why the order matters

Claude reads CLAUDE.md top-to-bottom. Content near the top gets stronger weight
in its context window. The ordering is intentional:

1. **Identity** (project name + one-liner) — Claude needs to know WHAT it's working on
   before anything else. Without this, it hallucinates stack assumptions.

2. **Commands** — The #1 source of Claude mistakes is running wrong commands.
   `pip install` instead of `uv add`. `python` instead of `uv run python`.
   Putting commands first means Claude sees them before it does anything.

3. **Architecture** — The directory tree tells Claude WHERE things live. Without it,
   Claude creates files in wrong directories or invents its own structure.
   The ASCII tree format is deliberate — Claude parses it more reliably than prose.

4. **Dependency Flow** — This is the most critical architectural constraint. Without
   explicit import hierarchy rules, Claude will happily create circular imports between
   layers. The ASCII arrow diagram is compact but encodes the entire architecture
   philosophy. Claude references it before every import decision.

5. **"Where does new code go?"** — This section eliminates the most common file
   placement mistakes. Without it, Claude defaults to putting new files wherever
   feels convenient. With it, every new piece of code has an unambiguous home.

6. **Code Style** — These are RULES, not suggestions. Each line should be a specific,
   testable constraint. "Write clean code" is useless. "Use `str | None` not
   `Optional[str]`" is actionable.

7. **Testing** — Separate from code style because testing conventions are the #1
   thing Claude ignores if not made explicit. Without this section, Claude writes
   implementation-first code with tests as an afterthought.

8. **Important Rules** (a.k.a. Gotchas) — These are things Claude WILL get wrong
   without explicit warnings. The word "NEVER" is intentional — Claude responds
   more strongly to absolute prohibitions than soft preferences.

---

## Why the architecture looks like this

The folder structure separates concerns into layers with a strict dependency flow:

```
infra/api → orchestration → core/features → integrations
                          ↘               ↗
                       data_definitions
                             ↑
                          modules (imports from NOTHING internal)
```

Key design decisions:

- **core/features/** is the domain layer — thin packages with routes and service
  logic. Features do NOT define their own schemas. They reference data_definitions/.
  This prevents schema duplication and keeps a single source of truth.

- **orchestration/** is where user-facing workflows live. It coordinates features
  and integrations. Example: an auth flow calls integrations/auth (the external
  provider client) while an onboarding flow might chain multiple features together.

- **integrations/** has one package per external service. This means swapping
  providers (e.g., Auth0 → Supabase Auth) only touches one package.

- **modules/** is the strictest boundary — it must NEVER import from any other
  internal package. If code here can't work in a completely different project,
  it doesn't belong here.

- **infra/api/** contains the FastAPI app factory pattern:
  - `main.py` (at package root) → thin entry point, just imports create_app()
  - `infra/api/app.py` → factory that assembles middleware and routers
  - `infra/api/v1/router.py` → single registry for all v1 routes
  This means you always know what routes are active by looking at one file.

- **data_definitions/** is the single source of truth for ALL Pydantic schemas,
  enums, and shared types. Every layer references it. No layer defines its own.

---

## Why certain things are NOT included

- **No personality instructions** ("be concise", "be friendly") — wastes tokens.
  Claude Code already has good defaults. Save personality tuning for chat, not code.

- **No formatting rules** — That's what Ruff and PostToolUse hooks do. Telling Claude
  "use 4-space indentation" wastes CLAUDE.md space when `ruff format` handles it
  deterministically after every edit.

- **No full API docs inlined** — Use `# See docs/API_DESIGN.md` as a lazy reference.
  Claude will read the file when needed. Don't @-import entire docs into CLAUDE.md.

- **No dependency versions** — That's what pyproject.toml is for. Claude reads it
  automatically.

- **No git workflow rules** — Git conventions (branch naming, commit messages) are
  better enforced by pre-commit hooks and CI, not by hoping Claude remembers.

---

## You don't fill in the placeholders manually

Run `/init-project` in Claude Code. It asks for your project name, description, and
Python version, then does everything: scaffolds folders, generates the app factory,
wires up pyproject.toml, and replaces all placeholders in CLAUDE.md.

The placeholders in CLAUDE.md for reference:
- `{{PROJECT_NAME}}` — Your project name (title case)
- `{{ONE_LINE_DESCRIPTION}}` — What the project does in one sentence
- `{{PYTHON_VERSION}}` — Minimum Python version (3.11, 3.12, etc.)
- `<app_name>` — The Python package name (lowercase, underscores)
- `{{path}}` — Example test path for running single tests

---

## The self-improvement loop

The most important habit with CLAUDE.md is **iterative refinement**:

1. Claude makes a mistake (e.g., uses `pip install` instead of `uv add`)
2. You correct Claude in chat
3. You say: "Update CLAUDE.md so you don't make that mistake again"
4. Claude adds a rule to the Important Rules section
5. The mistake never happens again (in any future session)

Over weeks, your CLAUDE.md evolves from a generic template into a project-specific
operating manual that encodes every lesson learned. This is the highest-leverage
practice in all of Claude Code usage.

---

## Line count budget

Keep CLAUDE.md under ~80-90 lines / ~2500 tokens. The system prompt already
consumes a significant chunk of Claude's instruction budget. If your CLAUDE.md
grows beyond this:

- Split layer-specific rules into `.claude/rules/*.md` files
- Use child CLAUDE.md files in subdirectories for package-specific context
- Move reference documentation to separate files and use lazy references
  (`# See docs/API_DESIGN.md` instead of inlining content)