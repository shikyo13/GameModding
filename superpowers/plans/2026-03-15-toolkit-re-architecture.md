# GameModding Toolkit Re-Architecture Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-architect all Claude Code automations into a context-optimized, engine-aware game modding toolkit with per-game MCP loading, standardized hooks, and production publishing workflows.

**Architecture:** Engine-profile hybrid. Shared plugin at workspace root, per-game `.mcp.json` with only engine-relevant servers (36 tools vs 182), standardized hooks per engine, clean permissions. New agents (mod-reviewer) and skills (/new-mod, /release, /workshop-prep) for income-grade modding.

**Tech Stack:** Claude Code plugins (markdown agents/skills), MCP servers (Python), bash hooks, tiered markdown docs

**Spec:** `superpowers/specs/2026-03-15-toolkit-re-architecture-design.md`

---

## Chunk 1: MCP Server Optimization + Workspace Root

### Task 1: Disable workspace-level MCP servers

**Files:**
- Modify: `D:\Dev\Projects\GameModding\.mcp.json`

- [ ] **Step 1: Update workspace .mcp.json — disable all servers**

Write `D:\Dev\Projects\GameModding\.mcp.json`:

```json
{
  "mcpServers": {
    "cheatengine": {
      "command": "C:/Python313/python.exe",
      "args": ["D:/AI/MCP Servers/cheatengine-mcp-bridge/MCP_Server/mcp_cheatengine.py"],
      "disabled": true
    },
    "ghidra": {
      "command": "C:/Users/Zero/re-mcp-toolkit/venv/Scripts/python.exe",
      "args": [
        "C:/Users/Zero/re-mcp-toolkit/GhidraMCP/bridge_mcp_ghidra.py",
        "--ghidra-server", "http://127.0.0.1:8080/"
      ],
      "disabled": true
    },
    "frida-game-hacking": {
      "command": "C:/Users/Zero/re-mcp-toolkit/venv/Scripts/python.exe",
      "args": ["-m", "frida_game_hacking_mcp"],
      "cwd": "C:/Users/Zero/re-mcp-toolkit",
      "disabled": true
    },
    "x64dbg": {
      "command": "C:/Users/Zero/re-mcp-toolkit/venv/Scripts/python.exe",
      "args": ["C:/Users/Zero/re-mcp-toolkit/x64dbgMCP/src/x64dbg.py"],
      "disabled": true
    },
    "re-orchestrator": {
      "command": "C:/Users/Zero/re-mcp-toolkit/venv/Scripts/python.exe",
      "args": ["C:/Users/Zero/re-mcp-toolkit/orchestrator/run_server.py"],
      "disabled": true
    }
  }
}
```

All servers disabled at workspace root. Per-game `.mcp.json` files will selectively enable what each engine needs. When opened at the root for cross-game work, user enables servers via `/mcp` as needed.

- [ ] **Step 2: Commit**

```bash
cd "D:/Dev/Projects/GameModding"
git add .mcp.json
git commit -m "Disable all MCP servers at workspace level (per-game configs will enable selectively)"
```

### Task 2: Create shared hook scripts

**Files:**
- Create: `D:\Dev\Projects\GameModding\.claude\hooks\block-game-dlls.sh`

- [ ] **Step 1: Write block-game-dlls.sh**

This hook is used by all game folders via a relative path from their settings.json. It blocks editing `.dll` files, game install directories, and reference mod repos.

```bash
#!/bin/bash
# PreToolUse hook: block edits to reference DLLs, game installs, and external repos
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Block .dll edits
if [[ "$FILE_PATH" == *.dll ]]; then
  echo '{"decision": "deny", "reason": "Cannot edit compiled DLL files"}' >&2
  exit 2
fi

# Block game install directories
if [[ "$FILE_PATH" == *"SteamLibrary"* ]] || [[ "$FILE_PATH" == *"steamapps"* ]]; then
  echo '{"decision": "deny", "reason": "Cannot edit game install files"}' >&2
  exit 2
fi

# Block reference repos (read-only copies of other mods)
if [[ "$FILE_PATH" == *"peterhaneve"* ]] || [[ "$FILE_PATH" == *"reference"* ]]; then
  echo '{"decision": "deny", "reason": "Read-only reference files"}' >&2
  exit 2
fi
```

- [ ] **Step 2: Commit**

```bash
cd "D:/Dev/Projects/GameModding"
git add .claude/hooks/block-game-dlls.sh
git commit -m "Add shared block-game-dlls hook for all game folders"
```

---

## Chunk 2: Per-Game Configuration — ONIMods

### Task 3: Create ONIMods .mcp.json

**Files:**
- Create: `D:\Dev\Projects\GameModding\ONIMods\.mcp.json`

- [ ] **Step 1: Write ONIMods .mcp.json (Unity Mono — re-orchestrator only)**

```json
{
  "mcpServers": {
    "re-orchestrator": {
      "command": "C:/Users/Zero/re-mcp-toolkit/venv/Scripts/python.exe",
      "args": ["C:/Users/Zero/re-mcp-toolkit/orchestrator/run_server.py"]
    }
  }
}
```

- [ ] **Step 2: Commit to ONIMods repo**

```bash
cd "D:/Dev/Projects/GameModding/ONIMods"
git add .mcp.json
git commit -m "Add per-game MCP config (re-orchestrator only for Unity Mono)"
```

### Task 4: Fix ONIMods hooks and settings

**Files:**
- Modify: `D:\Dev\Projects\GameModding\ONIMods\.claude\settings.json`
- Modify: `D:\Dev\Projects\GameModding\ONIMods\.claude\hooks\auto-build.sh`
- Replace: `D:\Dev\Projects\GameModding\ONIMods\.claude\settings.local.json`

- [ ] **Step 1: Fix settings.json — update hook paths**

