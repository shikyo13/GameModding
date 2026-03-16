---
name: compare-assemblies
description: "Diff two versions of a .NET assembly after a game update — show added, removed, and changed types and methods"
---

# /compare-assemblies — Assembly Version Diff

When the user runs `/compare-assemblies`, diff two versions of a .NET assembly to identify what changed after a game update.

## Required Input
- **Old assembly path**: Path to the previous version .dll
- **New assembly path**: Path to the updated version .dll

## Workflow

### Phase 1: Enumerate Both Versions
1. Use `re-orchestrator:enumerate_dotnet_types` on the OLD assembly.
2. Use `re-orchestrator:enumerate_dotnet_types` on the NEW assembly.
3. Build a set of all type names from each version.

### Phase 2: Identify Changes
4. **Added types**: Types present in NEW but not OLD.
5. **Removed types**: Types present in OLD but not NEW.
6. **Potentially changed types**: Types present in both — compare method counts.

### Phase 3: Method-Level Diff (for changed types)
7. For each potentially changed type, use `re-orchestrator:enumerate_dotnet_methods` on both versions.
8. Compare method signatures — identify added, removed, renamed methods.
9. For renamed methods: look for methods with same parameter types but different names.

### Phase 4: Report
10. Present summary:
    - Added types (with namespace grouping)
    - Removed types
    - Changed types (with method-level diff)
    - Impact assessment: which existing Harmony patches might break

### Phase 5: Save Findings
11. Use `re-orchestrator:save_finding` to persist the diff for future reference.
