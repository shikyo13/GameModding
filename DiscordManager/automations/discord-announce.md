---
name: discord-announce
description: Post a mod release announcement to Discord #mod-releases with appropriate role pings
user_invocable: true
arguments:
  - name: mod
    description: "Mod name (e.g. DuplicantStatusBar, ReplaceStuff)"
    required: true
  - name: version
    description: "Version number (e.g. 1.2.0)"
    required: true
  - name: game
    description: "Game name (ONI, Subnautica, Zomboid, Minecraft, RimWorld, Factorio)"
    required: true
---

# Discord Release Announcement

Post a formatted mod release announcement to the Discord server.

## Instructions

1. Read `DiscordManager/docs/id-map.md` to get the channel and role IDs
2. Determine the correct update role based on the game argument:
   - ONI -> ONI Updates role + All Updates role
   - Subnautica -> Subnautica Updates role + All Updates role
   - Zomboid -> Zomboid Updates role + All Updates role
   - Minecraft -> Minecraft Updates role + All Updates role
   - RimWorld -> RimWorld Updates role + All Updates role
   - Factorio -> Factorio Updates role + All Updates role
3. Use the Discord MCP `send_message` tool to post to #mod-releases (ID: 1483243738859045036)
4. Format the message as:

```
## {mod} v{version} Released!

{Brief description of what changed - ask user or check CHANGELOG.txt}

**Download:** [Steam Workshop](https://steamcommunity.com/id/ahunt/myworkshopfiles/) | [Nexus Mods](https://www.nexusmods.com/profile/Zer0TheAbs0lute/mods)

<@&{game_role_id}> <@&{all_updates_role_id}>
```

5. Ask the user if they also want to post a detailed changelog (triggers /discord-changelog)