Write `D:\Dev\Projects\GameModding\ONIMods\.claude\settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash D:/Dev/Projects/GameModding/ONIMods/.claude/hooks/auto-build.sh",
            "timeout": 60
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash D:/Dev/Projects/GameModding/.claude/hooks/block-game-dlls.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

Note: PostToolUse uses game-local auto-build hook. PreToolUse uses shared block-game-dlls from workspace root.

- [ ] **Step 2: Fix auto-build.sh — update cd path**

Write `D:\Dev\Projects\GameModding\ONIMods\.claude\hooks\auto-build.sh`:

```bash
#!/bin/bash
# PostToolUse hook: auto-build the affected mod after .cs file edits
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.cs ]]; then
  exit 0
fi

REPO_ROOT="D:/Dev/Projects/GameModding/ONIMods"

for mod in ReplaceStuff BuildThrough DuplicantStatusBar OniProfiler GCBudget; do
  if [[ "$FILE_PATH" == *"$mod"* ]]; then
    BUILD_OUTPUT=$(cd "$REPO_ROOT" && dotnet build "$mod/$mod.csproj" 2>&1 | tail -5)
    if echo "$BUILD_OUTPUT" | grep -q "Build succeeded"; then
      echo "$BUILD_OUTPUT"
    else
      echo "$BUILD_OUTPUT" >&2
      exit 2
    fi
    exit 0
  fi
done
```

- [ ] **Step 3: Replace settings.local.json — clean wildcard permissions**

Write `D:\Dev\Projects\GameModding\ONIMods\.claude\settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(dotnet *)",
      "Bash(ilspycmd *)",
      "Bash(git *)",
      "Bash(cp *)",
      "Bash(mkdir *)",
      "Bash(ls *)",
      "Bash(rm *)",
      "Bash(powershell *)",
      "Bash(find *)",
      "mcp__re-orchestrator__*",
      "WebSearch",
      "WebFetch(domain:raw.githubusercontent.com)",
      "WebFetch(domain:github.com)",
      "WebFetch(domain:forums.kleientertainment.com)"
    ]
  }
}
```

- [ ] **Step 4: Update ONIMods CLAUDE.md — ensure parent routing**

Verify `D:\Dev\Projects\GameModding\ONIMods\CLAUDE.md` starts with the parent reference line. It was added in the previous plan — just verify it's present.

- [ ] **Step 5: Commit to ONIMods repo**

```bash
cd "D:/Dev/Projects/GameModding/ONIMods"
git add .claude/settings.json .claude/hooks/auto-build.sh .claude/settings.local.json
git commit -m "Fix broken hook paths, clean permissions (185 junk entries → 14 wildcards)"
```

---

## Chunk 3: Per-Game Configuration — PhasmoMods

### Task 5: Configure PhasmoMods

**Files:**
- Create: `D:\Dev\Projects\GameModding\PhasmoMods\.mcp.json`
- Create: `D:\Dev\Projects\GameModding\PhasmoMods\.claude\settings.json`
- Create: `D:\Dev\Projects\GameModding\PhasmoMods\.claude\hooks\auto-build.sh`
- Replace: `D:\Dev\Projects\GameModding\PhasmoMods\.claude\settings.local.json`

- [ ] **Step 1: Write .mcp.json (Unity IL2CPP — re-orchestrator + ghidra)**

```json
{
  "mcpServers": {
    "re-orchestrator": {
      "command": "C:/Users/Zero/re-mcp-toolkit/venv/Scripts/python.exe",
      "args": ["C:/Users/Zero/re-mcp-toolkit/orchestrator/run_server.py"]
    },
    "ghidra": {
      "command": "C:/Users/Zero/re-mcp-toolkit/venv/Scripts/python.exe",
      "args": [
        "C:/Users/Zero/re-mcp-toolkit/GhidraMCP/bridge_mcp_ghidra.py",
        "--ghidra-server", "http://127.0.0.1:8080/"
      ]
    }
  }
}
```

- [ ] **Step 2: Write settings.json with hooks**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash D:/Dev/Projects/GameModding/PhasmoMods/.claude/hooks/auto-build.sh",
            "timeout": 60
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash D:/Dev/Projects/GameModding/.claude/hooks/block-game-dlls.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 3: Write auto-build.sh**

```bash
#!/bin/bash
# PostToolUse hook: auto-build PhasmoMods after .cs file edits
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.cs ]]; then
  exit 0
fi

REPO_ROOT="D:/Dev/Projects/GameModding/PhasmoMods"
BUILD_OUTPUT=$(cd "$REPO_ROOT" && dotnet build src/PhasmoMods/PhasmoMods.csproj -c Release 2>&1 | tail -5)
if echo "$BUILD_OUTPUT" | grep -q "Build succeeded"; then
  echo "$BUILD_OUTPUT"
else
  echo "$BUILD_OUTPUT" >&2
  exit 2
fi
```

- [ ] **Step 4: Write clean settings.local.json**

```json
{
  "permissions": {
    "allow": [
      "Bash(dotnet *)",
      "Bash(ilspycmd *)",
      "Bash(git *)",
      "Bash(cp *)",
      "Bash(mkdir *)",
      "Bash(ls *)",
      "Bash(rm *)",
      "mcp__re-orchestrator__*",
      "mcp__ghidra__*",
      "WebSearch",
      "WebFetch(domain:github.com)"
    ]
  }
}
```

- [ ] **Step 5: Commit to PhasmoMods repo**

```bash
cd "D:/Dev/Projects/GameModding/PhasmoMods"
mkdir -p .claude/hooks
git add .mcp.json .claude/settings.json .claude/hooks/auto-build.sh .claude/settings.local.json
git commit -m "Add per-game MCP config, build hooks, and clean permissions"
```

---

## Chunk 4: Per-Game Configuration — MCMods, RimWorldMods, StardewMods, SubnauticaMods, ZomboidMods

These 5 games follow the same pattern. Each gets a `.mcp.json`, `settings.json`, `auto-build.sh`, and clean `settings.local.json`. Independent of each other — can be parallelized.

### Task 6: Configure MCMods/Quantum Flux (Java/NeoForge)

**Files:**
- Create: `D:\Dev\Projects\GameModding\MCMods\Quantum Flux\.mcp.json`
- Create: `D:\Dev\Projects\GameModding\MCMods\Quantum Flux\.claude\settings.json`
- Create: `D:\Dev\Projects\GameModding\MCMods\Quantum Flux\.claude\hooks\auto-build.sh`
- Replace: `D:\Dev\Projects\GameModding\MCMods\.claude\settings.local.json`

- [ ] **Step 1: Write .mcp.json (Java — re-orchestrator only)**

```json
{
  "mcpServers": {
    "re-orchestrator": {
      "command": "C:/Users/Zero/re-mcp-toolkit/venv/Scripts/python.exe",
      "args": ["C:/Users/Zero/re-mcp-toolkit/orchestrator/run_server.py"]
    }
  }
}
```

- [ ] **Step 2: Write settings.json with Gradle build hook**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash D:/Dev/Projects/GameModding/MCMods/Quantum\\ Flux/.claude/hooks/auto-build.sh",
            "timeout": 120
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash D:/Dev/Projects/GameModding/.claude/hooks/block-game-dlls.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 3: Write auto-build.sh (Gradle)**

```bash
#!/bin/bash
# PostToolUse hook: auto-build Quantum Flux after .java file edits
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.java ]]; then
  exit 0
