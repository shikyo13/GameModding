# x64dbg Guide

## Overview

x64dbg is an open-source user-mode debugger for Windows. It handles both x86 (x32dbg)
and x64 (x64dbg) binaries, making it the primary tool for debugging native game executables
and DLLs.

## Setup

### Installation

1. Download from https://x64dbg.com/ (portable, no installer)
2. Extract to a permanent location (e.g., `D:\Tools\x64dbg\`)
3. Run `x96dbg.exe` -- it launches the correct bitness automatically
4. Or run `x32dbg.exe` / `x64dbg.exe` directly

### Initial Configuration

Options > Preferences:
- **Events tab**: uncheck "TLS Callbacks", "Entry Breakpoint" if you want fast startup
- **Engine tab**: set "Break on DLL Load" for specific modules you care about
- **Exceptions tab**: add common game exceptions to ignore list to reduce noise

### Loading a Game

- File > Open: select the game executable directly
- File > Attach: attach to a running process (useful for launchers)
- For Steam games: launch the game first, then attach to the actual game process
  (not the Steam launcher)

## Breakpoint Types

### Software Breakpoints (F2)

Standard breakpoints that replace the first byte of an instruction with `INT3` (`0xCC`).

```
# Set on current line
F2

# Set via command bar
bp 0x00401000
bp GameLogic.dll:0x1A2B3
bp kernel32.CreateFileA    # on API function
```

### Hardware Breakpoints

Use CPU debug registers (DR0-DR3). Limited to 4 simultaneous breakpoints.
Harder for anti-cheat to detect.

```
# Via right-click > Breakpoint > Set Hardware on Execution
bphws 0x00401000, "x"     # execute
bphws 0x00401000, "r", 4  # read, 4 bytes
bphws 0x00401000, "w", 4  # write, 4 bytes
```

### Memory Breakpoints

Trigger on any access to a memory page. Uses guard pages.

```
bpm 0x00FF1234, 0, "rw"   # read/write on address
```

### Conditional Breakpoints

Only break when a condition is met:

```
# Break only when eax == 100
bp 0x00401000
bpcnd 0x00401000, "eax==100"

# Break when a string parameter contains "player"
bp 0x00401000
bpcnd 0x00401000, "strstr(utf8(arg.get(0)), \"player\") != 0"

# Break on Nth hit
bp 0x00401000
bpcnd 0x00401000, "$breakpointcounter==5"

# Log without breaking
bp 0x00401000
SetBreakpointLog 0x00401000, "Health: {eax}, Damage: {edx}"
SetBreakpointCondition 0x00401000, "0"  # never actually break
```

## Stepping

| Action | Shortcut | Description |
|-|-|-|
| Step Into | F7 | Execute one instruction, follow calls |
| Step Over | F8 | Execute one instruction, skip calls |
| Step Out | Ctrl+F9 | Run until current function returns |
| Run to Cursor | F4 | Run until selected line |
| Run | F9 | Continue execution |
| Pause | F12 | Break into debugger |

### Animate

- Ctrl+F7: Animate Into (step into repeatedly with visual feedback)
- Ctrl+F8: Animate Over (step over repeatedly)

Useful for watching code flow in real-time.

## Register and Memory Inspection

### Registers Panel

The right panel shows all CPU registers. Right-click to:
- Modify value: type new value directly
- Follow in Dump: view the memory a register points to
- Follow in Disassembler: jump to address in a register

### Memory Dump

- Ctrl+G in dump panel: go to address
- Right-click > Follow DWORD/QWORD: dereference pointer
- Select bytes > right-click > Binary > Edit: modify memory

### Watch Expressions

Debug > Watch View (or the Watch tab):

```
[rsi+0x48]           # dereference
dword:[0x00FF1234]   # read 4 bytes
float:[rbx+0x20]     # read as float
```

## Pattern Scanning

### Find Pattern

Ctrl+B in the disassembly or memory view:

```
# Search for byte pattern (hex)
48 89 5C 24 08 57 48 83 EC 20

# With wildcards
48 89 ?? 24 ?? 57 48 83 EC ??
```

### Via Command Line

```
findallmem 0, "48 89 5C 24 08", 0   # scan all memory
findall GameLogic.dll, "89 86 ?? ?? 00 00"  # scan specific module
```

Results appear in the References tab.

## Tracing

### Run Trace

Debug > Trace Into / Trace Over:
- Records every instruction executed
- Stored in a trace file for post-analysis
- Use "Trace record" (View > Trace) to view recorded instructions

### Conditional Trace

```
# Trace into until condition met
TraceIntoConditional "eax==0"

# Trace over for N instructions
TraceOverConditional "$tracecounter==1000"
```

### Trace Coverage

After tracing, the disassembly highlights executed instructions. Useful for understanding
which code paths a specific action triggers.

## Scripting

### Command Script (.txt)

```
// x64dbg script
bp 0x00401000
SetBreakpointLog 0x00401000, "arg1={rcx}, arg2={rdx}"
SetBreakpointCondition 0x00401000, "0"
run
```

Load via: File > Run Script

### Plugin SDK

x64dbg supports C/C++ plugins for advanced automation. The plugin SDK provides:
- Callbacks for debug events (breakpoint hit, module load, etc.)
- Full access to the debugger's expression evaluator
- GUI integration (menus, tabs)

## Anti-Debug Bypass

Many games use anti-debug techniques. x64dbg includes built-in bypasses:

Plugins > ScyllaHide (bundled):
- PEB.BeingDebugged
- NtQueryInformationProcess
- NtSetInformationThread (HideFromDebugger)
- Timing checks (GetTickCount, QueryPerformanceCounter)

Enable profiles: "Basic", "Steam", or custom configuration.

## Tips

- Use `Ctrl+A` to re-analyze code at cursor (fixes misaligned disassembly)
- Bookmark important addresses with `Ctrl+D` for quick navigation
- The Graph view (press `G` on a function) shows control flow visually
- Use Labels (`:`key) and Comments (`;`key) to annotate your findings
- Import/export `.dd32`/`.dd64` database files to save your analysis
- x64dbg's expression evaluator supports C-like expressions: `rax*4+rbx`
- Use `Handle` tab to find open file/registry handles
- For .NET processes, use dnSpy instead -- x64dbg sees JIT-compiled native code
  which is harder to follow than IL
