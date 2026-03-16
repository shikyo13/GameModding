# Frida for Game Hacking

## Overview

Frida is a dynamic instrumentation toolkit that lets you inject JavaScript into running
processes. For game modding, it enables real-time function hooking, memory scanning,
and RPC communication without modifying game files.

## Attach vs Spawn

### Attach to Running Process

```bash
frida -p <PID> -l script.js
frida -n "Game.exe" -l script.js
```

Attaches to an already-running process. The game is briefly paused while the agent loads.

### Spawn and Instrument

```bash
frida -f "C:/Games/MyGame/Game.exe" -l script.js --no-pause
frida -f "Game.exe" -l script.js   # if on PATH
```

Spawns the process in suspended state, injects Frida, then resumes. Use this when you
need to hook initialization code that runs before you could attach.

The `--no-pause` flag auto-resumes after injection. Without it, call `%resume` in the
REPL or `device.resume(pid)` from Python.

## Script Structure

```javascript
// Runs when script is loaded
console.log("[*] Script loaded");

// Wait for a module to be loaded (useful with spawn)
Module.ensureInitialized("GameLogic.dll");

// Get module base
const base = Module.findBaseAddress("GameLogic.dll");
console.log("[*] GameLogic.dll base:", base);

// Script unload handler
Script.bindExitHandler(() => {
    console.log("[*] Cleaning up...");
});
```

## Interceptor.attach

The primary hooking mechanism. Intercepts calls to native functions.

```javascript
const takeDamage = Module.findExportByName("GameLogic.dll", "Player_TakeDamage");

Interceptor.attach(takeDamage, {
    onEnter(args) {
        // args[0] = this pointer, args[1] = damage amount (float)
        console.log("[*] TakeDamage called, damage:", args[1].toInt32());

        // Modify argument: set damage to 0
        args[1] = ptr(0);

        // Save for use in onLeave
        this.originalDamage = args[1].toInt32();
    },
    onLeave(retval) {
        console.log("[*] TakeDamage returned:", retval.toInt32());
        // Modify return value
        retval.replace(ptr(999));
    }
});
```

## Interceptor.replace

Completely replaces a function implementation:

```javascript
const isAdmin = Module.findExportByName("GameLogic.dll", "CheckAdmin");

Interceptor.replace(isAdmin, new NativeCallback(() => {
    return 1; // always return true
}, 'int', []));
```

## NativeFunction

Call native functions from JavaScript:

```javascript
const addGold = new NativeFunction(
    Module.findExportByName("GameLogic.dll", "AddGold"),
    'void',           // return type
    ['pointer', 'int'] // arg types: player ptr, amount
);

// Call it
const playerPtr = ptr("0x12345678");
addGold(playerPtr, 99999);
```

## Memory Operations

### Read/Write

```javascript
const addr = ptr("0x00FF1234");

// Read
const health = addr.readFloat();
const name = addr.readUtf16String();
const bytes = addr.readByteArray(16);

// Write
addr.writeFloat(100.0);
addr.writeUtf16String("Hacker");

// Pointer arithmetic
const next = addr.add(0x10);
const deref = addr.readPointer(); // follow pointer
```

### Memory.scan

Scan for byte patterns in memory:

```javascript
const module = Process.findModuleByName("GameLogic.dll");

Memory.scan(module.base, module.size, "48 89 5C 24 08 57 48 83 EC 20", {
    onMatch(address, size) {
        console.log("[*] Pattern found at:", address);
    },
    onComplete() {
        console.log("[*] Scan complete");
    }
});

// Synchronous version
const results = Memory.scanSync(module.base, module.size, "48 8B ?? ?? ?? ?? ?? 48 85 C0");
```

Wildcards use `??` for unknown bytes.

## RPC Methods

Expose functions from the Frida script to the Python host:

```javascript
// In the Frida script
rpc.exports = {
    getHealth() {
        return ptr("0x00FF1234").readFloat();
    },
    setHealth(value) {
        ptr("0x00FF1234").writeFloat(value);
    },
    scanForValue(target) {
        const results = Memory.scanSync(base, size, intToPattern(target));
        return results.map(r => r.address.toString());
    }
};
```

```python
# In the Python host
import frida

device = frida.get_local_device()
session = device.attach("Game.exe")
script = session.create_script(open("script.js").read())
script.load()

api = script.exports_sync

health = api.get_health()
print(f"Current health: {health}")

api.set_health(100.0)
```

## Common Game Hacking Patterns

### Finding Functions by Signature

```javascript
function findBySignature(moduleName, signature) {
    const mod = Process.findModuleByName(moduleName);
    const results = Memory.scanSync(mod.base, mod.size, signature);
    if (results.length === 0) throw new Error("Signature not found");
    return results[0].address;
}

const fn = findBySignature("Game.exe", "55 8B EC 83 EC ?? 53 56 57 8B F1");
```

### Hooking Virtual Table Methods

```javascript
function hookVtableEntry(objectAddr, vtableIndex) {
    const vtable = objectAddr.readPointer();
    const methodPtr = vtable.add(vtableIndex * Process.pointerSize).readPointer();
    Interceptor.attach(methodPtr, { onEnter(args) { /* ... */ } });
    return methodPtr;
}
```

### Monitoring All Calls to a Module Export

```javascript
const exports = Module.enumerateExports("GameLogic.dll");
exports.filter(e => e.type === "function").forEach(exp => {
    Interceptor.attach(exp.address, {
        onEnter() {
            console.log(`[*] ${exp.name} called`);
        }
    });
});
```

## Tips

- Use `Process.enumerateModules()` to discover loaded DLLs at runtime
- `Module.findExportByName(null, "func")` searches all modules
- Frida's JavaScript engine is V8-based; you get modern JS features
- Use `hexdump(addr, { length: 64 })` for quick memory visualization
- For Unity IL2CPP games, combine with il2cpp-bridge or dump metadata first
- Detach cleanly with `session.detach()` to avoid crashes
- Use `--runtime=v8` explicitly if you need specific V8 features
