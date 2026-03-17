---
name: discord-changelog
description: Post a formatted changelog to Discord #changelogs with Changelog Pings role
user_invocable: true
arguments:
  - name: mod
    description: "Mod name (e.g. DuplicantStatusBar)"
    required: true
  - name: version
    description: "Version number"
    required: true
---

# Discord Changelog Post

Post a detailed changelog to the #changelogs channel.

## Instructions

1. Read the mod's `CHANGELOG.txt` file from its project folder to get the latest version's changes
2. If no CHANGELOG.txt exists, ask the user what changed
3. Read `DiscordManager/docs/id-map.md` for IDs
4. Use the Discord MCP `send_message` tool to post to #changelogs (ID: 1483243865589940327)
5. Format:

```
## {mod} v{version}

**Changes:**
- {change 1}
- {change 2}
- {change 3}

<@&1483248167679037533>
```

The Changelog Pings role ID is `1483248167679037533`.
