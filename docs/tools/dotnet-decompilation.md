# .NET Decompilation Tools

## Overview

Most Unity games (Mono runtime) ship managed assemblies (`Assembly-CSharp.dll`) that can
be decompiled to near-original C# source. This guide covers the three main decompilers
and when to use each.

## Tool Comparison

| Feature | ILSpy/ilspycmd | dnSpy | dotPeek |
|-|-|-|-|
| GUI | ILSpy (standalone) | Yes (built-in) | Yes (standalone) |
| CLI | ilspycmd | No | No |
| Edit + Recompile | No | Yes | No |
| Debugger | No | Yes (.NET debugger) | No |
| Export to Project | Yes | Yes | Yes |
| Active Maintenance | Yes | Archived (use dnSpyEx) | Yes |
| IL View | Yes | Yes | Yes |
| Search Quality | Good | Excellent | Good |
| Free | Yes (MIT) | Yes (GPL) | Yes (proprietary) |

### When to Use Which

- **ilspycmd**: CI/CD pipelines, batch decompilation, scripted workflows
- **dnSpy/dnSpyEx**: Interactive RE, debugging, editing + recompiling assemblies
- **dotPeek**: Quick browsing, integration with JetBrains tools, project export

## ilspycmd CLI Reference

Install via .NET tool:

```bash
dotnet tool install -g ilspycmd
```

### Common Commands

```bash
# Decompile entire assembly to console
ilspycmd Assembly-CSharp.dll

# Decompile to a project directory
ilspycmd Assembly-CSharp.dll -p -o D:\Decompiled\GameSource

# Decompile a specific type
ilspycmd Assembly-CSharp.dll -t Player

# Decompile with specific language version
ilspycmd Assembly-CSharp.dll -lv CSharp10_0

# List all types in an assembly
ilspycmd Assembly-CSharp.dll -l

# Output IL instead of C#
ilspycmd Assembly-CSharp.dll --il
```

### Key Flags

| Flag | Description |
|-|-|
| `-p` | Decompile as project (generates .csproj) |
| `-o <path>` | Output directory (note: use `\\` path separators on Windows) |
| `-t <type>` | Decompile specific type only |
| `-l` | List types/members |
| `--il` | Output IL instead of C# |
| `-lv <ver>` | Target language version |
| `-r <path>` | Additional reference assembly path |
| `--nested-directories` | Create subdirectories for namespaces |

### Windows Path Note

ilspycmd uses backslash path separators on Windows. Forward slashes may cause issues:

```bash
# Correct on Windows
ilspycmd Assembly-CSharp.dll -p -o D:\\Decompiled\\Output

# May fail on Windows
ilspycmd Assembly-CSharp.dll -p -o D:/Decompiled/Output
```

## dnSpy GUI Workflow

dnSpy (use [dnSpyEx](https://github.com/dnSpyEx/dnSpy) for maintained fork) is the
gold standard for interactive .NET game RE.

### Basic Workflow

1. Open dnSpy, drag-drop `Assembly-CSharp.dll` into the assembly list
2. Also load framework assemblies for full reference resolution:
   - `UnityEngine.dll`, `UnityEngine.CoreModule.dll`
   - Other `Assembly-CSharp-firstpass.dll` if present
3. Browse the type tree or use `Ctrl+Shift+K` to search

### Editing and Recompiling

1. Right-click a method > Edit Method (C#)
2. Modify the code in the editor
3. File > Save Module (saves modified DLL)
4. Replace original DLL with modified version

This is the fastest way to make one-off changes without a full modding framework.

### Debugging Unity Games

1. Debug > Attach to Process (select Unity player)
2. Set breakpoints by clicking line gutters
3. Step through code with F10 (over) / F11 (into)
4. Inspect locals and watch expressions

Requirements:
- Game must use Mono runtime (not IL2CPP)
- Debug symbols help but aren't required
- dnSpy can debug even obfuscated assemblies

### Search Features

- `Ctrl+Shift+K`: Search types, methods, fields, properties
- `Ctrl+Shift+C`: Search constants and string literals
- Analyze (right-click > Analyze): find all references to a member
- Go to Metadata Token: useful when cross-referencing with other tools

## dotPeek Export-to-Project

### Workflow

1. Open dotPeek, File > Open > select DLL
2. Right-click assembly > Export to Project
3. Configure:
   - Output path
   - Export symbols: select all namespaces or specific ones
   - Create .sln file: Yes
4. Open exported solution in Visual Studio / Rider

### Advantages

- Generates compilable .sln with proper project references
- Good for creating a reference codebase to browse alongside modding work
- ReSharper integration for advanced navigation
- Handles multiple assemblies well (batch export)

### Limitations

- Cannot edit and recompile like dnSpy
- Decompiler output occasionally differs from ILSpy (neither is always better)
- No debugger

## Common Decompilation Artifacts

### Compiler-Generated Names

```csharp
// You'll see names like:
private sealed class <>c__DisplayClass12_0   // closure class
private int <health>k__BackingField          // auto-property backing field
private IEnumerator<int> <DoStuff>d__5       // coroutine state machine

// These come from:
// - Lambda closures
// - Auto-implemented properties (get; set;)
// - yield return / async methods
```

### State Machines (Coroutines / Async)

Unity coroutines decompile as state machine classes:

```csharp
// Original code (approximately):
IEnumerator LoadLevel() {
    ShowLoading();
    yield return new WaitForSeconds(1f);
    DoLoad();
    yield return null;
    HideLoading();
}

// Decompiled as:
private sealed class <LoadLevel>d__5 : IEnumerator<object> {
    public int <>1__state;
    public object <>2__current;
    public MyClass <>4__this;

    bool MoveNext() {
        switch (<>1__state) {
            case 0:
                <>4__this.ShowLoading();
                <>2__current = new WaitForSeconds(1f);
                <>1__state = 1;
                return true;
            case 1:
                <>4__this.DoLoad();
                <>2__current = null;
                <>1__state = 2;
                return true;
            case 2:
                <>4__this.HideLoading();
                return false;
        }
    }
}
```

### Switch on String

The compiler often converts string switches to hash-based lookups:

```csharp
// Decompiled output may show:
uint num = ComputeStringHash(text);
if (num <= 0xA3F...) { ... }  // hash comparisons instead of readable switch
```

### Obfuscation Indicators

- Single-letter or unicode class/method names
- Control flow flattening (giant switch in a while loop)
- String encryption (calls to decrypt methods for every string literal)
- Proxy delegates (extra indirection layers)

Tools like de4dot can partially reverse common obfuscators.

## Tips

- Always decompile with **matching framework references** loaded to get accurate type names
- Compare output across decompilers when one produces confusing code
- For IL2CPP games, use Il2CppDumper to generate dummy DLLs, then decompile those
  for type/method signatures (bodies will be empty stubs)
- Use `Assembly.GetReferencedAssemblies()` to find dependency chains
- Check for `[Serializable]` and `[SerializeField]` to find Unity-persisted data
