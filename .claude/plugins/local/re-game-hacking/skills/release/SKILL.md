---
name: release
description: "Build a release, bump version, generate changelog, and package a mod for distribution"
---

# /release — Release a Mod

When the user runs `/release`, prepare a mod for public release.

## Required Input
- **Version bump type**: major, minor, or patch (or explicit version number)

## Workflow

### Phase 1: Pre-Release Checks
1. Verify working directory is clean (`git status`).
2. Run a Release build and verify it succeeds.
3. Check for common issues (debug logging, hardcoded test values, TODO/FIXME).

### Phase 2: Version Bump
4. Detect version location based on framework:
   - `.csproj` → `<Version>` and `<AssemblyVersion>` properties
   - `mod_info.yaml` → `version:` field
   - `manifest.json` → `"Version"` field (SMAPI)
   - `build.gradle` → `version =` property
   - `mod.info` → version field (Zomboid)
5. Bump version according to semver rules.
6. Update all version locations consistently.

### Phase 3: Changelog
7. Generate changelog from git log since last tag.
8. Format as markdown with categories (Added, Changed, Fixed).
9. Prepend to CHANGELOG.md (create if doesn't exist).

### Phase 4: Package
10. Build in Release configuration.
11. Identify output files needed for distribution.
12. Report package contents and total size.

### Phase 5: Commit & Tag
13. Stage all version-bumped files + changelog.
14. Commit: `Release v<version>`
15. Create git tag: `v<version>`
16. Report: ready to publish, provide upload instructions for the relevant platform.
