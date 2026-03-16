# Tier 1 — RE Quick Reference (read once per session)

Hard cap: 100 lines. Tool inventory + decision trees.

## Tool Inventory

| Tool | Type | Purpose |
|-|-|-|
| re-analyst | Agent | Static/dynamic binary analysis, decompilation, xref tracing |
| memory-hunter | Agent | Memory scanning, pointer chains, AOB signatures |
| mod-builder | Agent | Code generation: BepInEx, Harmony, CE tables, Frida scripts |
| asset-explorer | Agent | Unity asset extraction, kanim/texture/animation inspection |
| /new-project | Skill | Initialize RE project, detect engine, run initial analysis |
| /analyze-assembly | Skill | Deep .NET assembly analysis — types, methods, findings |
| /find-value | Skill | Guided memory scanning workflow with CE |
| /trace-to-code | Skill | Map memory address → source code method |
| /generate-mod | Skill | Auto-generate mod from project findings |
| /compare-assemblies | Skill | Diff two DLL versions after game update |
| /dump-type | Skill | Single-type deep dive with full decompilation |
| /find-hooks | Skill | Search assemblies for candidate methods to patch |

## Decision Tree — "What do I use?"

### "I have a new game to mod"
1. `/new-project` — detects engine, creates project, runs initial analysis
2. If Unity Mono → `/analyze-assembly` on Assembly-CSharp.dll
3. If Unity IL2CPP → re-analyst agent (IL2CPP dumper workflow)
4. If Java → check game-specific docs (MCMods, ZomboidMods)

### "I want to find where X is implemented"
1. `/analyze-assembly` — broad search by keyword
2. `/dump-type` — deep dive on a specific type
3. `/find-hooks` — find patchable methods for a gameplay goal
4. re-analyst agent — complex multi-step analysis with Ghidra

### "I want to change a runtime value"
1. `/find-value` — guided memory scan workflow
2. memory-hunter agent — complex multi-step scanning with pointer chains

### "I want to build a mod from findings"
1. `/generate-mod` — auto-generate from saved project findings
2. mod-builder agent — custom mod with specific requirements

### "A game updated and my mod broke"
1. `/compare-assemblies` — diff old vs new DLL
2. `/analyze-assembly` — find renamed/moved methods
3. re-analyst agent — deep investigation of changes

### "I need to inspect game assets"
1. asset-explorer agent — Unity assets, textures, animations

## MCP Servers

| Server | Tools for | Required by |
|-|-|-|
| re-orchestrator | Project mgmt, .NET inspection, mod gen | All agents/skills |
| ghidra | Static binary analysis, decompilation | re-analyst |
| cheatengine | Memory scanning, breakpoints, AOB | memory-hunter, re-analyst |
| frida-game-hacking | Runtime hooking, cross-platform scanning | memory-hunter, mod-builder |
| x64dbg | Dynamic debugging (Windows native) | re-analyst |

## Engine Quick Reference

| Engine | Key DLL | Decompilation Tool | Mod Framework |
|-|-|-|-|
| Unity Mono | Assembly-CSharp.dll | ilspycmd / dnSpy | BepInEx + Harmony or UserMod2 |
| Unity IL2CPP | GameAssembly.dll | IL2CPP Dumper + Ghidra | BepInEx (Il2CppInterop) |
| Java (MC) | game JARs | JD-GUI / fernflower | Fabric / Forge |
| Java (Zomboid) | game JARs | JD-GUI | Lua API + Java patches |
| .NET (Stardew) | game DLLs | ilspycmd / dnSpy | SMAPI |
| Unreal | game .exe | Ghidra / x64dbg | UE4SS |
| Godot | .pck files | Godot RE tools | GDScript patches |

## Decompiler CLI Cheat Sheet

ilspycmd (installed globally):
- List types: `ilspycmd "path.dll" -l -r "ManagedDir"`
- Decompile type: `ilspycmd "path.dll" -t TypeName -r "ManagedDir"`
- Use `\\` path separators on Windows
