# Project Zomboid

## Engine Identification

- Custom Java engine (not Unity, not LibGDX)
- `ProjectZomboid64.exe` / `ProjectZomboid32.exe` launcher
- `zombie/` package in Java classes (decompiled)
- `java/` and `zombie/` directories in game install
- Lua scripts in `media/lua/` directory
- `media/` folder containing game data, maps, scripts

## Key Files and Binaries

| File/Dir | Purpose |
|-|-|
| `ProjectZomboid64.exe` | Native launcher (invokes JVM) |
| `zombie/` | Core Java classes (compiled .class files) |
| `media/lua/` | Lua game scripts (primary modding target) |
| `media/scripts/` | Item/recipe/vehicle definitions |
| `media/maps/` | Map data |
| `media/textures/` | Game textures |
| `media/sound/` | Audio files |
| `media/clothing/` | Clothing definitions |
| `Zomboid/mods/` | Installed mods directory (user home) |
| `Zomboid/Logs/` | Game logs |

## Lua Modding API

### Overview

Project Zomboid's primary modding interface is Lua. The game exposes Java objects
to Lua via a bridge, allowing mods to hook into game events, modify behaviors,
and add content without touching Java code.

### Mod Structure

```
MyMod/
    mod.info                  # Mod metadata
    media/
        lua/
            client/           # Client-side scripts
                MyClientMod.lua
            server/           # Server-side scripts
                MyServerMod.lua
            shared/           # Shared (both sides)
                MySharedMod.lua
        scripts/              # Item/recipe definitions
            items_mymod.txt
        textures/             # Custom textures
            Item_MyItem.png
    poster.png                # Workshop thumbnail
```

### mod.info Format

```
name=My Mod Name
poster=poster.png
id=MyModID
description=Description of the mod
url=https://example.com
modversion=1.0
require=OtherModID
```

### Event System

```lua
-- Hook into game events
Events.OnGameBoot.Add(function()
    print("Game is booting!")
end)

Events.OnPlayerUpdate.Add(function(player)
    -- Runs every tick for each player
end)

Events.OnCreatePlayer.Add(function(playerIndex, player)
    -- Player created
end)

Events.EveryOneMinute.Add(function()
    -- Timer event
end)

Events.OnFillInventoryObjectContextMenu.Add(function(playerIndex, context, items)
    -- Add custom right-click menu options
end)
```

### Common API Functions

```lua
-- Get the player
local player = getPlayer()
local players = getOnlinePlayers()  -- multiplayer

-- Inventory manipulation
player:getInventory():AddItem("Base.Hammer")
local items = player:getInventory():getItems()

-- World interaction
local square = getCell():getGridSquare(x, y, z)
local objects = square:getObjects()

-- Item definitions
local itemDef = ScriptManager.instance:getItem("Base.Hammer")

-- Spawning
local zombie = createZombie(x, y, z, nil, 0)
```

### Script Definitions

Items, recipes, and other data are defined in script files (`media/scripts/`):

```
module MyMod {
    item MyItem {
        DisplayName = My Custom Item,
        Icon = MyItem,
        Weight = 1.0,
        Type = Normal,
        DisplayCategory = Junk,
        Tooltip = Tooltip_MyItem,
    }

    recipe Open My Item {
        MyMod.MyItem,
        Result: Base.Plank=2,
        Time: 50.0,
        Category: General,
    }
}
```

## Java Decompilation for Core Patches

### When Lua Isn't Enough

Some modifications require patching the Java core:
- Changing hardcoded values
- Modifying rendering pipeline
- Fixing engine bugs
- Adding new Java-level event hooks

### Decompilation Workflow

1. **Locate class files**: `<GameDir>/zombie/` contains compiled .class files
2. **Decompile with CFR or JD-GUI**:
   ```bash
   java -jar cfr.jar zombie/characters/IsoPlayer.class --outputdir ./decompiled
   ```
3. **For bulk decompilation**, jar the classes first:
   ```bash
   jar cf zomboid-classes.jar zombie/
   java -jar cfr.jar zomboid-classes.jar --outputdir ./decompiled
   ```
4. **Browse with JD-GUI** for interactive exploration

### Key Java Packages

| Package | Content |
|-|-|
| `zombie.characters` | Player, NPC, zombie classes |
| `zombie.inventory` | Inventory system |
| `zombie.iso` | Isometric world/grid system |
| `zombie.network` | Multiplayer networking |
| `zombie.vehicles` | Vehicle system |
| `zombie.ui` | UI framework |
| `zombie.core` | Core engine classes |
| `zombie.scripting` | Script parser (item/recipe definitions) |

### Applying Java Patches

**Method 1: Classfile replacement**
- Decompile, modify, recompile, replace .class file
- Fragile — breaks on any game update
- Not recommended for distribution

**Method 2: Java agent**
- Use a Java agent to transform classes at load time
- More resilient but complex
- Can use ASM or Javassist for bytecode manipulation

**Method 3: Lua override**
- Many Java methods are exposed to Lua
- Override Lua-accessible behavior without touching Java
- Preferred approach when possible

## Workshop Publishing

### Steam Workshop Structure

1. Create your mod in `Zomboid/mods/YourModID/`
2. Test thoroughly in single-player and multiplayer
3. Use the in-game Workshop upload tool or:

### Manual Upload

1. Ensure `mod.info` is complete with correct `id`
2. Include a `poster.png` (256x256 recommended)
3. Use Steam Workshop uploader or Zomboid's built-in tool
4. Set visibility, tags, and description on Workshop page

### Workshop Categories

- Maps, Mods, or Modpacks
- Tag appropriately: Gameplay, Items, UI, Building, Vehicles, etc.

### Multiplayer Considerations

- Server mods go in server's `Zomboid/mods/`
- Clients auto-download Workshop mods if server requires them
- `client/` scripts only run on clients, `server/` only on server
- `shared/` scripts must be identical on client and server
- Lua sandbox restricts certain operations on multiplayer

## Gotchas and Pitfalls

- **Lua sandbox**: Multiplayer servers restrict file I/O and `os` library access
- **Load order**: Mods load alphabetically by ID unless dependencies specified
- **Global namespace pollution**: All Lua mods share one global state — use local variables
- **Event removal**: Cannot easily remove another mod's event handler
- **Java version**: PZ uses a bundled JVM — don't assume system Java
- **Save compatibility**: Adding/removing items can corrupt saves if not handled
- **Client/server split**: Running client code on server (or vice versa) causes desyncs
- **Mod conflicts**: Multiple mods overriding the same function — last one wins
- **Texture naming**: Textures must follow exact naming conventions (`Item_` prefix, etc.)
- **Map modding**: Requires TileZed/WorldEd tools, separate from Lua modding
- **Build versions**: Game updates frequently during Early Access — mods break often
- **Translation**: Use `Translate/EN/` folder for translatable strings
- **Require keyword**: `require()` in Lua loads shared modules — path resolution is tricky
