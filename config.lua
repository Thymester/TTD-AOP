Config = {}

--[[
TTD-AOP CONFIG (Non-Dev Friendly)

Quick tips:
1) You can safely change values on the RIGHT side only.
2) Do NOT rename keys on the LEFT side (example: aop, adminOnly, aliases).
3) true = enabled, false = disabled.
4) Numbers are minutes unless noted otherwise.
5) Restart the resource after config changes.
]]

-- ======================================
-- DEFAULT GAMEPLAY VALUES
-- ======================================
Config.Defaults = {
    -- Default Area of Patrol when server starts.
    aop = 'Los Santos',

    -- Default cooldown used by /setprio cd if no custom minutes are provided.
    priorityCooldownMinutes = 10,

    -- Optional fallback hold reason (currently informational).
    holdDefaultReason = ''
}

-- ======================================
-- IF PRIORITY HOLDER LEAVES SERVER
-- ======================================
Config.DisconnectBehavior = {
    -- true  = move to cooldown
    -- false = move straight to inactive
    cooldown = true,

    -- Minutes to use when cooldown = true.
    cooldownMinutes = 10
}

-- ======================================
-- ADMIN PERMISSIONS
-- ======================================
Config.Admin = {
    -- If true, ACE permission check is used.
    -- If false, only identifiers list below is used.
    useAcePermission = true,

    -- ACE permission node to grant to admins.
    acePermission = 'ttdaop.admin',

    -- Add admin identifiers here.
    -- Example formats:
    -- 'license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
    -- 'discord:123456789012345678'
    -- 'fivem:12345678'
    identifiers = {
        -- 'license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
        'discord:220512977642586113',
        'discord:217017445016272896'
    }
}

-- ======================================
-- HUD / ON-SCREEN TEXT (DRAW TEXT)
-- ======================================
Config.Ui = {
    -- Turn on-screen AOP/Priority text on/off.
    enabled = true,

    -- Position options: 'top-left', 'top-right', 'bottom-left', 'bottom-right'
    position = 'top-right',

    -- Label text displayed on the panel.
    aopLabel = 'AOP',
    priorityLabel = 'Priority',

    -- Show participant IDs when priority is active.
    showParticipants = true,

    -- Text colors.
    colors = {
        text = '#FFFFFF',
        inactive = '#3CB371',
        active = '#FF4D4D',
        cooldown = '#9E9E9E',
        hold = '#F4D35E'
    },

    drawText = {
        -- Uses native FiveM DrawText only (no black box background).
        -- Text is rendered with a black outline/drop-shadow for readability.

        -- Font ID (0 is GTA default and easiest to read).
        font = 0,

        -- Text scale/size.
        scale = 0.33,

        -- Distance between each line.
        lineHeight = 0.028,

        -- Corner offsets in pixels.
        -- Only the matching sides are used based on the selected corner.
        -- top-left:    left + down
        -- top-right:   right + down
        -- bottom-left:  left + up
        -- bottom-right: right + up
        -- These values are treated as 1080p-baseline pixels and are scaled
        -- to the current screen resolution automatically.
        baselineResolutionWidth = 1920,
        baselineResolutionHeight = 1080,
        pixelOffsetLeft = 0,
        pixelOffsetRight = 0,
        pixelOffsetUp = 0,
        pixelOffsetDown = 0,

        -- Outline strength (visual 2px-style edge/shadow).
        outlineThickness = 2,

        -- Extra bold effect by drawing same text multiple times with tiny offsets.
        -- 1 = normal, 2+ = bolder.
        boldPasses = 2,

        -- Offset per bold pass. Increase slightly if you want thicker text.
        boldOffset = 0.00045
    }
}

-- ======================================
-- NOTIFICATIONS
-- ======================================
Config.Notifications = {
    -- Show AOP change in chat.
    useChatForAopChange = true,

    -- Show GTA feed notification above minimap.
    useFeedForAopChange = true,

    -- GTA feed style options.
    feedIconType = 1,
    feedFlash = false,

    -- GTA sound played for key notifications.
    sound = {
        name = 'EVENT_START_TEXT',
        set = 'GTAO_FM_EVENTS_SOUNDSET'
    }
}

