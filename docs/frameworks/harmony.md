# Harmony 2.0 Patching Guide

## Overview

Harmony is a runtime method patching library for .NET and Mono. It enables modifying game
methods without changing original assemblies, making it the backbone of most Unity/Mono
game modding frameworks.

## Patch Types

### Prefix

Runs **before** the original method. Can skip the original by returning `false`.

```csharp
[HarmonyPatch(typeof(Player), nameof(Player.TakeDamage))]
class TakeDamagePatch
{
    static bool Prefix(Player __instance, ref float damage)
    {
        // Halve all incoming damage
        damage *= 0.5f;
        return true; // true = run original, false = skip
    }
}
```

### Postfix

Runs **after** the original method. Can read/modify the return value via `__result`.

```csharp
[HarmonyPatch(typeof(Shop), nameof(Shop.GetPrice))]
class GetPricePatch
{
    static void Postfix(ref int __result)
    {
        // Everything is free
        __result = 0;
    }
}
```

### Transpiler

Modifies the IL instructions of the original method directly. Most powerful but most fragile.

```csharp
[HarmonyPatch(typeof(Enemy), nameof(Enemy.CalculateStats))]
class CalculateStatsPatch
{
    static IEnumerable<CodeInstruction> Transpiler(
        IEnumerable<CodeInstruction> instructions)
    {
        var matcher = new CodeMatcher(instructions);

        matcher
            .MatchForward(false,
                new CodeMatch(OpCodes.Ldc_I4, 100),
                new CodeMatch(OpCodes.Stfld))
            .SetOperandAndAdvance(999);

        return matcher.InstructionEnumeration();
    }
}
```

### Finalizer

Runs after original + postfix, even if an exception was thrown. Replaces the exception
handling mechanism.

```csharp
[HarmonyPatch(typeof(SaveSystem), nameof(SaveSystem.Load))]
class LoadFinalizerPatch
{
    static Exception Finalizer(Exception __exception)
    {
        if (__exception != null)
            Debug.LogError($"Save load failed: {__exception.Message}");
        return null; // swallow exception
    }
}
```

## Special Parameters

Harmony injects parameters by name convention:

| Parameter | Type | Description |
|-|-|
| `__instance` | Declaring type | The `this` reference (instance methods only) |
| `__result` | Return type | The method's return value (postfix/finalizer) |
| `__state` | Any type | Shared state between prefix and postfix |
| `___fieldName` | Field type | Private field access (triple underscore) |
| `__originalMethod` | `MethodBase` | Reference to the patched method |
| `__args` | `object[]` | All arguments as an array |
| `__runOriginal` | `bool` | Whether the original will run (postfix only) |

Use `ref` to modify injected parameters:

```csharp
static void Postfix(ref int __result, ref float ___secretMultiplier)
{
    __result = (int)(__result * ___secretMultiplier);
    ___secretMultiplier = 1.0f; // reset the private field
}
```

## State Sharing Between Prefix and Postfix

```csharp
[HarmonyPatch(typeof(Timer), nameof(Timer.Execute))]
class TimerPatch
{
    static void Prefix(out Stopwatch __state)
    {
        __state = Stopwatch.StartNew();
    }

    static void Postfix(Stopwatch __state)
    {
        __state.Stop();
        Debug.Log($"Timer.Execute took {__state.ElapsedMilliseconds}ms");
    }
}
```

## HarmonyPatch Attribute Patterns

```csharp
// Basic
[HarmonyPatch(typeof(MyClass), nameof(MyClass.MyMethod))]

// With parameter types (for overloads)
[HarmonyPatch(typeof(MyClass), nameof(MyClass.MyMethod), new[] { typeof(int), typeof(string) })]

// Properties
[HarmonyPatch(typeof(MyClass), nameof(MyClass.MyProperty), MethodType.Getter)]
[HarmonyPatch(typeof(MyClass), nameof(MyClass.MyProperty), MethodType.Setter)]

// Constructors
[HarmonyPatch(typeof(MyClass), MethodType.Constructor)]
[HarmonyPatch(typeof(MyClass), MethodType.StaticConstructor)]

// Stacked attributes
[HarmonyPatch(typeof(MyClass))]
[HarmonyPatch(nameof(MyClass.MyMethod))]
[HarmonyPatch(new[] { typeof(int) })]
```

## AccessTools

Reflection helper for finding private/internal members:

```csharp
// Fields
FieldInfo fi = AccessTools.Field(typeof(Player), "m_health");

// Methods
MethodInfo mi = AccessTools.Method(typeof(Player), "SecretHeal", new[] { typeof(int) });

// Properties
PropertyInfo pi = AccessTools.Property(typeof(Player), "InternalName");

// Inner types
Type inner = AccessTools.Inner(typeof(Player), "PrivateData");

// Delegate creation
var del = AccessTools.MethodDelegate<Action<Player, int>>(mi);
```

## CodeMatcher (Transpiler Helper)

```csharp
static IEnumerable<CodeInstruction> Transpiler(IEnumerable<CodeInstruction> instructions)
{
    var matcher = new CodeMatcher(instructions);

    // Find a pattern
    matcher.MatchForward(true,
        new CodeMatch(OpCodes.Ldarg_0),
        new CodeMatch(OpCodes.Call, AccessTools.Method(typeof(Base), "Init")));

    // Insert after match
    matcher.Advance(1);
    matcher.Insert(
        new CodeInstruction(OpCodes.Ldarg_0),
        new CodeInstruction(OpCodes.Call, AccessTools.Method(typeof(MyPatch), "PostInit")));

    // Replace instruction
    matcher.SetOpcodeAndAdvance(OpCodes.Nop);

    // Remove instructions
    matcher.RemoveInstructions(3);

    return matcher.InstructionEnumeration();
}
```

## Debugging

### HarmonyDebug Attribute

```csharp
[HarmonyDebug] // dumps IL before and after patching to log
[HarmonyPatch(typeof(Player), nameof(Player.Update))]
class DebugPatch { ... }
```

### Manual Patching

```csharp
var harmony = new Harmony("com.example.mymod");
harmony.PatchAll(); // patch all annotated classes in assembly

// Or manually:
var original = AccessTools.Method(typeof(Player), "TakeDamage");
var prefix = new HarmonyMethod(typeof(MyPatch), nameof(MyPatch.Prefix));
harmony.Patch(original, prefix: prefix);

// Unpatch
harmony.UnpatchAll("com.example.mymod");
```

## Common Mistakes

1. **Forgetting `ref` on `__result`** -- Without `ref`, postfix modifications to `__result`
   are discarded. The compiler won't warn you.

2. **Wrong parameter names** -- `__instance` not `instance`. Triple underscore for fields:
   `___myField`. Typos silently produce `null`/default values.

3. **Transpiler fragility** -- IL patterns change between game versions. Always use
   `CodeMatcher` with semantic matches (method references) rather than raw opcode sequences.

4. **Patching generic methods** -- Use `AccessTools.Method` with explicit type parameters.
   `MakeGenericMethod` is your friend.

5. **Returning void in prefix** -- A prefix that returns `void` always runs the original.
   Return `bool` to control execution flow.

6. **Patch ordering** -- Multiple mods patching the same method run in load order. Use
   `[HarmonyPriority(Priority.High)]` or `[HarmonyBefore("other.mod.id")]` to control order.

7. **Static state in patches** -- Patch methods must be static. Use `__instance` or a
   side-channel (dictionary keyed on instance) for per-object state.

8. **Not unpatching in tests** -- Call `harmony.UnpatchAll(myId)` in cleanup to avoid
   test pollution.
