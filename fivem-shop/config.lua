-- frz-rp-shop : configuration de la ressource QBCore de livraison.
-- IMPORTANT : remplir ShopApiUrl et ShopApiToken avant utilisation.

Config = {}

-- URL publique du site de boutique (sans slash final).
-- Exemple : "https://shop.frz-rp.fr"
Config.ShopApiUrl = "http://localhost:3000"

-- Token partage avec le site (variable FIVEM_API_TOKEN dans le .env du site).
-- Generer avec : openssl rand -hex 32
-- NE JAMAIS partager ce token publiquement.
Config.ShopApiToken = "change-me-shared-secret-between-site-and-fivem"

-- Frequence (en secondes) a laquelle le serveur FiveM interroge le site
-- pour recuperer les livraisons en attente des joueurs connectes.
Config.PollInterval = 30

-- Si true, on affiche une notification au joueur quand un item est livre.
Config.NotifyOnDelivery = true

-- Commande /shop pour ouvrir le site dans le navigateur in-game (NUI).
Config.EnableShopCommand = true

-- Message FR affiche lors de la livraison.
Config.DeliveryMessageFormat = "Livraison recue : %s"

-- Table de mapping optionnelle nom_arme_qbcore -> hash GTA si tu utilises un
-- systeme d'inventaire standalone. Vide = on suppose qu'on passe par l'API
-- standard QBCore Player.Functions.AddItem.
Config.WeaponItemOverride = {}
