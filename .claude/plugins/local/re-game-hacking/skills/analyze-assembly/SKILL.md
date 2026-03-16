---
name: analyze-assembly
description: "Deep .NET assembly analysis — enumerate types, search for game logic, disassemble methods, save findings"
---

# /analyze-assembly — Deep .NET Assembly Analysis

When the user runs `/analyze-assembly`, perform comprehensive analysis of a .NET assembly.

## Required Input
- **Assembly path**: Path to the .dll or .exe to analyze (or auto-detect from project)

## Workflow

### Phase 1: Assembly Overview
1. Use `re-orchestrator:inspect_assembly` to get metadata (name, version, framework, type count).
2. Use `re-orchestrator:get_dotnet_assembly_refs` to identify dependencies.
3. Report the assembly overview: name, framework, type count, key dependencies.

### Phase 2: Type Enumeration
4. Use `re-orchestrator:enumerate_dotnet_types` to list all types.
5. Categorize types by namespace — identify the main game namespace(s).
6. Flag interesting types: those with names containing Manager, Controller, System, Data, Config, Player, Enemy, Resource, Economy, UI.

### Phase 3: Targeted Search
7. Use `re-orchestrator:search_dotnet_assembly` with gameplay keywords:
   - Combat: "Health", "Damage", "Attack", "Defense", "Armor"
   - Economy: "Gold", "Resource", "Currency", "Cost", "Price", "Population"
   - Player: "Player", "Character", "Stats", "Level", "Experience"
   - Game flow: "Manager", "Controller", "System", "Wave", "Spawn"
8. Report all matches grouped by category.

### Phase 4: Deep Dive
9. For each interesting type found, use `re-orchestrator:enumerate_dotnet_methods` to list methods.
10. Use `re-orchestrator:enumerate_dotnet_fields` to list fields (these reveal data structures).
11. For key methods, use `re-orchestrator:disassemble_dotnet_method` to inspect the IL code.

### Phase 5: Save Findings
12. Save discovered types as notes: `re-orchestrator:save_finding` with relevant details.
13. Save key methods as function findings with their RVAs.
14. Update project notes with the analysis summary: `re-orchestrator:update_project_notes`.

## Output Format
Present a structured report:
- Assembly metadata table
- Namespace breakdown with type counts
- Key gameplay classes with their fields and methods
- Recommended targets for modification (methods that control values of interest)
- Suggested next steps (memory scanning, mod generation)
