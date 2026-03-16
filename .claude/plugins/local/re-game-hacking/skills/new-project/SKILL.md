---
name: new-project
description: "Initialize a new RE project — detect game engine, create project, perform initial analysis, and generate an action plan"
---

# /new-project — Initialize a New RE Project

When the user runs `/new-project`, guide them through setting up a new reverse engineering project.

## Required Input
- **Game path**: The path to the game installation directory or main executable

## Workflow

1. **Detect Game Engine**
   Use `re-orchestrator:detect_game_engine` with the provided game path.
   Report: engine type, version, architecture, anti-cheat status.

2. **Analyze Directory**
   Use `re-orchestrator:analyze_game_directory` to catalog files.
   Report: executable count, managed DLL count, config files, asset files.

3. **Create Project**
   Use `re-orchestrator:create_project` with the game name, detected engine, and game path.

4. **Engine-Specific Initial Analysis**
   Based on the detected engine:

   - **Unity IL2CPP**: Run `re-orchestrator:run_il2cpp_dumper`, then `parse_il2cpp_dump`. Search for gameplay classes.
   - **Unity Mono**: Run `re-orchestrator:list_dotnet_assemblies`. Inspect Assembly-CSharp.dll.
   - **Unreal Engine**: Run `re-orchestrator:analyze_unreal_project`, `detect_unreal_version`, `list_unreal_assets`.
   - **Godot**: Run `re-orchestrator:analyze_godot_project`, `list_godot_resources`.
   - **.NET (non-Unity)**: Run `re-orchestrator:list_dotnet_assemblies`. Use `enumerate_dotnet_types` on the main executable to discover game classes. Use `search_dotnet_assembly` for common gameplay keywords (Health, Gold, Resource, Player, Manager, Economy, Damage). Use `get_dotnet_assembly_refs` to identify dependencies.
   - **Native**: Extract binary strings, note key findings.

5. **Generate Action Plan**
   Based on all findings, provide a structured action plan:
   - Key assemblies/binaries to analyze deeper
   - Suggested gameplay systems to investigate (based on detected types/strings)
   - Recommended modding approach for this engine
   - Next steps for the user or agent team

## Output Format
Present results in a clear, structured format with headers for each step. Include the project name/ID for future reference.
