TTD-AOP is a fully server-authoritative FiveM resource built to manage Area of Patrol and priority state in a clean, configurable way. It keeps all important state synced to every client, supports admin-only controls through ACE or identifier-based permissions, and updates the server browser metadata so players can see the current AOP and priority status directly in the server listing.

This resource includes a configurable on-screen draw text display for AOP and priority, optional chat and GTA feed notifications, join-request handling for active priority, cooldown and hold states, and configurable behavior when the priority holder disconnects. The script is built to be flexible while keeping the core logic centralized and easy to maintain.

### Features
- Server-synced AOP state
- Server-synced priority system
- Admin-only AOP and priority controls
- ACE permission support and identifier whitelist support
- AOP lookup command for players
- Priority join request flow with accept and deny handling
- Denial spam protection with temporary request cooldown
- Priority hold and cooldown states
- Optional reason support for priority holds
- Disconnect handling for active priority holders
- Configurable draw text HUD
- Corner-based HUD positioning
- Resolution-scaled pixel offsets
- Server browser metadata updates for AOP and priority
- Optional GTA feed and chat notifications
- Config-driven labels, colors, sounds, commands, and permissions


### Commands

- /aop - Shows the current AOP
- /aopset <name> - Sets the AOP
- /prio start - Starts priority
- /prio stop - Stops priority
- /setprio cd [minutes] - Sets priority cooldown
- /setprio hold [reason] - Puts priority on hold or resumes it
- /priojoin req or /priojoin request - Requests to join active priority
- /priojoin acc or /priojoin accept - Accepts the next pending request
- /priojoin deny - Denies the next pending request


### Configuration

Everything important is configurable in config.lua, including:

- Admin permissions
- Command names
- AOP defaults
- Priority cooldown handling
- Disconnect behavior
- HUD position and pixel offsets
- Text colors
- Notification behavior
- Game/browser display text
- Join request aliases and anti-spam rules

### Requirements


- FiveM server
- Standard chat resource running
- ACE permissions if using ACE-based admin access


### Download

Download the script using the ZIP file in [Releases](https://github.com/Thymester/TTD-AOP/releases).

### Additional Information


- Code is accessible: Yes
- Subscription-based: No
- Lines: Approximately 900+ lines
- Requirements: FiveM, chat resource, optional ACE setup with license and Discord ID.
- Support: Yes
