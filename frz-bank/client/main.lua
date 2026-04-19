-- FRZ Bank - client
-- - Blips et markers aux banques
-- - Detection ATM + touche E
-- - Ouverture NUI pour operations bancaires

local isOpen = false
local nearBank = nil     -- { name, x, y, z }
local nearATM = nil      -- entity handle
local account = { balance = 0, transactions = {} }

-- ============================================================================
-- UI
-- ============================================================================

local function openUI(context)
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        context = context,  -- 'atm' | 'bank' | 'phone'
        account = account,
        maxWithdraw = Config.MaxWithdraw,
        maxTransfer = Config.MaxTransfer,
    })
end

local function closeUI()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb) closeUI(); cb({ok=true}) end)

RegisterNUICallback('action', function(data, cb)
    TriggerServerEvent('frz-bank:action', data)
    cb({ok=true})
end)

RegisterNetEvent('frz-bank:setAccount', function(acc)
    account = acc
    if isOpen then
        SendNUIMessage({ action = 'update', account = account })
    end
end)

RegisterNetEvent('frz-bank:notify', function(msg, type)
    SendNUIMessage({ action = 'notify', message = msg, type = type })
end)

-- ============================================================================
-- Blips
-- ============================================================================

CreateThread(function()
    if not Config.ShowBankBlips then return end
    for _, b in ipairs(Config.Banks) do
        local blip = AddBlipForCoord(b.x, b.y, b.z)
        SetBlipSprite(blip, 108)   -- dollar sign
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.85)
        SetBlipColour(blip, 2)     -- vert
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(b.name or 'Banque FRZ')
        EndTextCommandSetBlipName(blip)
    end
end)

-- ============================================================================
-- Interaction banque (E pour ouvrir le menu)
-- ============================================================================

local function drawBankMarker(b)
    DrawMarker(
        1,                           -- type
        b.x, b.y, b.z - 0.98,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        1.2, 1.2, 0.6,
        231, 76, 60, 140,
        false, true, 2, false, nil, nil, false
    )
end

local function drawHelpText(text)
    SetTextComponentFormat('STRING')
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local p = GetEntityCoords(ped)
        local closest, closestDist = nil, math.huge
        for _, b in ipairs(Config.Banks) do
            local d = #(p - vector3(b.x, b.y, b.z))
            if d < 30.0 then
                sleep = 0
                if b.marker then drawBankMarker(b) end
                if d < (Config.BankInteractDistance or 1.8) and d < closestDist then
                    closest, closestDist = b, d
                end
            end
        end
        nearBank = closest
        if nearBank then
            drawHelpText('Appuyez sur ~INPUT_CONTEXT~ pour accéder à la banque')
            if IsControlJustReleased(0, 38) and not isOpen then  -- E
                openUI('bank')
            end
        end
        Wait(sleep)
    end
end)

-- ============================================================================
-- Interaction ATM
-- ============================================================================

CreateThread(function()
    while true do
        local sleep = 750
        local ped = PlayerPedId()
        local p = GetEntityCoords(ped)
        local found = nil
        for _, model in ipairs(Config.ATMModels) do
            local obj = GetClosestObjectOfType(p.x, p.y, p.z, (Config.ATMInteractDistance or 1.2) + 0.5,
                GetHashKey(model), false, false, false)
            if obj ~= 0 and DoesEntityExist(obj) then
                local oc = GetEntityCoords(obj)
                local d = #(p - oc)
                if d < (Config.ATMInteractDistance or 1.2) + 0.3 then
                    found = obj
                    sleep = 0
                    break
                end
            end
        end
        nearATM = found
        if nearATM then
            drawHelpText('Appuyez sur ~INPUT_CONTEXT~ pour utiliser le distributeur')
            if IsControlJustReleased(0, 38) and not isOpen then
                openUI('atm')
            end
        end
        Wait(sleep)
    end
end)

-- ESC ferme via NUI cote JS, mais on expose aussi une commande.
RegisterCommand('frz_bank_close', closeUI, false)

-- Quand un joueur utilise un item "bankcard" (inventaire), on ouvre la banque (depot/retrait).
RegisterNetEvent('frz-inventory:itemUsed', function(itemName)
    if itemName == 'bankcard' or itemName == 'wallet' then
        TriggerServerEvent('frz-bank:refresh')
    end
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('frz-bank:refresh')
end)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(200) end
    Wait(500)
    TriggerServerEvent('frz-bank:refresh')
end)
