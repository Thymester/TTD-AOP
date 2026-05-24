TTDAOPPermissions = {}

local function hasConfiguredIdentifier(source)
    local playerIdentifiers = GetPlayerIdentifiers(source)

    for _, configuredIdentifier in ipairs(Config.Admin.identifiers) do
        for _, playerIdentifier in ipairs(playerIdentifiers) do
            if configuredIdentifier == playerIdentifier then
                return true
            end
        end
    end

    return false
end

function TTDAOPPermissions.IsAdmin(source)
    if source == 0 then
        return true
    end

    if Config.Admin.useAcePermission and IsPlayerAceAllowed(source, Config.Admin.acePermission) then
        return true
    end

    return hasConfiguredIdentifier(source)
end

function TTDAOPPermissions.RequireAdmin(source)
    return TTDAOPPermissions.IsAdmin(source)
end
