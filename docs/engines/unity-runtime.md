# Unity Runtime Inspection and Debugging

## Overview

Runtime inspection tools let you explore Unity's scene graph, inspect GameObjects
and Components, modify values live, and execute C# code — all while the game runs.
This is invaluable for understanding undocumented game systems before writing mods.

## UnityExplorer

### What It Is

[UnityExplorer](https://github.com/sinai-dev/UnityExplorer) is a BepInEx plugin
that provides a full in-game inspection UI. It works with both Mono and IL2CPP
Unity games.

### Installation

**BepInEx 5 (Mono):**
1. Install BepInEx 5 (see unity-mono.md)
2. Download `UnityExplorer.BepInEx5.Mono.zip` from releases
3. Extract `UnityExplorer.BepInEx5.Mono.dll` to `BepInEx/plugins/`

**BepInEx 6 (IL2CPP):**
1. Install BepInEx 6 Bleeding Edge
2. Download `UnityExplorer.BepInEx.IL2CPP.zip`
3. Extract to `BepInEx/plugins/`

**MelonLoader:**
- Use `UnityExplorer.MelonLoader.Mono.dll` or `.IL2CPP.dll`
- Place in `Mods/` folder

**Standalone:**
- Inject via doorstop without BepInEx (advanced, rarely needed)

### First Launch

1. Start the game with UnityExplorer installed
2. Press **F7** to toggle the UnityExplorer UI (default hotkey)
3. The main panel appears with tabs across the top

### Key Panels

| Panel | Purpose |
|-|-|
| Object Explorer | Browse scene hierarchy and DontDestroyOnLoad objects |
| Inspector | View/edit component fields, properties, methods |
| C# Console | Execute arbitrary C# at runtime |
| Mouse Inspector | Click on game objects to inspect them |
| Clipboard | Store references for use across inspections |
| Options | Configure hotkeys, colors, behavior |

## GameObject Inspection

### Scene Hierarchy

1. Open Object Explorer tab
2. Select a scene from the dropdown (or "DontDestroyOnLoad")
3. Navigate the tree — same hierarchy as Unity Editor
4. Click a GameObject to open it in Inspector

### Inspector Features

- **Fields and Properties**: View all serialized and non-serialized values
- **Edit values**: Click on a value to modify it live
- **Components**: List all components on the GameObject
- **Methods**: Call any method with the "Invoke" button
- **References**: Click object references to inspect them recursively

### Mouse Inspector

1. Click "Mouse Inspector" button (or press hotkey)
2. Select mode: World or UI
3. Hover over game elements — the inspector highlights them
4. Click to select and inspect the GameObject under cursor

## Component Modification

### Live Value Editing

In the Inspector panel:
- Primitive types (int, float, bool, string): click and type new value
- Enums: dropdown selection
- Vectors: edit individual components (x, y, z)
- Colors: edit RGBA values
- Object references: click to inspect, or set to null

### Transform Manipulation

Every GameObject has a Transform (or RectTransform for UI):
- Position: modify world/local position
- Rotation: modify euler angles
- Scale: modify local scale
- Parent: change hierarchy placement

### Enabling/Disabling

- Toggle GameObject active state via checkbox
- Enable/disable individual components
- Useful for isolating visual elements or disabling game systems temporarily

## In-Game C# Console

### Basic Usage

The C# Console tab provides a REPL environment:

```csharp
// Find all objects of a type
var cameras = GameObject.FindObjectsOfType<Camera>();
Log(cameras.Length);

// Access a specific singleton
var gameManager = GameManager.Instance;
Log(gameManager.currentState);

// Modify a value
PlayerController.Instance.moveSpeed = 20f;

// Call a method
SomeSystem.Instance.DebugReset();
```

### Tips

- `Log(obj)` prints to the console output
- Use `using` directives at the top for namespaces
- The console has access to all loaded assemblies
- Tab completion works for type and member names
- Multi-line scripts are supported
- Previous commands are accessible via history

### Useful One-Liners

```csharp
// List all active scenes
for (int i = 0; i < SceneManager.sceneCount; i++)
    Log(SceneManager.GetSceneAt(i).name);

// Find objects by name
var obj = GameObject.Find("ExactName");

// Find inactive objects (Find won't return these)
var all = Resources.FindObjectsOfTypeAll<SomeComponent>();

// Dump component list for a GameObject
foreach (var c in targetObj.GetComponents<Component>())
    Log(c.GetType().FullName);

// Time scale manipulation
Time.timeScale = 0.1f;  // slow motion
Time.timeScale = 0f;    // pause
Time.timeScale = 1f;    // normal
```

## Debug Hotkeys and Common Shortcuts

### UnityExplorer Defaults

| Key | Action |
|-|-|
| F7 | Toggle UnityExplorer UI |
| F8 | Toggle Mouse Inspector |

### Useful Runtime Debug Techniques

- **Time.timeScale = 0**: Freeze the game while inspecting
- **Camera manipulation**: Move/rotate cameras to see hidden geometry
- **Layer toggling**: Disable rendering layers to isolate elements
- **Force-invoke methods**: Call initialization or debug methods manually

## Integration with Mod Development

### Workflow

1. Run game with UnityExplorer to explore unknown systems
2. Identify target classes, fields, methods
3. Cross-reference with decompiled source (ilspycmd / dnSpy)
4. Write Harmony patches targeting the identified members
5. Test with UnityExplorer's console before committing to code

### Inspecting Mod Effects

- After loading your BepInEx plugin, check the console for errors
- Use Inspector to verify your patches modified the expected values
- Use C# Console to call your mod's public methods for testing

## Gotchas and Pitfalls

- UnityExplorer can cause lag in complex scenes — disable when not needed
- Some games detect and block UnityExplorer (anti-cheat)
- IL2CPP builds may not expose all members through UnityExplorer
- Modifying values in Inspector doesn't persist across game sessions
- The C# Console uses Mono's evaluator — some C# features are unsupported
- Heavy use of FindObjectsOfType can cause frame hitches
- DontDestroyOnLoad objects persist across scene loads — check both tabs
- Some singletons are lazily initialized — accessing too early causes null refs
