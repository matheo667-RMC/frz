# frz-rp-shop (ressource FiveM QBCore)

Client QBCore qui livre automatiquement en jeu les items achetes sur le site
[`shop/`](../shop) (FRZ RP Boutique).

## Fonctionnement

1. Toutes les `Config.PollInterval` secondes, le serveur interroge le site :
   `GET {ShopApiUrl}/api/fivem/pending?license=<l>&citizenid=<c>&discordId=<d>`
   avec l'entete `Authorization: Bearer <ShopApiToken>`. Le site resoud
   l'utilisateur par priorite license/citizenid (lien `/linkshop`) puis
   Discord ID en fallback.
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

Deux modes coexistent :

1. **Lien FiveM explicite (recommande)** : le joueur se connecte sur le site,
   clique sur "Generer mon code de liaison" dans `/account`, puis tape
   `/linkshop <code>` in-game. Le serveur associe son `license:` et son
   `citizenid` QBCore a son compte shop. Les livraisons sont ensuite routees
   sur CE personnage — meme si Discord n'est pas ouvert au moment de jouer,
   et meme si le joueur a plusieurs personnages sur le serveur.

2. **Fallback Discord** : sans lien explicite, on utilise le `discord:XXXX`
   des identifiers FiveM (requiert Discord ouvert sur le meme PC que GTA V).
   C'est le meme ID que celui utilise par l'OAuth Discord du site, donc les
   deux identites se synchronisent naturellement.

## Commandes

- `/linkshop <code>` : lie le personnage QBCore actuel au compte shop.
- `/shopsync` : force une synchro immediate des achats en attente.

Logs serveur : `[frz-rp-shop] ...` en cas de probleme HTTP.

## Securite

- Le `ShopApiToken` est un secret partage cote serveur uniquement. Il ne doit
  JAMAIS etre inclus cote client ni commit dans un repo public.
- L'API du site ne delivre que les livraisons `PENDING` pour l'identifiant
  fourni (license/citizenid ou Discord ID), donc meme une fuite de token ne
  permettrait pas d'obtenir plus que des items deja payes.
- La confirmation `DELIVERED` est envoyee AVANT de donner les items au joueur :
  si l'appel HTTP rate, on retente au prochain poll plutot que de livrer 2x.
