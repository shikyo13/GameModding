# Godot Engine

## Engine Identification

- `.pck` file alongside the executable (or embedded in it)
- `godot.windows.opt.64.exe` or custom-named executable
- `.import` files if shipped unpackaged (rare)
- `project.godot` file if project is accessible
- Godot splash screen on startup (unless replaced)
- `GodotSharp/` directory indicates Godot with C# (Mono build)

## Key Files and Formats

| File/Extension | Purpose |
|-|-|
| `<game>.pck` | Packed game resources and scripts |
| `<game>.exe` | Engine executable (may contain embedded .pck) |
| `.gd` | GDScript source files (inside .pck) |
| `.tscn` / `.scn` | Scene files (text / binary) |
| `.tres` / `.res` | Resource files (text / binary) |
| `.gdshader` | Shader files |
| `GodotSharp/` | Mono/.NET assemblies (C# Godot builds) |

## PCK File Extraction

### Tools

- **Godot RE Tools** (gdre_tools): Primary tool for .pck extraction and GDScript decompilation
- **GodotPCKExplorer**: GUI tool for browsing .pck contents
- **godotdec**: Older decompiler for Godot 3.x

### Extraction with gdre_tools

```bash
# Extract all files from a .pck
gdre_tools --headless --recover="game.pck" --output-dir="./extracted"

# If .pck is embedded in the executable
gdre_tools --headless --recover="game.exe" --output-dir="./extracted"
```

### Handling Embedded PCK

Some games embed the .pck at the end of the executable:
1. Open the .exe in a hex editor
2. Search for `GDPC` magic bytes (PCK header)
3. Extract from that offset to end of file
4. Or just use gdre_tools which handles this automatically

## GDScript Decompilation

### Godot 3.x

- GDScript is compiled to bytecode stored in `.gdc` files inside .pck
- gdre_tools can decompile `.gdc` back to `.gd` (GDScript source)
- Decompilation quality is generally good — variable names preserved
- Comments are stripped during compilation

### Godot 4.x

- GDScript bytecode format changed significantly
- gdre_tools supports Godot 4 decompilation (use latest version)
- Some games may ship with GDScript source (not compiled) — check .pck contents

### C# Godot Builds

- If `GodotSharp/` directory exists, game uses C#
- Decompile assemblies with ILSpy/dnSpy (same as any .NET assembly)
- Look in `GodotSharp/Api/` for engine bindings
- Game code in `.dll` files alongside or in the .pck

## Godot RE Patterns

### Scene File Analysis

Text scene files (.tscn) are human-readable:
```
[gd_scene load_steps=3 format=2]
[ext_resource path="res://player.gd" type="Script" id=1]
[node name="Player" type="KinematicBody2D"]
script = ExtResource( 1 )
speed = 200.0
```

Binary scene files (.scn) need conversion:
- gdre_tools converts .scn to .tscn during extraction
- Or use Godot editor to open and re-save as text

### Resource Inspection

- `.tres` (text resource): directly readable, contains game data
- `.res` (binary resource): needs conversion or Godot editor
- Resources define game configuration, item databases, etc.

### Project Structure

Typical Godot project layout after extraction:
```
project.godot          # Project settings
default_env.tres       # Default environment
scenes/                # Scene files
scripts/               # GDScript files
assets/                # Art, audio, etc.
addons/                # Third-party plugins
autoload/              # Singleton scripts
```

## Asset Inspection

### Textures and Images
- Stored as `.stex` (Godot 3) or `.ctex` (Godot 4) inside .pck
- gdre_tools exports these as .png during recovery
- Original formats vary: .png, .jpg, .webp

### Audio
- `.sample` or `.oggstr` inside .pck
- Exported as .ogg or .wav by gdre_tools

### Fonts
- `.font` / `.fontdata` resources
- May reference system fonts or bundled .ttf/.otf

## Modding Approaches

### Direct File Replacement
- Extract .pck, modify files, repack
- Repacking: `godot --export-pack` or use GodotPCKExplorer
- Fragile — game updates break mods

### PCK Patching
- Godot loads multiple .pck files
- A second .pck can override resources from the first
- Place a `<game>_patch.pck` alongside the main .pck (check game-specific behavior)

### GDScript Modification
- Decompile, modify, recompile with matching Godot version
- Or replace compiled .gdc with source .gd (Godot can run both)

### C# Mod Loading (Mono builds)
- Similar to Unity Mono modding
- Harmony patches work on Godot C# assemblies
- No standardized mod framework (game-specific)

## Gotchas and Pitfalls

- Godot version must match exactly for recompilation — check `project.godot`
- Bytecode format is not stable between Godot minor versions
- Embedded .pck extraction sometimes misidentifies the offset
- Some games use custom encryption on .pck files
- GDScript decompilation may produce slightly incorrect code around complex expressions
- Godot 3 -> 4 migration means tools for one won't work on the other
- No standard modding framework — each Godot game has its own approach
- Export templates strip debug info — function names may be missing in native code
- .import files are editor-only; exported games use processed versions
