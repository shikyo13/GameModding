# Unity (Mono Backend)

## Engine Identification

- `UnityPlayer.dll` in game root
- `<Game>_Data/Managed/` folder containing .NET assemblies
- `Assembly-CSharp.dll` — the primary game logic assembly
- `mono-2.0-bdwgc.dll` or `mono.dll` in root or Mono subdirectory
- `globalgamemanagers` or `mainData` in the Data folder
- `level0`, `level1`, ... files indicate Unity scene bundles
- **No** `GameAssembly.dll` (that indicates IL2CPP — see unity-il2cpp.md)

## Key DLLs and Binaries

| File | Purpose |
|-|-|
| `Assembly-CSharp.dll` | Game logic (your primary target) |
| `Assembly-CSharp-firstpass.dll` | Plugins compiled in first pass |
| `UnityEngine.dll` | Core Unity runtime |
| `UnityEngine.CoreModule.dll` | Core module (newer Unity) |
| `UnityEngine.UI.dll` | Unity UI system |
| `0Harmony.dll` | Harmony patching library (if BepInEx installed) |

Managed directory path examples:
- Windows: `<Game>\\<Game>_Data\\Managed\\`
- Linux: `<Game>/<Game>_Data/Managed/`
- macOS: `<Game>.app/Contents/Resources/Data/Managed/`

## Decompilation Workflow

### ILSpy (CLI)

List all types in an assembly (Windows paths use `\\`):
```bash
ilspycmd "Assembly-CSharp.dll" -l -r "ManagedDir"
```

Decompile a specific type:
```bash
ilspycmd "Assembly-CSharp.dll" -t TypeName -r "ManagedDir"
```

Decompile entire assembly to a project:
```bash
ilspycmd "Assembly-CSharp.dll" -p -o "./decompiled" -r "ManagedDir"
```

The `-r` flag adds a reference search directory so ILSpy can resolve dependencies.

### dnSpy (GUI)

1. Open dnSpy, drag `Assembly-CSharp.dll` into the assembly list
2. Navigate the type tree or use Search (Ctrl+K)
3. Right-click a method > Edit Method Body for quick IL patches (not recommended for distribution)
4. Use Analyze (Ctrl+R) to find usages of a type/method

### Recommended Approach

1. Decompile with ILSpy CLI for bulk analysis
2. Use dnSpy for interactive browsing and debugging
3. Never distribute modified assemblies — use Harmony patches instead

## Common Modding Frameworks

### BepInEx

The standard modding framework for Unity Mono games.

**Installation:**
1. Download BepInEx 5.x for Mono (not 6.x unless IL2CPP)
2. Extract to game root (winhttp.dll, doorstop_config.ini, BepInEx/)
3. Run game once to generate BepInEx/config/ and BepInEx/plugins/

**Plugin structure:**
```csharp
[BepInPlugin("com.author.pluginname", "Plugin Name", "1.0.0")]
public class MyPlugin : BaseUnityPlugin
{
    void Awake()
    {
        // Entry point — runs when plugin loads
        Harmony harmony = new Harmony("com.author.pluginname");
        harmony.PatchAll();
    }
}
```

### Harmony Patching

```csharp
[HarmonyPatch(typeof(TargetClass), "TargetMethod")]
public class MyPatch
{
    static void Prefix(TargetClass __instance, ref float __result)
    {
        // Runs before the original method
    }

    static void Postfix(TargetClass __instance, ref float __result)
    {
        // Runs after the original method
    }

    static IEnumerable<CodeInstruction> Transpiler(
        IEnumerable<CodeInstruction> instructions)
    {
        // Modify IL instructions directly
    }
}
```

### ONI-Specific: UserMod2 Pattern

Oxygen Not Included uses a custom mod loading system on top of Harmony:

```csharp
public class MyMod : KMod.UserMod2
{
    public override void OnLoad(Harmony harmony)
    {
        base.OnLoad(harmony);
        // harmony instance is already created for you
    }
}
```

ONI mods target `Assembly-CSharp.dll` in `OxygenNotIncluded_Data\\Managed\\`.
Use PLib for shared utilities and options UI across ONI mods.

## Gotchas and Pitfalls

### Version Mismatches
- Unity version changes can shuffle internal APIs between releases
- Always check `UnityEngine.Application.unityVersion` at runtime
- BepInEx 5.x is for Mono, BepInEx 6.x is for IL2CPP — do not mix
- Harmony 2.x is NOT backward-compatible with Harmony 1.x annotations

### Private Fields and Protected Methods
- Use Harmony's `AccessTools` to reflect into private members:
  ```csharp
  var field = AccessTools.Field(typeof(Target), "privateField");
  var method = AccessTools.Method(typeof(Target), "ProtectedMethod");
  ```
- Traverse API for chained access:
  ```csharp
  Traverse.Create(instance).Field("hidden").SetValue(42);
  ```
- Do NOT use `BindingFlags` manually when AccessTools covers your case

### Assembly Load Order
- `Assembly-CSharp-firstpass.dll` loads before `Assembly-CSharp.dll`
- Plugins in BepInEx load alphabetically unless `[BepInDependency]` is set
- Use `[BepInDependency("other.plugin.guid")]` to enforce load order

### Stripping and Obfuscation
- Some games strip unused code — methods you see in decompiler may be absent at runtime
- IL2CPP builds strip aggressively (but that's a different backend)
- Obfuscated assemblies need de4dot before decompilation

### Common Mistakes
- Forgetting `ref` on `__result` in Harmony patches (value won't propagate)
- Patching generic methods without specifying type arguments
- Using `typeof()` on a type from a different assembly version
- Not handling null `__instance` in static method patches (there is no instance)
