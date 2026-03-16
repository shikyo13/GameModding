---
name: generate-mod
description: "Auto-generate mods from project findings — select format by engine, generate multi-format output with installation instructions"
---

# /generate-mod — Generate Mods from Findings

When the user runs `/generate-mod`, auto-generate mods based on the project's accumulated findings.

## Required Input
- **Project name**: The RE project to generate mods for (or auto-detect if only one exists)
- **Scope**: Which findings to turn into mods (all, or specific ones)

## Workflow

### Phase 1: Gather Context
1. Use `re-orchestrator:get_findings` to retrieve all project findings.
2. Use `re-orchestrator:list_projects` if project name not specified.
3. Categorize findings:
   - Address findings -> value editors / freezers
   - Pattern/AOB findings -> code patches
   - Function findings -> hooks / method patches
   - Pointer chain findings -> stable value access

### Phase 2: Select Format by Engine
4. Check the project's engine type to determine primary format:

| Engine | Primary | Secondary | Tertiary |
|--------|---------|-----------|----------|
| Unity Mono | BepInEx plugin | CE table | Frida script |
| Unity IL2CPP | BepInEx (Il2CppInterop) | CE table | Frida script |
| Unreal (UE4SS) | UE4SS Lua mod | CE table | Frida script |
| Unreal (no UE4SS) | Frida script | CE table | - |
| .NET (non-Unity) | Standalone Harmony loader | Assembly patcher | CE table |
| Native C++ | CE table | Frida script | - |

### Phase 3: Generate Mods

**For .NET (non-Unity) games:**
5a. Use `re-orchestrator:generate_standalone_loader` for runtime Harmony patches.
5b. Use `re-orchestrator:generate_assembly_patcher` for offline IL modifications.
5c. Use `re-orchestrator:generate_cheat_table` for CE-based value editing.

**For Unity Mono games:**
5a. Use `re-orchestrator:generate_bepinex_plugin` for the primary mod.
5b. Use `re-orchestrator:generate_cheat_table` for CE table.

**For Unity IL2CPP games:**
5a. Use `re-orchestrator:generate_bepinex_plugin` with `il2cpp: true`.
5b. Use `re-orchestrator:generate_cheat_table` for CE table.
5c. Use `re-orchestrator:generate_frida_script` for Frida hooks.

**For Unreal games:**
5a. Use `re-orchestrator:generate_ue4ss_mod` if UE4SS is available.
5b. Use `re-orchestrator:generate_frida_script` for native hooks.
5c. Use `re-orchestrator:generate_cheat_table` for memory values.

**For all games (if AOB findings exist):**
5d. Use `re-orchestrator:generate_ce_trainer` for a Lua-based trainer with hotkeys.

### Phase 4: Deliver
6. For each generated mod, provide:
   - What it does (list of features/cheats)
   - File location
   - Build instructions (if compilation needed)
   - Installation instructions
   - Usage instructions (hotkeys, commands, etc.)
7. Save generated mods as findings: `re-orchestrator:save_finding` with type `mod`.

## Output Format
Present each generated mod format with clear headers, build steps, install steps, and usage/hotkey reference.
