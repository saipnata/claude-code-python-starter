---
name: data-modeling
description: >
  Enforces Pydantic schema conventions whenever Claude creates, modifies, or
  discusses data models, schemas, enums, or shared types. Auto-invokes when
  working with files in data_definitions/, or when creating Pydantic BaseModel
  subclasses, Field definitions, or enum types anywhere in the project.
---

# Data Modeling Conventions

All Pydantic models, enums, and shared types live in `data_definitions/`.
No other layer defines its own schemas. This is the single source of truth.

## File Organization

Use flat files — one file per domain:

```
data_definitions/
├── __init__.py
├── onboarding.py          # OnboardingRequest, OnboardingResponse, OnboardingStatus
├── documents.py           # DocumentUploadRequest, DocumentResponse, DocumentType
├── query.py               # QueryRequest, QueryResponse, QueryFilters
├── users.py               # UserBase, UserCreateRequest, UserResponse
└── common.py              # Shared enums, pagination, error responses
```

Rules:
- One file per domain area, named after the domain (not the layer that uses it)
- If a file grows beyond ~300 lines, split it into a package:
  `data_definitions/documents/schemas.py`, `data_definitions/documents/enums.py`
- `common.py` holds truly shared types (pagination, error responses, base enums)
  that span multiple domains

## Field Definitions

Every field MUST have a description. This is non-negotiable — our APIs are
MCP-ready, meaning LLM agents read these descriptions to understand the data.

```python
# WRONG — no descriptions, ambiguous names
class QueryRequest(BaseModel):
    q: str
    n: int = 10
    f: str | None = None

# CORRECT — self-documenting, MCP-ready
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
- `Field(description=...)` on EVERY field — no exceptions
- Field names must be self-descriptive (`search_query` not `q`)
- Include constraints in the description (valid ranges, allowed values)
- Use `str | None` syntax, not `Optional[str]`
- NEVER use `Any` — always specify the type
- For optional fields, describe what happens when omitted

## Base Model Inheritance

When two or more schemas share fields, extract a base model. This prevents
duplication and ensures changes propagate to all variants.

```python
# data_definitions/users.py

class UserBase(BaseModel):
    """Shared fields across all user schemas."""
    email: str = Field(description="User's email address")
    name: str = Field(description="User's display name")

class UserCreateRequest(UserBase):
    """Request body for creating a new user."""
    password: str = Field(description="Initial password, minimum 8 characters")

class UserResponse(UserBase):
    """User data returned by the API."""
    user_id: str = Field(description="Unique user identifier")
    created_at: datetime = Field(description="Account creation timestamp")
```

Rules:
- Extract a base when 2+ schemas share fields
- Base model names end in `Base` (e.g., `UserBase`, `DocumentBase`)
- Only ONE level of inheritance — no deep chains
- Base models are NOT used directly as request/response types. They exist
  only to be extended.
- If schemas don't share fields, keep them independent — don't force inheritance

## Naming Conventions

```
<Domain><Action><Type>

Examples:
  UserCreateRequest       — request body for creating a user
  UserCreateResponse      — response after creating a user
  UserResponse            — general user response (when there's only one)
  DocumentUploadRequest   — request body for uploading a document
  DocumentListResponse    — response containing a list of documents
  OnboardingStatus        — enum or model representing status
```

Rules:
- Request schemas end in `Request`
- Response schemas end in `Response`
- Base schemas end in `Base`
- Enums are named descriptively: `DocumentType`, `OnboardingStatus`, `UserRole`
- NEVER use generic names like `Data`, `Info`, `Item`, `Payload`

## Enums

Enums live in the same file as their related schemas. Use `StrEnum` for
string-based enums (most common in APIs):

```python
from enum import StrEnum

class DocumentType(StrEnum):
    """Type of document being processed."""
    PDF = "pdf"
    DOCX = "docx"
    TXT = "txt"
    MARKDOWN = "markdown"
```

Rules:
- Use `StrEnum` for values that appear in JSON (API request/response fields)
- Use `IntEnum` only when the value is genuinely numeric
- Every enum gets a docstring explaining what it represents
- Enum values should be lowercase strings

## Validators

Use Pydantic validators sparingly — only when `Field` constraints aren't enough:

```python
from pydantic import field_validator

class DocumentUploadRequest(BaseModel):
    filename: str = Field(description="Name of the file being uploaded")
    content_type: str = Field(description="MIME type of the file")

    @field_validator("content_type")
    @classmethod
    def validate_content_type(cls, v: str) -> str:
        allowed = {"application/pdf", "text/plain", "text/markdown"}
        if v not in allowed:
            raise ValueError(f"Content type must be one of: {allowed}")
        return v
```

Rules:
- Prefer `Field(ge=, le=, min_length=, max_length=, pattern=)` over validators
- Use `@field_validator` only for complex validation logic
- Validators should raise `ValueError` with a clear message
- Keep validators in the same class — don't create external validator functions

## What NOT to Do

- **NEVER define Pydantic models outside data_definitions/** — not in routers,
  not in services, not in integrations
- **NEVER use raw dicts** for structured data — create a Pydantic model
- **NEVER use `Any`** — find the actual type or use `str | int | float`
- **NEVER create deep inheritance chains** — one level max (Base → Specific)
- **NEVER duplicate fields** across schemas that could share a base model

## Checklist Before Finishing

When you create or modify schemas in data_definitions/, verify:
- [ ] Models are in data_definitions/, not defined elsewhere
- [ ] Every field has `Field(description=...)`
- [ ] Field names are self-descriptive
- [ ] Shared fields are extracted into a Base model
- [ ] Naming follows `<Domain><Action><Type>` convention
- [ ] Enums use `StrEnum` with lowercase values
- [ ] No `Any` types, no `Optional[]` syntax
- [ ] Validators are used only when Field constraints aren't sufficient