-- FRZ Bank - serveur
-- Comptes indexes par license. Transactions journalisees.
-- Integration :
--   - frz-phone:  export handlePhoneAction + getAccount
--   - frz-inventory: utilise addItem/removeItem pour cash/bankcard (si present)

local ACCOUNTS = {}  -- identifier -> { balance, transactions = [] , cardNumber }
local ONLINE = {}    -- identifier -> src

-- ============================================================================
-- Persistance
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

local function saveAll()
    SaveResourceFile(GetCurrentResourceName(), Config.PersistenceFile or 'bank.json',
        json.encode(ACCOUNTS), -1)
end

local function loadAll()
    local raw = LoadResourceFile(GetCurrentResourceName(), Config.PersistenceFile or 'bank.json')
    if raw and raw ~= '' then
        local ok, parsed = pcall(json.decode, raw)
        if ok and type(parsed) == 'table' then ACCOUNTS = parsed end
    end
end

loadAll()
CreateThread(function() while true do Wait(60000); saveAll() end end)
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then saveAll() end
end)

local function ensureAccount(id)
    if ACCOUNTS[id] then return ACCOUNTS[id] end
    ACCOUNTS[id] = {
        balance = Config.StartingBalance or 0.0,
        transactions = {},
        cardNumber = nil,
    }
    return ACCOUNTS[id]
end

local function getPhoneNumber(src)
    if GetResourceState('frz-phone') ~= 'started' then return nil end
    local ok, num = pcall(function() return exports['frz-phone']:getPhoneNumber(src) end)
    return ok and num or nil
end

local function findSourceByPhoneNumber(number)
    if GetResourceState('frz-phone') ~= 'started' then return nil end
    local ok, src = pcall(function() return exports['frz-phone']:getSourceByNumber(number) end)
    return ok and src or nil
end

local function findIdByPhoneNumber(number)
    local src = findSourceByPhoneNumber(number)
    if not src then return nil end
    return getIdentifier(src)
end

-- ============================================================================
-- Transactions
-- ============================================================================

local function addTransaction(account, label, amount, type_)
    table.insert(account.transactions, 1, {
        label = label, amount = amount, type = type_, ts = os.time(),
    })
    while #account.transactions > 50 do table.remove(account.transactions) end
end

local function sendAccount(src)
    local id = getIdentifier(src)
    local a = ensureAccount(id)
    TriggerClientEvent('frz-bank:setAccount', src, {
        balance = a.balance,
        transactions = a.transactions,
        card = { holder = getPhoneNumber(src) or '—' },
    })
    -- Refresh phone UI.
    if GetResourceState('frz-phone') == 'started' then
        pcall(function() exports['frz-phone']:refreshPhone(src) end)
    end
end

local function notify(src, msg, type)
    TriggerClientEvent('frz-bank:notify', src, msg, type)
end

-- ============================================================================
-- Core operations
-- ============================================================================

local function deposit(src, amount)
    amount = tonumber(amount); if not amount or amount <= 0 then return false, 'montant invalide' end
    local id = getIdentifier(src)
    local a = ensureAccount(id)
    -- Retire le cash de l'inventaire si possible.
    if GetResourceState('frz-inventory') == 'started' then
        local have = 0
        pcall(function() have = exports['frz-inventory']:countItem(src, 'cash') end)
        if have < amount then
            return false, 'pas assez de cash'
        end
        local rmOk, rmRet = pcall(function() return exports['frz-inventory']:removeItem(src, 'cash', amount) end)
        if not rmOk or rmRet == false then
            return false, 'erreur retrait cash'
        end
    end
    a.balance = a.balance + amount
    addTransaction(a, 'Dépôt', amount, 'deposit')
    sendAccount(src)
    return true
end

