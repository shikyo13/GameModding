# Unity Assets and Animation Pipeline

## Engine Identification (Asset Layer)

- `.assets` files in `<Game>_Data/` directory
- `.unity3d` or `.bundle` asset bundles
- `resources.assets` — default resource container
- `sharedassets0.assets`, `sharedassets1.assets`, ... per scene
- `StreamingAssets/` folder for raw files accessible at runtime

## Key Tools

| Tool | Purpose |
|-|-|
| AssetStudio | Extract textures, meshes, audio, sprites from .assets |
| UABE (Unity Asset Bundle Extractor) | Edit and replace individual assets |
| AssetRipper | Full project reconstruction from assets |
| kanimal-SE | ONI-specific kanim format conversion |

## Asset Extraction with AssetStudio

1. Open AssetStudio
2. File > Load File (single .assets) or Load Folder (entire Data dir)
3. Use Asset List tab to browse by type (Texture2D, Sprite, AudioClip, etc.)
4. Filter by name in the search bar
5. Export selected: Export > Selected Assets (or Filtered Assets)

### Export Tips
- Textures export as .png by default
- Sprites export with correct crop from atlas
- AudioClip exports vary: .ogg, .wav, .fsb depending on compression
- AnimationClip exports as .anim (Unity YAML) — not directly useful for modding

## Kanim Format (Oxygen Not Included)

ONI uses a custom animation format called **kanim** consisting of three files:

| File | Content |
|-|-|
| `<name>_anim.bytes` | Animation keyframe data (which frames, timing, transforms) |
| `<name>_build.bytes` | Build data (symbol names, frame indices, pivot points) |
| `<name>_0.png` | Sprite atlas texture (all frames packed into one image) |

### How Kanim Works

- A **build** defines named symbols (body parts, layers)
- Each symbol has one or more **frames** (sprite regions in the atlas)
- An **anim** defines named animations with frame sequences
- Each animation frame references symbols and applies transforms
- The game assembles the final image by layering transformed symbols

### Extracting Kanims

From game assets:
1. Use AssetStudio to find `*_anim`, `*_build` TextAsset entries
2. Export the .bytes files
3. Find matching `*_0` Texture2D and export as .png
4. Use kanimal-SE to convert to Spriter format for editing

### kanimal-SE Conversion

```bash
# Convert kanim to Spriter project
kanimal-cli kanim-to-scml --output ./spriter_project input_anim.bytes input_build.bytes input_0.png

# Convert Spriter project back to kanim
kanimal-cli scml-to-kanim --output ./kanim_output project.scml
```

## Spriter Workflow for ONI Animations

### Setting Up a Spriter Project

1. Convert existing kanim to Spriter using kanimal-SE (or start from template)
2. Open the `.scml` file in Spriter
3. Each symbol from the build becomes a sprite in Spriter
4. Animations map to Spriter animations

### Critical Rules for ONI-Compatible Spriter Projects

**These rules are non-negotiable. Violating them produces broken kanims.**

1. **Never use bones** — ONI kanim format does not support skeletal animation.
   Spriter bones will be silently ignored or cause conversion errors.

2. **Never use non-linear tweens** — Only use instant or linear interpolation.
   Bezier curves, cubic, and other easing types cannot be represented in kanim.

3. **Never resize sprites within the bounding box** — Scaling transforms are
   applied to the entire symbol, not the sprite content. If you need a different
   size, edit the source PNG.

4. **33ms frame duration with snapping** — ONI runs animations at ~30fps.
   Set Spriter's snapping to 33ms intervals. Frames at non-33ms boundaries
   will be quantized and may produce visual glitches.

5. **Even static graphics need anim.bytes** — A building or item that never
   animates still requires a valid anim.bytes file with at least one animation
   containing one frame. Use the "default" or "ui" animation name.

6. **Symbol naming matters** — The game references symbols by exact name.
   If replacing an existing entity, match the original symbol names precisely.

### Spriter Project Checklist

- [ ] No bones in any animation
- [ ] All tweens set to Linear or Instant
- [ ] Frame snapping at 33ms
- [ ] No sprite scaling (only position and rotation)
- [ ] At least one animation defined
- [ ] Symbol names match expected values

## Mod Folder Structure for Animations

When adding custom animations to an ONI mod:

```
<mod>/
  anim/
    assets/
      <animname>/
        <animname>_anim.bytes
        <animname>_build.bytes
        <animname>_0.png
```

Example:
```
MyBuildingMod/
  anim/
    assets/
      my_custom_building/
        my_custom_building_anim.bytes
        my_custom_building_build.bytes
        my_custom_building_0.png
```

### Important Notes on Mod Assets

- The folder name under `assets/` must match the anim name prefix
- The `_0` suffix on the PNG is required (supports `_0`, `_1`, etc. for multi-atlas)
- Files must be actual kanim binary format, not raw images or text
- The game loads mod anims at startup — missing files cause silent failures
- Use `Assets.GetAnim("animname")` in code to reference your custom animation
- Multiple mods can add anims but cannot override base game anims without patches

## Gotchas and Pitfalls

- AssetStudio versions matter: older versions can't read newer Unity asset formats
- Large atlas textures (4096x4096+) may fail to export in some tools
- Asset bundles may use LZMA or LZ4 compression — ensure your tool handles both
- Replacing assets in .assets files directly is fragile; prefer mod frameworks
- ONI kanim format has changed between game versions — use matching kanimal-SE
- Spriter 1 vs Spriter 2: ONI tooling targets Spriter 1 (.scml), not Spriter 2
- PNG color space must be sRGB — linear color space textures render incorrectly
- Anim.bytes with zero animations will crash the game's KAnimController