fi

REPO_ROOT="D:/Dev/Projects/GameModding/MCMods/Quantum Flux"
BUILD_OUTPUT=$(cd "$REPO_ROOT" && ./gradlew build 2>&1 | tail -5)
if echo "$BUILD_OUTPUT" | grep -q "BUILD SUCCESSFUL"; then
  echo "$BUILD_OUTPUT"
else
  echo "$BUILD_OUTPUT" >&2
  exit 2
fi
```

- [ ] **Step 4: Write clean settings.local.json at MCMods level**

```json
{
  "permissions": {
    "allow": [
      "Bash(./gradlew *)",
      "Bash(java *)",
      "Bash(git *)",
      "Bash(cp *)",
      "Bash(mkdir *)",
      "Bash(ls *)",
      "Bash(rm *)",
      "mcp__re-orchestrator__*",
      "WebSearch",
      "WebFetch(domain:github.com)"
    ]
  }
}
```

- [ ] **Step 5: Create MCMods CLAUDE.md (missing)**

Write `D:\Dev\Projects\GameModding\MCMods\CLAUDE.md`:

```markdown
# Parent workspace: See `../CLAUDE.md` for shared RE toolkit, engine docs, and modding conventions.

# MC Mods — Minecraft Modding

Java mods for Minecraft using NeoForge/Fabric. See `../docs/engines/java-minecraft.md` for engine reference.

## Game Folders

| Folder | Mod | Framework |
|-|-|-|
| Quantum Flux/ | Quantum Flux (energy/tech mod) | NeoForge 1.21.1 |

## Build & Deploy

- Build: `cd "Quantum Flux" && ./gradlew build`
- Deploy: Auto-copies to ATM10SKY instance via Gradle task
- Game: Minecraft via CurseForge launcher

## Conventions

- Follow NeoForge mod structure and naming conventions
- Use `@Mod` annotation for mod entry point
- Data generation via `./gradlew runData`
```

- [ ] **Step 6: Commit to MCMods/Quantum Flux repo**

```bash
cd "D:/Dev/Projects/GameModding/MCMods/Quantum Flux"
mkdir -p .claude/hooks
git add .mcp.json .claude/settings.json .claude/hooks/auto-build.sh
git commit -m "Add per-game MCP config, Gradle build hooks, and clean permissions"
```

Also commit CLAUDE.md and settings.local.json at MCMods level (these are untracked since MCMods has no top-level git):

```bash
# MCMods/.claude/settings.local.json is local config, not committed
# MCMods/CLAUDE.md — commit to Quantum Flux repo or leave untracked
```

### Task 7: Configure RimWorldMods (Unity Mono)

**Files:**
- Create: `D:\Dev\Projects\GameModding\RimWorldMods\.mcp.json`
- Create: `D:\Dev\Projects\GameModding\RimWorldMods\.claude\settings.json`
- Create: `D:\Dev\Projects\GameModding\RimWorldMods\.claude\hooks\auto-build.sh`
- Create: `D:\Dev\Projects\GameModding\RimWorldMods\.claude\settings.local.json`

- [ ] **Step 1: Write .mcp.json (Unity Mono — re-orchestrator only)**

```json
{
  "mcpServers": {
    "re-orchestrator": {
      "command": "C:/Users/Zero/re-mcp-toolkit/venv/Scripts/python.exe",
      "args": ["C:/Users/Zero/re-mcp-toolkit/orchestrator/run_server.py"]
    }
  }
}
```

- [ ] **Step 2: Write settings.json**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash D:/Dev/Projects/GameModding/RimWorldMods/.claude/hooks/auto-build.sh",
            "timeout": 60
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash D:/Dev/Projects/GameModding/.claude/hooks/block-game-dlls.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 3: Write auto-build.sh**

```bash
#!/bin/bash
# PostToolUse hook: auto-build RimWorld mods after .cs file edits
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.cs ]]; then
  exit 0
fi

REPO_ROOT="D:/Dev/Projects/GameModding/RimWorldMods"
BUILD_OUTPUT=$(cd "$REPO_ROOT" && dotnet build Source/RimThreaded.sln 2>&1 | tail -5)
if echo "$BUILD_OUTPUT" | grep -q "Build succeeded"; then
  echo "$BUILD_OUTPUT"
else
  echo "$BUILD_OUTPUT" >&2
  exit 2
fi
```

- [ ] **Step 4: Write clean settings.local.json**

```json
{
  "permissions": {
    "allow": [
      "Bash(dotnet *)",
      "Bash(ilspycmd *)",
      "Bash(git *)",
      "Bash(cp *)",
      "Bash(mkdir *)",
      "Bash(ls *)",
      "Bash(rm *)",
      "mcp__re-orchestrator__*",
      "WebSearch",
      "WebFetch(domain:github.com)"
    ]
  }
}
```

- [ ] **Step 5: Update RimWorldMods CLAUDE.md with parent reference**

Add as first line: `# Parent workspace: See ../CLAUDE.md for shared RE toolkit, engine docs, and modding conventions.`