local function withdraw(src, amount)
    amount = tonumber(amount); if not amount or amount <= 0 then return false, 'montant invalide' end
    if amount > (Config.MaxWithdraw or math.huge) then return false, 'plafond depasse' end
    local id = getIdentifier(src)
    local a = ensureAccount(id)
    if a.balance < amount then return false, 'solde insuffisant' end
    -- On debite seulement si le cash peut etre credite dans l'inventaire (si present).
    if GetResourceState('frz-inventory') == 'started' then
        local addOk, addRet = pcall(function() return exports['frz-inventory']:addItem(src, 'cash', amount) end)
        if not addOk or addRet == false then
            return false, 'inventaire plein'
        end
    end
    a.balance = a.balance - amount
    addTransaction(a, 'Retrait', -amount, 'withdraw')
    sendAccount(src)
    return true
end

local function transfer(src, targetNumber, amount)
    amount = tonumber(amount); if not amount or amount <= 0 then return false, 'montant invalide' end
    if amount > (Config.MaxTransfer or math.huge) then return false, 'plafond depasse' end
    local id = getIdentifier(src)
    local a = ensureAccount(id)
    if a.balance < amount + (Config.TransferFee or 0) then return false, 'solde insuffisant' end

    local targetId = findIdByPhoneNumber(targetNumber)
    if not targetId then
        return false, 'destinataire introuvable'
    end
    local b = ensureAccount(targetId)
    a.balance = a.balance - amount - (Config.TransferFee or 0)
    b.balance = b.balance + amount

    local myNumber = getPhoneNumber(src) or '—'
    addTransaction(a, 'Virement vers ' .. targetNumber, -amount, 'transfer-out')
    addTransaction(b, 'Virement de ' .. myNumber, amount, 'transfer-in')
    sendAccount(src)
    -- Refresh destinataire s'il est online.
    local targetSrc = findSourceByPhoneNumber(targetNumber)
    if targetSrc then sendAccount(targetSrc) end
    return true
end

-- ============================================================================
-- Events client
-- ============================================================================

RegisterNetEvent('frz-bank:refresh', function()
    local src = source
    ONLINE[getIdentifier(src)] = src
    sendAccount(src)
end)

RegisterNetEvent('frz-bank:action', function(payload)
    local src = source
    local t = payload and payload.type
    local ok, err
    if t == 'deposit' then ok, err = deposit(src, payload.amount)
    elseif t == 'withdraw' then ok, err = withdraw(src, payload.amount)
    elseif t == 'transfer' then ok, err = transfer(src, payload.to, payload.amount)
    else return end
    if not ok then notify(src, 'Erreur : ' .. (err or 'inconnue'), 'error')
    else notify(src, 'Opération effectuée.', 'success') end
end)

AddEventHandler('playerDropped', function()
    local src = source
    ONLINE[getIdentifier(src)] = nil
    saveAll()
end)

-- ============================================================================
-- Exports (pour frz-phone, frz-inventory, etc.)
-- ============================================================================

exports('getBalance', function(src)
    local id = getIdentifier(src)
    return ensureAccount(id).balance
end)

exports('getAccount', function(src)
    local id = getIdentifier(src)
    local a = ensureAccount(id)
    return {
        balance = a.balance,
        transactions = a.transactions,
        card = { holder = getPhoneNumber(src) or '—' },
    }
end)

exports('deposit',  function(src, amt) return deposit(src, amt) end)
exports('withdraw', function(src, amt) return withdraw(src, amt) end)
exports('transfer', function(src, to, amt) return transfer(src, to, amt) end)

exports('handlePhoneAction', function(src, payload)
    local t = payload and payload.type
    if t == 'deposit' then return deposit(src, payload.amount)
    elseif t == 'withdraw' then return withdraw(src, payload.amount)
    elseif t == 'transfer' then return transfer(src, payload.to, payload.amount)
    end
    return false, 'action inconnue'
end)

-- ============================================================================
-- Admin
-- ============================================================================

RegisterCommand('frz_bank_set', function(source, args)
    if source ~= 0 then return end
    local target = tonumber(args[1])
    local amount = tonumber(args[2])
    if not target or not amount then
        print('Usage: frz_bank_set <playerId> <balance>')
        return
    end
    local id = getIdentifier(target)
    local a = ensureAccount(id)
    a.balance = amount
    addTransaction(a, 'Admin set', amount, 'admin')
    if ONLINE[id] then sendAccount(ONLINE[id]) end
    print(('balance de %d : %.2f'):format(target, amount))
end, true)
