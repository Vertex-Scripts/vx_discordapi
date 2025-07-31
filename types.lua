---@class ErrorResponse
---@field message string
---@field code integer

---@class BaseResponse
---@field status integer
---@field body any
---@field headers table<string, string>
---@field error ErrorResponse?

---@class DiscordUser
---@field id string
---@field username string

---@class DiscordMember
---@field user DiscordUser
---@field avatar? string
---@field banner? string
---@field roles string[]

---@class DiscordRole
---@field name string
---@field id string
---@field colors { primary_color: integer, secondary_color: integer }

---@class DiscordGuild
---@field id string
---@field roles DiscordRole[]

---@class DiscordRole
---@field id string
---@field name string
---@field color integer
---@field position integer

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
