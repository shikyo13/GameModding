---
name: discord-add-game
description: Add a new game to the Discord server - creates category, channels, role, forum tags, and updates onboarding
user_invocable: true
arguments:
  - name: game
    description: "Game name (e.g. 'Stardew Valley')"
    required: true
  - name: prefix
    description: "Channel prefix (e.g. 'stardew')"
    required: true
  - name: color
    description: "Role color hex (e.g. '#FF6B6B')"
    required: true
  - name: emoji
    description: "Emoji for the role (e.g. a circle color emoji)"
    required: true
---

# Add New Game to Discord Server

Automate the full process of adding a new game section to the server.

## Steps

Read `DiscordManager/docs/id-map.md` for reference IDs throughout.

### 1. Create Category & Channels
```
create_category: {GAME NAME (uppercase)}
create_text_channel: {prefix}-my-mods (category: above, topic: "Zero's {game} mods - discussion and info")
create_text_channel: {prefix}-mod-help (category: above, topic: "Need help with a {game} mod? Ask here")
create_text_channel: {prefix}-modding (category: above, topic: "{game} modding discussion")
create_text_channel: {prefix}-general (category: above, topic: "General {game} chat")
```

### 2. Create Update Role
```
create_role: {game} Updates (color: {color}, hoist: false, mentionable: true)
```

### 3. Add Forum Tags
```
create_forum_tag: bug-reports -> {game}
create_forum_tag: feature-requests -> {game}
```

### 4. Post & Pin Links in my-mods Channel
Post the standard my-mods pinned message with download/support links and pin it.

### 5. Update #roles Message
Edit message `1483248615542624358` in #roles to add the new emoji-role mapping.
Add the corresponding reaction to the message.

### 6. Update Onboarding
Use the Discord API (curl) to add the new game as an onboarding option.
Fetch current onboarding first, add the new option to the existing prompts array.

### 7. Update Documentation
Update `DiscordManager/docs/id-map.md` with the new category, channel, and role IDs.

### 8. Report
List everything created with IDs.
