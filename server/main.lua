TTDAOPServerMessaging = {}

local function buildPriorityBrowserValue(priority)
    if priority.status == 'inactive' then
        return 'Inactive'
    end

    if priority.status == 'active' then
        local participants = priority.participantsText
        if TTDAOPUtils.IsEmpty(participants) then
            participants = ('#%s'):format(priority.holder or '?')
        end

        return ('Active (%s)'):format(participants)
    end

    if priority.status == 'cooldown' then
        return ('Cooldown (%s minutes)'):format(priority.cooldownMinutesRemaining)
    end

    local holderText = ('#%s'):format(priority.holder or '?')
    if TTDAOPUtils.IsEmpty(priority.holdReason) then
        return ('On Hold (%s)'):format(holderText)
    end

    return ('On Hold (%s) (%s)'):format(holderText, priority.holdReason)
end

local function updateServerBrowserMeta(state)
    local aopValue = state.aop or 'Unknown'
    local priorityValue = buildPriorityBrowserValue(state.priority)
    local browserMapName = ('AOP: %s'):format(aopValue)
    local browserGameType = ('Priority: %s'):format(priorityValue)

    -- Match the working resource behavior as closely as possible.
    -- AOP should be the map name, Priority should be the game type.
    SetMapName(browserMapName)
    SetGameType(browserGameType)

    -- Re-apply for a short burst in case another resource overwrites the values.
    CreateThread(function()
        for _ = 1, 10 do
            Wait(1000)
            SetMapName(browserMapName)
            SetGameType(browserGameType)
        end
    end)
end

TTDAOPApplyBrowserMeta = updateServerBrowserMeta

function TTDAOPServerMessaging.SendChat(target, message)
    TriggerClientEvent('chat:addMessage', target, {
        color = { 255, 255, 255 },
        multiline = false,
        args = { 'TTD-AOP', message }
    })
end

function TTDAOPServerMessaging.BroadcastChat(message)
    TriggerClientEvent('chat:addMessage', -1, {
        color = { 255, 255, 255 },
        multiline = false,
        args = { 'TTD-AOP', message }
    })
end

function TTDAOPServerMessaging.SendPriorityRequest(target, message)
    TriggerClientEvent('ttdaop:client:priorityRequest', target, message)
end

function TTDAOPServerMessaging.BroadcastAopChanged(newAop)
    TriggerClientEvent('ttdaop:client:aopChanged', -1, {
        aop = newAop,
        message = ('AOP has changed to %s'):format(newAop)
    })
end

AddEventHandler('ttdaop:server:stateUpdated', function(state)
    updateServerBrowserMeta(state)
end)

RegisterNetEvent('ttdaop:server:requestSync', function()
    local source = source
    TTDAOPState.PushState(source)
end)

AddEventHandler('playerDropped', function()
    local source = source
    local changedByDisconnect, cooldownMinutes = TTDAOPState.HandleHolderDisconnect(source)
    TTDAOPState.RemovePlayer(source)
    TTDAOPState.PushState()
    TTDAOPApplyBrowserMeta(TTDAOPState.GetPublicState())

    if changedByDisconnect then
        if cooldownMinutes then
            TTDAOPServerMessaging.BroadcastChat(Config.Messages.holderLeftCooldown:format(cooldownMinutes))
        else
            TTDAOPServerMessaging.BroadcastChat(Config.Messages.holderLeftInactive)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)

        if TTDAOPState.TryExpireCooldown() then
            TTDAOPState.PushState()
            TTDAOPApplyBrowserMeta(TTDAOPState.GetPublicState())
            TTDAOPServerMessaging.BroadcastChat(Config.Messages.cooldownEndedBroadcast)
        end
    end
end)

TTDAOPCommands.RegisterAll()
TTDAOPApplyBrowserMeta(TTDAOPState.GetPublicState())
