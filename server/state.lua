TTDAOPState = {}

local serverState = {
    aop = Config.Defaults.aop,
    priority = {
        status = 'inactive',
        holder = nil,
        participants = {},
        cooldownEndsAt = 0,
        holdReason = ''
    }
}

local pendingRequestsByHolder = {}
local deniedRequestTracker = {}
local lastActiveSnapshot = nil

local function nowSeconds()
    return os.time()
end

local function clearPendingRequests()
    pendingRequestsByHolder = {}
end

local function cloneParticipants()
    return TTDAOPUtils.ShallowCopyArray(serverState.priority.participants)
end

local function getCooldownMinutesRemaining()
    local secondsRemaining = serverState.priority.cooldownEndsAt - nowSeconds()
    return TTDAOPUtils.CeilMinutesFromSeconds(secondsRemaining)
end

local function buildPublicPriorityState()
    return {
        status = serverState.priority.status,
        holder = serverState.priority.holder,
        participants = cloneParticipants(),
        participantsText = TTDAOPUtils.JoinServerIds(serverState.priority.participants),
        holdReason = serverState.priority.holdReason,
        cooldownMinutesRemaining = getCooldownMinutesRemaining()
    }
end

function TTDAOPState.GetPublicState()
    return {
        aop = serverState.aop,
        priority = buildPublicPriorityState()
    }
end

function TTDAOPState.PushState(target)
    local payload = TTDAOPState.GetPublicState()
    TriggerClientEvent('ttdaop:client:state', target or -1, payload)
end

function TTDAOPState.GetAop()
    return serverState.aop
end

function TTDAOPState.SetAop(newAop)
    serverState.aop = newAop
end

function TTDAOPState.GetPriority()
    return serverState.priority
end

function TTDAOPState.StartPriority(holderServerId)
    serverState.priority.status = 'active'
    serverState.priority.holder = holderServerId
    serverState.priority.participants = { holderServerId }
    serverState.priority.cooldownEndsAt = 0
    serverState.priority.holdReason = ''
    clearPendingRequests()
end

function TTDAOPState.StopPriority()
    serverState.priority.status = 'inactive'
    serverState.priority.holder = nil
    serverState.priority.participants = {}
    serverState.priority.cooldownEndsAt = 0
    serverState.priority.holdReason = ''
    lastActiveSnapshot = nil
    clearPendingRequests()
end

function TTDAOPState.SetCooldown(minutes)
    serverState.priority.status = 'cooldown'
    serverState.priority.holder = nil
    serverState.priority.participants = {}
    serverState.priority.cooldownEndsAt = nowSeconds() + (minutes * 60)
    serverState.priority.holdReason = ''
    lastActiveSnapshot = nil
    clearPendingRequests()
end

function TTDAOPState.ToggleHold(source, reason)
    if serverState.priority.status == 'hold' then
        if lastActiveSnapshot then
            serverState.priority.status = 'active'
            serverState.priority.holder = lastActiveSnapshot.holder
            serverState.priority.participants = TTDAOPUtils.ShallowCopyArray(lastActiveSnapshot.participants)
            serverState.priority.cooldownEndsAt = 0
            serverState.priority.holdReason = ''
            lastActiveSnapshot = nil

            return 'resumed'
        end

        serverState.priority.status = 'active'
        serverState.priority.holder = source
        serverState.priority.participants = { source }
        serverState.priority.cooldownEndsAt = 0
        serverState.priority.holdReason = ''

        return 'resumed'
    end

    if serverState.priority.status == 'active' then
        lastActiveSnapshot = {
            holder = serverState.priority.holder,
            participants = TTDAOPUtils.ShallowCopyArray(serverState.priority.participants)
        }
    else
        lastActiveSnapshot = {
            holder = source,
            participants = { source }
        }
    end

    serverState.priority.status = 'hold'
    serverState.priority.holder = lastActiveSnapshot.holder
    serverState.priority.participants = TTDAOPUtils.ShallowCopyArray(lastActiveSnapshot.participants)
    serverState.priority.cooldownEndsAt = 0
    serverState.priority.holdReason = reason or ''
    clearPendingRequests()

    return 'held'
end

function TTDAOPState.IsRequesterBlocked(source)
    local tracker = deniedRequestTracker[source]
    if not tracker then
        return false, 0
    end

    if tracker.blockedUntil > nowSeconds() then
        local remainingSeconds = tracker.blockedUntil - nowSeconds()
        return true, TTDAOPUtils.CeilMinutesFromSeconds(remainingSeconds)
    end

    tracker.blockedUntil = 0
    return false, 0
