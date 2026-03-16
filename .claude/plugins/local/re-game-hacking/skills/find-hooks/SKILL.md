---
name: find-hooks
description: "Given a gameplay goal, search assemblies for candidate methods to Harmony-patch"
---

# /find-hooks — Find Patchable Methods

When the user runs `/find-hooks`, search assemblies for methods that can be patched to achieve a gameplay goal.

## Required Input
- **Goal description**: What the user wants to change (e.g., "modify building cost", "change movement speed")
- **Assembly path**: Path to the .dll to search (or auto-detect from project)

## Workflow

### Phase 1: Keyword Extraction
1. Extract search keywords from the goal description.
2. Generate synonyms and related terms (e.g., "cost" → "Cost", "Price", "Resource", "Expense").
3. Generate likely class name patterns (e.g., "movement speed" → "Movement", "Locomotion", "Navigator", "Speed").

### Phase 2: Broad Search
4. Use `re-orchestrator:search_dotnet_assembly` with each keyword set.
5. Collect all matching types and methods.
6. Deduplicate and rank by relevance (exact match > partial match > related term).

### Phase 3: Method Analysis
7. For the top 10 candidates, use `re-orchestrator:disassemble_dotnet_method` to decompile.
8. Analyze each method for:
   - Does it read/write the target value?
   - Is it virtual (easier to patch)?
   - What are its parameters and return type?
   - Is it called frequently (per-frame) or infrequently (on-event)?

### Phase 4: Recommend Hook Points
9. Present ranked list of recommended hook points:
   - Method signature
   - Patch type recommendation (prefix/postfix/transpiler)
   - What to modify (parameter, return value, internal logic)
   - Risk assessment (per-frame performance, side effects)

### Phase 5: Save Findings
10. Use `re-orchestrator:save_finding` to persist hook recommendations.
