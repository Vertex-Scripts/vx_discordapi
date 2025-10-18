vx.print.info({
    c = "print('test')"
})

if ServerConfig.token == "none" then
    error(
        "Discord bot token is not set in the server configuration. Please set 'discordToken' convar or update config.server.lua.")
end

local baseUrl = string.format("https://discordapp.com/api/v9/guilds/%s", ServerConfig.guildId)
local memoryCache = vx.memoryCache:new()
local requestQueue = {}
local isProcessing = false
local ratelimitBuffer = 0

---@type DiscordGuild?
local currentGuild = nil

---@type table<string, DiscordMember>
local cache = {}

local defaultHeaders = {
    ["Authorization"] = string.format("Bot %s", ServerConfig.token),
    ["Content-Type"] = "application/json",
}

local function debug(...)
    if not ServerConfig.debug then return end
    vx.print.info(string.format(...))
end

---@return BaseResponse
local function sendHttpRequest(url)
    local promise = promise.new()
    PerformHttpRequest(baseUrl .. url, function(status, response, headers, rawError)
        if rawError then rawError = rawError:match("HTTP %d+: (.+)") end
        local error = rawError and json.decode(rawError) or {}

        ---@type BaseResponse
        local res = {
            status = status,
            body = json.decode(response),
            headers = headers,
            error = {
                code = error.code or 0,
                message = error.message or "Unknown error",
            },
        }

        promise:resolve(res)
    end, "GET", nil, defaultHeaders)

    return Citizen.Await(promise)
end

local function processRequestQueue()
    local rateLimitRemaining = 1
    local rateLimitResetAfter = 0

    while #requestQueue > 0 do
        local request = table.remove(requestQueue, 1)
        local response = sendHttpRequest(request.path)

        local remaining = response.headers["x-ratelimit-remaining"]
        local resetAfter = response.headers["x-ratelimit-reset-after"]
        rateLimitRemaining = remaining and tonumber(remaining) or 1
        rateLimitResetAfter = resetAfter and tonumber(resetAfter) or 0
        request.promise:resolve(response)

        if rateLimitRemaining == 0 then
            local waitFor = math.ceil(rateLimitResetAfter * 1000) + ratelimitBuffer
            debug("Rate limit reached, waiting for %d ms", waitFor)

            Citizen.Wait(waitFor)
        end

        debug("Processed request: %s, Status: %d, Remaining: %d, Reset After: %.2fs",
            request.path == "" and "/" or request.path, response.status, rateLimitRemaining, rateLimitResetAfter)
    end

    isProcessing = false
end

---@return BaseResponse
local function sendRatelimitedRequest(path)
    local p = promise.new()
    table.insert(requestQueue, {
        path = path,
        promise = p
    })

    if not isProcessing then
        isProcessing = true
        Citizen.CreateThread(processRequestQueue)
    end

    debug("Queued request for path: " .. path)
    return Citizen.Await(p)
end

---@return DiscordMember?
local function getGuildMember(userId)
    local response = sendRatelimitedRequest(string.format("/members/%s", userId))
    if response.status ~= 200 then
        return vx.print.error("Failed to fetch Discord member: ", response.error?.message)
    end

    return response.body
end

---@return DiscordGuild?
local function getGuild()
    local response = sendHttpRequest("")
    if response.status ~= 200 then
        return vx.print.error("Failed to fetch Discord guild: ", response.error?.message)
    end

    return response.body
end

local function loadMember(source)
    local discordId = vx.player.getIdentifier(source, false, "discord")
    if not discordId then
        return vx.print.info(string.format("Player %s does not have a Discord ID", source))
    end

    local member = getGuildMember(discordId)
    if not member then
        return vx.print.info(("Failed to fetch Discord member for player %s with Discord ID %s"):format(source, discordId))
    end

    cache[discordId] = member
end

local function giveRole(userId, roleId)
    local url = string.format("https://discord.com/api/v10/guilds/%s/members/%s/roles/%s",
        ServerConfig.guildId, userId, roleId)

    local response = vx.sendHttpRequest(url, {
        method = "PUT",
        headers = {
            ["Authorization"] = string.format("Bot %s", ServerConfig.token),
            ["Content-Type"] = "application/json"
        }
    })

    vx.print.info(response)
end

Citizen.CreateThread(function()
    currentGuild = getGuild()
end)

------------------------
-- Events / Callbacks --
------------------------

function serverCallbackBridge.getCurrentMember(source)
    local discordId = vx.player.getIdentifier(source, false, "discord")
    return cache[discordId]
end

function serverCallbackBridge.getDiscordRoles()
    local roles = vx.waitFor(function()
        if currentGuild?.roles then
            return currentGuild?.roles
        end
    end, "Failed to get discord roles", 3000)

    for _, role in pairs(roles) do
        local roleColor = role.color
        role.hexColor = string.format("#%06X", roleColor)
    end

    return roles
end

function serverEventBridge.playerLoaded(source)
    loadMember(source)
end

vx.registerNetEvent("payerDropped", function()
    local source = source
    local discordId = vx.player.getIdentifier(source, false, "discord")
    if not discordId then
        return
    end

    cache[discordId] = nil
end)

--------------
-- Commands --
--------------

if ServerConfig.refreshCommandEnabled then
    vx.addCommand(ServerConfig.refreshCommandName, {}, function(source)
        local cooldownKey = string.format("command_cooldown_%s", source)
        local lastUsed = memoryCache:get(cooldownKey)
        if lastUsed then
            local secondsLeft = lastUsed + (ServerConfig.refreshCommandCooldown / 1000) - os.time()
            return vx.notify(source, {
                title = "Cooldown",
                message = string.format("You must wait %d seconds before using this command again.", secondsLeft),
                type = "error"
            })
        end

        local now = os.time()
        memoryCache:set(cooldownKey, now, ServerConfig.refreshCommandCooldown)

        vx.notify(source, {
            title = "Discord",
            message = "Loading Discord data...",
            type = "info"
        })

        loadMember(source)

        local discordId = vx.player.getIdentifier(source, false, "discord")
        local success = cache[discordId] ~= nil
        vx.notify(source, {
            title = "Discord",
            message = success and "Discord data loaded successfully!" or "Failed to load Discord data.",
            type = success and "success" or "error"
        })
    end)
end

-------------
-- Exports --
-------------

exports("giveRole", function(userId, roleId)
    giveRole(userId, roleId)
end)

exports("getMemberByUserId", function(userId)
    return cache[userId]
end)

exports("getMemberByPlayerId", function(playerId)
    local discordId = vx.player.getIdentifier(playerId, false, "discord")
    return cache[discordId]
end)

exports("hasRoleId", function(source, roleId)
    local discordId = vx.player.getIdentifier(source, false, "discord")
    local member = cache[discordId]
    if not member then
        return false
    end

    for _, id in pairs(member.roles or {}) do
        if id == roleId then
            return true
        end
    end

    return false
end)

exports("getRoleById", function(roleId)
    if not currentGuild then
        return nil
    end

    for _, role in pairs(currentGuild.roles) do
        if role.id == roleId then
            return role
        end
    end

    return nil
end)
