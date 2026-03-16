# GameModding Toolkit Re-Architecture Design

**Goal:** Re-architect all Claude Code automations into the ultimate game modding toolkit. Per-game context optimization, broken path fixes, production-quality mod workflows for income generation.

**Architecture:** Engine-profile hybrid (A-hybrid). Plugin stays shared at workspace root. Each game folder gets its own `.mcp.json`, hooks, and permissions tailored to its engine. MCP servers load only what's needed per engine.

## MCP Server Tiers

| Tier | Servers | Loading |
|-|-|-|
| Core | re-orchestrator (36 tools) | Per-game `.mcp.json` |
| Engine | + ghidra (27), x64dbg (34) | Only for native/IL2CPP engines |
| On-demand | cheatengine (43), frida (42) | User enables via `/re-tools` or `/mcp` |

### Per-Engine MCP Defaults

| Engine | Servers in `.mcp.json` |
|-|-|
| Unity Mono | re-orchestrator |
| Unity IL2CPP | re-orchestrator, ghidra |
| Java (Fabric/Forge) | re-orchestrator |
| Java/Lua (Zomboid) | re-orchestrator |
| .NET/SMAPI | re-orchestrator |
| Unreal | re-orchestrator, ghidra |
| Godot | re-orchestrator |

### Workspace Root `.mcp.json`

All 5 servers listed but **disabled**. Serves as reference and fallback for cross-game RE sessions.

## Plugin Scope

Single plugin source at `GameModding/.claude/plugins/local/re-game-hacking/`. Register in `installed_plugins.json` with one entry per game folder path so the plugin loads when opening any game folder directly.

## Agents (4)

| Agent | Role | Replaces |
|-|-|-|
| re-analyst | Static/dynamic binary analysis, .NET decompilation, memory hunting workflows | re-analyst + memory-hunter merged |
| mod-builder | Engine-aware code generation, project scaffolding, framework auto-detection | mod-builder enhanced |
| mod-reviewer | Quality assurance, compatibility checks, workshop descriptions, changelog generation | NEW (replaces memory-hunter) |
| asset-explorer | Unity asset extraction, kanim inspection | Unchanged |

## Skills (11)

### RE Skills
| Skill | Purpose |
|-|-|
| `/analyze-assembly` | Deep .NET assembly analysis |
| `/find-hooks` | Find patchable methods for a gameplay goal |
| `/dump-type` | Single-type deep decompilation |
| `/compare-assemblies` | Diff DLLs after game update |
| `/find-value` | Guided memory scan (requires CE enabled) |
| `/trace-to-code` | Map memory address to source method |

### Build Skills
| Skill | Purpose |
|-|-|
| `/new-game` | Rework of `/new-project`. Scaffold full game folder: detect engine, generate .mcp.json, settings.json, hooks, CLAUDE.md, register plugin path |
| `/generate-mod` | Generate mod code from project findings |
| `/new-mod` | NEW. Scaffold new mod within game folder (csproj/manifest/entry point/build config) |

### Publish Skills
| Skill | Purpose |
|-|-|
| `/release` | NEW. Build release, bump version, generate changelog, package for distribution |
| `/workshop-prep` | NEW. Generate workshop description, preview image checklist, tag suggestions, SEO |

## Per-Game Configuration

Each game folder gets:

### `.mcp.json`
Engine-appropriate MCP servers only.

### `.claude/settings.json`
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{ "type": "command", "command": "bash .claude/hooks/auto-build.sh", "timeout": 60 }]
    }],
    "PreToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{ "type": "command", "command": "bash .claude/hooks/block-game-dlls.sh", "timeout": 5 }]
    }]
  }
}
```

### `.claude/settings.local.json`
Clean wildcard permissions replacing accumulated junk:
```json
{
  "permissions": {
    "allow": [
      "Bash(dotnet *)", "Bash(git *)", "Bash(cp *)", "Bash(mkdir *)",
      "Bash(ls *)", "Bash(rm *)", "mcp__re-orchestrator__*", "WebSearch"
    ]
  }
}
```
Plus engine-specific additions (e.g., `Bash(./gradlew *)` for Java).

### `.claude/hooks/auto-build.sh`
Engine-specific build command. Detects which mod was edited and builds it.

### `.claude/hooks/block-game-dlls.sh`
Blocks editing `.dll` files and game install directories.

### `CLAUDE.md`
Parent routing + game-specific conventions, DLL paths, mod framework info.

### `docs/tier1-quickref.md`
Game-specific mod index, build commands, deploy paths, gotchas.

## Per-Game Specifics

### ONIMods (Unity Mono)
- Build: `dotnet build <Mod>/<Mod>.csproj`
- Deploy: `$USERPROFILE/Documents/Klei/OxygenNotIncluded/mods/dev/<Mod>/`
- Framework: UserMod2 + PLib + Harmony
- Extra: auto-build detects which of 5+ mods was edited

### PhasmoMods (Unity IL2CPP)
- Build: `dotnet build`
- Deploy: BepInEx plugins folder
- Framework: BepInEx 6 + Il2CppInterop
- MCP: re-orchestrator + ghidra (IL2CPP needs native analysis)

### MCMods/Quantum Flux (Java/NeoForge)
- Build: `./gradlew build`
- Deploy: `run/mods/`
- Framework: NeoForge
- Permissions: `Bash(./gradlew *)`

### RimWorldMods (Unity Mono)
- Build: `dotnet build`
- Deploy: RimWorld mods folder
- Framework: Harmony

### StardewMods (.NET/SMAPI)
- Build: `dotnet build`
- Deploy: SMAPI mods folder
- Framework: SMAPI + Content Patcher

### SubnauticaMods (Unity Mono)
- Build: `dotnet build`
- Deploy: BepInEx plugins folder
- Framework: BepInEx 5 + Harmony

### ZomboidMods (Java/Lua)
- Build: file copy (Lua mods) or javac
- Deploy: Zomboid mods folder
- Framework: Lua API

## Broken Path Fixes

All fixed by regenerating per-game config from templates:

| File | Issue |
|-|-|
| ONIMods/.claude/settings.json | Hook paths reference old `D:/Dev/Projects/ONI Mods` |
| ONIMods/.claude/hooks/auto-build.sh | Internal `cd` path references old location |
| ONIMods/.claude/settings.local.json | 185 junk entries with old paths |
| MCMods/.claude/settings.local.json | References old `D:/Dev/Projects/MC Mods` |
| ZomboidMods/.claude/settings.local.json | Inconsistent paths |

## New Documentation

### `docs/monetization.md`
Covers: platforms (Nexus, Patreon, ko-fi, CurseForge), mod presentation best practices, workshop SEO, audience building, licensing for donation-supported mods.

## Context Budget

| Session type | Deferred tools | vs current |
|-|-|-|
| Unity Mono coding | ~36 | -80% |
| Unity IL2CPP RE | ~63 | -65% |
| Active memory scanning | +43 CE on-demand | same when needed |
| Non-game project | 0 | -100% |
