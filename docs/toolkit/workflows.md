# Workflows — End-to-End Recipes

Step-by-step procedures for common game modding scenarios. Each recipe specifies
which skill or agent to use at each step.

---

## Recipe 1: New Unity Mono Game to First Harmony Mod

**Scenario:** You have a Unity game using Mono (not IL2CPP) and want to create
your first mod that patches game behavior.

**Time estimate:** 30-60 minutes for a simple patch.

### Steps

1. **Create project**
   - Skill: `/new-project`
   - Input: game name, path to game directory
   - Verify: engine detected as "Unity", Mono runtime confirmed

2. **Install BepInEx**
   - Manual: download BepInEx 5.x, extract to game root
   - Verify: `BepInEx/` folder exists alongside game executable
   - Run game once to generate `BepInEx/config/` and plugin folders

3. **Locate assemblies**
   - Skill: `/analyze-game`
   - Look for `[GameName]_Data/Managed/Assembly-CSharp.dll`
   - Note any additional game assemblies (Assembly-CSharp-firstpass, etc.)

4. **Analyze target assembly**
   - Skill: `/analyze-assembly` on Assembly-CSharp.dll
   - Agent: `re-analyst` if you need to explore broadly
   - Identify the namespace and class for your target system

5. **Find hook points**
   - Skill: `/find-hooks` with your target area (e.g., "player health")
   - Review candidates: prefer virtual methods, Awake/Start, Update patterns
   - Save findings with notes on patch strategy

6. **Write the patch**
   - Skill: `/generate-mod` with framework=BepInEx+Harmony
   - Or: `/generate-patch` for just the Harmony patch code
   - Agent: `mod-builder` if you need complex multi-patch logic

7. **Build and test**
   - Compile the generated .cs files against game assemblies
   - Place output DLL in `BepInEx/plugins/`
   - Run game, check BepInEx log for patch application

8. **Iterate**
   - Check `BepInEx/LogOutput.log` for errors
   - Use `re-analyst` to dig deeper if behavior isn't as expected
   - Regenerate patch with adjusted parameters

---

## Recipe 2: New Unity IL2CPP Game to First Mod

**Scenario:** The game uses IL2CPP compilation. No managed DLLs are directly
available — you need to dump metadata first.

**Time estimate:** 45-90 minutes (extra time for IL2CPP pipeline).

### Steps

1. **Create project**
   - Skill: `/new-project`
   - Verify: engine detected as "Unity", IL2CPP runtime confirmed
   - Look for `GameAssembly.dll` and `global-metadata.dat`

2. **Dump IL2CPP metadata**
   - Skill: `/il2cpp-dump`
   - Input: path to `GameAssembly.dll` and `global-metadata.dat`
   - Output: `dump.cs` with reconstructed type definitions

3. **Search the dump**
   - Agent: `re-analyst` to explore the dump for target systems
   - Use `search_il2cpp_dump` with keywords like "Health", "Damage", "Player"
   - Identify target classes and method signatures

4. **Install mod loader**
   - For IL2CPP: install BepInEx 6.x (IL2CPP build) or MelonLoader
   - Extract to game root, run once to initialize

5. **Find hook points**
   - Skill: `/find-hooks` using dump data
   - Note: method addresses come from the dump, not live assemblies
   - Prefer methods with clear signatures (fewer generics/structs)

6. **Validate addresses at runtime** (optional but recommended)
   - Agent: `memory-hunter`
   - Use Frida to attach and verify method addresses match dump
   - Set breakpoints to confirm methods are called when expected

7. **Generate mod**
   - Skill: `/generate-mod` with framework=BepInEx6-IL2CPP or MelonLoader
   - IL2CPP mods use unhollowed assemblies for type references
   - Agent: `mod-builder` for complex scenarios

8. **Build and test**
   - Compile against unhollowed/interop assemblies
   - Place in appropriate plugins folder
   - Check logs for successful hook registration

---

## Recipe 3: Game Updated, Mod Broke — Fix It

**Scenario:** A game update changed internal code. Your existing mod throws errors
or doesn't apply correctly.

**Time estimate:** 15-60 minutes depending on severity.

### Steps

1. **Diagnose the failure**
   - Read the mod loader log (BepInEx/LogOutput.log, MelonLoader/Latest.log)
   - Common errors: MissingMethodException, TypeLoadException, NullReference
   - Identify which patches failed and why

2. **Re-analyze the updated assembly**
   - Skill: `/analyze-assembly` on the new Assembly-CSharp.dll
   - For IL2CPP: re-run `/il2cpp-dump` to get updated metadata

3. **Compare with previous analysis**
   - Agent: `re-analyst`
   - Search for the original target methods by name
   - Check if: method renamed, signature changed, method moved, class restructured

4. **Find replacement hooks**
   - If method was renamed: search by similar functionality keywords
   - If signature changed: update parameter types in patch
   - If method was removed: use `/find-hooks` to locate alternative
   - If class was restructured: trace xrefs to find new location

