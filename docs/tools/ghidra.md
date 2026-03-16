# Ghidra for Game Reverse Engineering

## Overview

Ghidra is an open-source reverse engineering suite from the NSA. It provides disassembly,
decompilation, and scripting capabilities for analyzing game binaries.

## Setup for Game RE

### Initial Configuration

1. Download from https://ghidra-sre.org/ (requires JDK 17+)
2. Create a new project: File > New Project > Non-Shared Project
3. Import game binary: File > Import File, select the `.exe` or `.dll`

### Import Settings

- **Format**: PE for Windows executables, ELF for Linux
- **Language**: x86/64 with compiler `windows` or `gcc`
- For Unity IL2CPP: import `GameAssembly.dll` (the main logic binary)
- For Unreal: import the main shipping binary

### Auto-Analysis Settings

After import, Ghidra prompts for analysis. Recommended options:

| Analyzer | Recommendation | Notes |
|-|-|-|
| Aggressive Instruction Finder | OFF | Causes false positives in data sections |
| Decompiler Parameter ID | ON | Improves decompiler output |
| RTTI Analyzer | ON | Recovers C++ class hierarchies |
| Stack | ON | Critical for local variable recovery |
| Windows x86 PE RTTI | ON | vtable and class name recovery |
| PDB (if available) | ON | Load symbols from .pdb file |
| Scalar Operand References | ON | Helps find constant references |

For large binaries (>100MB), analysis can take 30+ minutes. Let it finish before
browsing to avoid incomplete results.

## Function Discovery

### From Strings

1. Open Window > Defined Strings
2. Search for recognizable game strings ("Health", "Damage", "SaveGame")
3. Double-click to navigate to the string in the listing
4. Right-click > References > Show References to Address
5. Follow xrefs to find the function that uses the string

### From Exports

1. Open Window > Symbol Table
2. Filter by "Export" source type
3. Game DLLs often export key manager classes or init functions

### From Known Addresses

If you found an address via Cheat Engine or x64dbg:

1. Press `G` (Go To) and enter the address
2. If in the middle of a function, scroll up to find the function entry
3. Press `F` to create a function if Ghidra missed it

## Decompilation

### Reading Decompiled Output

The Decompiler window shows C-like pseudocode. Key patterns:

```c
// this pointer is typically the first parameter
void __thiscall Player::TakeDamage(Player *this, float damage)
{
    if (this->shield > 0.0) {
        this->shield = this->shield - damage;
    } else {
        this->health = this->health - damage;
    }
}
```

### Improving Decompilation

1. **Retype variables**: Right-click a variable > Retype Variable (or `Ctrl+L`)
2. **Rename variables**: Right-click > Rename Variable (or `L`)
3. **Set calling convention**: Right-click function signature > Edit Function Signature
4. **Apply structures**: Create structs in Data Type Manager, then retype parameters
5. **Set function prototype**: If you know the signature, edit it directly

## Cross-Reference Tracing

### Finding Callers/Callees

- Right-click function name > References > Show References to (incoming xrefs)
- Window > Function Call Graph for visual call tree
- Right-click > References > Show References from (outgoing xrefs)

### Data References

- Right-click any address/variable > References > Show References to
- Useful for finding all code that reads/writes a global variable
- Filter by access type (READ, WRITE) in the references window

## Structure Recovery

### Creating Structures

1. Open Window > Data Type Manager
2. Right-click program archive > New > Structure
3. Add fields with offsets matching what you see in decompilation

```
struct Player {          // size: 0x48
    void* vtable;        // 0x00
    float posX;          // 0x08
    float posY;          // 0x0C
    float posZ;          // 0x10
    float health;        // 0x20
    float maxHealth;     // 0x24
    int level;           // 0x28
    char name[32];       // 0x2C
};
```

### Auto-Creating from Decompiler

1. In the decompiler, right-click a pointer parameter
2. Select "Auto Create Structure"
3. Ghidra infers fields from how the pointer is dereferenced

## Annotation Best Practices

- **Name every function** you understand, even partially: `Player::maybeUpdateHP`
- **Add plate comments** (`;` key) at function entry describing purpose
- **Label global addresses** with descriptive names: `g_playerManager`
- **Bookmark** (Ctrl+D) important locations for quick navigation
- **Use namespaces**: Edit Function > set namespace to class name
- **Tag functions** (right-click > Set Tag) for categorization: "combat", "save", "network"

## Scripting via MCP

With the Ghidra MCP bridge, you can script analysis from external tools:

```
# Common MCP operations:
- list_functions: enumerate all discovered functions
- decompile_function: get C pseudocode for a named function
- get_function_xrefs: find all callers of a function
- rename_function: apply your RE findings
- search_functions_by_name: find functions matching a pattern
- list_strings: search for interesting strings
- list_classes: enumerate RTTI-discovered classes
```

This enables automation: scan for functions matching patterns, decompile in batch,
and cross-reference systematically without clicking through the GUI.

## Tips

- Use the "Version Tracking" feature to diff two versions of a game binary
- Import header files (`.h`) via File > Parse C Source for known SDKs
- For Unity IL2CPP, use il2cppdumper's script.json output as Ghidra labels
- The Entropy view (Window > Entropy) helps locate packed/encrypted sections
- Export a Ghidra Function ID database (`.fidb`) to share function signatures
  across team members or game versions
