-- FRZ Phone - gestion des appels cote serveur.
-- Un appel actif = { caller = src, callee = src, state = 'ringing|active', startedAt }

local CALLS = {}  -- callId -> call
local nextCallId = 1
local SRC_TO_CALL = {}  -- src -> callId

local function newCallId()
    local id = tostring(nextCallId); nextCallId = nextCallId + 1; return id
end

local function endCall(callId, reason)
    local call = CALLS[callId]; if not call then return end
    CALLS[callId] = nil
    for _, src in ipairs({ call.caller, call.callee }) do
        SRC_TO_CALL[src] = nil
        TriggerClientEvent('frz-phone:callEnded', src, reason or 'ended')
        TriggerClientEvent('frz-phone:voice:disconnect', src)
    end
    -- Log dans le call history des deux.
    if FrzPhone and FrzPhone.ensurePhone then
        local function log(src, otherNumber, ctype)
            local id
            for _, ident in ipairs(GetPlayerIdentifiers(src) or {}) do
                if ident:match('^license:') then id = ident; break end
            end
            if not id then
                for _, ident in ipairs(GetPlayerIdentifiers(src) or {}) do
                    if ident:match('^steam:') then id = ident; break end
                end
            end
            if not id then id = 'ip:' .. (GetPlayerEndpoint(src) or tostring(src)) end
            if not id then return end
            local p = FrzPhone.ensurePhone(id)
            table.insert(p.callLog, 1, { number = otherNumber, type = ctype, ts = os.time() })
            -- Limit 50.
            while #p.callLog > 50 do table.remove(p.callLog) end
            FrzPhone.sendState(src)
        end
        log(call.caller, call.calleeNumber, call.connectedAt and 'out' or 'out-missed')
        log(call.callee, call.callerNumber, call.connectedAt and 'in' or 'missed')
    end
end

RegisterNetEvent('frz-phone:call:start', function(targetNumber)
    local src = source
    if SRC_TO_CALL[src] then return end
    local targetSrc = FrzPhone and FrzPhone.NUMBER_TO_ID and FrzPhone.NUMBER_TO_ID[targetNumber]
                         and FrzPhone.ONLINE and FrzPhone.ONLINE[FrzPhone.NUMBER_TO_ID[targetNumber]]
    if not targetSrc then
        TriggerClientEvent('frz-phone:callEnded', src, 'unavailable')
        return
    end
    if SRC_TO_CALL[targetSrc] then
        TriggerClientEvent('frz-phone:callEnded', src, 'busy')
        return
    end

    local function resolveId(playerSrc)
        for _, i in ipairs(GetPlayerIdentifiers(playerSrc) or {}) do
            if i:match('^license:') then return i end
        end
        for _, i in ipairs(GetPlayerIdentifiers(playerSrc) or {}) do
            if i:match('^steam:') then return i end
        end
        return 'ip:' .. (GetPlayerEndpoint(playerSrc) or tostring(playerSrc))
    end
    local callerId = resolveId(src)
    local callerPhone = FrzPhone.ensurePhone(callerId)
    local calleeId = resolveId(targetSrc)
    local calleePhone = FrzPhone.ensurePhone(calleeId)

    local id = newCallId()
    CALLS[id] = {
        id = id,
        caller = src, callee = targetSrc,
        callerNumber = callerPhone.number, calleeNumber = calleePhone.number,
        state = 'ringing',
        startedAt = os.time(),
    }
    SRC_TO_CALL[src] = id
    SRC_TO_CALL[targetSrc] = id

    -- Cherche le nom dans les contacts du callee pour affichage.
    local callerName = callerPhone.number
    for _, c in ipairs(calleePhone.contacts) do
        if c.number == callerPhone.number then callerName = c.name; break end
    end

    -- Nom du callee pour l'affichage cote caller.
    local calleeName = calleePhone.number
    for _, c in ipairs(callerPhone.contacts) do
        if c.number == calleePhone.number then calleeName = c.name; break end
    end

    TriggerClientEvent('frz-phone:incomingCall', targetSrc, callerPhone.number, callerName)
    -- Etat "ringing" cote caller : evenement distinct de callConnected.
    TriggerClientEvent('frz-phone:outgoingCall', src, calleePhone.number, calleeName)

    -- Timeout 30s si pas de reponse.
    SetTimeout(30000, function()
        local c = CALLS[id]
        if c and c.state == 'ringing' then endCall(id, 'timeout') end
    end)
end)

RegisterNetEvent('frz-phone:call:answer', function()
    local src = source
    local callId = SRC_TO_CALL[src]; if not callId then return end
    local call = CALLS[callId]; if not call or call.state ~= 'ringing' then return end
    call.state = 'active'
    call.connectedAt = os.time()
    TriggerClientEvent('frz-phone:callConnected', call.caller, call.calleeNumber, call.calleeNumber)
    TriggerClientEvent('frz-phone:callConnected', call.callee, call.callerNumber, call.callerNumber)
    TriggerClientEvent('frz-phone:voice:connect', call.caller, call.callee, call.calleeNumber)
    TriggerClientEvent('frz-phone:voice:connect', call.callee, call.caller, call.callerNumber)
end)

RegisterNetEvent('frz-phone:call:decline', function()
    local src = source
    local callId = SRC_TO_CALL[src]; if not callId then return end
    endCall(callId, 'declined')
end)

RegisterNetEvent('frz-phone:call:hangup', function()
    local src = source
    local callId = SRC_TO_CALL[src]; if not callId then return end
    endCall(callId, 'hangup')
end)

AddEventHandler('playerDropped', function()
    local src = source
    local callId = SRC_TO_CALL[src]
    if callId then endCall(callId, 'peer-disconnected') end
end)
