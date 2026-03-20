# Plan a Feature

You are creating an implementation plan for a new feature. The plan must be
thorough enough that implementation becomes mechanical — no architectural
decisions should be left to coding time.

## Step 1: Understand the Feature

Ask the developer:
- **What is the feature?** — describe what it does from the user's perspective
- **Which layer does it primarily belong to?** — core/features, orchestration,
  integration, or a combination

If the feature is large, break it into smaller sub-features and confirm the
scope before proceeding.

Wait for their response before proceeding.

## Step 2: Create the Plan

Read the following skills before writing the plan — they contain the architectural
rules the plan must follow:
- `.claude/skills/api-conventions/SKILL.md`
- `.claude/skills/service-patterns/SKILL.md`
- `.claude/skills/testing-patterns/SKILL.md`

Create a file at `plans/<feature_name>.md` with the following structure:

```markdown
# Feature: <Feature Name>

## Overview
<What this feature does, who it serves, which architectural layers it touches>

## File Map
Every file being created or modified, grouped by layer:

### data_definitions/
- `data_definitions/<feature>/schemas.py` — <what schemas, brief description>

### core/features/ (if applicable)
- `core/features/<feature>/service.py` — <service class and purpose>
- `core/features/<feature>/router.py` — <only if feature needs direct HTTP access>

### orchestration/ (if applicable)
- `orchestration/<workflow>/service.py` — <workflow coordination logic>
- `orchestration/<workflow>/router.py` — <user-facing endpoints>

### integrations/ (if applicable)
- `integrations/<service>/base.py` — <abstract interface>
- `integrations/<service>/<provider>_client.py` — <concrete implementation>

### tests/
- `tests/unit/test_<what>.py` — <what's being unit tested>
- `tests/e2e/test_<what>.py` — <what's being e2e tested>

## Classes and Methods

For every class being created, list:
- Class name and one-line purpose
- Every public method with its signature and what it does
- Which layer it lives in

Example:
### OnboardingService (orchestration/onboarding/service.py)
Coordinates the new user onboarding workflow.
- `async def start(self, request: OnboardingRequest) -> OnboardingResponse`
  Creates user via auth client, provisions workspace, returns session.
- `async def get_status(self, user_id: str) -> OnboardingStatus`
  Returns current onboarding progress for a user.

## Schema Definitions

For every Pydantic model being created in data_definitions/:
- Model name, all fields with types and descriptions
- Note which endpoints use each schema (request vs response)

## API Endpoints

For every route being created:
- HTTP method + path
- Summary and description (MCP-ready)
- Request/response schemas
- Which router file it lives in
- Registration line for infra/api/v1/router.py

## Dependencies

External services or clients this feature requires:
- Existing clients it will use
- New clients that need to be created (with abstract base + implementation)

## Implementation Phases

Phase 1: Schemas — define all Pydantic models in data_definitions/
Phase 2: Integration clients — create/modify any external service clients
Phase 3: Services — implement business logic in core/features/ and/or orchestration/
Phase 4: Routes — wire up endpoints and register in v1/router.py
Phase 5: Tests — unit tests for individual methods, e2e for workflows

## Open Questions
<Any ambiguities or decisions the developer needs to make before implementation>
```

## Step 3: Review and Refine

Present the plan to the developer. Ask them to review it — specifically:
- Are the classes and methods correct?
- Are the schemas complete?
- Are there any missing endpoints or flows?
- Any open questions that need answering?

Iterate on the plan until the developer explicitly approves it. Update the
plan file with each revision.

## Step 4: Implement

Once the developer approves the plan (says something like "looks good",
"approved", "go ahead", "ship it"), begin implementation following the plan
phases in order. Reference the plan file throughout — it is the source of truth.

After implementation is complete, add a `## Status` section at the top of the
plan file marking it as `IMPLEMENTED` with the date.