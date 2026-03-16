# BepInEx Modding Framework

## Overview

BepInEx (Bepis Injector Extensible) is the most widely used Unity game modding framework.
It handles mod loading, configuration, logging, and integrates Harmony for runtime patching.

## BepInEx 5.x vs 6.x

| Feature | 5.x (Stable) | 6.x (Bleeding Edge) |
|-|-|-|
| Runtime | Mono, IL2CPP (partial) | Mono, IL2CPP (full), CoreCLR |
| Harmony | HarmonyX (Harmony 2 fork) | HarmonyX |
| .NET Target | .NET Framework 4.x | .NET Standard 2.1 / .NET 6+ |
| Preloader | MonoMod-based | MonoMod-based, improved |
| Status | Production-ready | Experimental / nightly |

For most Unity modding today, **BepInEx 5.4.x** is the standard choice. Use 6.x only
for IL2CPP games that require it or CoreCLR titles.

## Installation

1. Download the correct build for your game's runtime (Mono x64/x86, IL2CPP)
2. Extract into the game's root directory (where the `.exe` lives)
3. Run the game once to generate `BepInEx/config/` and `BepInEx/plugins/`
4. Place plugin DLLs in `BepInEx/plugins/`

Directory structure after install:

```
GameRoot/
  BepInEx/
    core/           # Framework assemblies
    config/         # Configuration files
    plugins/        # Your mods go here
    patchers/       # Preloader patchers (advanced)
    cache/          # IL2CPP metadata cache
  doorstop_config.ini
  winhttp.dll       # Unity doorstop proxy DLL
```

## Plugin Anatomy

```csharp
using BepInEx;
using BepInEx.Logging;
using HarmonyLib;

[BepInPlugin("com.example.mymod", "My Mod", "1.0.0")]
[BepInDependency("com.other.requiredmod", BepInDependency.DependencyFlags.SoftDependency)]
[BepInProcess("Game.exe")] // optional: restrict to specific executable
public class MyPlugin : BaseUnityPlugin
{
    internal static ManualLogSource Log;
    private Harmony _harmony;

    private void Awake()
    {
        // Earliest lifecycle hook. Runs once when the plugin loads.
        Log = Logger;
        Log.LogInfo("MyMod loaded!");

        _harmony = new Harmony("com.example.mymod");
        _harmony.PatchAll(); // Apply all [HarmonyPatch] in this assembly
    }

    private void Start()
    {
        // Runs after all plugins have called Awake().
        // Safe to interact with other plugins here.
    }

    private void Update()
    {
        // Runs every frame (MonoBehaviour.Update).
        if (Input.GetKeyDown(KeyCode.F5))
            Log.LogInfo("F5 pressed!");
    }

    private void OnDestroy()
    {
        _harmony?.UnpatchSelf();
    }
}
```

## Lifecycle Order

1. **Preloader patchers** run (assembly-level patching before game code loads)
2. **Chainloader** discovers and sorts plugins by dependencies
3. `Awake()` called on each plugin in dependency order
4. `Start()` called on each plugin after all Awake() calls complete
5. `Update()` / `FixedUpdate()` / `LateUpdate()` called per-frame

## Configuration

```csharp
public class MyPlugin : BaseUnityPlugin
{
    private ConfigEntry<float> _damageMultiplier;
    private ConfigEntry<bool> _godMode;
    private ConfigEntry<KeyboardShortcut> _toggleKey;

    private void Awake()
    {
        _damageMultiplier = Config.Bind(
            "Combat",           // section
            "DamageMultiplier", // key
            1.5f,               // default
            "Multiplier for outgoing damage" // description
        );

        _godMode = Config.Bind("Combat", "GodMode", false,
            new ConfigDescription(
                "Enable invincibility",
                new AcceptableValueList<bool>(true, false)));

        _toggleKey = Config.Bind("General", "ToggleKey",
            new KeyboardShortcut(KeyCode.F1),
            "Key to toggle the mod");

        // React to config changes (e.g., from ConfigManager GUI)
        _damageMultiplier.SettingChanged += (_, _) =>
            Logger.LogInfo($"Damage multiplier changed to {_damageMultiplier.Value}");
    }
}
```

Config files are auto-generated at `BepInEx/config/com.example.mymod.cfg` in TOML-like format.
Use [BepInEx.ConfigurationManager](https://github.com/BepInEx/BepInEx.ConfigurationManager)
for an in-game GUI.

## Logging

```csharp
Logger.LogDebug("Verbose details");    // only shown if log level includes Debug
Logger.LogInfo("Normal information");
Logger.LogWarning("Something is off");
Logger.LogError("Something broke");
Logger.LogFatal("Cannot continue");
```

Log output goes to `BepInEx/LogOutput.log` and the in-game console (if enabled).
Configure log levels in `BepInEx/config/BepInEx.cfg`.

## Harmony Integration

BepInEx ships with HarmonyX. Do **not** bundle your own Harmony DLL.

```csharp
// Auto-patch: finds all [HarmonyPatch] classes in the calling assembly
_harmony = new Harmony(Info.Metadata.GUID);
_harmony.PatchAll();

// Manual patch
_harmony.Patch(
    AccessTools.Method(typeof(GameManager), "SaveGame"),
    prefix: new HarmonyMethod(typeof(SavePatch), nameof(SavePatch.BeforeSave)));
```

## Preloader Patchers

For cases where Harmony is too late (need to modify assemblies before they load):

```csharp
public static class MyPatcher
{
    public static IEnumerable<string> TargetDLLs { get; } = new[] { "Assembly-CSharp.dll" };

    public static void Patch(AssemblyDefinition assembly)
    {
        // Use Mono.Cecil to modify types/methods at the IL level
        var type = assembly.MainModule.GetType("GameManager");
        // ... modify ...
    }
}
```

Place the compiled DLL in `BepInEx/patchers/`. Preloader patchers use Mono.Cecil and run
before the CLR loads the target assemblies.

## Tips

- Always use `Info.Metadata.GUID` as your Harmony ID for consistency
- Use `[BepInDependency]` to declare load-order requirements between plugins
- For IL2CPP games, use `Il2CppInterop` (formerly unhollower) type mappings
- Test with `--doorstop-enable true --doorstop-target` CLI args for automation
- The `BepInEx.cfg` setting `HideManagerGameObject = true` prevents the plugin
  manager from appearing in Unity's hierarchy (anti-detection)
