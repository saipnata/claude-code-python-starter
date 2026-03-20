# {{PROJECT_NAME}}

{{ONE_LINE_DESCRIPTION}} — Python {{PYTHON_VERSION}}+ / FastAPI / Pydantic v2

## Commands

- Install deps: `uv sync`
- Dev server: `uv run uvicorn src.<app_name>.main:app --reload --port 8000`
- Run all tests: `uv run pytest`
- Run single test: `uv run pytest tests/{{path}} -v`
- Lint: `uv run ruff check .`
- Format: `uv run ruff format .`
- Type check: `uv run mypy .`

## Architecture

```
src/<app_name>/
├── core/features/        # DOMAIN LAYER — product capabilities
│   ├── feature_a/        #   Each feature = router + service logic
│   ├── feature_b/        #   Thin layers: validate → service → respond
│   └── feature_c/        #   Schemas come from data_definitions/, not here
├── orchestration/        # USER WORKFLOWS — coordinates features + integrations
│   ├── auth/             #   e.g. signup flow, login flow (calls integrations/auth)
│   ├── onboarding/       #   Multi-step user journeys
│   └── query_workflows/  #   Chains multiple features into a user-facing flow
├── integrations/         # EXTERNAL SERVICES — one package per external service
│   ├── auth/             #   Client wrapper for external auth provider
│   ├── storage/          #   Cloud storage client (S3, Azure Blob, etc.)
│   └── parsing/          #   Document parsing service client
├── agents/               # AI AGENTS — worker and master agent definitions
├── modules/              # SHARED LIBRARY — business-agnostic, reusable
│                         #   crud utils, llm_interface, security helpers, common
│                         #   MUST NOT import from any other internal package
├── config/               # App settings, env management (pydantic-settings)
├── telemetry/            # Monitoring, logging, observability, evals
├── infra/                # APPLICATION INFRASTRUCTURE
│   ├── database/         #   DB setup, session management, migrations
│   └── api/              #   FastAPI app factory, middleware, CORS, main router
│       └── v1/           #   API version 1 route registration
└── data_definitions/     # ALL models and schemas — Pydantic, enums, constants
tests/
├── conftest.py           # Shared fixtures, factories, test config
├── unit/                 # No I/O, no DB, no network. Fast and isolated.
├── integration/          # Real DB, test containers. Slower but realistic.
└── e2e/                  # Full API calls via TestClient against running app.
```

### Dependency Flow (IMPORTANT — Claude must respect this hierarchy)

```
infra/api → orchestration → core/features → integrations
                          ↘               ↗
                       data_definitions
                             ↑
                          modules (imports from NOTHING internal)
```

- **modules/** is fully standalone. It must NEVER import from core/, orchestration/,
  integrations/, agents/, or any other internal package. If it can't work in a
  completely different project, it doesn't belong here.
- **data_definitions/** is the single source of truth for all Pydantic schemas,
  enums, and shared types. May import from modules/ only.
- **core/features/** owns business logic per feature. Imports from data_definitions/,
  modules/, and integrations/. Does NOT define its own schemas.
- **orchestration/** coordinates user-facing workflows by calling core/features/
  and integrations/. This is where multi-step flows live.
- **integrations/** wraps external services behind clean interfaces. One package per
  external service. Imports from data_definitions/ and modules/ only.
- **infra/** is the base layer — DB connections, FastAPI app factory, middleware.
  Everything depends on it. It depends on nothing above it. No business logic here.
- **agents/** defines AI agent behavior. Agents call core/features/ and integrations/.
- **config/** feeds settings into all layers. No business logic.
- **telemetry/** is cross-cutting — any layer can use it. It imports from nothing above modules/.

### Where does new code go?

- New product capability → `core/features/<name>/`
- New user-facing workflow → `orchestration/<name>/`
- New external service client → `integrations/<name>/`
- New Pydantic schema, enum, or shared type → `data_definitions/`
- New reusable utility → `modules/` (only if business-agnostic)
- New AI agent → `agents/`

## Code Style

- Type hints on ALL function signatures — params AND return types
- Use `str | None` syntax, not `Optional[str]`. NEVER use `Any`.
- Pydantic models for ALL request/response shapes — no raw dicts
- Routes stay thin: validate input → call service → return response
- Use `Depends()` for all shared state (db sessions, auth, config)
- Async routes by default; sync only when calling blocking I/O
- snake_case everywhere except class names (PascalCase)

## Testing

- Arrange-Act-Assert pattern. One assertion concept per test.
- Fixtures in `tests/conftest.py` — prefer factory fixtures over static data
- Mock external services — never call real APIs in tests
- Name tests: `test_<unit>_<scenario>_<expected>`

## Important Rules

- ALWAYS prefix commands with `uv run`. NEVER use bare `pip install` or `python`.
- NEVER commit `.env` files. Use `.env.example` as reference.
- ALL routes use `/api/v1/` prefix — registered in `infra/api/v1/`.
- New feature? Create package in `core/features/`, schemas in `data_definitions/`.
- New external service? Create client in `integrations/`, never inline API calls.
- Log with structured logging, not `print()`. No print statements in production code.
- Respect the dependency flow. NEVER create circular imports between layers.