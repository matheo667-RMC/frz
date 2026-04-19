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
--
-- Important : pour un systeme d'argent reel, on livre les items d'abord puis
-- on confirme DELIVERED au site. C'est le moindre mal entre deux risques :
--   * Confirmer avant livrer = items perdus si le joueur deco entre les deux
--     (le site considere la livraison faite, refuse de rejouer).
--   * Livrer avant confirmer = risque de double livraison si la confirmation
--     HTTP rate, car la livraison reste PENDING et sera retentee.
-- On choisit le 2e : "items perdus" est pire qu'un double-send pour un achat
-- reel (detection + correction admin triviale vs. customer furieux).
-- Le cache local 'processedIds' (marque AVANT la livraison) empeche les
-- doublons entre polls pendant la vie du resource. Seul un restart du
-- resource avec une confirmation HTTP ayant rate peut entrainer un double
-- send — rare, detectable (log 'deliver confirm HTTP != 2xx'), corrigeable
-- par l'admin en passant la delivery a DELIVERED a la main.

local QBCore = exports['qb-core']:GetCoreObject()

-- Cache des deliveryId deja traites pendant cette execution du resource.
-- Evite les doublons si un poll tombe pendant qu'un autre est en cours.
local processedIds = {}

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

--- Recupere le license: d'un joueur FiveM (stable, toujours present).
local function getLicense(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if id:sub(1, 8) == "license:" then
            return id:sub(9)
        end
    end
    return nil
end

--- Signature d'identite d'un joueur : combine license + citizenid.
-- Utilisee pour la re-verification apres un appel HTTP asynchrone, au cas ou
-- le joueur s'est deconnecte et qu'un autre joueur a repris le meme source.
local function getIdentitySig(source)
    local license = getLicense(source)
    local Player = QBCore.Functions.GetPlayer(source)
    local citizenid = Player and Player.PlayerData and Player.PlayerData.citizenid or nil
    return (license or "") .. "|" .. (citizenid or "")
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
        -- Plaque : 1 lettre + 4 chiffres -> ~234k combinaisons. Reduit fortement
        -- le risque de collision dans qb-garages vs math.random(100, 999) (900).
        local plate = payload.plate
            or ("FRZ" .. string.char(math.random(65, 90)) .. math.random(1000, 9999))
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
    local license = getLicense(source)
    local Player = QBCore.Functions.GetPlayer(source)
    local citizenid = Player and Player.PlayerData and Player.PlayerData.citizenid or nil

    -- On construit l'URL avec les 3 identifiants qu'on a : le site resoud par
    -- priorite license/citizenid (lien fort via /linkshop) puis Discord ID
    -- (fallback). Au moins un doit etre present.
    if not discordId and not license and not citizenid then return end
    local params = {}
    if license   then params[#params + 1] = "license=" .. license end
    if citizenid then params[#params + 1] = "citizenid=" .. citizenid end
    if discordId then params[#params + 1] = "discordId=" .. discordId end
    local url = Config.ShopApiUrl .. "/api/fivem/pending?" .. table.concat(params, "&")
    local identitySig = getIdentitySig(source)

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
        if getIdentitySig(source) ~= identitySig then return end

        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return end

        for _, delivery in ipairs(data.deliveries) do
            if not processedIds[delivery.id] then
                -- Marque AVANT pour eviter les doublons si 2 polls se
                -- chevauchent (ex: /shopsync declenche pendant un poll auto).
                processedIds[delivery.id] = true

                -- Livraison synchrone via QBCore (AddItem, insert vehicule…).
                local ok, msg = deliverPayload(source, Player, delivery.payload)
                if ok and Config.NotifyOnDelivery then
                    notify(source, Config.DeliveryMessageFormat:format(delivery.itemName or msg), "success")
                elseif not ok then
                    print(("[frz-rp-shop] deliverPayload KO: %s"):format(tostring(msg)))
                end

                -- Confirme le statut au site APRES livraison. Si l'HTTP
                -- echoue, la livraison reste PENDING cote DB → un admin peut
                -- manuellement passer la delivery a DELIVERED. On ne retente
                -- PAS automatiquement (on ne retire pas de processedIds),
                -- sinon le prochain poll redonnerait les items.
                local finalStatus = ok and "DELIVERED" or "FAILED"
                PerformHttpRequest(Config.ShopApiUrl .. "/api/fivem/deliver",
                    function(dStatus, _, _)
                        if dStatus < 200 or dStatus >= 300 then
                            print(("[frz-rp-shop] deliver confirm HTTP %s pour delivery %s - items livres mais DB pas a jour, revoir manuellement"):format(tostring(dStatus), tostring(delivery.id)))
                        end
                    end,
                    "POST",
                    jsonEncode({
                        deliveryId = delivery.id,
                        status = finalStatus,
                        note = ok and nil or msg,
                    }),
                    {
                        ["Content-Type"] = "application/json",
                        ["Authorization"] = "Bearer " .. Config.ShopApiToken,
                    }
                )
            end
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

-- Lie le personnage QBCore actuel au compte shop (Discord) qui a genere le
-- code sur /account. Apres liaison, les livraisons sont routees par
-- license/citizenid → ca garantit que la voiture atterrit sur CE personnage,
-- meme si Discord n'est pas ouvert pendant que le joueur joue.
QBCore.Commands.Add('linkshop', 'Lie ton compte FiveM au shop FRZ RP', {
    { name = 'code', help = 'Code affiche sur ton compte shop' },
}, true, function(source, args)
    local code = args[1]
    if not code or code == "" then
        notify(source, "Usage: /linkshop <code>", "error")
        return
    end
    local license = getLicense(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not license then
        notify(source, "Impossible de lire ton personnage QBCore", "error")
        return
    end
    local citizenid = Player.PlayerData.citizenid

    PerformHttpRequest(Config.ShopApiUrl .. "/api/fivem/link",
        function(status, body, _)
            if status >= 200 and status < 300 then
                notify(source, "Compte shop lie a ce personnage ✓", "success")
                -- Declenche un poll immediat pour recuperer les achats
                -- en attente sur le nouveau lien.
                fetchAndDeliverFor(source)
                return
            end
            local data = jsonDecode(body or "") or {}
            local msg = data.message or ("Erreur HTTP " .. tostring(status))
            notify(source, msg, "error")
        end,
        "POST",
        jsonEncode({
            code = code:upper(),
            license = license,
            citizenid = citizenid,
        }),
        {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. Config.ShopApiToken,
        }
    )
end)
