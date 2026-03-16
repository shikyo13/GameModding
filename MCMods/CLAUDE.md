# Parent workspace: See `../CLAUDE.md` for shared RE toolkit, engine docs, and modding conventions.

# MC Mods — Minecraft Modding

Java mods for Minecraft using NeoForge/Fabric. See `../docs/engines/java-minecraft.md` for engine reference.

## Game Folders

| Folder | Mod | Framework |
|-|-|-|
| Quantum Flux/ | Quantum Flux (energy/tech mod) | NeoForge 1.21.1 |

## Build & Deploy

- Build: `cd "Quantum Flux" && ./gradlew build`
- Deploy: Auto-copies to ATM10SKY instance via Gradle task
- Game: Minecraft via CurseForge launcher

## Conventions

- Follow NeoForge mod structure and naming conventions
- Use `@Mod` annotation for mod entry point
- Data generation via `./gradlew runData`
