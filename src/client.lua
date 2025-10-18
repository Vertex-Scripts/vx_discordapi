local memoryCache = vx.memoryCache:new()

Citizen.CreateThread(function()
    serverEventBridge.playerLoaded()
end)

exports("getMember", function()
    local member = serverCallbackBridge.getCurrentMember()
    return member
end)

exports("getDiscordRoles", function()
    local cacheKey = "discord_roles"
    local cachedRoles = memoryCache:get(cacheKey)
    if cachedRoles then
        return cachedRoles
    end

    local roles = serverCallbackBridge.getDiscordRoles()
    memoryCache:set(cacheKey, roles, 60 * 1000)

    return roles
end)

exports("hasRoleId", function(roleId)
    local member = serverCallbackBridge.getCurrentMember()
    if not member then
        return false
    end

    for _, id in ipairs(member.roles) do
        if id == roleId then
            return true
        end
    end

    return false
end)
