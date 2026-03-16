# Minecraft (Java Edition)

## Engine Identification

- Java-based: runs on JVM, distributed as `.jar` files
- `client.jar` / `server.jar` — main game archives
- `.minecraft/versions/<version>/<version>.jar` — version-specific client
- `net.minecraft` package in decompiled source
- Mojang launcher or third-party launcher (MultiMC, Prism, etc.)
- `.minecraft/libraries/` — dependency jars

## Key Files and Binaries

| File/Dir | Purpose |
|-|-|
| `<version>.jar` | Obfuscated game bytecode |
| `<version>.json` | Version manifest (libraries, main class, mappings URL) |
| `client-<version>-mappings.txt` | Official Mojang mappings (ProGuard format) |
| `.minecraft/mods/` | Mod jar drop folder (Fabric/Forge) |
| `.minecraft/config/` | Mod configuration files |
| `.minecraft/logs/` | Game logs |

## Obfuscation and Mappings

Minecraft ships obfuscated — class/method/field names are replaced with
short identifiers. Multiple mapping sets exist to restore readable names:

| Mapping Set | Source | Used By |
|-|-|-|
| Mojang (Official) | Mojang (since 1.14.4) | Official reference |
| Yarn | FabricMC community | Fabric mods |
| SRG/MCP | Forge community (legacy) | Forge mods (older) |
| Mojmap | Mojang mappings adapted for Forge | Forge mods (newer) |
| Intermediary | FabricMC | Fabric stable ABI layer |

### Mapping Layers (Fabric)

```
Obfuscated (a.class, b(), c)
    -> Intermediary (net/minecraft/class_1234, method_5678, field_9012)
        -> Yarn (net/minecraft/entity/player/PlayerEntity, getHealth, health)
```

Intermediary names are stable across Minecraft versions (same class keeps same
intermediary name). Yarn names are human-readable but may change.

### Mapping Layers (Forge)

```
Obfuscated (a.class)
    -> SRG (net/minecraft/src/EntityPlayer, func_12345, field_67890)
        -> MCP (net/minecraft/entity/player/EntityPlayer, getHealth, health)
```

Newer Forge uses Mojang mappings directly.

## Decompilation Workflow

### Step 1: Get Mappings

**Fabric (Yarn):**
```bash
# Clone yarn repository for your MC version
git clone https://github.com/FabricMC/yarn.git
git checkout <mc-version>
```

**Mojang:**
- Download from URL in `<version>.json` manifest
- Or use `net.fabricmc:mapping-io` to convert between formats

### Step 2: Decompile

**Using JD-GUI:**
1. Open `<version>.jar` directly in JD-GUI
2. Names will be obfuscated — useful for quick browsing only

**Using Fabric toolchain (recommended):**
```bash
# Enigma (Fabric's mapping tool) can deobfuscate and decompile
# Or use the Fabric dev environment which handles this automatically
```

**Using CFR (better decompiler):**
```bash
java -jar cfr.jar client.jar --outputdir ./decompiled
```

**Using Vineflower (best quality):**
```bash
java -jar vineflower.jar client.jar ./decompiled
```

### Step 3: Apply Mappings

Fabric's Loom Gradle plugin handles this automatically in dev environments.
For manual work, use `tiny-remapper` or `mapping-io`.

## Modding Frameworks

### Fabric

Modern, lightweight modding framework:

**Setup:**
1. Use Fabric Template Mod generator
2. `gradle build` to compile
3. Drop resulting `.jar` in `.minecraft/mods/`

**Mod Structure:**
```
src/main/java/com/example/mymod/
    MyMod.java              # Mod entrypoint
src/main/resources/
    fabric.mod.json         # Mod metadata
    mymod.mixins.json       # Mixin configuration
```

**fabric.mod.json:**
```json
{
    "schemaVersion": 1,
    "id": "mymod",
    "version": "1.0.0",
    "entrypoints": {
        "main": ["com.example.mymod.MyMod"]
    },
    "depends": {
        "fabricloader": ">=0.14.0",
        "minecraft": "~1.20"
    }
}
```

**Entrypoint:**
```java
public class MyMod implements ModInitializer {
    @Override
    public void onInitialize() {
        // Mod initialization
    }
}
```

### Forge

Older, more established framework:
- Heavier API surface, more built-in event hooks
- Uses `@Mod` annotation for entrypoint
- Gradle-based setup similar to Fabric
- Better backward compatibility within major MC versions

### NeoForge

Fork of Forge (post-1.20.2):
- Community-driven continuation
- API diverging from Forge over time
- Migration path from Forge mods

## Mixin Framework

Mixins are the primary code modification mechanism for Fabric (and available in Forge):

```java
@Mixin(PlayerEntity.class)
public abstract class PlayerEntityMixin {

    @Inject(method = "tick", at = @At("HEAD"))
    private void onTick(CallbackInfo ci) {
        // Injected at the start of PlayerEntity.tick()
    }

    @Inject(method = "damage", at = @At("RETURN"), cancellable = true)
    private void onDamage(DamageSource source, float amount, CallbackInfoReturnable<Boolean> cir) {
        // Can cancel or modify return value
        if (amount > 100) cir.setReturnValue(false);
    }

    @Redirect(method = "jump", at = @At(value = "INVOKE",
        target = "Lnet/minecraft/entity/player/PlayerEntity;getJumpVelocity()F"))
    private float modifyJumpVelocity(PlayerEntity self) {
        return self.getJumpVelocity() * 2.0f; // Double jump height
    }
}
```

### Mixin Configuration

`mymod.mixins.json`:
```json
{
    "required": true,
    "package": "com.example.mymod.mixin",
    "compatibilityLevel": "JAVA_17",
    "mixins": ["PlayerEntityMixin"],
    "injectors": { "defaultRequire": 1 }
}
```

## Gotchas and Pitfalls

- **Mapping mismatches**: Using Yarn names in a Forge environment (or vice versa) causes crashes
- **Version specificity**: Most mods only work on one MC version — plan for porting
- **Mixin ordering**: Multiple mods injecting at the same point can conflict
- **Access Wideners** (Fabric) / **Access Transformers** (Forge): needed to access private members
- **Client vs Server**: Minecraft has logical sides — accessing client classes on server crashes
- **Mod compatibility**: Test with popular mods; Mixin conflicts are common
- **Intermediary stability**: Use intermediary names in production code, not Yarn
- **Java version**: MC 1.17+ requires Java 17+; older versions use Java 8
- **DataFixerUpper**: MC's data migration system adds complexity to NBT/data mods
- **Registries**: All blocks, items, entities must be registered — order and timing matter
- **Obfuscation at runtime**: In production, classes use SRG/intermediary names, not decompiled names