5. **Update the mod**
   - For simple signature changes: edit the patch manually
   - For major restructuring: `/generate-patch` with new target
   - Agent: `mod-builder` if multiple patches need updating

6. **For AOB/signature-based mods**
   - Agent: `memory-hunter`
   - Re-scan with original AOB pattern — if it fails, the bytes changed
   - Disassemble the area around the old address to find shifted code
   - Generate a new signature with `/aob-scan`

7. **Test thoroughly**
   - Verify all patched methods are reached during gameplay
   - Check for subtle behavior changes (different argument values, timing)
   - Update version compatibility notes in the mod

---

## Recipe 4: Find and Modify a Runtime Value

**Scenario:** You want to find and change a specific game value (health, currency,
speed) at runtime without creating a permanent mod.

**Time estimate:** 10-30 minutes.

### Steps

1. **Attach to process**
   - Agent: `memory-hunter`
   - Ensure Cheat Engine or Frida can see the game process
   - Note the current in-game value you want to find

2. **Initial scan**
   - Skill: `/scan-value` with current value and expected type (int32, float, double)
   - If value is displayed as "100/100", try both integer 100 and float 100.0
   - For unknown value types, start with 4-byte scan

3. **Narrow results**
   - Change the value in-game (take damage, spend gold, etc.)
   - Skill: `/narrow-scan` with the new value
   - Repeat until you have fewer than 10 candidates

4. **Identify the real address**
   - Write a test value to each candidate
   - The correct address is the one that changes the displayed game value
   - Verify by changing the value in-game again and reading back

5. **Find what accesses the address**
   - Set a data breakpoint on the address
   - Skill: `/watch-address` to see what code reads/writes it
   - This reveals the game function responsible for the value

6. **Build a pointer chain** (for persistence across restarts)
   - Skill: `/find-pointer` from the dynamic address
   - Verify the chain resolves correctly after restarting the game
   - Save the chain as a finding for later use

7. **Optionally make it permanent**
   - Use findings to create a trainer: `/generate-trainer`
   - Or create a Harmony patch on the writing code: `/generate-patch`
   - Or write a Frida script for runtime interception: `/generate-script`

---

## Recipe 5: Build a Comprehensive Trainer

**Scenario:** You want a multi-feature trainer that modifies several game values
and behaviors (god mode, infinite ammo, speed hack, etc.).

**Time estimate:** 2-4 hours for a full-featured trainer.

### Steps

1. **Plan features**
   - List desired features: god mode, infinite ammo, infinite currency, speed multiplier, etc.
   - Categorize each: value modification (memory) vs behavior modification (code patch)

2. **Set up the project**
   - Skill: `/new-project`
   - Skill: `/analyze-game` to understand the game structure

3. **Find value-based features**
   - Agent: `memory-hunter` for each value target
   - Follow Recipe 4 for each value: health, ammo, currency, etc.
   - Build pointer chains for every address
   - Save all findings with clear labels

4. **Find code-based features**
   - Agent: `re-analyst` for behavioral changes
   - God mode: find the damage application function, plan to NOP or return early
   - Speed hack: find the movement speed multiplier in the update loop
   - No cooldowns: find cooldown timer checks
   - Save hook points as findings

5. **Identify toggle mechanisms**
   - For each feature, determine how to enable/disable:
     - Value freezing (write the value every frame)
     - Code patching (NOP/restore original bytes)
     - Function hooking (intercept and modify parameters)

6. **Generate the trainer**
   - Skill: `/generate-trainer` with all findings
   - This produces a Cheat Engine table with hotkey-toggled features
   - Or: Agent `mod-builder` for a standalone executable trainer

7. **Generate companion scripts** (optional)
   - `/generate-script` for Frida-based features that need complex logic
   - `/generate-patch` for Harmony-based features in Mono games

8. **Build the UI** (for standalone trainers)
   - Agent: `mod-builder` for a standalone loader with GUI
   - Include hotkey bindings, feature status display, process attachment

9. **Test each feature independently**
   - Enable one feature at a time, verify it works
   - Test feature combinations for conflicts
   - Verify disable/toggle correctly restores original state

10. **Polish and package**
    - Add version detection to warn about game updates
    - Include instructions for end users
    - Export findings for future reference: `/export-findings`

---

## Quick Reference: Which Tool for Which Task

| Task | First try (skill) | If you need more (agent) |
|-|-|-|
| Understand game structure | `/analyze-game` | `re-analyst` |
| Find a method to patch | `/find-hooks` | `re-analyst` |
| Find a memory address | `/scan-value` + `/narrow-scan` | `memory-hunter` |
| Generate mod code | `/generate-mod` | `mod-builder` |
| Browse game assets | `/analyze-game` | `asset-explorer` |
| Fix a broken mod | `/analyze-assembly` | `re-analyst` + `mod-builder` |
| Build a trainer | `/generate-trainer` | `memory-hunter` + `mod-builder` |