- [ ] **Step 6: Commit**

```bash
cd "D:/Dev/Projects/GameModding/RimWorldMods"
mkdir -p .claude/hooks
git add .mcp.json .claude/settings.json .claude/hooks/auto-build.sh CLAUDE.md
git commit -m "Add per-game MCP config, build hooks, clean permissions, parent reference"
```

### Task 8: Configure StardewMods (.NET/SMAPI)

**Files:**
- Create: `D:\Dev\Projects\GameModding\StardewMods\.mcp.json`
- Create: `D:\Dev\Projects\GameModding\StardewMods\.claude\settings.json`
- Create: `D:\Dev\Projects\GameModding\StardewMods\.claude\hooks\auto-build.sh`
- Create: `D:\Dev\Projects\GameModding\StardewMods\.claude\settings.local.json`

- [ ] **Step 1: Write .mcp.json (SMAPI/.NET — re-orchestrator only)**

```json
{
  "mcpServers": {
    "re-orchestrator": {
      "command": "C:/Users/Zero/re-mcp-toolkit/venv/Scripts/python.exe",
      "args": ["C:/Users/Zero/re-mcp-toolkit/orchestrator/run_server.py"]
    }
  }
}
```

- [ ] **Step 2: Write settings.json**

Same hook pattern as other .NET games. Build hook points to StardewMods auto-build.sh.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash D:/Dev/Projects/GameModding/StardewMods/.claude/hooks/auto-build.sh",
            "timeout": 60
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash D:/Dev/Projects/GameModding/.claude/hooks/block-game-dlls.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 3: Write auto-build.sh (SMAPI mods)**

```bash
#!/bin/bash
# PostToolUse hook: auto-build Stardew Valley mods after .cs file edits
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.cs ]]; then
  exit 0
fi

REPO_ROOT="D:/Dev/Projects/GameModding/StardewMods"

# Find the .csproj closest to the edited file
MOD_DIR=$(dirname "$FILE_PATH")
while [[ "$MOD_DIR" != "$REPO_ROOT" ]] && [[ "$MOD_DIR" != "/" ]]; do
  CSPROJ=$(ls "$MOD_DIR"/*.csproj 2>/dev/null | head -1)
  if [[ -n "$CSPROJ" ]]; then
    BUILD_OUTPUT=$(dotnet build "$CSPROJ" 2>&1 | tail -5)
    if echo "$BUILD_OUTPUT" | grep -q "Build succeeded"; then
      echo "$BUILD_OUTPUT"
    else
      echo "$BUILD_OUTPUT" >&2
      exit 2
    fi
    exit 0
  fi
  MOD_DIR=$(dirname "$MOD_DIR")
done
```

- [ ] **Step 4: Write clean settings.local.json**

```json
{
  "permissions": {
    "allow": [
      "Bash(dotnet *)",
      "Bash(ilspycmd *)",
      "Bash(git *)",
      "Bash(cp *)",
      "Bash(mkdir *)",
      "Bash(ls *)",
      "Bash(rm *)",
      "mcp__re-orchestrator__*",
      "WebSearch",
      "WebFetch(domain:github.com)"
    ]
  }
}
```

- [ ] **Step 5: Update StardewMods CLAUDE.md with parent reference**

Add as first line: `# Parent workspace: See ../CLAUDE.md for shared RE toolkit, engine docs, and modding conventions.`

- [ ] **Step 6: Commit**

```bash
cd "D:/Dev/Projects/GameModding/StardewMods"
mkdir -p .claude/hooks
git add .mcp.json .claude/settings.json .claude/hooks/auto-build.sh CLAUDE.md
git commit -m "Add per-game MCP config, SMAPI build hooks, clean permissions"
```

### Task 9: Configure SubnauticaMods (Unity Mono/BepInEx 5)

**Files:**
- Create: `D:\Dev\Projects\GameModding\SubnauticaMods\.mcp.json`
- Create: `D:\Dev\Projects\GameModding\SubnauticaMods\.claude\settings.json`
- Create: `D:\Dev\Projects\GameModding\SubnauticaMods\.claude\hooks\auto-build.sh`
- Replace: `D:\Dev\Projects\GameModding\SubnauticaMods\.claude\settings.local.json`

- [ ] **Step 1: Write .mcp.json (Unity Mono — re-orchestrator only)**

```json
{
  "mcpServers": {
    "re-orchestrator": {
      "command": "C:/Users/Zero/re-mcp-toolkit/venv/Scripts/python.exe",
      "args": ["C:/Users/Zero/re-mcp-toolkit/orchestrator/run_server.py"]
    }
  }
}
```

- [ ] **Step 2: Write settings.json**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash D:/Dev/Projects/GameModding/SubnauticaMods/.claude/hooks/auto-build.sh",
            "timeout": 60
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash D:/Dev/Projects/GameModding/.claude/hooks/block-game-dlls.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 3: Write auto-build.sh (BepInEx monorepo with CopyToPlugins)**

```bash
#!/bin/bash
# PostToolUse hook: auto-build Subnautica mods after .cs file edits
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.cs ]]; then
  exit 0
fi

REPO_ROOT="D:/Dev/Projects/GameModding/SubnauticaMods"

# Find the .csproj closest to the edited file
MOD_DIR=$(dirname "$FILE_PATH")
while [[ "$MOD_DIR" != "$REPO_ROOT" ]] && [[ "$MOD_DIR" != "/" ]]; do
  CSPROJ=$(ls "$MOD_DIR"/*.csproj 2>/dev/null | head -1)
  if [[ -n "$CSPROJ" ]]; then
    BUILD_OUTPUT=$(dotnet build "$CSPROJ" -c Release 2>&1 | tail -5)
    if echo "$BUILD_OUTPUT" | grep -q "Build succeeded"; then
      echo "$BUILD_OUTPUT"
    else
      echo "$BUILD_OUTPUT" >&2
      exit 2
    fi
    exit 0
  fi
  MOD_DIR=$(dirname "$MOD_DIR")
done
```

