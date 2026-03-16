---
name: new-mod
description: "Scaffold a new mod within a game folder — creates project file, manifest, entry point, and build config for the detected engine/framework"
---

# /new-mod — Scaffold New Mod

When the user runs `/new-mod`, create a new mod project within the current game folder.

## Required Input
- **Mod name**: Name for the new mod
- **Description**: One-line description of what it does

## Workflow

### Phase 1: Detect Context
1. Identify current game folder from working directory.
2. Read the game's CLAUDE.md to determine engine and framework.
3. If unable to detect, ask the user which framework to use.

### Phase 2: Scaffold (engine-dependent)

**Unity Mono (UserMod2 — ONI):**
- Create `<ModName>/` folder
- Create `<ModName>/<ModName>.csproj` with game DLL references
- Create `<ModName>/<ModName>Mod.cs` with UserMod2 entry point
- Create `<ModName>/mod_info.yaml`
- Create `<ModName>/mod.yaml` (title, description, author)

**Unity Mono (BepInEx — Subnautica, RimWorld):**
- Create `<ModName>/` folder
- Create `<ModName>/<ModName>.csproj` with BepInEx + game DLL references
- Create `<ModName>/Plugin.cs` with `[BepInPlugin]` entry point
- Add CopyToPlugins build target if pattern exists in sibling mods

**Java (NeoForge/Fabric):**
- Guide user through `./gradlew init` or scaffold manually
- Create main mod class with `@Mod` annotation

**.NET (SMAPI):**
- Create `<ModName>/` folder
- Create `<ModName>/<ModName>.csproj` with SMAPI references
- Create `<ModName>/ModEntry.cs` with IModHelper entry point
- Create `<ModName>/manifest.json` (SMAPI mod manifest)

**Lua (Zomboid):**
- Create `<ModName>/` folder
- Create `<ModName>/mod.info` (mod metadata)
- Create `<ModName>/media/lua/client/` or `server/` starter script

### Phase 3: Verify & Report
4. Verify the project builds (if compilable).
5. Report what was created and next steps.
