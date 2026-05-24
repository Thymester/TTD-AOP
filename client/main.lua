local currentState = nil

local function hexToRgb(hex)
    local cleaned = (hex or '#FFFFFF'):gsub('#', '')
    if #cleaned ~= 6 then
        return 255, 255, 255
    end

    local r = tonumber(cleaned:sub(1, 2), 16) or 255
    local g = tonumber(cleaned:sub(3, 4), 16) or 255
    local b = tonumber(cleaned:sub(5, 6), 16) or 255

    return r, g, b
end

local function getStatusColor(status)
    local palette = Config.Ui.colors

    if status == 'active' then
        return hexToRgb(palette.active)
    end

    if status == 'cooldown' then
        return hexToRgb(palette.cooldown)
    end

    if status == 'hold' then
        return hexToRgb(palette.hold)
    end

    return hexToRgb(palette.inactive)
end

local function getAnchorByPosition()
    local drawConfig = Config.Ui.drawText
    local leftPixels = math.max(0, tonumber(drawConfig.pixelOffsetLeft) or 0)
    local rightPixels = math.max(0, tonumber(drawConfig.pixelOffsetRight) or 0)
    local upPixels = math.max(0, tonumber(drawConfig.pixelOffsetUp) or 0)
    local downPixels = math.max(0, tonumber(drawConfig.pixelOffsetDown) or 0)

    local baselineWidth = math.max(1, tonumber(drawConfig.baselineResolutionWidth) or 1920)
    local baselineHeight = math.max(1, tonumber(drawConfig.baselineResolutionHeight) or 1080)

    local pixelsToX = function(pixels)
        return pixels / baselineWidth
    end

    local pixelsToY = function(pixels)
        return pixels / baselineHeight
    end

    local baseLeft = 0.015
    local baseRight = 0.985
    local baseTop = 0.02
    local baseBottom = 0.94

    if Config.Ui.position == 'top-left' then
        return baseLeft + pixelsToX(leftPixels), baseTop + pixelsToY(downPixels), false
    end

    if Config.Ui.position == 'bottom-left' then
        return baseLeft + pixelsToX(leftPixels), baseBottom - pixelsToY(upPixels), false
    end

    if Config.Ui.position == 'bottom-right' then
        return baseRight - pixelsToX(rightPixels), baseBottom - pixelsToY(upPixels), true
    end

    return baseRight - pixelsToX(rightPixels), baseTop + pixelsToY(downPixels), true
end

local function drawHudTextLine(x, y, text, rightAlign, r, g, b)
    local drawConfig = Config.Ui.drawText

    local function drawPass(drawX, drawY)
        SetTextFont(drawConfig.font or 0)
        SetTextScale(drawConfig.scale or 0.33, drawConfig.scale or 0.33)
        SetTextColour(r, g, b, 255)
        SetTextDropshadow(drawConfig.outlineThickness or 2, 0, 0, 0, 255)
        SetTextEdge(drawConfig.outlineThickness or 2, 0, 0, 0, 255)
        SetTextOutline()
        SetTextCentre(false)

        if rightAlign then
            SetTextRightJustify(true)
            SetTextWrap(0.0, x)
        else
            SetTextRightJustify(false)
        end

        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(drawX, drawY)
    end

    local boldPasses = math.max(1, math.floor(drawConfig.boldPasses or 1))
    local boldOffset = drawConfig.boldOffset or 0.00045

    if boldPasses > 1 then
        for pass = 1, boldPasses - 1 do
            local passOffset = boldOffset * pass
            drawPass(x + passOffset, y)
            drawPass(x - passOffset, y)
            drawPass(x, y + passOffset)
            drawPass(x, y - passOffset)
        end
    end

    drawPass(x, y)
end

local function startsWithLabel(statusText, label)
    local loweredStatus = TTDAOPUtils.ToLower(statusText or '')
    local loweredLabel = TTDAOPUtils.ToLower(label or '')

    if TTDAOPUtils.IsEmpty(loweredLabel) then
        return false
    end

    return loweredStatus:sub(1, #loweredLabel) == loweredLabel
end

local function formatPriorityLine(label, statusText)
    if startsWithLabel(statusText, label) then
        return statusText
    end

    return ('%s: %s'):format(label, statusText)
end

local function buildPriorityStatusText(priority)
    if priority.status == 'inactive' then
        return Config.Branding.statusText.inactive, nil, nil
    end

    if priority.status == 'active' then
        local participants = priority.participantsText
        if TTDAOPUtils.IsEmpty(participants) then
            participants = ('#%s'):format(priority.holder or '?')
        end

        return Config.Branding.statusText.active, participants, nil
    end

    if priority.status == 'cooldown' then
        return Config.Branding.statusText.cooldown, nil, ('%s minutes'):format(priority.cooldownMinutesRemaining)
    end

    local holderText = ('#%s'):format(priority.holder or '?')
    if TTDAOPUtils.IsEmpty(priority.holdReason) then
        return Config.Branding.statusText.hold, holderText, nil
    end

    return Config.Branding.statusText.hold, holderText, priority.holdReason
end

local function drawHud()
    if not Config.Ui.enabled or not currentState then
        return
    end

    local x, y, rightAlign = getAnchorByPosition()
    local lineHeight = Config.Ui.drawText.lineHeight or 0.028
    local whiteR, whiteG, whiteB = hexToRgb(Config.Ui.colors.text)
    local statusR, statusG, statusB = getStatusColor(currentState.priority.status)
    local statusText, participantText, tailText = buildPriorityStatusText(currentState.priority)

    local aopLine = ('%s: %s'):format(Config.Ui.aopLabel, currentState.aop)
    drawHudTextLine(x, y, aopLine, rightAlign, whiteR, whiteG, whiteB)

    local priorityBase = formatPriorityLine(Config.Ui.priorityLabel, statusText)
    drawHudTextLine(x, y + lineHeight, priorityBase, rightAlign, statusR, statusG, statusB)

    if participantText and not TTDAOPUtils.IsEmpty(participantText) then
        drawHudTextLine(x, y + (lineHeight * 2), ('(%s)'):format(participantText), rightAlign, whiteR, whiteG, whiteB)
    elseif tailText and not TTDAOPUtils.IsEmpty(tailText) then
        drawHudTextLine(x, y + (lineHeight * 2), ('(%s)'):format(tailText), rightAlign, whiteR, whiteG, whiteB)
    end
end

local function showFeedNotification(message)
    if not Config.Notifications.useFeedForAopChange then
        return
    end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(Config.Notifications.feedFlash, true)
    PlaySoundFrontend(-1, Config.Notifications.sound.name, Config.Notifications.sound.set, true)
end

local function sendChatMessage(prefix, message, color)
    TriggerEvent('chat:addMessage', {
        color = color or { 255, 255, 255 },
        multiline = false,
        args = { prefix, message }
    })
end

RegisterNetEvent('ttdaop:client:state', function(state)
    currentState = state
end)

RegisterNetEvent('ttdaop:client:aopChanged', function(payload)
    local message = payload.message or ('AOP has changed to %s'):format(payload.aop)

    if Config.Notifications.useChatForAopChange then
        sendChatMessage('AOP', message, { 255, 255, 255 })
    end

    showFeedNotification(message)
end)

RegisterNetEvent('ttdaop:client:priorityRequest', function(message)
    sendChatMessage('Priority Request', message, { 244, 211, 94 })

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
    PlaySoundFrontend(-1, Config.Notifications.sound.name, Config.Notifications.sound.set, true)
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('ttdaop:server:requestSync')
end)

CreateThread(function()
    while true do
        Wait(0)
        drawHud()
    end
end)
