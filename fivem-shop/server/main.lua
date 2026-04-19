-- frz-rp-shop : serveur QBCore qui interroge le site de boutique et livre
-- les items achetes aux joueurs connectes.
--
-- Architecture :
--   1. Toutes les Config.PollInterval secondes, pour chaque joueur connecte,
--      on appelle GET {ShopApiUrl}/api/fivem/pending?discordId=<id>
--      avec l'entete Authorization: Bearer <ShopApiToken>.
--   2. Pour chaque livraison PENDING renvoyee, on livre l'item au joueur
--      (arme, vehicule, item d'inventaire, argent, VIP) via QBCore.
--   3. On marque la livraison comme DELIVERED via POST /api/fivem/deliver.

local QBCore = exports['qb-core']:GetCoreObject()

local function jsonEncode(t)
    return json.encode(t)
end

local function jsonDecode(s)
    local ok, data = pcall(json.decode, s)
    if not ok then return nil end
    return data
end

--- Recupere le Discord ID d'un joueur FiveM a partir de ses identifiers.
-- Retourne le snowflake numerique (ex: "123456789012345678"), ou nil.
local function getDiscordId(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if id:sub(1, 8) == "discord:" then
            return id:sub(9)
        end
    end
    return nil
end

local function notify(source, message, type)
    TriggerClientEvent('QBCore:Notify', source, message, type or 'success')
end

-- Livraison d'un payload selon son type.
-- Retourne true si livre, false sinon, + message (string).
local function deliverPayload(source, Player, payload)
    if not payload or not payload.type then
        return false, "payload invalide"
    end

    if payload.type == "weapon" then
        local weapon = payload.name or "weapon_pistol"
        local amount = payload.amount or 1
        local ammo = payload.ammo or 0
        Player.Functions.AddItem(weapon, amount, false, {
            quality = 100,
            ammo = ammo,
        })
        return true, ("Arme %s x%d"):format(weapon, amount)

    elseif payload.type == "item" then
        local name = payload.name
        local amount = payload.amount or 1
        if not name then return false, "item sans nom" end
        Player.Functions.AddItem(name, amount)
        return true, ("Item %s x%d"):format(name, amount)

    elseif payload.type == "money" then
        local account = payload.account or "bank"
        local amount = tonumber(payload.amount) or 0
        if amount <= 0 then return false, "montant invalide" end
        Player.Functions.AddMoney(account, amount, "shop-delivery")
        return true, ("+%d $ sur %s"):format(amount, account)

    elseif payload.type == "vehicle" then
        local model = payload.model
        if not model then return false, "vehicle model manquant" end
        local plate = payload.plate or ("FRZ" .. math.random(100, 999))
        local citizenid = Player.PlayerData.citizenid
        -- Insertion directe dans la table player_vehicles de QBCore.
        -- La ressource qb-garages detectera le vehicule au prochain chargement.
        exports.oxmysql:insert(
            [[INSERT INTO player_vehicles
                (license, citizenid, vehicle, hash, mods, plate, garage, state)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?)]],
            {
                Player.PlayerData.license,
                citizenid,
                model,
                GetHashKey(model),
                "{}",
                plate,
                "pillboxgarage",
                1,
            }
        )
        return true, ("Vehicule %s (plaque %s) ajoute a ton garage"):format(model, plate)

    elseif payload.type == "vip" then
        local tier = payload.tier or "gold"
        local days = payload.days or 30
        -- On stocke l'expiration en metadata du joueur.
        local until_ts = os.time() + (days * 86400)
        Player.Functions.SetMetaData("vip", { tier = tier, until_ = until_ts })
        return true, ("VIP %s actif pour %d jours"):format(tier, days)
    end

    return false, "type inconnu: " .. tostring(payload.type)
end

local function fetchAndDeliverFor(source)
    local discordId = getDiscordId(source)
    if not discordId then return end

    local url = Config.ShopApiUrl .. "/api/fivem/pending?discordId=" .. discordId
    PerformHttpRequest(url, function(status, body, _)
        if status ~= 200 or not body then
            if status ~= 0 and status ~= 200 then
                print(("[frz-rp-shop] pending HTTP %s"):format(tostring(status)))
            end
            return
        end
        local data = jsonDecode(body)
        if not data or not data.deliveries then return end

        -- Re-verification de l'identite apres l'appel HTTP asynchrone : si le
        -- joueur s'est deconnecte et qu'un autre joueur a repris le meme
        -- source ID, on ne livre pas a la mauvaise personne.
        local currentDiscordId = getDiscordId(source)
        if currentDiscordId ~= discordId then return end

        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return end

        for _, delivery in ipairs(data.deliveries) do
            local ok, msg = deliverPayload(source, Player, delivery.payload)
            if ok and Config.NotifyOnDelivery then
                notify(source, Config.DeliveryMessageFormat:format(delivery.itemName or msg), "success")
            end
            -- On marque toujours la livraison (sinon boucle infinie).
            local finalStatus = ok and "DELIVERED" or "FAILED"
            PerformHttpRequest(Config.ShopApiUrl .. "/api/fivem/deliver",
                function(dStatus, _, _)
                    if dStatus < 200 or dStatus >= 300 then
                        print(("[frz-rp-shop] deliver HTTP %s"):format(tostring(dStatus)))
                    end
                end,
                "POST",
                jsonEncode({
                    deliveryId = delivery.id,
                    status = finalStatus,
                    note = msg,
                }),
                {
                    ["Content-Type"] = "application/json",
                    ["Authorization"] = "Bearer " .. Config.ShopApiToken,
                }
            )
        end
    end, "GET", "", {
        ["Authorization"] = "Bearer " .. Config.ShopApiToken,
    })
end

-- Boucle de polling globale.
CreateThread(function()
    while true do
        Wait((Config.PollInterval or 30) * 1000)
        local players = QBCore.Functions.GetQBPlayers()
        for source, _ in pairs(players) do
            fetchAndDeliverFor(source)
        end
    end
end)

-- Commande manuelle pour forcer la recuperation (debug / QA).
QBCore.Commands.Add('shopsync', 'Force la livraison des achats en attente', {}, false, function(source)
    fetchAndDeliverFor(source)
    TriggerClientEvent('QBCore:Notify', source, 'Synchronisation boutique lancee…', 'primary')
end)
