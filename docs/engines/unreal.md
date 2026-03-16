# Unreal Engine

## Engine Identification

- `UE4-*`, `UE5-*` prefix in crash logs or binary names
- `.pak` files in `Content/Paks/` directory
- `Engine/Binaries/` folder structure
- `<Game>-Shipping.exe` or `<Game>-Win64-Shipping.exe`
- `UnrealCEFSubProcess.exe` in Binaries (embedded Chromium)
- `tps` files referencing Epic third-party libraries
- `oo2core_*` (Oodle) or `bink2w64.dll` (Bink video) libraries
- UE version can often be read from `Engine/Build/Build.version`

## Key Binaries and Files

| File/Dir | Purpose |
|-|-|
| `<Game>-Win64-Shipping.exe` | Main game executable |
| `Content/Paks/*.pak` | Packaged game assets |
| `Engine/Binaries/ThirdParty/` | Engine third-party libraries |
| `<Game>/Binaries/Win64/` | Game-specific binaries |
| `Saved/Config/` | Runtime configuration (editable .ini) |
| `Saved/Logs/` | Game logs |

## Asset Formats

### .pak Files

Unreal packages assets into `.pak` (Pak archive) files:
- Compressed archives containing .uasset, .uexp, .ubulk files
- May be encrypted (AES-256) — need the key to unpack
- Tools: UnrealPak (official), QuickBMS with UE scripts, FModel

### .uasset / .uexp / .ubulk

| Extension | Content |
|-|-|
| `.uasset` | Asset header, metadata, imports/exports table |
| `.uexp` | Asset data (bulk of the content) |
| `.ubulk` | Large bulk data (textures, audio) |

### Extraction Tools

- **FModel**: GUI tool for browsing .pak contents, previewing assets
- **UAssetGUI / UAssetAPI**: Read and modify .uasset files programmatically
- **UnrealPak**: Official CLI for packing/unpacking .pak files
- **Asset Editor**: Edit cooked assets (limited capabilities)

## Decompilation / Reverse Engineering

### Ghidra for Native Analysis

Most UE games ship as compiled C++ — no IL to decompile:

1. Import the game executable into Ghidra
2. Let auto-analysis complete (this takes a while for large UE binaries)
3. UE binaries are typically very large (100MB+) — be patient
4. Look for `UObject`, `AActor`, `UGameInstance` vtables as landmarks
5. String references help locate specific game logic

### Finding UE Reflection Data

UE's reflection system (UObject, UPROPERTY, UFUNCTION) embeds metadata:
- Search for `StaticClass` functions to find class definitions
- `GNames` and `GObjects` arrays contain runtime type information
- UE4SS can dump this information at runtime (preferred method)

### Blueprint Analysis

Many UE games use Blueprints (visual scripting):
- Blueprint logic is serialized in .uasset files
- FModel can display Blueprint node graphs
- Blueprint bytecode can be partially decompiled
- Pure Blueprint mods can replace .uasset files

## Modding Frameworks

### UE4SS (Unreal Engine Scripting System)

The primary modding framework for UE4/UE5 games:

**Installation:**
1. Download UE4SS release matching your UE version
2. Extract to `<Game>/Binaries/Win64/`
3. Key files: `UE4SS.dll`, `UE4SS-settings.ini`

**Features:**
- Lua scripting API for game logic modification
- Live object dumper (generates C++ headers from runtime reflection)
- Console commands and hot reload
- Blueprint mod loading
- C++ mod SDK

**Lua Mod Structure:**
```
Mods/
  MyMod/
    enabled.txt
    scripts/
      main.lua
```

**Example Lua Script:**
```lua
RegisterHook("/Script/Game.PlayerCharacter:TakeDamage", function(self, damage)
    -- Halve all damage
    damage:set(damage:get() * 0.5)
end)
```

### Blueprint Mods

For games that support loose file loading:
1. Create assets in UE Editor (matching game's engine version)
2. Cook the assets
3. Package as a .pak file
4. Place in `Content/Paks/~mods/` (the `~` prefix ensures load after base)

### C++ Mods with UE4SS SDK

For deeper modifications:
- UE4SS provides a C++ SDK for writing native mods
- Compiled as DLLs, loaded by UE4SS
- Full access to UE reflection system and engine internals
- Can hook any virtual function

## Configuration Modding

### .ini File Editing

Many game parameters live in config files:
- `<Game>/Saved/Config/WindowsNoEditor/` — user overrides
- `Engine.ini`, `Game.ini`, `Input.ini`, `Scalability.ini`
- Base configs in `Content/` inside .pak files

### Console Variables

UE games have CVars accessible via console:
- Enable console: add `ConsoleKey=Tilde` to Input.ini
- Many games ship with console disabled — UE4SS can re-enable it
- CVars control rendering, physics, gameplay parameters

## Blueprint vs C++ Modding

| Aspect | Blueprint | C++ (UE4SS) |
|-|-|-|
| Ease of entry | Lower (visual) | Higher (programming) |
| Capability | Asset replacement, new actors | Full engine access |
| Game updates | Fragile (asset format changes) | Fragile (offset changes) |
| Distribution | .pak files | DLL + scripts |
| Multiplayer | Usually safe | Often blocked by anti-cheat |

## Gotchas and Pitfalls

- UE version mismatches: UE4SS must match the game's exact UE version
- Encrypted .pak files cannot be unpacked without the AES key
- Cooked assets from one UE version rarely work in another
- Blueprint mods require matching the exact UE Editor version the game uses
- Large binaries make Ghidra analysis slow — use function filtering
- UE's hot reload can mask bugs that appear on cold start
- Shipping builds strip debug symbols — analysis is harder than Development builds
- Some games use custom engine forks — standard UE4SS may not work
- IoStore format (.utoc/.ucas) in newer UE5 games requires updated tools
- Anti-cheat is common in UE multiplayer games — limits modding approaches
