---
name: api-conventions
description: >
  Enforces API route conventions whenever Claude creates, modifies, or discusses
  API endpoints, routes, routers, or HTTP handlers. Auto-invokes when working with
  FastAPI route definitions, APIRouter instances, or files in infra/api/, 
  orchestration/*/router.py, or core/features/*/router.py.
---

# API Conventions

Follow these rules whenever creating or modifying API routes in this project.
These are non-negotiable architectural constraints — not suggestions.

## Route Ownership

Routes live in TWO places only:

- **orchestration/<workflow>/router.py** — user-facing routes. These are what the
  frontend or external clients call. Examples: auth flows, onboarding steps, query
  endpoints, dashboard data.

- **core/features/<feature>/router.py** — system/internal routes. These exist ONLY
  when a feature needs direct HTTP access (webhooks, admin endpoints, service-to-service
  calls). Most features do NOT need a router — they're called by orchestration services.

**NEVER** define routes in `modules/`, `integrations/`, `data_definitions/`, or
directly in `infra/api/`.

## Route Registration

Every router MUST be registered in `infra/api/v1/router.py`. This is the single
source of truth for active routes. No exceptions.

```python
# infra/api/v1/router.py

from fastapi import APIRouter

v1_router = APIRouter()

# ── User-facing (orchestration) ─────────────────────────────
from <app_name>.orchestration.auth.router import router as auth_router
v1_router.include_router(auth_router, prefix="/auth", tags=["auth"])

# ── System/internal (features) ──────────────────────────────
from <app_name>.core.features.rag.router import router as rag_router
v1_router.include_router(rag_router, prefix="/internal/rag", tags=["internal"])
```

Rules:
- User-facing routes get descriptive prefixes: `/auth`, `/onboarding`, `/query`
- Internal routes use `/internal/<feature>` prefix
- Every router gets a `tags=` parameter for OpenAPI grouping
- Imports go inside the function or at module level — be consistent with the existing pattern

## Route Handler Structure

Route handlers MUST be thin. The pattern is always:

```python
@router.post(
    "/start",
    response_model=OnboardingResponse,
    summary="Start user onboarding",
    description="Initiates the onboarding flow for a new user. Creates the initial "
    "workspace and returns the onboarding session with next steps.",
)
async def start_onboarding(
    request: OnboardingRequest,
    service: OnboardingService = Depends(get_onboarding_service),
) -> OnboardingResponse:
    """Start user onboarding flow."""
    result = await service.start(request)
    return result
```

Rules:
- **Validate** — FastAPI + Pydantic handle this via type annotations
- **Call service** — one service method call. Business logic lives in the service, not here.
- **Return response** — return the Pydantic response model

**NEVER** put business logic in route handlers. No database queries, no external API
calls, no conditional workflows, no data transformations beyond what Pydantic handles.

## Schemas and Models

All request/response schemas come from `data_definitions/`. NEVER define Pydantic
models inline in a router file or service file.

```python
# CORRECT — import from data_definitions
from <app_name>.data_definitions.onboarding import OnboardingRequest, OnboardingResponse

# WRONG — defining schemas in the router file
class OnboardingRequest(BaseModel):  # ← NEVER do this here
    name: str
```

## MCP-Ready API Design

All endpoints must be designed so that an LLM agent can discover, understand, and
call them correctly from the OpenAPI spec alone. This is not optional — our APIs
may be exposed as MCP tools or used by AI agents.

### Routes must have rich descriptions

Every route decorator MUST include `summary=` (short, verb-first) and
`description=` (detailed: what it does, side effects, what it returns).

```python
# WRONG — no descriptions, LLM has to guess what this does
@router.post("/start")

# CORRECT — LLM can understand and use this endpoint
@router.post(
    "/start",
    summary="Start user onboarding",
    description="Initiates the onboarding flow for a new user. Creates the initial "
    "workspace, sends a welcome email, and returns the onboarding session ID "
    "with a list of next steps the client should present.",
)
```

### Every schema field MUST have a description

LLM agents read field descriptions to decide what values to pass. Ambiguous field
names without descriptions cause hallucinated parameters.

```python
# WRONG — LLM-hostile
class QueryRequest(BaseModel):
    q: str
    n: int = 10
    f: str | None = None

# CORRECT — LLM-friendly, MCP-ready
class QueryRequest(BaseModel):
    query: str = Field(description="Natural language search query from the user")
    max_results: int = Field(
        default=10,
        ge=1,
        le=100,
        description="Maximum number of results to return, between 1 and 100",
    )
    filter_category: str | None = Field(
        default=None,
        description="Optional category slug to filter results. Must match a value "
        "from the /categories endpoint.",
    )
```

Rules:
- Use `Field(description=...)` on EVERY schema field — no exceptions
- Field names must be self-descriptive (`search_query` not `q`, `max_results` not `n`)
- Include constraints in the description when they exist (valid ranges, allowed values,
  relationships to other endpoints)
- For enums, the description should list the allowed values
- For optional fields, describe what happens when omitted

## Dependencies

Use `Depends()` for all shared state:

```python
from fastapi import Depends

@router.get("/me", response_model=UserResponse)
async def get_current_user(
    user: User = Depends(get_current_user),
    service: UserService = Depends(get_user_service),
) -> UserResponse:
    return await service.get_profile(user.id)
```

Common dependencies: DB sessions, auth/current user, service instances, config.
NEVER instantiate services or DB connections directly in route handlers.

## Async by Default

All route handlers should be `async def` unless they call blocking I/O that has
no async alternative. If you must use sync, document why.

## Checklist Before Finishing

When you create or modify any route, verify:
- [ ] Route is in the correct location (orchestration/ or core/features/)
- [ ] Router is registered in `infra/api/v1/router.py`
- [ ] Request/response schemas are in `data_definitions/`
- [ ] Handler is thin — validate, call service, return
- [ ] Dependencies use `Depends()`
- [ ] Route is `async def`
- [ ] Tags are set for OpenAPI grouping
- [ ] Route has `summary=` and `description=` (MCP-ready)
- [ ] Every schema field has `Field(description=...)` (MCP-ready)
- [ ] Field names are self-descriptive, not abbreviated (MCP-ready)