end

local function registerDeniedRequest(source)
    local tracker = deniedRequestTracker[source] or {
        deniedCount = 0,
        windowEndsAt = 0,
        blockedUntil = 0
    }

    if tracker.windowEndsAt <= nowSeconds() then
        tracker.deniedCount = 0
        tracker.windowEndsAt = nowSeconds() + (Config.JoinRequests.deniedWindowMinutes * 60)
    end

    tracker.deniedCount = tracker.deniedCount + 1

    if tracker.deniedCount >= Config.JoinRequests.maxDeniedBeforeCooldown then
        tracker.deniedCount = 0
        tracker.blockedUntil = nowSeconds() + (Config.JoinRequests.deniedRequestCooldownMinutes * 60)
        deniedRequestTracker[source] = tracker
        return true
    end

    deniedRequestTracker[source] = tracker
    return false
end

function TTDAOPState.CanQueueJoinRequest(source)
    if serverState.priority.status ~= 'active' then
        return false, 'no_active'
    end

    if not serverState.priority.holder then
        return false, 'no_active'
    end

    if source == serverState.priority.holder then
        return false, 'holder_cannot_request'
    end

    if TTDAOPUtils.ArrayContains(serverState.priority.participants, source) then
        return false, 'already_member'
    end

    local blocked, minutesRemaining = TTDAOPState.IsRequesterBlocked(source)
    if blocked then
        return false, 'blocked', minutesRemaining
    end

    local holderQueue = pendingRequestsByHolder[serverState.priority.holder] or {}
    if TTDAOPUtils.ArrayContains(holderQueue, source) then
        return false, 'already_pending'
    end

    return true, nil
end

function TTDAOPState.QueueJoinRequest(source)
    local holderId = serverState.priority.holder
    local holderQueue = pendingRequestsByHolder[holderId] or {}
    holderQueue[#holderQueue + 1] = source
    pendingRequestsByHolder[holderId] = holderQueue

    return holderId
end

local function getNextValidRequest(holderId)
    local holderQueue = pendingRequestsByHolder[holderId] or {}

    while #holderQueue > 0 do
        local requester = table.remove(holderQueue, 1)
        if GetPlayerName(requester) then
            pendingRequestsByHolder[holderId] = holderQueue
            return requester
        end
    end

    pendingRequestsByHolder[holderId] = holderQueue
    return nil
end

function TTDAOPState.ResolveNextJoinRequest(holderId, accepted)
    local requester = getNextValidRequest(holderId)

    if not requester then
        return false, nil, false
    end

    if accepted then
        if not TTDAOPUtils.ArrayContains(serverState.priority.participants, requester) then
            serverState.priority.participants[#serverState.priority.participants + 1] = requester
        end

        return true, requester, false
    end

    local blockedAfterDeny = registerDeniedRequest(requester)
    return true, requester, blockedAfterDeny
end

function TTDAOPState.TryExpireCooldown()
    if serverState.priority.status ~= 'cooldown' then
        return false
    end

    if nowSeconds() < serverState.priority.cooldownEndsAt then
        return false
    end

    TTDAOPState.StopPriority()
    return true
end

function TTDAOPState.HandleHolderDisconnect(source)
    local isHolder = serverState.priority.holder == source
    local isHolderState = serverState.priority.status == 'active' or serverState.priority.status == 'hold'

    if not isHolder or not isHolderState then
        return false, nil
    end

    if Config.DisconnectBehavior.cooldown then
        local minutes = tonumber(Config.DisconnectBehavior.cooldownMinutes) or Config.Defaults.priorityCooldownMinutes
        if minutes < 1 then
            minutes = 1
        end

        TTDAOPState.SetCooldown(minutes)
        return true, minutes
    end

    TTDAOPState.StopPriority()
    return true, nil
end

function TTDAOPState.RemovePlayer(source)
    TTDAOPUtils.ArrayRemoveValue(serverState.priority.participants, source)

    if serverState.priority.holder == source then
        if #serverState.priority.participants > 0 then
            serverState.priority.holder = serverState.priority.participants[1]
        else
            TTDAOPState.StopPriority()
        end
    end

    for holderId, queue in pairs(pendingRequestsByHolder) do
        TTDAOPUtils.ArrayRemoveValue(queue, source)
        pendingRequestsByHolder[holderId] = queue
    end
end
