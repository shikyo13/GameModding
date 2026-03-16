# Source 2 Engine (Stub)

## Engine Identification

- `engine2.dll` in game binaries
- `resourcecompiler.dll` present
- `.vpk` (Valve Pak) files for assets
- `game/` and `content/` directory structure
- `.vmap_c`, `.vmat_c`, `.vmdl_c` compiled asset formats
- Valve games: Dota 2, Half-Life: Alyx, Deadlock, Counter-Strike 2

## Key Files and Formats

| File/Extension | Purpose |
|-|-|
| `engine2.dll` | Core engine |
| `.vpk` | Valve Pak archives |
| `.vmap_c` | Compiled map files |
| `.vmat_c` | Compiled material files |
| `.vmdl_c` | Compiled model files |
| `.vpcf_c` | Compiled particle files |
| `.vsndevts_c` | Sound event definitions |
| `.vtex_c` | Compiled textures |

## Scripting

### Lua / VScript

Source 2 games use VScript (Lua or Squirrel depending on game):
- Dota 2: Lua scripting for custom games
- Other Source 2 titles may use Squirrel

### Dota 2 Custom Games

Primary Source 2 modding ecosystem:
- Lua scripts in `game/scripts/vscripts/`
- Panorama UI (HTML/CSS/JS-like) in `game/content/panorama/`
- Custom game mode framework with event-driven API
- Workshop Tools DLC provides in-engine editor

## Asset Handling

- **Source 2 Viewer**: Open-source tool for viewing compiled assets
- **ValveResourceFormat (VRF)**: C# library for parsing Source 2 formats
- Assets are compiled from source format to `_c` (compiled) format
- Workshop Tools includes `resourcecompiler.exe` for asset compilation

## Notes

This document is a stub. Expand when actively working on a Source 2 game.
Potential sections to add:
- Detailed VScript API reference
- Panorama UI development workflow
- Custom game publishing pipeline
- Ghidra analysis of engine2.dll
- Network message hooking
- Particle editor workflow
