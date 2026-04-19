-- frz-rp-shop : configuration PARTAGEE (client + serveur).
-- Ne JAMAIS mettre de secret ici : ce fichier est envoye a tous les clients
-- et peut etre dumpe par n'importe quel joueur avec un executeur Lua.
-- Les secrets (token API, etc.) vont dans `config_server.lua`.

Config = Config or {}

-- URL publique du site de boutique (sans slash final).
-- Exemple : "https://shop.frz-rp.fr"
Config.ShopApiUrl = "http://localhost:3000"

-- Commande /shop pour afficher le lien de la boutique aux joueurs.
Config.EnableShopCommand = true