- [ ] **Step 4: Write clean settings.local.json**

```json
{
  "permissions": {
    "allow": [
      "Bash(dotnet *)",
      "Bash(ilspycmd *)",
      "Bash(git *)",
      "Bash(cp *)",
      "Bash(mkdir *)",
      "Bash(ls *)",
      "Bash(rm *)",
      "mcp__re-orchestrator__*",
      "WebSearch",
      "WebFetch(domain:github.com)"
    ]
  }
}
```

- [ ] **Step 5: Update SubnauticaMods CLAUDE.md with parent reference**

Read existing CLAUDE.md. Add as first line if not present: `# Parent workspace: See ../CLAUDE.md for shared RE toolkit, engine docs, and modding conventions.`

- [ ] **Step 6: Commit**

```bash
cd "D:/Dev/Projects/GameModding/SubnauticaMods"
mkdir -p .claude/hooks
git add .mcp.json .claude/settings.json .claude/hooks/auto-build.sh .claude/settings.local.json CLAUDE.md
git commit -m "Add per-game MCP config, build hooks, clean permissions"
```

### Task 10: Configure ZomboidMods (Java/Lua)

**Files:**
- Create: `D:\Dev\Projects\GameModding\ZomboidMods\.mcp.json`
- Create: `D:\Dev\Projects\GameModding\ZomboidMods\.claude\settings.json`
- Replace: `D:\Dev\Projects\GameModding\ZomboidMods\.claude\settings.local.json`

- [ ] **Step 1: Write .mcp.json (Lua — re-orchestrator only)**

```json
{
  "mcpServers": {
    "re-orchestrator": {
      "command": "C:/Users/Zero/re-mcp-toolkit/venv/Scripts/python.exe",
      "args": ["C:/Users/Zero/re-mcp-toolkit/orchestrator/run_server.py"]
    }
  }
}
```

- [ ] **Step 2: Write settings.json (no auto-build for Lua mods — just block-dlls)**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash D:/Dev/Projects/GameModding/.claude/hooks/block-game-dlls.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

No auto-build hook — Zomboid Lua mods don't need compilation. The game reads Lua files directly.

- [ ] **Step 3: Write clean settings.local.json**

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(cp *)",
      "Bash(mkdir *)",
      "Bash(ls *)",
      "Bash(rm *)",
      "mcp__re-orchestrator__*",
      "WebSearch",
      "WebFetch(domain:github.com)"
    ]
  }
}
```

- [ ] **Step 4: Update ZomboidMods CLAUDE.md with parent reference**

Read existing CLAUDE.md. Add as first line if not present: `# Parent workspace: See ../CLAUDE.md for shared RE toolkit, engine docs, and modding conventions.`

- [ ] **Step 5: Commit**

```bash
cd "D:/Dev/Projects/GameModding/ZomboidMods"
mkdir -p .claude/hooks
git add .mcp.json .claude/settings.json .claude/settings.local.json CLAUDE.md
git commit -m "Add per-game MCP config, block-dlls hook, clean permissions"
```

---

## Chunk 5: Plugin Registration for All Game Folders

### Task 11: Register plugin for all game folder paths

**Files:**
- Modify: `C:\Users\Zero\.claude\plugins\installed_plugins.json`

- [ ] **Step 1: Add entries for all 7 game folder paths**

Read current `installed_plugins.json`. Update the `re-game-hacking@local` array to include entries for each game folder. All entries share the same `installPath` pointing to the shared plugin source.

The array should contain entries for:
- `D:\\Dev\\Projects\\GameModding` (root — already exists)
- `D:\\Dev\\Projects\\GameModding\\ONIMods`
- `D:\\Dev\\Projects\\GameModding\\PhasmoMods`
- `D:\\Dev\\Projects\\GameModding\\MCMods`
- `D:\\Dev\\Projects\\GameModding\\RimWorldMods`
- `D:\\Dev\\Projects\\GameModding\\StardewMods`
- `D:\\Dev\\Projects\\GameModding\\SubnauticaMods`
- `D:\\Dev\\Projects\\GameModding\\ZomboidMods`

Each entry:
```json
{
  "scope": "project",
  "projectPath": "<path>",
  "installPath": "D:\\Dev\\Projects\\GameModding\\.claude\\plugins\\local\\re-game-hacking",
  "version": "2.0.0",
  "installedAt": "2026-03-15T00:00:00.000Z",
  "lastUpdated": "2026-03-15T00:00:00.000Z"
}
```

---

## Chunk 6: Agent Updates

### Task 12: Replace memory-hunter with mod-reviewer

**Files:**
- Delete: `D:\Dev\Projects\GameModding\.claude\plugins\local\re-game-hacking\agents\memory-hunter.md`
- Create: `D:\Dev\Projects\GameModding\.claude\plugins\local\re-game-hacking\agents\mod-reviewer.md`
- Modify: `D:\Dev\Projects\GameModding\.claude\plugins\local\re-game-hacking\agents\re-analyst.md`
- Modify: `D:\Dev\Projects\GameModding\.claude\plugins\local\re-game-hacking\.claude-plugin\plugin.json`

- [ ] **Step 1: Read memory-hunter.md to capture its capabilities**

Read the file to know what memory scanning knowledge needs to fold into re-analyst.

- [ ] **Step 2: Write mod-reviewer.md**

