---
name: service-patterns
description: >
  Enforces service design patterns whenever Claude creates or modifies service
  classes, integration clients, utility functions, or business logic. Auto-invokes
  when working with files in core/features/, orchestration/, integrations/, or
  modules/, or when creating classes that handle business logic or external service
  communication.
---

# Service Patterns

Follow these rules whenever writing business logic, service classes, integration
clients, or utility code. Use OOP where it adds value. Use plain functions where
a class would be overhead. Never force-fit either pattern.

## When to Use Classes vs Functions

### Use classes when:
- You're encapsulating a workflow with related methods (services)
- You're wrapping an external service (integration clients)
- There's state or configuration to manage across method calls
- There are (or will be) multiple implementations of the same interface

### Use plain functions when:
- The logic is stateless (string cleaning, date formatting, data transforms)
- There are no dependencies to manage
- A single function fully solves the problem
- You're writing utilities in `modules/`

```python
# CORRECT — plain function for stateless utility
def clean_html(raw: str) -> str:
    """Strip HTML tags and normalize whitespace."""
    ...

# WRONG — unnecessary class wrapper for a stateless operation
class HtmlCleaner:
    def clean(self, raw: str) -> str:
        ...
```

## Service Classes

Services live in `core/features/` (domain logic) and `orchestration/` (workflow
coordination). Each service class has ONE focused purpose — the class name should
tell you exactly what it does.

### Orchestration services coordinate workflows:

```python
# orchestration/onboarding/service.py

class OnboardingService:
    """Coordinates the new user onboarding workflow."""

    async def start(self, request: OnboardingRequest) -> OnboardingResponse:
        auth_client = AuthClient()
        user = await auth_client.create_user(request.email)

        storage_client = StorageClient()
        await storage_client.create_workspace(user.id)

        return OnboardingResponse(user_id=user.id, workspace_created=True)

    async def get_status(self, user_id: str) -> OnboardingStatus:
        ...
```

### Feature services handle domain-specific logic:

```python
# core/features/knowledge_graph/service.py

class KnowledgeGraphService:
    """Manages knowledge graph construction and querying."""

    async def build_from_documents(self, doc_ids: list[str]) -> GraphResult:
        ...

    async def query(self, query: str, filters: GraphFilters) -> list[GraphNode]:
        ...
```

### Rules:
- One class, one focused purpose. If the class name needs "And" in it, split it.
- Methods should each do one specific thing. If a method is doing multiple unrelated
  steps, break it into smaller methods.
- Services instantiate the clients they need internally — no dependency injection
  frameworks required. Keep it Pythonic.
- Route handlers call services. Services call clients and other services. Clients
  call external APIs. This is the chain — don't skip levels.

## Integration Clients

Integration clients live in `integrations/`. They wrap external services behind
clean interfaces. **Always start with an abstract base class**, even if there's
only one implementation today. This keeps implementations swappable.

### Abstract base defines the contract:

```python
# integrations/llm/base.py

from abc import ABC, abstractmethod

class BaseLLMClient(ABC):
    """Interface for LLM provider clients."""

    @abstractmethod
    async def generate(self, prompt: str, **kwargs) -> str:
        """Generate a completion from the given prompt."""
        ...

    @abstractmethod
    async def generate_structured(self, prompt: str, schema: type) -> dict:
        """Generate a structured response matching the given schema."""
        ...
```

### Concrete implementation extends the base:

```python
# integrations/llm/openai_client.py

class OpenAIClient(BaseLLMClient):
    """OpenAI-specific implementation of the LLM client."""

    def __init__(self, api_key: str | None = None):
        self.client = AsyncOpenAI(api_key=api_key or settings.openai_api_key)

    async def generate(self, prompt: str, **kwargs) -> str:
        response = await self.client.chat.completions.create(
            model=kwargs.get("model", "gpt-4o"),
            messages=[{"role": "user", "content": prompt}],
        )
        return response.choices[0].message.content
```

### Adding a new provider means adding one file:

```python
# integrations/llm/anthropic_client.py

class AnthropicClient(BaseLLMClient):
    """Anthropic-specific implementation of the LLM client."""
    ...
```

### Rules:
- One package per external service in `integrations/`
- Always define an abstract base class with the public interface
- Concrete implementations extend the base
- `__init__` handles configuration (API keys, endpoints, timeouts)
- Swapping providers should only require changing which class gets instantiated

## Utility Code (modules/)

Utilities in `modules/` are business-agnostic and reusable. They MUST NOT import
from any other internal package (`core/`, `orchestration/`, `integrations/`, etc.).

```python
# modules/common/text.py

def slugify(text: str) -> str:
    """Convert text to URL-safe slug."""
    ...

def truncate(text: str, max_length: int, suffix: str = "...") -> str:
    """Truncate text to max_length, appending suffix if truncated."""
    ...
```

If it needs business context to work, it doesn't belong in `modules/`.

## What NOT to Do

- **No god classes** — a class with dozens of methods handling unrelated concerns.
  Split it into focused services.
- **No god methods** — a method that runs for hundreds of lines doing everything.
  Break it into smaller, named steps.
- **No business logic in route handlers** — routes validate, call a service, return.
  That's it.
- **No abstract bases for utilities** — if a function will never have multiple
  implementations, don't wrap it in an ABC. That's over-engineering.
- **No raw API calls outside integrations/** — every external service gets a client
  in `integrations/`. Never call `httpx.get()` directly from a service.

## Testing Boundaries

The testing strategy matches the design boundaries:

- **Unit tests** target individual methods — test `AuthClient.create_user`,
  `KnowledgeGraphService.query`, `slugify()` in isolation
- **Integration tests** verify real external connections where needed
- **E2e tests** target orchestration flows — test `OnboardingService.start` end-to-end

This means services don't need dependency injection for testability. You test the
clients independently at the unit level, and the full workflow at the e2e level.

## Checklist Before Finishing

When you create or modify a service, client, or utility, verify:
- [ ] Class has a single, focused purpose (name doesn't need "And")
- [ ] Methods are each doing one specific thing
- [ ] Integration clients extend an abstract base class
- [ ] Utility functions in modules/ have no internal imports
- [ ] Business logic is in a service, not in a route handler
- [ ] External API calls go through an integration client, never inline
- [ ] Testing boundary is clear — unit for methods, e2e for workflows