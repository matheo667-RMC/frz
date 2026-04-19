-- frz-rp-shop : configuration SERVEUR UNIQUEMENT.
-- Contient le token API partage avec le site web. Ce fichier est charge
-- uniquement dans `server_scripts` (cf. fxmanifest.lua) et n'est donc jamais
-- envoye aux clients.

Config = Config or {}

-- Token partage avec le site (variable FIVEM_API_TOKEN dans le .env du site).
-- Generer avec : openssl rand -hex 32
-- NE JAMAIS partager ce token publiquement, ne JAMAIS le mettre dans
-- `config.lua` (qui est shared_script).
Config.ShopApiToken = "change-me-shared-secret-between-site-and-fivem"

-- Frequence (en secondes) a laquelle le serveur FiveM interroge le site
-- pour recuperer les livraisons en attente des joueurs connectes.
Config.PollInterval = 30

-- Si true, on affiche une notification au joueur quand un item est livre.
Config.NotifyOnDelivery = true

-- Message FR affiche lors de la livraison.
Config.DeliveryMessageFormat = "Livraison recue : %s"

-- Table de mapping optionnelle nom_arme_qbcore -> hash GTA si tu utilises un
-- systeme d'inventaire standalone. Vide = on suppose qu'on passe par l'API
-- standard QBCore Player.Functions.AddItem.
Config.WeaponItemOverride = {}
