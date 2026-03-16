---
name: workshop-prep
description: "Generate workshop description, preview image checklist, tags, and publishing materials for mod marketplace listings"
---

# /workshop-prep — Prepare Workshop Listing

When the user runs `/workshop-prep`, generate all materials needed to publish a mod.

## Required Input
- **Mod name**: Which mod to prepare (auto-detect from working directory if single mod)

## Workflow

### Phase 1: Analyze Mod
1. Read the mod's source code, manifest, and any existing documentation.
2. Identify features, configuration options, and dependencies.
3. Determine the target platform (Steam Workshop, Nexus Mods, CurseForge, Thunderstore).

### Phase 2: Generate Workshop Description
4. Write an engaging description following platform best practices:
   - Hook line (what it does in one sentence)
   - Feature list (bulleted, scannable)
   - Installation instructions
   - Configuration guide (if configurable)
   - Compatibility notes (game version, known conflicts)
   - Credits and license
5. Format for the target platform (Steam uses BBCode, Nexus uses markdown).

### Phase 3: Preview Image Checklist
6. Recommend preview image requirements:
   - Dimensions per platform (Steam: 512x512, Nexus: 1280x720, etc.)
   - Content suggestions (in-game screenshot, logo, feature comparison)

### Phase 4: Tags & Discoverability
7. Suggest tags/categories based on mod functionality.
8. Recommend title formatting for search optimization.
9. Suggest related mods to reference for cross-promotion.

### Phase 5: Publishing Checklist
10. Present final checklist:
    - [ ] Description written and formatted
    - [ ] Preview image(s) prepared
    - [ ] Version number is correct
    - [ ] Changelog is current
    - [ ] License file included
    - [ ] Dependencies documented
    - [ ] Tested on latest game version
