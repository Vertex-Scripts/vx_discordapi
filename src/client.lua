Citizen.CreateThread(function()
    for i = 0, 100 do
        serverEventBridge.playerLoaded()
    end
end)

exports("getMember", function()
    local member = serverCallbackBridge.getCurrentMember()
    return member
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
