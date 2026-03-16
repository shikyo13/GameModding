# MonoGame / XNA — SMAPI (Stardew Valley)

## Engine Identification

- MonoGame/XNA runtime: `MonoGame.Framework.dll` or `Microsoft.Xna.Framework.dll`
- `Stardew Valley.exe` or `StardewModdingAPI.exe` (when SMAPI installed)
- `Content/` folder with `.xnb` files (XNA content pipeline)
- `Stardew Valley.deps.json` (.NET build)
- No UnityPlayer.dll, no UE signatures — process of elimination helps

## Key Files and Binaries

| File | Purpose |
|-|-|
| `Stardew Valley.dll` | Main game assembly (.NET 6 on modern versions) |
| `StardewModdingAPI.exe` | SMAPI launcher/runtime |
| `Content/` | Game assets in .xnb format |
| `Content/Data/` | JSON data files (crops, fish, NPCs, etc.) |
| `Content/Maps/` | Tiled .tmx map files (compiled to .xnb) |
| `Mods/` | SMAPI mod installation directory |
| `smapi-internal/` | SMAPI framework files |

## SMAPI Framework

### What Is SMAPI

Stardew Modding API — the standard mod loader for Stardew Valley.
Provides mod lifecycle management, event system, content API, and multiplayer
sync. Virtually all Stardew Valley mods require SMAPI.

### Installation

1. Download SMAPI from https://smapi.io
2. Run the installer — it patches the game launcher
3. Launch via `StardewModdingAPI.exe` (Steam can be configured to use this)
4. SMAPI creates `Mods/` folder on first run

### Mod Lifecycle

Every SMAPI mod implements `IMod` with an `Entry` method:

```csharp
public class MyMod : Mod
{
    public override void Entry(IModHelper helper)
    {
        // Called once when the mod loads
        // Subscribe to events, register content, etc.

        helper.Events.GameLoop.DayStarted += OnDayStarted;
        helper.Events.Input.ButtonPressed += OnButtonPressed;
    }

    private void OnDayStarted(object sender, DayStartedEventArgs e)
    {
        Monitor.Log("A new day begins!", LogLevel.Info);
    }

    private void OnButtonPressed(object sender, ButtonPressedEventArgs e)
    {
        if (e.Button == SButton.F5)
            Monitor.Log("F5 pressed!", LogLevel.Debug);
    }
}
```

### SMAPI Event Categories

| Category | Examples |
|-|-|
| `GameLoop` | GameLaunched, SaveLoaded, DayStarted, TimeChanged, UpdateTicked |
| `Input` | ButtonPressed, ButtonReleased, CursorMoved, MouseWheelScrolled |
| `World` | LocationListChanged, ObjectListChanged, TerrainFeatureListChanged |
| `Player` | InventoryChanged, LevelChanged, Warped |
| `Display` | Rendered, RenderingHud, MenuChanged |
| `Multiplayer` | PeerConnected, ModMessageReceived |
| `Content` | AssetRequested, AssetsInvalidated |

## Mod Manifest Format

Every SMAPI mod requires a `manifest.json`:

```json
{
    "Name": "My Mod",
    "Author": "YourName",
    "Version": "1.0.0",
    "Description": "Does something cool.",
    "UniqueID": "YourName.MyMod",
    "EntryDll": "MyMod.dll",
    "MinimumApiVersion": "3.18.0",
    "Dependencies": [
        {
            "UniqueID": "Pathoschild.ContentPatcher",
            "MinimumVersion": "1.30.0",
            "IsRequired": false
        }
    ],
    "ContentPackFor": null,
    "UpdateKeys": ["Nexus:12345"]
}
```

### Key Manifest Fields

| Field | Purpose |
|-|-|
| `UniqueID` | Globally unique mod identifier (Author.ModName convention) |
| `EntryDll` | DLL filename containing the `IMod` implementation |
| `MinimumApiVersion` | Minimum SMAPI version required |
| `Dependencies` | Other mods this depends on (optional or required) |
| `ContentPackFor` | If this is a content pack, which mod consumes it |
| `UpdateKeys` | Where to check for updates (Nexus, GitHub, etc.) |

## Content Patcher

The most popular way to modify game content without C# code:

### What It Does

Content Patcher lets you create "content packs" that modify game assets
(images, data files, maps) using JSON configuration instead of compiled code.

### Content Pack Structure

```
[CP] My Changes/
    manifest.json          # ContentPackFor: Pathoschild.ContentPatcher
    content.json           # Edit/replace instructions
    assets/
        my_texture.png     # Replacement assets
```

### content.json Example

```json
{
    "Format": "2.0.0",
    "Changes": [
        {
            "Action": "EditImage",
            "Target": "Characters/Abigail",
            "FromFile": "assets/abigail.png"
        },
        {
            "Action": "EditData",
            "Target": "Data/ObjectInformation",
            "Entries": {
                "128": "Pufferfish/200/40/Fish -4/Pufferfish/Legendary fish."
            }
        },
        {
            "Action": "EditMap",
            "Target": "Maps/Town",
            "FromFile": "assets/town_overlay.tmx",
            "ToArea": { "X": 10, "Y": 20, "Width": 5, "Height": 5 }
        }
    ]
}
```

## Harmony Integration

SMAPI includes Harmony for patching game methods:

```csharp
public override void Entry(IModHelper helper)
{
    var harmony = new Harmony(ModManifest.UniqueID);
    harmony.PatchAll();  // Apply all [HarmonyPatch] in the assembly

    // Or patch manually
    harmony.Patch(
        original: AccessTools.Method(typeof(Game1), "performTenMinuteClockUpdate"),
        prefix: new HarmonyMethod(typeof(MyPatches), nameof(MyPatches.BeforeClockUpdate))
    );
}
```

### SMAPI + Harmony Best Practices

- Use SMAPI events when possible — only use Harmony when events don't cover your need
- Always use `ModManifest.UniqueID` as Harmony instance ID
- SMAPI logs Harmony patch conflicts — check the log for `[SMAPI] Patched` messages
- Prefix patches returning `false` skip the original — be careful with compatibility

## Decompilation Workflow

1. Open `Stardew Valley.dll` in ILSpy or dnSpy
2. Modern Stardew Valley is .NET 6 — use a decompiler that supports it
3. Key namespaces:
   - `StardewValley` — core game logic
   - `StardewValley.Objects` — game items
   - `StardewValley.Characters` — NPCs
   - `StardewValley.TerrainFeatures` — trees, crops, etc.
   - `StardewValley.Locations` — map locations
4. Cross-reference with SMAPI source (open source) for framework internals
5. The game wiki documents most data formats — start there before decompiling

## Gotchas and Pitfalls

- **SMAPI version**: Mods targeting old SMAPI versions may not work on current game
- **Content pipeline**: .xnb files need `xnb_node` or similar to unpack/repack
- **.NET migration**: Stardew Valley moved from .NET Framework to .NET 6 (v1.6) — old mods broke
- **Multiplayer**: Not all events fire for farmhands — test both host and client
- **Save serialization**: Custom data must use SMAPI's `Data` API, not direct save modification
- **Content invalidation**: After editing assets, call `helper.GameContent.InvalidateCache()`
- **Mod conflicts**: Multiple mods editing the same asset — Content Patcher handles priority via `Priority` field
- **Android/console**: SMAPI only works on PC — mobile/console have no mod support
- **Update checks**: Include `UpdateKeys` in manifest for SMAPI's update alert system
- **Config files**: Use `helper.ReadConfig<T>()` — creates `config.json` automatically
- **Translation**: Use `helper.Translation` API, not hardcoded strings