```markdown
---
name: mod-reviewer
description: "Quality assurance and publishing specialist. Reviews mod code for compatibility, performance, and best practices. Generates workshop descriptions, changelogs, and publishing materials. Ensures mods meet community quality standards for income-generating releases."
model: inherit
color: green
---

# Mod Reviewer Agent

You are a mod quality assurance and publishing specialist. Your job is to ensure mods are production-ready: well-tested, compatible, performant, and professionally presented for workshop/marketplace publishing.

You have access to MCP tool servers and filesystem tools. Use `ToolSearch` to load any MCP tool before calling it.

## Core Workflows

### 1. Code Quality Review
- Check for common mod pitfalls:
  - Thread safety issues (Unity is single-threaded for most operations)
  - Performance-critical paths (per-frame vs on-event)
  - Save/load safety (serialization attributes, data persistence)
  - Memory leaks (event handler deregistration, static references)
  - Null reference patterns (missing null checks on Unity objects)
- Framework-specific checks:
  - Harmony: patch priority conflicts, transpiler correctness, proper `__instance`/`__result` usage
  - BepInEx: plugin lifecycle issues, config validation
  - UserMod2: `base.OnLoad()` call, PLib initialization order
  - SMAPI: content patcher conflicts, API version compat

### 2. Compatibility Review
- Check mod framework version compatibility
- Identify potential conflicts with popular mods
- Verify game version targeting (build number, DLC flags)
- Check for deprecated API usage
- Review assembly references for version mismatches

### 3. Publishing Preparation
- Generate workshop descriptions (engaging, well-formatted, feature lists)
- Create changelogs from git history
- Suggest tags and categories for discoverability
- Review preview images checklist
- Verify mod manifest completeness (version, description, author, supported versions)
- License recommendations for donation-supported mods

### 4. Version Bump & Release
- Semantic versioning guidance
- Changelog generation from commits since last tag
- Build verification (Release config, no debug symbols)
- Package verification (correct files included, no junk)

## Quality Checklist Template

When reviewing a mod, cover:
- [ ] Code compiles in Release mode without warnings
- [ ] No hardcoded paths or machine-specific values
- [ ] Error handling for game version differences
- [ ] Logging uses appropriate levels (Debug for dev, Warning for issues)
- [ ] Config options have sensible defaults
- [ ] Mod manifest/info file is complete and accurate
- [ ] Workshop description is engaging and informative
- [ ] Preview image is present and appropriate size
- [ ] License file exists

## Working as a Teammate

### What to Report
- Quality score (issues found / severity)
- Compatibility concerns
- Publishing readiness assessment
- Workshop description draft
- Recommended improvements ranked by impact
```

- [ ] **Step 3: Update re-analyst.md — add memory scanning section**

Read the current re-analyst.md. Add a new section absorbing memory-hunter's capabilities:

```markdown
### 7. Memory Scanning & Runtime Analysis

When Cheat Engine or Frida MCP servers are available (enabled on-demand), you can perform memory analysis:

**Cheat Engine workflow (via cheatengine MCP):**
1. `cheatengine:scan_all` — initial value scan
2. `cheatengine:next_scan` — narrow results
3. `cheatengine:read_memory` / `cheatengine:write_memory` — verify
4. `cheatengine:aob_scan` — pattern-based scanning
5. `cheatengine:set_data_breakpoint` — find what accesses/writes an address
6. `cheatengine:read_pointer_chain` — resolve pointer paths
7. `cheatengine:generate_signature` — create AOB signatures

**Frida workflow (via frida-game-hacking MCP):**
1. `frida:attach` — connect to running process
2. `frida:scan_value` — initial memory scan
3. `frida:scan_next` / `frida:scan_changed` — narrow results
4. `frida:hook_native_function` — intercept function calls
5. `frida:read_memory` / `frida:write_memory` — inspect/modify
6. `frida:intercept_module_function` — hook by module+export name

**When to use which:**
- Cheat Engine: Windows games, complex pointer chains, AOB signatures, DBVM hardware breakpoints
- Frida: Cross-platform, scripted hooks, function interception, RPC automation

**Note:** These servers must be enabled first via /mcp or by adding them to the game's .mcp.json. They are not loaded by default to minimize context overhead.
```

- [ ] **Step 4: Update plugin.json — swap memory-hunter for mod-reviewer**

Replace `"./agents/memory-hunter.md"` with `"./agents/mod-reviewer.md"` in the agents array.

- [ ] **Step 5: Delete memory-hunter.md**

```bash
rm "D:/Dev/Projects/GameModding/.claude/plugins/local/re-game-hacking/agents/memory-hunter.md"
```

- [ ] **Step 6: Commit**

```bash
cd "D:/Dev/Projects/GameModding"
git add .claude/plugins/local/re-game-hacking/agents/ .claude/plugins/local/re-game-hacking/.claude-plugin/plugin.json
git commit -m "Replace memory-hunter with mod-reviewer agent, fold memory scanning into re-analyst"
```

---

## Chunk 7: New Skills

### Task 13: Create /new-mod skill

**Files:**
- Create: `D:\Dev\Projects\GameModding\.claude\plugins\local\re-game-hacking\skills\new-mod\SKILL.md`

- [ ] **Step 1: Write new-mod SKILL.md**

```markdown
---
name: new-mod
description: "Scaffold a new mod within a game folder — creates project file, manifest, entry point, and build config for the detected engine/framework"
---

# /new-mod — Scaffold New Mod

When the user runs `/new-mod`, create a new mod project within the current game folder.

## Required Input
- **Mod name**: Name for the new mod
- **Description**: One-line description of what it does

## Workflow

### Phase 1: Detect Context
1. Identify current game folder from working directory.
2. Read the game's CLAUDE.md to determine engine and framework.
3. If unable to detect, ask the user which framework to use.

### Phase 2: Scaffold (engine-dependent)

**Unity Mono (UserMod2 — ONI):**
- Create `<ModName>/` folder
- Create `<ModName>/<ModName>.csproj` with game DLL references
- Create `<ModName>/<ModName>Mod.cs` with UserMod2 entry point
- Create `<ModName>/mod_info.yaml`
- Create `<ModName>/mod.yaml` (title, description, author)

**Unity Mono (BepInEx — Subnautica, RimWorld):**
- Create `<ModName>/` folder
- Create `<ModName>/<ModName>.csproj` with BepInEx + game DLL references
- Create `<ModName>/Plugin.cs` with `[BepInPlugin]` entry point
- Add CopyToPlugins build target if pattern exists in sibling mods

**Java (NeoForge/Fabric):**
- Guide user through `./gradlew init` or scaffold manually
- Create main mod class with `@Mod` annotation

**.NET (SMAPI):**
- Create `<ModName>/` folder
- Create `<ModName>/<ModName>.csproj` with SMAPI references
- Create `<ModName>/ModEntry.cs` with IModHelper entry point
- Create `<ModName>/manifest.json` (SMAPI mod manifest)

**Lua (Zomboid):**
- Create `<ModName>/` folder
- Create `<ModName>/mod.info` (mod metadata)
- Create `<ModName>/media/lua/client/` or `server/` starter script

### Phase 3: Verify & Report
4. Verify the project builds (if compilable).
5. Report what was created and next steps.
```

