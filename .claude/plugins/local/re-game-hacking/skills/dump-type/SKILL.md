---
name: dump-type
description: "Single-type deep dive — decompile a type with all fields, methods, base classes, and interfaces"
---

# /dump-type — Deep Type Inspection

When the user runs `/dump-type`, perform a comprehensive inspection of a single .NET type.

## Required Input
- **Assembly path**: Path to the .dll containing the type
- **Type name**: Full or partial type name to inspect

## Workflow

### Phase 1: Find the Type
1. If partial name given, use `re-orchestrator:search_dotnet_assembly` to find matches.
2. If multiple matches, present them and ask user to pick one.
3. Confirm the full type name (with namespace).

### Phase 2: Type Overview
4. Use `re-orchestrator:enumerate_dotnet_fields` to get all fields (name, type, visibility, static/instance).
5. Use `re-orchestrator:enumerate_dotnet_methods` to get all methods (name, return type, parameters, visibility).
6. Identify: base class, implemented interfaces, nested types.

### Phase 3: Method Decompilation
7. For each method, use `re-orchestrator:disassemble_dotnet_method` to get decompiled C# source.
8. Present methods grouped by visibility (public → protected → private).
9. Flag interesting patterns: virtual methods (patchable), event handlers, serialization attributes.

### Phase 4: Cross-Reference Analysis
10. Identify which other types reference this type (consumers).
11. Identify which types this type references (dependencies).

### Phase 5: Save & Report
12. Use `re-orchestrator:save_finding` with type "structure" to persist the full type analysis.
13. Present a summary with the type's role in the codebase and suggested hook points.
