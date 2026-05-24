TTDAOPCommands = {}

local function sendUsage(source, usage)
    TTDAOPServerMessaging.SendChat(source, Config.Messages.invalidCommand .. ' Usage: ' .. usage)
end

local function requireAdminIfNeeded(source, isRequired)
    if not isRequired then
        return true
    end

    if TTDAOPPermissions.RequireAdmin(source) then
        return true
    end

    TTDAOPServerMessaging.SendChat(source, Config.Messages.noPermission)
    return false
end

local function formatPriorityDisplayForChat(priority)
    if priority.status == 'inactive' then
        return '^7Priority:^0 ^2Inactive^0'
    end

    if priority.status == 'active' then
        return ('^7Priority:^0 ^1Active^0 (^7%s^0)'):format(TTDAOPUtils.JoinServerIds(priority.participants))
    end

    if priority.status == 'cooldown' then
        return ('^7Priority:^0 ^5Cooldown^0 (^7%s minute(s)^0)'):format(priority.cooldownMinutesRemaining)
    end

    local base = ('^7Priority:^0 ^3On Hold^0 (^7#%s^0)'):format(priority.holder or '?')
    if not TTDAOPUtils.IsEmpty(priority.holdReason) then
        return base .. (' (^7%s^0)'):format(priority.holdReason)
    end

    return base
end

local function handleAopCommand(source)
    TTDAOPServerMessaging.SendChat(source, Config.Messages.currentAop:format(TTDAOPState.GetAop()))
end

local function handleAopSetCommand(source, args)
    if not requireAdminIfNeeded(source, Config.Commands.aopSet.adminOnly) then
        return
    end

    local newAop = TTDAOPUtils.MergeArgs(args, 1)
    if TTDAOPUtils.IsEmpty(newAop) then
        sendUsage(source, '/' .. Config.Commands.aopSet.name .. ' <name>')
        return
    end

    TTDAOPState.SetAop(newAop)
    TTDAOPState.PushState()
    TTDAOPApplyBrowserMeta(TTDAOPState.GetPublicState())
    TTDAOPServerMessaging.BroadcastChat(Config.Messages.aopChangedBroadcast:format(newAop))
    TTDAOPServerMessaging.BroadcastAopChanged(newAop)
end

local function handlePrioStart(source)
    if not requireAdminIfNeeded(source, Config.Commands.prio.startAdminOnly) then
        return
    end

    local priority = TTDAOPState.GetPriority()
    if priority.status == 'active' then
        TTDAOPServerMessaging.SendChat(source, Config.Messages.priorityAlreadyActive)
        return
    end

    TTDAOPState.StartPriority(source)
    TTDAOPState.PushState()
    TTDAOPApplyBrowserMeta(TTDAOPState.GetPublicState())
    TTDAOPServerMessaging.BroadcastChat(Config.Messages.priorityStarted:format(source))
end

local function handlePrioStop(source)
    if not requireAdminIfNeeded(source, Config.Commands.prio.stopAdminOnly) then
        return
    end

    TTDAOPState.StopPriority()
    TTDAOPState.PushState()
    TTDAOPApplyBrowserMeta(TTDAOPState.GetPublicState())
    TTDAOPServerMessaging.BroadcastChat(Config.Messages.priorityStopped)
end

local function handlePrioCommand(source, args)
    local subCommand = TTDAOPUtils.ToLower(TTDAOPUtils.GetFirstArg(args, ''))

    if subCommand == 'start' then
        handlePrioStart(source)
        return
    end

    if subCommand == 'stop' then
        handlePrioStop(source)
        return
    end

    sendUsage(source, '/' .. Config.Commands.prio.name .. ' <start|stop>')
end

local function handleSetPrioCommand(source, args)
    if not requireAdminIfNeeded(source, Config.Commands.setPrio.adminOnly) then
        return
    end

    local subCommand = TTDAOPUtils.ToLower(TTDAOPUtils.GetFirstArg(args, ''))

    if subCommand == 'cd' then
        local customMinutes = tonumber(args[2])
        local minutes = customMinutes or Config.Defaults.priorityCooldownMinutes

        if minutes < 1 then
            TTDAOPServerMessaging.SendChat(source, Config.Messages.invalidCommand)
            return
        end

        TTDAOPState.SetCooldown(minutes)
        TTDAOPState.PushState()
        TTDAOPApplyBrowserMeta(TTDAOPState.GetPublicState())
        TTDAOPServerMessaging.BroadcastChat(Config.Messages.priorityCooldownSet:format(minutes))
        return
    end

    if subCommand == 'hold' then
        local reason = TTDAOPUtils.MergeArgs(args, 2)
        local action = TTDAOPState.ToggleHold(source, reason)

        TTDAOPState.PushState()
        TTDAOPApplyBrowserMeta(TTDAOPState.GetPublicState())

        if action == 'resumed' then
            TTDAOPServerMessaging.BroadcastChat(Config.Messages.priorityHoldResumed)
        else
            TTDAOPServerMessaging.BroadcastChat(Config.Messages.priorityHoldSet)
            if not TTDAOPUtils.IsEmpty(reason) then
                TTDAOPServerMessaging.BroadcastChat(Config.Messages.holdReasonTemplate:format(reason))
            end
        end

        return
    end

    sendUsage(source, '/' .. Config.Commands.setPrio.name .. ' <cd|hold> [minutes|reason]')
