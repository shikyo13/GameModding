---
name: new-game
description: "Add a new game to the modding workspace — detects engine, creates game folder with .mcp.json, hooks, settings, CLAUDE.md, and registers the plugin"
---

# /new-game — Add Game to Workspace

When the user runs `/new-game`, set up a complete game folder in the GameModding workspace.

## Required Input
- **Game name**: Name of the game
- **Game install path**: Path to the game's installation (Steam library)

## Workflow

### Phase 1: Engine Detection
1. Use `re-orchestrator:detect_game_engine` on the install path.
2. If detection fails, ask the user to confirm the engine type.
3. Determine the modding framework.

### Phase 2: Create Game Folder
4. Create `D:/Dev/Projects/GameModding/<GameName>Mods/`
5. Initialize git repo: `git init`
6. Create `.gitignore` (engine-appropriate: bin/, obj/, build/, etc.)

### Phase 3: Generate Configuration Files
7. Create `.mcp.json` based on engine tier:
   - Unity Mono: re-orchestrator only
   - Unity IL2CPP: re-orchestrator + ghidra
   - Java: re-orchestrator only
   - Unreal: re-orchestrator + ghidra
   - Others: re-orchestrator only
8. Create `.claude/settings.json` with engine-appropriate hooks.
9. Create `.claude/hooks/auto-build.sh` (if applicable).
10. Create `.claude/settings.local.json` with clean wildcard permissions.

### Phase 4: Generate Documentation
11. Create `CLAUDE.md` with parent workspace reference, engine info, build/deploy commands.
12. Create `docs/tier1-quickref.md` with mod index, build commands, deploy paths.

### Phase 5: Register Plugin
13. Read `C:\Users\Zero\.claude\plugins\installed_plugins.json`.
14. Add new entry for the game folder path.
15. Report: folder created, plugin registered, ready to create first mod with `/new-mod`.

### Phase 6: Initial Analysis (optional)
16. If Unity Mono: run `/analyze-assembly` on Assembly-CSharp.dll.
17. If Unity IL2CPP: note that IL2CPP Dumper workflow is needed.
18. Save initial findings via `re-orchestrator:save_finding`.