- [ ] **Step 2: Commit**

```bash
cd "D:/Dev/Projects/GameModding"
git add .claude/plugins/local/re-game-hacking/skills/new-mod/
git commit -m "Add /new-mod skill for scaffolding mods within game folders"
```

### Task 14: Create /release skill

**Files:**
- Create: `D:\Dev\Projects\GameModding\.claude\plugins\local\re-game-hacking\skills\release\SKILL.md`

- [ ] **Step 1: Write release SKILL.md**

```markdown
---
name: release
description: "Build a release, bump version, generate changelog, and package a mod for distribution"
---

# /release — Release a Mod

When the user runs `/release`, prepare a mod for public release.

## Required Input
- **Version bump type**: major, minor, or patch (or explicit version number)

## Workflow

### Phase 1: Pre-Release Checks
1. Verify working directory is clean (`git status`).
2. Run a Release build and verify it succeeds.
3. Check for common issues:
   - Debug logging left enabled
   - Hardcoded test values
   - TODO/FIXME comments in shipping code

### Phase 2: Version Bump
4. Detect version location based on framework:
   - `.csproj` → `<Version>` and `<AssemblyVersion>` properties
   - `mod_info.yaml` → `version:` field
   - `manifest.json` → `"Version"` field (SMAPI)
   - `build.gradle` → `version =` property
   - `mod.info` → version field (Zomboid)
5. Bump version according to semver rules.
6. Update all version locations consistently.

### Phase 3: Changelog
7. Generate changelog from git log since last tag.
8. Format as markdown with categories (Added, Changed, Fixed).
9. Prepend to CHANGELOG.md (create if doesn't exist).

### Phase 4: Package
10. Build in Release configuration.
11. Identify output files needed for distribution.
12. Report package contents and total size.

### Phase 5: Commit & Tag
13. Stage all version-bumped files + changelog.
14. Commit: `Release v<version>`
15. Create git tag: `v<version>`
16. Report: ready to publish, provide upload instructions for the relevant platform.
```

- [ ] **Step 2: Commit**

```bash
cd "D:/Dev/Projects/GameModding"
git add .claude/plugins/local/re-game-hacking/skills/release/
git commit -m "Add /release skill for version bumping, changelog, and packaging"
```

### Task 15: Create /workshop-prep skill

**Files:**
- Create: `D:\Dev\Projects\GameModding\.claude\plugins\local\re-game-hacking\skills\workshop-prep\SKILL.md`

- [ ] **Step 1: Write workshop-prep SKILL.md**

```markdown
---
name: workshop-prep
description: "Generate workshop description, preview image checklist, tags, and publishing materials for mod marketplace listings"
---

# /workshop-prep — Prepare Workshop Listing

When the user runs `/workshop-prep`, generate all materials needed to publish a mod on its platform's workshop/marketplace.

## Required Input
- **Mod name**: Which mod to prepare (auto-detect from working directory if single mod)

## Workflow

### Phase 1: Analyze Mod
1. Read the mod's source code, manifest, and any existing documentation.
2. Identify features, configuration options, and dependencies.
3. Determine the target platform (Steam Workshop, Nexus Mods, CurseForge, Thunderstore).

### Phase 2: Generate Workshop Description
4. Write an engaging description following platform best practices:
   - Hook line (what it does in one sentence)
   - Feature list (bulleted, scannable)
   - Installation instructions
   - Configuration guide (if configurable)
   - Compatibility notes (game version, known conflicts)
   - Credits and license
5. Format for the target platform (Steam uses BBCode, Nexus uses markdown).

### Phase 3: Preview Image Checklist
6. Recommend preview image requirements:
   - Dimensions per platform (Steam: 512x512, Nexus: 1280x720, etc.)
   - Content suggestions (in-game screenshot, logo, feature comparison)
   - Reminder: no copyrighted assets in preview images

### Phase 4: Tags & Discoverability
7. Suggest tags/categories based on mod functionality.
8. Recommend title formatting for search optimization.
9. Suggest related mods to reference for cross-promotion.

### Phase 5: Publishing Checklist
10. Present final checklist:
    - [ ] Description written and formatted
    - [ ] Preview image(s) prepared
    - [ ] Version number is correct
    - [ ] Changelog is current
    - [ ] License file included
    - [ ] Dependencies documented
    - [ ] Tested on latest game version
```

- [ ] **Step 2: Commit**

```bash
cd "D:/Dev/Projects/GameModding"
git add .claude/plugins/local/re-game-hacking/skills/workshop-prep/
git commit -m "Add /workshop-prep skill for marketplace listing preparation"
```

### Task 16: Rework /new-project into /new-game

**Files:**
- Modify: `D:\Dev\Projects\GameModding\.claude\plugins\local\re-game-hacking\skills\new-project\SKILL.md`
- Modify: `D:\Dev\Projects\GameModding\.claude\plugins\local\re-game-hacking\.claude-plugin\plugin.json`

- [ ] **Step 1: Rewrite new-project SKILL.md as new-game**

Read the current `new-project/SKILL.md`. Rewrite it to handle the full game folder setup:

