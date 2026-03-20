# Generate Test Report

You are generating a test report after running the test suite. The report should
give a clear picture of what's tested, what passed, and what failed — organized
by source file for unit tests and by feature/UX journey for e2e tests.

## Step 1: Run the Tests

Run the full test suite with verbose output:

```bash
uv run pytest -v --tb=short 2>&1
```

Capture the full output. If specific test tiers are requested (e.g., "just unit
tests"), run only that tier:
- Unit: `uv run pytest tests/unit/ -v --tb=short`
- Integration: `uv run pytest tests/integration/ -v --tb=short`
- E2e: `uv run pytest tests/e2e/ -v --tb=short`

## Step 2: Generate the Report

Create or update `test_report.md` in the project root with the following format:

```markdown
# Test Report

Generated: <current date and time>

## Summary

| Tier        | Passed | Failed | Skipped | Total |
|-------------|--------|--------|---------|-------|
| Unit        | X      | X      | X       | X     |
| Integration | X      | X      | X       | X     |
| E2e         | X      | X      | X       | X     |
| **Total**   | **X**  | **X**  | **X**   | **X** |

## Unit Tests — By Source File

### src/<app_name>/integrations/auth/client.py
| Test | Result |
|------|--------|
| test_create_user_valid_email_returns_user_id | ✅ PASSED |
| test_create_user_duplicate_email_raises_conflict | ❌ FAILED |

**Failure details:**
> Brief description of what failed and why (from pytest output)

### src/<app_name>/modules/common/text.py
| Test | Result |
|------|--------|
| test_slugify_with_spaces_returns_hyphenated | ✅ PASSED |
| test_slugify_empty_string_returns_empty | ✅ PASSED |

## Integration Tests — By Component

### Database Connection
| Test | Result |
|------|--------|
| test_db_connection_pool_creates_sessions | ✅ PASSED |

## E2e Tests — By Feature/UX Journey

### Onboarding Flow
| Test | Result |
|------|--------|
| test_onboarding_start_new_user_creates_workspace | ✅ PASSED |
| test_onboarding_start_existing_user_returns_error | ✅ PASSED |

### Query Workflow
| Test | Result |
|------|--------|
| test_query_with_filters_returns_filtered_results | ❌ FAILED |

**Failure details:**
> Brief description of what failed and why

## Coverage Gaps

List any source files or features in the plan that do NOT have corresponding tests:
- <file or feature with no test coverage>

If a plan exists in `plans/`, cross-reference it to identify what was planned
but not yet tested.
```

## Step 3: Present the Report

After writing the file, summarize the results to the developer:
- Total pass/fail counts
- Any failures with one-line explanations
- Any coverage gaps found
- If all tests passed, say so clearly

Do NOT just dump the raw pytest output — the report is the deliverable.