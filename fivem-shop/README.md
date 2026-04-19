# frz-rp-shop (ressource FiveM QBCore)

Client QBCore qui livre automatiquement en jeu les items achetes sur le site
[`shop/`](../shop) (FRZ RP Boutique).

## Fonctionnement

1. Toutes les `Config.PollInterval` secondes, le serveur interroge le site :
   `GET {ShopApiUrl}/api/fivem/pending?discordId=<snowflake>`
   avec l'entete `Authorization: Bearer <ShopApiToken>`.
2. Pour chaque livraison `PENDING` retournee, le script livre l'item au joueur
   (arme, vehicule, item d'inventaire, argent, VIP) via QBCore.
3. La livraison est ensuite marquee `DELIVERED` via `POST /api/fivem/deliver`
   pour qu'elle ne soit pas rejouee.

## Installation

1. Copier ce dossier dans `resources/[frz]/frz-rp-shop/` de votre serveur FiveM.
2. Editer `config.lua` :
   - `Config.ShopApiUrl` : URL publique du site de boutique.
   - `Config.ShopApiToken` : meme valeur que la variable `FIVEM_API_TOKEN` dans
     le `.env` du site. Generer avec `openssl rand -hex 32`.
3. Ajouter dans `server.cfg` :
   ```
   ensure oxmysql
   ensure qb-core
   ensure frz-rp-shop
   ```
4. Redemarrer le serveur.

## Dependances

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [oxmysql](https://github.com/overextended/oxmysql) (utilise pour la livraison
  de vehicules via la table `player_vehicles`).

## Identification du joueur

La correspondance joueur <-> compte boutique se fait via le **Discord ID**
(snowflake) du joueur, extrait des identifiers FiveM (`discord:XXXXX...`).
Le joueur doit donc avoir lie son compte Discord a FiveM (par defaut si
Discord tourne sur le meme PC que GTA V).

C'est aussi ce Discord ID qui est utilise lors de la connexion OAuth sur le
site : les deux identites se synchronisent naturellement.

## Debug

- `/shopsync` en jeu : force une synchro immediate des achats pour le joueur.
- Logs serveur : `[frz-rp-shop] ...` en cas de probleme HTTP.

## Securite

- Le `ShopApiToken` est un secret partage cote serveur uniquement. Il ne doit
  JAMAIS etre inclus cote client ni commit dans un repo public.
- L'API du site ne delivre que les livraisons `PENDING` pour le Discord ID
  fourni, donc meme une fuite de token ne permettrait pas d'obtenir plus que
  des items deja payes.