end

local function handleJoinRequest(source)
    local allowed, failureReason, cooldownRemaining = TTDAOPState.CanQueueJoinRequest(source)

    if not allowed then
        if failureReason == 'no_active' then
            TTDAOPServerMessaging.SendChat(source, Config.Messages.noActivePriority)
            return
        end

        if failureReason == 'already_member' then
            TTDAOPServerMessaging.SendChat(source, Config.Messages.alreadyInPriority)
            return
        end

        if failureReason == 'blocked' then
            TTDAOPServerMessaging.SendChat(source, Config.Messages.requestBlockedActiveCooldown:format(cooldownRemaining))
            return
        end

        TTDAOPServerMessaging.SendChat(source, Config.Messages.requestFailedGeneric)
        return
    end

    local holderId = TTDAOPState.QueueJoinRequest(source)
    local requesterName = GetPlayerName(source) or 'Unknown'

    TTDAOPServerMessaging.SendChat(source, Config.Messages.requestSent)
    TTDAOPServerMessaging.SendPriorityRequest(
        holderId,
        Config.Messages.joinRequestTemplate:format(requesterName, source, Config.Commands.prioJoin.name, Config.Commands.prioJoin.name)
    )
end

local function processJoinDecision(source, accepted)
    local priority = TTDAOPState.GetPriority()
    if priority.holder ~= source then
        TTDAOPServerMessaging.SendChat(source, Config.Messages.notPriorityHolder)
        return
    end

    local resolved, requester, blockedAfterDeny = TTDAOPState.ResolveNextJoinRequest(source, accepted)
    if not resolved then
        TTDAOPServerMessaging.SendChat(source, Config.Messages.noPendingRequest)
        return
    end

    if accepted then
        TTDAOPServerMessaging.SendChat(requester, Config.Messages.requestAccepted)
        TTDAOPServerMessaging.SendChat(source, Config.Messages.joinRequestAcceptedByHolder)
        TTDAOPState.PushState()
        TTDAOPApplyBrowserMeta(TTDAOPState.GetPublicState())
        return
    end

    TTDAOPServerMessaging.SendChat(requester, Config.Messages.requestDenied)
    TTDAOPServerMessaging.SendChat(source, Config.Messages.joinRequestDeniedByHolder)

    if blockedAfterDeny then
        TTDAOPServerMessaging.SendChat(requester, Config.Messages.requestDeniedCooldown:format(Config.JoinRequests.deniedRequestCooldownMinutes))
    end
end

local function handlePrioJoinCommand(source, args)
    local subCommand = TTDAOPUtils.ToLower(TTDAOPUtils.GetFirstArg(args, ''))

    if TTDAOPUtils.IsValueInAliases(subCommand, Config.JoinRequests.aliases.request) then
        handleJoinRequest(source)
        return
    end

    if TTDAOPUtils.IsValueInAliases(subCommand, Config.JoinRequests.aliases.accept) then
        processJoinDecision(source, true)
        return
    end

    if TTDAOPUtils.IsValueInAliases(subCommand, Config.JoinRequests.aliases.deny) then
        processJoinDecision(source, false)
        return
    end

    sendUsage(source, '/' .. Config.Commands.prioJoin.name .. ' <request|accept|deny>')
end

function TTDAOPCommands.RegisterAll()
    RegisterCommand(Config.Commands.aop.name, function(source)
        handleAopCommand(source)
    end, false)

    RegisterCommand(Config.Commands.aopSet.name, function(source, args)
        handleAopSetCommand(source, args)
    end, false)

    RegisterCommand(Config.Commands.prio.name, function(source, args)
        handlePrioCommand(source, args)
    end, false)

    RegisterCommand(Config.Commands.setPrio.name, function(source, args)
        handleSetPrioCommand(source, args)
    end, false)

    RegisterCommand(Config.Commands.prioJoin.name, function(source, args)
        handlePrioJoinCommand(source, args)
    end, false)
end
