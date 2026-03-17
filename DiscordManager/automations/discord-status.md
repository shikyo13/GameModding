---
name: discord-status
description: Audit the Discord server state - channels, roles, permissions, webhooks, automod
user_invocable: true
---

# Discord Server Status Audit

Run a comprehensive check of the server state and report any issues.

## Instructions

Run the following Discord MCP tools and compare against `DiscordManager/docs/id-map.md`:

1. `list_channels` - verify all expected channels exist in correct categories
2. `list_roles` - verify role hierarchy and colors match
3. `list_webhooks` - verify all 5 webhooks are present and active
4. `list_automod_rules` - verify 3 automod rules are active
5. `get_onboarding` - verify onboarding is enabled with game selection prompt
6. `get_welcome_screen` - verify welcome screen is enabled

## Report Format

```
## Discord Server Audit

**Channels:** {count}/54 expected - {OK/issues}
**Roles:** {count}/14 expected - {OK/issues}
**Webhooks:** {count}/5 expected - {OK/issues}
**Automod:** {count}/3 rules - {OK/issues}
**Onboarding:** {enabled/disabled} - {prompt count} prompts
**Welcome Screen:** {enabled/disabled}

### Issues Found
- {any discrepancies}
```

If everything matches, report "All systems nominal."
