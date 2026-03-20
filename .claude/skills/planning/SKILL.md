---
name: planning
description: >
  Enforces plan-before-code workflow whenever Claude detects a request to build,
  create, or implement a new feature, workflow, endpoint, or significant piece of
  functionality. Auto-invokes when the developer asks to "build", "create",
  "implement", "add", or "set up" something that spans multiple files or layers.
  Does NOT trigger for small edits, bug fixes, or single-file changes.
---

# Planning Before Coding

## The Rule

When the developer asks to build something that will span multiple files or
architectural layers, Claude MUST plan before writing any code.

**This triggers when:**
- Creating a new feature, workflow, or integration
- Adding a new set of endpoints
- Building something that touches core/features/, orchestration/, AND/OR integrations/
- Any task that will create 3+ new files

**This does NOT trigger when:**
- Fixing a bug in an existing file
- Adding a method to an existing class
- Modifying a single file
- Refactoring existing code
- The developer explicitly says "just do it" or "skip the plan"

## What to Do

1. **Check if a plan already exists.** Look in `plans/` for a relevant plan file.
   If one exists and is approved, implement against it — don't re-plan.

2. **If no plan exists**, tell the developer:
   > "This looks like it'll span multiple files. I'd recommend creating a plan first
   > so we can agree on the structure before I start coding. Want me to run `/plan`
   > to map it out, or would you prefer I just go ahead?"

3. **If the developer wants to plan**, follow the `/plan` command workflow.
   The plan MUST be written to `plans/<feature_name>.md` — never just output
   it in chat. The plan file is the source of truth for implementation.

4. **If the developer says skip it**, proceed with implementation but still follow
   api-conventions and service-patterns skills.

## Referencing Existing Plans

When implementing any feature, always check `plans/` first. If an approved plan
exists for the feature being worked on:
- Follow the plan's file map, class definitions, and method signatures
- Don't deviate from the approved schema definitions
- If something in the plan doesn't work during implementation, flag it to the
  developer rather than silently changing the approach