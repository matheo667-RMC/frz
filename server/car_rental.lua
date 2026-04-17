-- FRZ RP - logique serveur pour la location de voitures au vendeur du terminal.
-- Utilise les helpers d'argent exposes par server/main.lua (FrzMoney_*).

local function findVehicle(model)
    if not Config.CarRental or not Config.CarRental.vehicles then return nil end
    if type(model) ~= 'string' or model == '' then return nil end
    for _, v in ipairs(Config.CarRental.vehicles) do
        if v.model == model then return v end
    end
    return nil
end

-- Client demande d'ouvrir le menu : on renvoie son solde pour affichage.
RegisterNetEvent('frz-rp-spawn:openRentalMenu', function()
    local src = source
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
    local src = source
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
