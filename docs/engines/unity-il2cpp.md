# Unity (IL2CPP Backend)

## Engine Identification

- `GameAssembly.dll` in game root (the compiled C++ output)
- `global-metadata.dat` in `<Game>_Data/il2cpp_data/Metadata/`
- `UnityPlayer.dll` still present (it's still Unity)
- **No** `Assembly-CSharp.dll` in Managed folder (or only stubs)
- `<Game>_Data/Managed/` may exist but contains only reference stubs
- il2cpp_data folder structure present

## Key DLLs and Binaries

| File | Purpose |
|-|-|
| `GameAssembly.dll` | All game logic compiled to native C++ |
| `global-metadata.dat` | Type/method/string metadata for reconstruction |
| `UnityPlayer.dll` | Unity runtime |
| `il2cpp_data/` | IL2CPP runtime support data |

## How IL2CPP Works

Unity's IL2CPP pipeline:
1. C# source -> IL bytecode (normal .NET compilation)
2. IL bytecode -> C++ source (il2cpp transpiler)
3. C++ source -> native binary (platform compiler)

The `global-metadata.dat` file retains type names, method signatures, and string
literals — this is what makes reconstruction possible.

## Decompilation Workflow

### Step 1: IL2CPP Dumper

Use [Il2CppDumper](https://github.com/Perfare/Il2CppDumper):

```bash
Il2CppDumper.exe GameAssembly.dll global-metadata.dat output_dir
```

This produces:
- `dump.cs` — reconstructed C# type/method signatures (no bodies)
- `il2cpp.h` — C header with struct definitions
- `script.json` — address-to-method mapping
- `stringliteral.json` — string literal addresses

### Step 2: Load into Ghidra

1. Open Ghidra, create new project, import `GameAssembly.dll`
2. Let auto-analysis complete
3. Run `ghidra_with_struct.py` from Il2CppDumper output to apply type info
4. Alternatively, use the Ghidra script `Il2CppDumper/Ghidra/ghidra.py`

### Step 3: Cross-Reference Dump Offsets

In `dump.cs`, methods have RVA (Relative Virtual Address) comments:
```csharp
// RVA: 0x1A2B3C Offset: 0x1A2B3C
public void TakeDamage(float amount) { }
```

In Ghidra, navigate to `GameAssembly.dll` base + RVA to find the native code.
Use the `script.json` to batch-label functions in Ghidra.

### Step 4: Reconstruct Logic

- Native code won't look like C# — expect inlined methods, vtable calls
- String references use `il2cpp_string_new` or metadata indices
- Generic methods are monomorphized (separate native function per type param)
- Virtual calls go through `il2cpp_runtime_invoke` or vtable slots

## Common Modding Frameworks

### BepInEx 6.x (Bleeding Edge)

BepInEx 6 supports IL2CPP via Il2CppInterop (formerly unhollower):

1. Download BepInEx 6 IL2CPP build for your game
2. Extract to game root
3. Run game once — BepInEx generates proxy assemblies in `BepInEx/interop/`
4. Reference proxy assemblies in your mod project

```csharp
[BepInPlugin("com.author.plugin", "Plugin", "1.0.0")]
public class MyPlugin : BasePlugin
{
    public override void Load()
    {
        // Note: BasePlugin, not BaseUnityPlugin
        AddComponent<MyMonoBehaviour>();
    }
}
```

### Il2CppInterop Specifics

- Proxy assemblies mirror original C# types but call into native code
- `Il2CppSystem` namespace wraps IL2CPP runtime types
- Convert between managed and IL2CPP types:
  ```csharp
  Il2CppSystem.String il2cppStr = "hello";  // implicit conversion
  string managedStr = il2cppStr;              // implicit conversion
  ```
- Arrays: use `Il2CppArrayBase<T>`, `Il2CppReferenceArray<T>`

### MelonLoader

Alternative framework, also supports IL2CPP:
- Uses similar unhollowing approach
- Different plugin API (`MelonMod` base class)
- Some games have better MelonLoader support than BepInEx

## Limitations vs Mono

| Aspect | Mono | IL2CPP |
|-|-|-|
| Decompilation | Full C# reconstruction | Signatures only, native bodies |
| Harmony patching | Full support | Limited (detour-based) |
| Runtime reflection | Full .NET reflection | Partial, via Il2CppInterop |
| Transpiler patches | Yes | No (no IL to modify) |
| Performance mods | Easy | Harder to reason about |
| New MonoBehaviours | Straightforward | Requires ClassInjector |

### Key Limitations

- **No Transpilers**: IL2CPP has no IL to transpile. Use Prefix/Postfix only.
- **Injecting new types**: Must use `ClassInjector.RegisterTypeInIl2Cpp<T>()`
- **Delegates**: IL2CPP delegates need special handling via `Il2CppSystem.Action`
- **Generics**: Some generic instantiations may not exist in the binary
- **Coroutines**: Must use `Il2CppSystem.Collections.IEnumerator` wrapper

## Gotchas and Pitfalls

- `global-metadata.dat` format changes between Unity versions — use matching Il2CppDumper version
- Game updates regenerate `GameAssembly.dll` — all RVA offsets shift
- Some games encrypt or obfuscate `global-metadata.dat`
- Anti-cheat (EAC, BattlEye) often blocks IL2CPP modding frameworks
- Il2CppInterop proxy assemblies must be regenerated when game updates
- String comparisons may behave differently (IL2CPP string interning differs)
- Null checks: IL2CPP objects can be "not null in C#" but "null in native"
  — use `== null` (which is overloaded) instead of `is null`
- Stack traces in IL2CPP are often unhelpful — use logging liberally
