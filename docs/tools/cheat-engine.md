# Cheat Engine Guide

## Overview

Cheat Engine (CE) is a memory scanner and debugger specialized for game hacking. It excels
at finding runtime values, building pointer chains, and creating reusable cheat tables.

## Core Workflow: Scan-Narrow-Find

The fundamental CE workflow for finding a game value:

1. **Initial scan**: Know your health is 100? Scan for `100` as 4-byte integer
2. **Change the value**: Take damage in-game so health changes to, say, 85
3. **Next scan**: Search for `85` within previous results
4. **Repeat**: Change value again, scan again, until 1-3 addresses remain
5. **Verify**: Modify the found address and confirm the game reflects the change

### Value Type Selection

| Type | Size | Use Case |
|-|-|-|
| Byte | 1 | Small flags, booleans |
| 2 Bytes | 2 | Item counts, small stats |
| 4 Bytes | 4 | Most integer values (health, gold, ammo) |
| 8 Bytes | 8 | Large counters, some 64-bit games |
| Float | 4 | Position, speed, damage multipliers |
| Double | 8 | High-precision floats, some Unity values |
| String | varies | Player names, item names |
| Array of Bytes | varies | Specific byte sequences |

### Scan Types

- **Exact Value**: when you know the current value
- **Unknown Initial Value**: when you don't know the value, then use Increased/Decreased
- **Increased/Decreased**: after changing an unknown value
- **Value Between**: when you know the range
- **Changed/Unchanged**: for binary state detection

## Data Breakpoints (Find What Accesses/Writes)

Once you find an address:

1. Right-click address > "Find out what writes to this address"
2. CE sets a hardware data breakpoint
3. Go back to the game and trigger a write (take damage, spend gold)
4. CE shows the instruction and register state at the write

This reveals the **code** responsible for the value change, which is essential for:
- Building pointer chains (the base register often holds the object pointer)
- Finding related values at nearby offsets
- Understanding game logic

## Pointer Chain Resolution

Game objects are dynamically allocated, so raw addresses change between sessions.
Pointer chains provide stable paths from static addresses to dynamic values.

### Manual Pointer Chain Building

1. Find the dynamic address of your value (e.g., health at `0x1A2B3C4D`)
2. "Find what accesses this address" -- note the instruction, e.g., `mov [rsi+0x48], eax`
3. `rsi` held `0x1A2B3C05` at that moment, so health offset is `+0x48`
4. Now scan for `0x1A2B3C05` (the object pointer) as 8-byte value
5. Repeat until you reach a static (green) address

### Pointer Scan

1. Right-click address > Pointer Scan for this address
2. Configure: max level 5-7, max offset 0x1000
3. Save the scan, restart the game, find the new address
4. Rescan the pointer scan with the new address
5. After 2-3 restarts, usually 1-10 valid chains remain

## AOB (Array of Bytes) Signature Generation

AOB patterns survive game updates better than static addresses.

### From CE Disassembler

1. Find the instruction that modifies your value
2. Right-click > "Generate AOB pattern"
3. CE creates a wildcarded byte pattern: `89 86 ?? ?? 00 00 8B 46 ??`

### From Memory View

1. Select instruction bytes in the memory view
2. Tools > Generate AOB String
3. Manually wildcard operand bytes that may change between versions

### Using AOB in Scripts

```
[ENABLE]
aobscanmodule(DamageSig, GameLogic.dll, 89 86 ?? ?? 00 00 8B 46)
registersymbol(DamageSig)

DamageSig:
  nop
  nop
  nop
  nop
  nop
  nop

[DISABLE]
DamageSig:
  db 89 86 48 00 00 00

unregistersymbol(DamageSig)
```

## Auto Assemble Scripts

CE's scripting language for code injection:

### Basic Code Injection

```
[ENABLE]
alloc(newmem, 2048, GameLogic.dll)
label(returnhere)
label(originalcode)

newmem:
  // Custom logic: set health to max
  mov [rsi+48], (float)100.0
  jmp originalcode

originalcode:
  mov [rsi+48], eax      // original instruction
  jmp returnhere

GameLogic.dll+1A2B3:
  jmp newmem
  nop
returnhere:

[DISABLE]
GameLogic.dll+1A2B3:
  db 89 46 48 8B 46      // restore original bytes
dealloc(newmem)
```

### Symbols and Labels

```
alloc(cave, 1024)           // allocate memory
label(skip)                  // forward reference
registersymbol(myBase)       // make accessible to other scripts
globalalloc(shared, 256)     // persistent across enable/disable

define(healthOff, 48)        // named constant
define(manaOff, 4C)
```

## Cheat Table Creation

1. Add found addresses to the address list
2. Organize with Group Headers (Ctrl+Alt+G)
3. Add descriptions and value types
4. Attach Auto Assemble scripts to entries
5. Save as `.CT` file: File > Save As

### Table Best Practices

- Use AOB scans, not hardcoded addresses (survives updates)
- Include `{$lua}` version checks if needed
- Use `{$strict}` for scans that must find exactly one match
- Group related cheats under headers
- Add hotkeys via right-click > Set Hotkey

## DBVM (Debug Virtual Machine)

DBVM is CE's hypervisor layer for bypassing kernel-level anti-cheat:

- Runs below the OS as a thin hypervisor
- Makes hardware breakpoints invisible to anti-cheat
- Required for some protected games (EAC, BattlEye)
- Load via: CE menu > DBVM > Load DBVM

**Warning**: DBVM modifies system-level CPU state. Use in isolated environments only.
Not compatible with other hypervisors (Hyper-V, VMware).

## Tips

- Use `Ctrl+B` for manual memory browse at a specific address
- Enable "MEM_MAPPED" in scan settings for memory-mapped files
- Speedhack: CE can modify the game's time scale without code injection
- Lua scripting (via CE's built-in Lua engine) is more flexible than Auto Assemble
- Use Structure Dissect (Ctrl+D on address) to explore an object's memory layout
- CE's Ultimap feature traces all executed code for comprehensive analysis
