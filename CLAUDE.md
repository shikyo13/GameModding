# GameModding — RE & Modding Workspace

Multi-game modding workspace with shared RE toolkit. Engine-specific docs at this level; game-specific APIs and guides live in each game folder.

## Modding Ethics

- Never distribute decompiled game code or assets
- Never charge money for mods (donations OK if they don't gate features)
- Respect other modders' work — check licenses before reusing code
- When uncertain, ask the community first

## Documentation Routing

| When | Read |
|-|-|
| Every session | docs/tier1-re-quickref.md |
| Unity Mono game | docs/engines/unity-mono.md |
| Unity IL2CPP game | docs/engines/unity-il2cpp.md |
| Unity assets/animations | docs/engines/unity-assets.md |
| Unity runtime inspection | docs/engines/unity-runtime.md |
| Unreal Engine game | docs/engines/unreal.md |
| Godot engine game | docs/engines/godot.md |
| Minecraft modding | docs/engines/java-minecraft.md |
| Project Zomboid modding | docs/engines/java-zomboid.md |
| Stardew Valley modding | docs/engines/monogame-smapi.md |
| Source 2 engine game | docs/engines/source2.md |
| Writing Harmony patches | docs/frameworks/harmony.md |
| Setting up BepInEx | docs/frameworks/bepinex.md |
| Writing Frida scripts | docs/frameworks/frida.md |
| Static analysis (Ghidra) | docs/tools/ghidra.md |
| Memory scanning (CE) | docs/tools/cheat-engine.md |
| .NET decompilation | docs/tools/dotnet-decompilation.md |
| Dynamic debugging (x64dbg) | docs/tools/x64dbg.md |
| Using an agent | docs/toolkit/agents.md |
| Looking up a slash command | docs/toolkit/skills.md |
| Full workflow recipe | docs/toolkit/workflows.md |
| MCP server setup/issues | docs/toolkit/mcp-servers.md |
| Helper scripts | docs/toolkit/commands.md |
| Publishing/monetization | docs/monetization.md |
| Managing Discord server | DiscordManager/CLAUDE.md |
| Working on a specific game | <GameFolder>/CLAUDE.md |

## Game Folders

| Folder | Game | Engine |
|-|-|-|
| ONIMods/ | Oxygen Not Included | Unity (Mono) |
| PhasmoMods/ | Phasmophobia | Unity |
| MCMods/ | Minecraft | Java (Fabric/Forge) |
| RimWorldMods/ | RimWorld | Unity (Mono) |
| StardewMods/ | Stardew Valley | .NET (SMAPI) |
| SubnauticaMods/ | Subnautica | Unity (Mono) |
| ZomboidMods/ | Project Zomboid | Java (Lua modding) |
| DiscordManager/ | Zero's Mods Discord server | Discord MCP + GitHub Actions |

## Conventions

- Save RE findings via `re-orchestrator:save_finding` for cross-session persistence
- Use `/new-project` skill when starting work on a new game target
- Each game folder has its own CLAUDE.md with game-specific routing and conventions
