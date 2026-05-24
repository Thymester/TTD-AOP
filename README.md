# TTD-AOP FiveM Resource

Server-synced AOP and priority system with configurable admin controls, join requests, cooldown handling, and HUD display.

## Install

1. Place this folder in your server resources directory.
2. Add `ensure TTD-AOP` in your `server.cfg`.
3. Configure admins and settings in `config.lua`.

## Admin Setup

You can authorize admins by either method:

- ACE permission (`Config.Admin.useAcePermission = true` and assign `ttdaop.admin`)
- Identifier whitelist (`Config.Admin.identifiers`)

## Commands

- `/aop` - Show current AOP.
- `/aopset <name>` - Set AOP (admin only by default).
- `/prio start` - Start priority (configurable admin-only).
- `/prio stop` - Stop priority/inactive (admin only by default).
- `/setprio cd [minutes]` - Start cooldown (admin only).
- `/setprio hold [reason]` - Put priority on hold (admin only). Running hold again resumes active priority.
- `/priojoin req` or `/priojoin request` - Ask active holder to join their priority.
- `/priojoin acc` or `/priojoin accept` - Holder accepts next pending request.
- `/priojoin deny` - Holder denies next pending request.

## Behavior Notes

- AOP changes are server-broadcast and synced to every player.
- Priority state is server authoritative and replicated to all clients.
- Join-request denial spam protection is configurable in `Config.JoinRequests`.
- Hold reason is optional.
- If the active/on-hold priority holder disconnects, behavior is configurable in `Config.DisconnectBehavior`:
  - `cooldown = true` -> move to cooldown
  - `cooldown = false` -> move straight to inactive
- UI position is configurable with `Config.Ui.position`:
  - `top-left`
  - `top-right`
  - `bottom-left`
  - `bottom-right`

## Config-Driven Customization

The following are configurable in `config.lua`:

- Admin controls
- Command names and admin restrictions
- Join request aliases and anti-spam thresholds
- Disconnect behavior for active holder leaving
- Notification styles and sounds
- Game/map display templates
- All user-facing messages
- HUD labels, colors, and position
