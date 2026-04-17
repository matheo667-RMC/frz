-- FRZ RP - logique serveur pour la location de voitures au vendeur du terminal.
-- Utilise les helpers d'argent exposes par server/main.lua (FrzMoney_*).

local function isEnabled()
    return Config.CarRental ~= nil and Config.CarRental.enabled == true
end

local function findVehicle(model)
    if not isEnabled() or not Config.CarRental.vehicles then return nil end
    if type(model) ~= 'string' or model == '' then return nil end
    for _, v in ipairs(Config.CarRental.vehicles) do
        if v.model == model then return v end
    end
    return nil
end

-- Anti-spoof : verifie que le joueur est bien proche du vendeur config avant
-- de traiter une action. Evite qu'un client malveillant ouvre le menu ou spawn
-- une voiture depuis n'importe ou sur la map.
local function isNearDealer(src)
    if not isEnabled() or not Config.CarRental.pedPos then return false end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    if not coords then return false end

    local pp = Config.CarRental.pedPos
    local dx, dy, dz = coords.x - pp.x, coords.y - pp.y, coords.z - pp.z
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

    -- Marge : on accepte jusqu'a 2x la distance d'interaction (latence,
    -- position de spawn de la voiture un peu plus loin, etc.).
    local maxDist = ((Config.CarRental.interactionDistance or 2.5) * 2) + 5.0
    return dist <= maxDist
end

-- Client demande d'ouvrir le menu : on renvoie son solde pour affichage.
RegisterNetEvent('frz-rp-spawn:openRentalMenu', function()
    if not isEnabled() then return end
    local src = source
    if not isNearDealer(src) then return end

    local id = FrzMoney_LicenseOfSource(src)
    if not id then
        TriggerClientEvent('frz-rp-spawn:showRentalMenu', src, 0, Config.CarRental.vehicles)
        return
    end
    local money = FrzMoney_Get(id)
    TriggerClientEvent('frz-rp-spawn:showRentalMenu', src, money, Config.CarRental.vehicles)
end)

-- Client demande a louer/acheter un vehicule.
RegisterNetEvent('frz-rp-spawn:rentVehicle', function(model)
    if not isEnabled() then return end
    local src = source
    if not isNearDealer(src) then
        TriggerClientEvent('frz-rp-spawn:rentalResult', src, {
            ok = false, reason = 'too_far', newBalance = 0,
        })
        return
    end

    local id = FrzMoney_LicenseOfSource(src)
    if not id then
        TriggerClientEvent('frz-rp-spawn:rentalResult', src, {
            ok = false, reason = 'identification', newBalance = 0,
        })
        return
    end

    -- Verifie que le vehicule demande est bien dans la config (securite : le client
    -- pourrait envoyer n'importe quel modele).
    local entry = findVehicle(model)
    if not entry then
        TriggerClientEvent('frz-rp-spawn:rentalResult', src, {
            ok = false, reason = 'unknown_model', newBalance = FrzMoney_Get(id),
        })
        return
    end

    local price = tonumber(entry.price) or 0
    if price <= 0 then
        -- Voiture gratuite : aucune deduction.
        TriggerClientEvent('frz-rp-spawn:rentalResult', src, {
            ok = true, model = entry.model, label = entry.label,
            price = 0, newBalance = FrzMoney_Get(id),
        })
        return
    end

    if not FrzMoney_TryDeduct(id, price) then
        TriggerClientEvent('frz-rp-spawn:rentalResult', src, {
            ok = false, reason = 'insufficient_funds', newBalance = FrzMoney_Get(id),
        })
        return
    end

    TriggerClientEvent('frz-rp-spawn:rentalResult', src, {
        ok = true, model = entry.model, label = entry.label,
        price = price, newBalance = FrzMoney_Get(id),
    })
end)

-- ============================================================================
-- Commandes admin (console serveur uniquement)
-- ============================================================================

-- frzgivemoney <playerId> <amount>   : ajoute <amount> GTA $ au joueur
RegisterCommand('frzgivemoney', function(source, args)
    if source ~= 0 then return end
    local target = tonumber(args[1])
    local amount = tonumber(args[2])
    if not target or not amount then
        print('[frz-rp-spawn] Usage : frzgivemoney <playerId> <amount>')
        return
    end
    local id = FrzMoney_LicenseOfSource(target)
    if not id then
        print('[frz-rp-spawn] Joueur ' .. tostring(target) .. ' introuvable.')
        return
    end
    FrzMoney_Add(id, amount)
    local newBal = FrzMoney_Get(id)
    print(('[frz-rp-spawn] %+d $ ajoute a %s (nouveau solde : %d $)'):format(amount, id, newBal))
    -- Notifie le joueur en jeu.
    TriggerClientEvent('frz-rp-spawn:moneyUpdate', target, newBal)
end, true)

-- frzsetmoney <playerId> <amount>   : fixe le solde a <amount>
RegisterCommand('frzsetmoney', function(source, args)
    if source ~= 0 then return end
    local target = tonumber(args[1])
    local amount = tonumber(args[2])
    if not target or not amount then
        print('[frz-rp-spawn] Usage : frzsetmoney <playerId> <amount>')
        return
    end
    local id = FrzMoney_LicenseOfSource(target)
    if not id then
        print('[frz-rp-spawn] Joueur ' .. tostring(target) .. ' introuvable.')
        return
    end
    FrzMoney_Set(id, amount)
    local newBal = FrzMoney_Get(id)
    print(('[frz-rp-spawn] Solde de %s defini a %d $'):format(id, newBal))
    TriggerClientEvent('frz-rp-spawn:moneyUpdate', target, newBal)
end, true)

-- frzgetmoney <playerId>   : affiche le solde
RegisterCommand('frzgetmoney', function(source, args)
    if source ~= 0 then return end
    local target = tonumber(args[1])
    if not target then
        print('[frz-rp-spawn] Usage : frzgetmoney <playerId>')
        return
    end
    local id = FrzMoney_LicenseOfSource(target)
    if not id then
        print('[frz-rp-spawn] Joueur ' .. tostring(target) .. ' introuvable.')
        return
    end
    print(('[frz-rp-spawn] Solde de %s : %d $'):format(id, FrzMoney_Get(id)))
end, true)
