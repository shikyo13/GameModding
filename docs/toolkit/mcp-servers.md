# MCP Servers Reference

Each MCP server provides a specific set of capabilities to the GameModding toolkit.
This document covers what each server does, how to verify it, and troubleshooting.

---

## Server Inventory

### re-orchestrator

**What it provides:** Project management, .NET assembly analysis, IL2CPP dumping,
code generation (Harmony, BepInEx, Frida, CE trainers, UE4SS mods), and the
shared findings system that connects all agents.

**Key capabilities:**
- Create/manage RE projects
- Inspect and search .NET assemblies (types, methods, fields, references)
- Run IL2CPP dumper and parse/search the output
- Generate mod code for multiple frameworks
- Save/search/export findings

**Verify:** Call `mcp__re-orchestrator__list_projects` — should return a list (possibly empty).

**Depends on:** .NET runtime for assembly inspection, Il2CppDumper binary for IL2CPP analysis.

**Used by:** All agents. This is the central coordination server.

---

### cheatengine

**What it provides:** Memory scanning, reading, writing, breakpoints, AOB scanning,
pointer chain resolution, structure dissection, and disassembly — all through
Cheat Engine's automation interface.

**Key capabilities:**
- Value scanning with type filters (int, float, double, string, AOB)
- Multi-step scan refinement (next_scan with changed/unchanged)
- Memory read/write at arbitrary addresses
- Hardware and software breakpoints with hit logging
- Pointer chain traversal
- AOB pattern scanning and signature generation
- Structure dissection around an address
- Module enumeration and symbol resolution

**Verify:** Call `mcp__cheatengine__ping` — should return a success response.

**Prerequisites:** Cheat Engine must be running with the Lua server enabled.
The game process must be attached in Cheat Engine before scanning.

**Used by:** `memory-hunter` agent, memory-related skills (`/scan-value`, `/narrow-scan`, etc.)

---

### frida-game-hacking

**What it provides:** Runtime instrumentation via Frida — process attachment,
memory scanning, function hooking, script injection, and register access.

**Key capabilities:**
- Attach to or spawn processes
- List modules, exports, imports, memory regions
- Scan memory for values and patterns
- Hook native and managed functions
- Replace function implementations
- Read/write memory and registers
- Take screenshots of game windows
- Load custom Frida scripts

**Verify:** Call `mcp__frida-game-hacking__list_processes` — should return running processes.

**Prerequisites:** Frida and frida-tools must be installed (`pip install frida frida-tools`).
For some games, you may need to run as administrator.

**Used by:** `memory-hunter` agent (as Frida alternative to CE), `re-analyst` for runtime validation.

---

### ghidra

**What it provides:** Deep binary analysis through Ghidra's decompiler and
disassembler — function decompilation, cross-references, class analysis, and
symbol management.

**Key capabilities:**
- Decompile functions to C-like pseudocode
- Disassemble functions to raw instructions
- List and search functions, classes, namespaces, exports, imports
- Follow cross-references in both directions
- Rename functions, variables, and data for annotation
- Set comments in decompiled and disassembled views
- List strings and data items

**Verify:** Call `mcp__ghidra__get_current_address` — should return an address if a program is loaded.

**Prerequisites:** Ghidra must be running with the MCP bridge script active.
A game binary must be loaded and analyzed in the current Ghidra project.

**Used by:** `re-analyst` agent for deep static analysis and binary-level reverse engineering.

---

### x64dbg

**What it provides:** Live debugging — breakpoints, stepping, register manipulation,
memory access, and pattern scanning in a running process.

**Key capabilities:**
- Set/delete breakpoints
- Step in/over/out through code
- Read/write registers and memory
- Assemble instructions at addresses
- Pattern scan in memory
- Evaluate expressions
- Stack inspection (peek, push, pop)

**Verify:** Call `mcp__x64dbg__IsDebugging` — returns true if a process is being debugged.

**Prerequisites:** x64dbg must be running with the MCP plugin loaded.
A game process must be attached or spawned within x64dbg.

**Used by:** `memory-hunter` for debugging, `re-analyst` for dynamic analysis.

---

## Troubleshooting

### Server not responding

1. Check that the host application (CE, Ghidra, x64dbg) is actually running.
2. Verify the MCP bridge/plugin/script is loaded within that application.
3. Restart the MCP server process if the bridge is running but not responding.
4. Check for port conflicts if the server uses TCP.

### Common failures

| Symptom | Likely cause | Fix |
|-|-|-|
| "No process attached" | Tool called before attaching to game | Attach to the game process in CE/x64dbg first |
| Scan returns 0 results | Wrong data type or value | Try float instead of int, or vice versa |
| IL2CPP dump fails | Wrong metadata version | Update Il2CppDumper to latest release |
| Ghidra decompile timeout | Function too large | Try disassemble instead, or split analysis |
| Frida attach fails | Anti-cheat blocking | Try spawning instead of attaching, or use kernel mode |
| "Assembly not found" | Path not correct | Use absolute paths, check for spaces in path |

### Agent-to-server dependency map

| Agent | Required servers | Optional servers |
|-|-|-|
| re-analyst | re-orchestrator | ghidra, x64dbg |
| memory-hunter | re-orchestrator | cheatengine, frida-game-hacking, x64dbg |
| mod-builder | re-orchestrator | (none) |
| asset-explorer | re-orchestrator | (none) |