-- ======================================
-- GAME / MAP DISPLAY TEXT
-- ======================================
Config.Branding = {
    -- Final game name format. First %s = prefix, second %s = priority text.
    gameNameTemplate = '%s | %s',

    -- Server name part shown in game display text.
    gameNamePrefix = 'TTD Roleplay',

    -- Map name format. %s = current AOP.
    mapNameTemplate = 'AOP: %s',

    -- Priority status text labels.
    statusText = {
        inactive = 'Priority: Inactive',
        active = 'Priority: Active',
        cooldown = 'Priority: Cooldown',
        hold = 'Priority: On Hold'
    }
}

-- ======================================
-- COMMAND NAMES + ADMIN RULES
-- ======================================
Config.Commands = {
    aop = {
        -- /aop
        name = 'aop'
    },
    aopSet = {
        -- /aopset <name>
        name = 'aopset',
        adminOnly = true
    },
    prio = {
        -- /prio start and /prio stop
        name = 'prio',

        -- Set true if you want ONLY admins to be able to start prio.
        startAdminOnly = false,

        -- Usually true so only admins can force stop.
        stopAdminOnly = true
    },
    setPrio = {
        -- /setprio cd [minutes], /setprio hold [reason]
        name = 'setprio',
        adminOnly = true
    },
    prioJoin = {
        -- /priojoin request|accept|deny
        name = 'priojoin'
    }
}

-- ======================================
-- PRIORITY JOIN REQUEST SETTINGS
-- ======================================
Config.JoinRequests = {
    -- Command aliases players can use.
    aliases = {
        request = { 'req', 'request' },
        accept = { 'acc', 'accept' },
        deny = { 'deny' }
    },

    -- After this many denies, requester is temporarily blocked.
    maxDeniedBeforeCooldown = 3,

    -- Block duration after deny spam.
    deniedRequestCooldownMinutes = 5,

    -- Time window used to count deny-spam attempts.
    deniedWindowMinutes = 20
}

-- ======================================
-- CHAT/NOTIFICATION MESSAGES
-- ======================================
-- You can safely edit message text below.
-- Keep %s placeholders intact where present.
Config.Messages = {
    noPermission = '^1You do not have permission to use this command.^0',
    invalidCommand = '^1Invalid command usage.^0',
    currentAop = '^2Current AOP:^0 %s',
    aopChangedBroadcast = '^3AOP has changed to:^0 %s',
    priorityAlreadyActive = '^1A priority is already active.^0',
    priorityStarted = '^2Priority started by:^0 #%s',
    priorityStopped = '^3Priority has been set to inactive.^0',
    priorityCooldownSet = '^3Priority cooldown started for %s minutes.^0',
    priorityHoldSet = '^3Priority is now on hold.^0',
    priorityHoldResumed = '^2Priority hold lifted. Priority is active again.^0',
    noActivePriority = '^1No active priority right now.^0',
    alreadyInPriority = '^1You are already part of the active priority.^0',
    requestSent = '^2Join request sent to active priority holder.^0',
    noPendingRequest = '^1No pending join requests to process.^0',
    notPriorityHolder = '^1Only the active priority holder can do this.^0',
    requestAccepted = '^2Your join request was accepted. You are now in the active priority.^0',
    requestDenied = '^1Your join request was denied.^0',
    requestDeniedCooldown = '^1You have been temporarily blocked from sending priority requests for %s minute(s).^0',
    requestBlockedActiveCooldown = '^1You are currently on request cooldown for %s minute(s).^0',
    holdReasonTemplate = 'Reason: %s',
    joinRequestTemplate = 'Priority Request: %s #%s is requesting to join your active priority. To either accept or deny, do /%s accept or /%s deny',
    joinRequestAcceptedByHolder = '^2Join request accepted.^0',
    joinRequestDeniedByHolder = '^3Join request denied.^0',
    requestFailedGeneric = '^1Unable to send priority join request right now.^0',
    cooldownEndedBroadcast = '^2Priority cooldown ended. Priority is now inactive.^0',
    holderLeftCooldown = '^3Active priority holder disconnected. Priority is now on cooldown for %s minute(s).^0',
    holderLeftInactive = '^3Active priority holder disconnected. Priority is now inactive.^0'
}
