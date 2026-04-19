-- FRZ Phone - client principal
local isOpen = false
local myData = nil  -- { number, os, contacts, messages, callLog }

local function hasPhoneItem()
    if not Config.RequirePhoneItem then return true end
    local inv = GetResourceState('frz-inventory')
    if inv ~= 'started' then return true end  -- inventaire absent : on autorise
    return exports['frz-inventory']:hasItem('phone', 1)
end

local function openPhone()
    if isOpen then return end
    if not hasPhoneItem() then
        SetNotificationTextEntry('STRING')
        AddTextComponentString('Vous n\'avez pas de telephone.')
        DrawNotification(false, false)
        return
    end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = myData or {},
        apps = Config.Apps,
    })
end

local function closePhone()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb) closePhone(); cb({ok=true}) end)

RegisterNUICallback('call', function(data, cb)
    TriggerServerEvent('frz-phone:call:start', data.number)
    cb({ok=true})
end)

RegisterNUICallback('hangup', function(_, cb)
    TriggerServerEvent('frz-phone:call:hangup')
    cb({ok=true})
end)

RegisterNUICallback('answer', function(_, cb)
    TriggerServerEvent('frz-phone:call:answer')
    cb({ok=true})
end)

RegisterNUICallback('decline', function(_, cb)
    TriggerServerEvent('frz-phone:call:decline')
    cb({ok=true})
end)

RegisterNUICallback('sendMessage', function(data, cb)
    TriggerServerEvent('frz-phone:message:send', data.to, data.text)
    cb({ok=true})
end)

RegisterNUICallback('addContact', function(data, cb)
    TriggerServerEvent('frz-phone:contact:add', data.name, data.number)
    cb({ok=true})
end)

RegisterNUICallback('removeContact', function(data, cb)
    TriggerServerEvent('frz-phone:contact:remove', data.number)
    cb({ok=true})
end)

RegisterNUICallback('setOS', function(data, cb)
    TriggerServerEvent('frz-phone:setOS', data.os)
    cb({ok=true})
end)

RegisterNUICallback('bank', function(data, cb)
    TriggerServerEvent('frz-phone:bank:action', data)
    cb({ok=true})
end)

-- Etat synchronise par le serveur.
RegisterNetEvent('frz-phone:setState', function(state)
    myData = state
    if isOpen then
        SendNUIMessage({ action = 'update', data = state })
    end
end)

RegisterNetEvent('frz-phone:incomingCall', function(fromNumber, fromName)
    SendNUIMessage({ action = 'incomingCall', from = fromNumber, name = fromName })
    -- Ouvre le phone si ferme.
    if not isOpen then openPhone() end
end)

RegisterNetEvent('frz-phone:callEnded', function(reason)
    SendNUIMessage({ action = 'callEnded', reason = reason })
end)

RegisterNetEvent('frz-phone:callConnected', function(peerNumber, peerName)
    SendNUIMessage({ action = 'callConnected', number = peerNumber, name = peerName })
end)

RegisterNetEvent('frz-phone:outgoingCall', function(peerNumber, peerName)
    SendNUIMessage({ action = 'outgoingCall', number = peerNumber, name = peerName })
    if not isOpen then openPhone() end
end)

RegisterNetEvent('frz-phone:notify', function(msg, type)
    SendNUIMessage({ action = 'notify', message = msg, type = type })
end)

RegisterNetEvent('frz-phone:newMessage', function(fromNumber, text)
    SendNUIMessage({ action = 'newMessage', from = fromNumber, text = text })
    -- Notification GTA discrete si phone ferme.
    if not isOpen then
        SetNotificationTextEntry('STRING')
        AddTextComponentString(('SMS de %s : %s'):format(fromNumber, text))
        DrawNotification(false, false)
    end
end)

RegisterCommand('frz_phone_toggle', function()
    if isOpen then closePhone() else openPhone() end
end, false)

RegisterKeyMapping('frz_phone_toggle', 'Ouvrir FRZ Phone', 'keyboard', Config.OpenKey or 'F1')

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('frz-phone:requestState')
end)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(200) end
    Wait(500)
    TriggerServerEvent('frz-phone:requestState')
end)

-- Quand l'inventaire declare que le joueur utilise un "phone" -> ouvre le tel.
RegisterNetEvent('frz-inventory:itemUsed', function(itemName)
    if itemName == 'phone' then openPhone() end
end)

-- Export : numero de telephone local (utile pour frz-bank).
exports('getMyNumber', function()
    return myData and myData.number or nil
end)

exports('openPhone', openPhone)
exports('closePhone', closePhone)
