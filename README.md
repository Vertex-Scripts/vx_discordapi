# vx_discordapi
Discord API script for FiveM with exports to get a discord member & roles. (For now, might add other stuff as well)

When a player is connecting it will fetch the discord member and cache it until the player leaves, they can use a command to refresh the data.
The script handles the ratelimitting of Discord so no ratelimitting issues.

## Dependencies
* https://github.com/vertex-scripts/vx_lib

## Setup

1. Make sure [vx_lib](https://github.com/vertex-scripts/vx_lib) is started before this script
2. Set the convar `discordToken` in your server configuration

## Exports

```lua
--------------------
-- Server Exports --
--------------------

---@param userId string
---@return DiscordMember?
---`Server`
function exports.vx_discordapi:getMemberByUserId(userId) end

---@param source number|string
---@return DiscordMember?
---`Server`
function exports.vx_discordapi:getMemberByPlayerId(source) end

---@param source number|string
---@param roleId string
---@return boolean
---`Server`
function exports.vx_discordapi:hasRoleId(source, roleId) return false end

--------------------
-- Client Exports --
--------------------

---@param roleId string
---@return boolean
---`Client`
function exports.vx_discordapi:hasRoleId(roleId) return false end
```
