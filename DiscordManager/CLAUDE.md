# Parent workspace: See `../CLAUDE.md` for shared RE toolkit, engine docs, and modding conventions.

# DiscordManager - Zero's Mods Discord Server

Management project for the "Zero's Mods" Discord server (Guild ID: 229047002116128768).

## Quick Reference

| What | Where |
|-|-|
| Server state snapshot | `docs/server-state.md` |
| Channel & role ID map | `docs/id-map.md` |
| Webhook URLs & integration | `docs/webhooks.md` |
| MCP config | `../.mcp.json` (discord entry) |
| GitHub Actions monitor | `../ONIMods/.github/workflows/discord-monitor.yml` |
| MCP tool patches | `docs/mcp-patches.md` |

## MCP Tools

The Discord MCP server (`@quadslab.io/discord-mcp`) provides 134 tools. It's configured in the parent workspace `.mcp.json`. The bot token and guild ID are in env vars there.

**Patched tools:** The onboarding tool has been extended to support prompts/questions. See `docs/mcp-patches.md` for details.

## Automations

| Skill/Command | Purpose |
|-|-|
| `/discord-announce` | Post a mod release announcement to #mod-releases with role pings |
| `/discord-changelog` | Post a formatted changelog to #changelogs |
| `/discord-status` | Audit server state - channels, roles, permissions, webhooks |
| `/discord-add-game` | Add a new game category with all 4 channels, update role, and forum tags |

## Conventions

- Never hardcode webhook URLs or tokens in committed files - use docs/ (gitignored) or GitHub secrets
- Channel references in messages must use `<#channel_id>` format for clickable links
- Role references must use `<@&role_id>` format
- When adding a new game: create category + 4 channels + update role + forum tags on both forums + update onboarding + update #roles message
- All read-only channels: deny SendMessages for @everyone, allow for Admin + bot roles