```markdown
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
3. Determine the modding framework:
   - Unity Mono → check for existing BepInEx install or UserMod2 convention
   - Unity IL2CPP → BepInEx 6 + Il2CppInterop
   - Java → Fabric, Forge, or NeoForge
   - .NET → SMAPI or custom
   - Unreal → UE4SS
   - Godot → GDScript patches
   - Lua-based → game-specific API

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
9. Create `.claude/hooks/auto-build.sh` (if applicable — skip for Lua/script mods).
10. Create `.claude/settings.local.json` with clean wildcard permissions.

### Phase 4: Generate Documentation
11. Create `CLAUDE.md` with:
    - Parent workspace reference
    - Engine identification
    - Game DLL/binary paths
    - Build and deploy commands
    - Framework conventions
12. Create `docs/tier1-quickref.md` with:
    - Mod index (empty initially)
    - Build commands
    - Deploy paths
    - Common gotchas for this engine

### Phase 5: Register Plugin
13. Read `C:\Users\Zero\.claude\plugins\installed_plugins.json`.
14. Add new entry for the game folder path.
15. Report: folder created, plugin registered, ready to create first mod with `/new-mod`.

### Phase 6: Initial Analysis (optional)
16. If Unity Mono: run `/analyze-assembly` on Assembly-CSharp.dll.
17. If Unity IL2CPP: note that IL2CPP Dumper workflow is needed.
18. Save initial findings via `re-orchestrator:save_finding`.
```

- [ ] **Step 2: Rename skill folder from new-project to new-game**

```bash
cd "D:/Dev/Projects/GameModding/.claude/plugins/local/re-game-hacking/skills"
mv new-project new-game
```

- [ ] **Step 3: Update plugin.json — rename skill reference**

Change `"./skills/new-project"` to `"./skills/new-game"` in the skills array.

- [ ] **Step 4: Commit**

```bash
cd "D:/Dev/Projects/GameModding"
git add .claude/plugins/local/re-game-hacking/skills/new-game/ .claude/plugins/local/re-game-hacking/.claude-plugin/plugin.json
git commit -m "Rework /new-project into /new-game (full game folder scaffolding)"
```

### Task 17: Update plugin.json with all new skills

**Files:**
- Modify: `D:\Dev\Projects\GameModding\.claude\plugins\local\re-game-hacking\.claude-plugin\plugin.json`

- [ ] **Step 1: Write final plugin.json**

```json
{
  "name": "re-game-hacking",
  "version": "3.0.0",
  "description": "Game modding toolkit: reverse engineering, mod generation, quality review, and publishing. Engine-aware agents and skills for building income-grade mods.",
  "author": {
    "name": "Zero"
  },
  "agents": [
    "./agents/re-analyst.md",
    "./agents/mod-builder.md",
    "./agents/mod-reviewer.md",
    "./agents/asset-explorer.md"
  ],
  "skills": [
    "./skills/analyze-assembly",
    "./skills/find-value",
    "./skills/trace-to-code",
    "./skills/generate-mod",
    "./skills/new-game",
    "./skills/compare-assemblies",
    "./skills/dump-type",
    "./skills/find-hooks",
    "./skills/new-mod",
    "./skills/release",
    "./skills/workshop-prep"
  ]
}
```

- [ ] **Step 2: Commit**

```bash
cd "D:/Dev/Projects/GameModding"
git add .claude/plugins/local/re-game-hacking/.claude-plugin/plugin.json
git commit -m "Update plugin.json to v3.0.0 — 4 agents, 11 skills"
```

---

## Chunk 8: Monetization Docs

### Task 18: Create monetization guide

**Files:**
- Create: `D:\Dev\Projects\GameModding\docs\monetization.md`

- [ ] **Step 1: Write monetization.md**

Cover:
- **Platforms**: Nexus Mods (donation points), Patreon (membership tiers), ko-fi (one-time donations), CurseForge (CurseForge Rewards program for MC mods), Thunderstore
- **Ethics**: Never paywall features. Donations only. Early access for patrons is OK for a limited window.
- **Workshop SEO**: Title formatting, tag selection, description structure, preview images
- **Building an audience**: Cross-game reputation, consistent branding, community engagement, mod showcases
- **Mod presentation**: Professional descriptions, feature screenshots, comparison images, installation guides
- **Licensing**: MIT or LGPL for open mods with donation support; avoid restrictive licenses that scare away users
- **Revenue expectations**: Realistic numbers per platform, which games have the most generous mod communities
- **Quality signals**: Frequent updates, responsive to bug reports, clear changelogs, compatibility lists

Target: 100-150 lines.

- [ ] **Step 2: Update CLAUDE.md routing table**

Add a row to the Documentation Routing table:

```markdown
| Publishing/monetization | docs/monetization.md |
```

- [ ] **Step 3: Commit**

```bash
cd "D:/Dev/Projects/GameModding"
git add docs/monetization.md CLAUDE.md
git commit -m "Add monetization guide for income-generating mod publishing"
```

---

## Execution Notes

### Parallelism
- **Chunk 2** (ONIMods) must go first — it's the most complex game with broken paths
- **Chunks 3-4** (PhasmoMods + remaining 5 games): All independent, can be parallelized
- **Chunk 5** (plugin registration): After all game folders exist
- **Chunks 6-7** (agents + skills): Independent of per-game config, can parallel with chunks 3-4
- **Chunk 8** (monetization): Independent, can parallel with anything

### Task dependencies
```
Chunk 1 (workspace MCP + shared hooks)
  ├→ Chunk 2 (ONIMods fix)
  ├→ Chunk 3 (PhasmoMods)
  ├→ Chunk 4 (MC, RimWorld, Stardew, Subnautica, Zomboid) ─→ Chunk 5 (plugin registration)
  ├→ Chunk 6 (agent updates)
  ├→ Chunk 7 (new skills)
  └→ Chunk 8 (monetization)
```

### Verification checkpoints
- After Chunk 2: Open Claude Code at ONIMods — verify hooks fire on .cs edit, verify only re-orchestrator in deferred tools (not 182)
- After Chunk 5: Open Claude Code at any game folder — verify plugin agents/skills appear
- After Chunk 6: Verify mod-reviewer agent appears, memory-hunter gone
- After Chunk 7: Verify /new-game, /new-mod, /release, /workshop-prep appear as skills
