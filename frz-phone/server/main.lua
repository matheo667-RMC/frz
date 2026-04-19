-- FRZ Phone - serveur principal
-- Stockage JSON : phones.json (identifier -> data), messages.json, calls.json.

local PHONES = {}   -- identifier -> { number, os, contacts, callLog }
local MESSAGES = {} -- number -> [ {from, to, text, ts} ]
local NUMBER_TO_ID = {}  -- phone_number -> identifier (pour routing appels/SMS)
local ONLINE = {}   -- identifier -> src

-- ============================================================================
-- Utilities
-- ============================================================================

local function getIdentifier(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:match('^license:') then return id end
    end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:match('^steam:') then return id end
    end
    return 'ip:' .. (GetPlayerEndpoint(src) or tostring(src))
end

local function generateNumber()
    -- Evite les collisions.
    for _ = 1, 20 do
        local n = Config.NumberPrefix or '555-'
        local digits = Config.NumberDigits or 4
        for _ = 1, digits do
            n = n .. tostring(math.random(0, 9))
        end
        if not NUMBER_TO_ID[n] then return n end
    end
    return (Config.NumberPrefix or '555-') .. tostring(os.time()):sub(-4)
end

local function savePhones()
    SaveResourceFile(GetCurrentResourceName(), Config.PhoneDataFile or 'phones.json',
        json.encode(PHONES), -1)
    SaveResourceFile(GetCurrentResourceName(), Config.MessagesFile or 'messages.json',
        json.encode(MESSAGES), -1)
end

local function loadPhones()
    local raw = LoadResourceFile(GetCurrentResourceName(), Config.PhoneDataFile or 'phones.json')
    if raw and raw ~= '' then
        local ok, parsed = pcall(json.decode, raw)
        if ok and type(parsed) == 'table' then
            PHONES = parsed
            for id, p in pairs(PHONES) do
                if p.number then NUMBER_TO_ID[p.number] = id end
            end
        end
    end
    local raw2 = LoadResourceFile(GetCurrentResourceName(), Config.MessagesFile or 'messages.json')
    if raw2 and raw2 ~= '' then
        local ok, parsed = pcall(json.decode, raw2)
        if ok and type(parsed) == 'table' then MESSAGES = parsed end
    end
end

loadPhones()

CreateThread(function()
    while true do Wait(60000); savePhones() end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then savePhones() end
end)

-- ============================================================================
-- Phone data helpers
-- ============================================================================

local function ensurePhone(id)
    if PHONES[id] then return PHONES[id] end
    local phone = {
        number = generateNumber(),
        os = Config.DefaultOS or 'iphone',
        contacts = {},   -- [ {name, number} ]
        callLog = {},    -- [ {number, name, type='in|out|missed', ts} ]
    }
    PHONES[id] = phone
    NUMBER_TO_ID[phone.number] = id
    return phone
end

local function messagesForNumber(num)
    if not MESSAGES[num] then MESSAGES[num] = {} end
    return MESSAGES[num]
end

local function sendState(src)
    local id = getIdentifier(src)
    local phone = ensurePhone(id)
    local msgs = messagesForNumber(phone.number)
    -- Regroupe les messages par conversation (autre numero).
    local convos = {}  -- number -> {name, messages[]}
    for _, m in ipairs(msgs) do
        local other = (m.from == phone.number) and m.to or m.from
        if not convos[other] then convos[other] = { number = other, name = other, messages = {} } end
        table.insert(convos[other].messages, m)
    end
    -- Associe les noms de contacts.
    for _, c in ipairs(phone.contacts) do
        if convos[c.number] then convos[c.number].name = c.name end
    end
    local convoList = {}
    for _, v in pairs(convos) do table.insert(convoList, v) end

    -- Solde bancaire via frz-bank (export optionnel).
    local bank = { balance = 0, card = nil, transactions = {} }
    if GetResourceState('frz-bank') == 'started' then
        local ok, data = pcall(function()
            return exports['frz-bank']:getAccount(src)
        end)
        if ok and data then bank = data end
    end

    TriggerClientEvent('frz-phone:setState', src, {
        number = phone.number,
        os = phone.os,
        contacts = phone.contacts,
        callLog = phone.callLog,
        conversations = convoList,
        bank = bank,
    })
end

-- ============================================================================
-- Events client
-- ============================================================================

RegisterNetEvent('frz-phone:requestState', function()
    local src = source
    local id = getIdentifier(src)
    ensurePhone(id)
    ONLINE[id] = src
    sendState(src)
end)

RegisterNetEvent('frz-phone:setOS', function(osName)
    local src = source
    if osName ~= 'iphone' and osName ~= 'android' then return end
    local id = getIdentifier(src)
    local phone = ensurePhone(id)
    phone.os = osName
    sendState(src)
end)

RegisterNetEvent('frz-phone:contact:add', function(name, number)
    local src = source
    if not name or not number then return end
    name = tostring(name):sub(1, 32)
    number = tostring(number):sub(1, 20)
    local id = getIdentifier(src)
    local phone = ensurePhone(id)
    -- Dedup.
    for _, c in ipairs(phone.contacts) do
        if c.number == number then c.name = name; sendState(src); return end
    end
    table.insert(phone.contacts, { name = name, number = number })
    sendState(src)
end)

RegisterNetEvent('frz-phone:contact:remove', function(number)
    local src = source
    local id = getIdentifier(src)
    local phone = ensurePhone(id)
    for i, c in ipairs(phone.contacts) do
        if c.number == number then table.remove(phone.contacts, i); break end
    end
    sendState(src)
end)

RegisterNetEvent('frz-phone:message:send', function(toNumber, text)
    local src = source
    if not toNumber or not text or text == '' then return end
    text = tostring(text):sub(1, 500)
    toNumber = tostring(toNumber)
    local id = getIdentifier(src)
    local phone = ensurePhone(id)
    local msg = {
        from = phone.number,
        to = toNumber,
        text = text,
        ts = os.time(),
    }
    table.insert(messagesForNumber(phone.number), msg)
    table.insert(messagesForNumber(toNumber), msg)
    -- Notification au destinataire si en ligne.
    local targetId = NUMBER_TO_ID[toNumber]
    if targetId and ONLINE[targetId] then
        TriggerClientEvent('frz-phone:newMessage', ONLINE[targetId], phone.number, text)
        sendState(ONLINE[targetId])
    end
    sendState(src)
end)

-- Banque proxy : delegue au resource frz-bank si present.
RegisterNetEvent('frz-phone:bank:action', function(payload)
    local src = source
    if GetResourceState('frz-bank') ~= 'started' then
        TriggerClientEvent('frz-phone:notify', src, 'Service bancaire indisponible', 'error')
        return
    end
    local pcallOk, bankOk, bankErr = pcall(function()
        return exports['frz-bank']:handlePhoneAction(src, payload)
    end)
    if not pcallOk then
        TriggerClientEvent('frz-phone:notify', src, 'Erreur banque', 'error')
    elseif bankOk == false then
        TriggerClientEvent('frz-phone:notify', src, 'Erreur : ' .. tostring(bankErr or 'inconnue'), 'error')
    else
        TriggerClientEvent('frz-phone:notify', src, 'Operation effectuee', 'success')
    end
    sendState(src)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local id = getIdentifier(src)
    ONLINE[id] = nil
    savePhones()
end)

-- ============================================================================
-- Exports pour autres resources
-- ============================================================================

exports('getPhoneNumber', function(src)
    local id = getIdentifier(src)
    local p = ensurePhone(id)
    return p.number
end)

exports('getSourceByNumber', function(number)
    local id = NUMBER_TO_ID[number]
    return id and ONLINE[id] or nil
end)

exports('sendNotification', function(src, msg, type)
    TriggerClientEvent('frz-phone:notify', src, msg, type)
end)

exports('refreshPhone', function(src) sendState(src) end)

-- Helpers internes utilises par calls.lua.
FrzPhone = FrzPhone or {}
FrzPhone.ensurePhone = ensurePhone
FrzPhone.NUMBER_TO_ID = NUMBER_TO_ID
FrzPhone.ONLINE = ONLINE
FrzPhone.sendState = sendState
