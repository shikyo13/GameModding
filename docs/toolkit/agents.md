# Agent Reference

This document describes the specialized agents available in the GameModding workspace.
Each agent is a role Claude can adopt, with access to specific MCP tool sets and
domain knowledge for a particular phase of game modding.

---

## re-analyst

**Purpose:** Static analysis, reverse engineering, and code understanding.

**When to use:**
- Decompiling game assemblies to understand structure
- Tracing cross-references to find how systems connect
- Identifying hook points for modding
- Analyzing IL2CPP metadata dumps
- Understanding class hierarchies and inheritance

**Key MCP tools:**
- `mcp__ghidra__decompile_function` / `decompile_function_by_address` — read C-like pseudocode
- `mcp__ghidra__get_function_xrefs` / `get_xrefs_to` / `get_xrefs_from` — trace call graphs
- `mcp__ghidra__list_classes` / `list_methods` / `list_namespaces` — survey type layout
- `mcp__ghidra__search_functions_by_name` — locate targets by name pattern
- `mcp__re-orchestrator__inspect_assembly` — .NET assembly overview
- `mcp__re-orchestrator__enumerate_dotnet_types` / `enumerate_dotnet_methods` — managed code browsing
- `mcp__re-orchestrator__search_dotnet_assembly` — text search inside assemblies
- `mcp__re-orchestrator__run_il2cpp_dumper` / `parse_il2cpp_dump` / `search_il2cpp_dump` — IL2CPP pipeline

**Example prompts:**
- "Decompile the PlayerHealth class and find where damage is applied."
- "Trace all callers of `ApplyDamage` and show me the call chain."
- "Search Assembly-CSharp for classes related to inventory management."
- "Dump the IL2CPP metadata and find all MonoBehaviour subclasses."

---

## memory-hunter

**Purpose:** Runtime memory analysis, value scanning, and pointer resolution.

**When to use:**
- Finding the memory address of a game value (health, gold, ammo)
- Building pointer chains for stable access across restarts
- Setting breakpoints to find what code reads/writes a value
- Watching memory regions for changes
- Validating that a found address is correct before building a mod

**Key MCP tools:**
- `mcp__cheatengine__scan_all` / `next_scan` / `get_scan_results` — value scanning
- `mcp__cheatengine__read_memory` / `read_integer` / `read_string` — inspect values
- `mcp__cheatengine__write_memory` / `write_integer` — test modifications
- `mcp__cheatengine__read_pointer` / `read_pointer_chain` — pointer chain resolution
- `mcp__cheatengine__set_breakpoint` / `set_data_breakpoint` / `get_breakpoint_hits` — find accessing code
- `mcp__cheatengine__aob_scan` / `generate_signature` — pattern-based address finding
- `mcp__cheatengine__dissect_structure` — map out data structures around an address
- `mcp__frida-game-hacking__scan_value` / `scan_next` / `scan_changed` — Frida-based scanning
- `mcp__frida-game-hacking__read_memory` / `write_memory` — Frida memory access

**Example prompts:**
- "Scan for my current health value of 100, then narrow it down after I take damage."
- "Find a pointer chain to the player's gold address."
- "Set a breakpoint on the ammo address and show me what code writes to it."
- "Generate an AOB signature for the instruction that modifies player speed."

---

## mod-builder

**Purpose:** Code generation for mods, trainers, and patches based on analysis findings.

**When to use:**
- Generating a BepInEx/Harmony plugin from identified hook points
- Creating a Cheat Engine table or trainer from found addresses
- Building a Frida script for runtime interception
- Writing an assembly patcher for permanent modifications
- Generating UE4SS Lua mods for Unreal games

**Supported frameworks:**
- **Harmony patches** — prefix/postfix/transpiler for .NET games
- **BepInEx plugins** — full plugin scaffolding with config
- **Cheat Engine tables/trainers** — .CT files and standalone trainers
- **Frida scripts** — JavaScript-based runtime hooks
- **Assembly patchers** — direct IL modification
- **UE4SS mods** — Lua scripting for Unreal Engine games

**Key MCP tools:**
- `mcp__re-orchestrator__generate_harmony_patch` — Harmony patch code
- `mcp__re-orchestrator__generate_bepinex_plugin` — full BepInEx plugin
- `mcp__re-orchestrator__generate_cheat_table` / `generate_ce_trainer` — CE outputs
- `mcp__re-orchestrator__generate_frida_script` — Frida interception scripts
- `mcp__re-orchestrator__generate_assembly_patcher` — IL-level patching
- `mcp__re-orchestrator__generate_ue4ss_mod` — Unreal Lua mods
- `mcp__re-orchestrator__generate_standalone_loader` — standalone mod loaders

**Example prompts:**
- "Generate a Harmony patch that doubles XP gain in the LevelUp method."
- "Create a BepInEx plugin with a config option to set max health."
- "Build a Cheat Engine table from the addresses we found for health, mana, and gold."
- "Write a Frida script that intercepts the damage function and logs all calls."

---

## asset-explorer

**Purpose:** Game asset inspection — models, textures, animations, and resource files.

**When to use:**
- Listing Unity asset bundles and their contents
- Browsing Unreal Engine .pak/.uasset files
- Finding specific textures, models, or audio files
- Understanding asset references and dependencies
- Exploring Godot project resources

**Key MCP tools:**
- `mcp__re-orchestrator__list_unity_assets` — browse Unity asset bundles
- `mcp__re-orchestrator__list_unreal_assets` — browse Unreal packages
- `mcp__re-orchestrator__list_godot_resources` — browse Godot resources
- `mcp__re-orchestrator__analyze_game_directory` — general asset survey
- `mcp__re-orchestrator__extract_binary_strings` — find embedded text in assets

**Example prompts:**
- "List all Unity asset bundles in the game's data folder."
- "Find all texture assets that contain 'player' in the name."
- "Analyze the game directory and tell me what engine it uses and where assets live."
- "Extract strings from the main asset bundle to find localization keys."

---

## Team Mode: Agent Communication via Findings

Agents don't talk directly to each other. Instead, they share results through the
**re-orchestrator findings system**, which acts as a shared knowledge base.

**How it works:**
1. `re-analyst` discovers a hook point and calls `save_finding` with type, address, and notes.
2. `memory-hunter` finds a pointer chain and saves it as a finding.
3. `mod-builder` calls `get_findings` or `search_findings` to retrieve all prior analysis.
4. Any agent can call `export_findings` to produce a summary report.

**Key coordination tools:**
- `mcp__re-orchestrator__save_finding` — store a discovery
- `mcp__re-orchestrator__get_findings` — retrieve all findings for a project
- `mcp__re-orchestrator__search_findings` — search by keyword
- `mcp__re-orchestrator__delete_finding` — remove outdated entries
- `mcp__re-orchestrator__export_findings` — generate a report

**Typical team flow:**
1. User creates a project with `create_project`.
2. `re-analyst` populates findings with classes, methods, and hook points.
3. `memory-hunter` adds runtime addresses and pointer chains.
4. `mod-builder` reads all findings and generates complete mod code.

This decoupled approach means each agent can work independently, and findings
accumulate into a comprehensive picture of the target game.
