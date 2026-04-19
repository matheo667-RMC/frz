# FRZ

Ressources FiveM et services web pour le serveur **FRZ RP**.

## Contenu du depot

| Dossier | Description |
| --- | --- |
| [`frz-rp-spawn`](#) (racine) | Ressource FiveM : spawn a LSIA au premier join, cinematique d'atterrissage d'avion et annonce vocale francaise. |
| [`shop/`](./shop) | Site web de la **boutique officielle FRZ RP** (Next.js 14 + TypeScript + Tailwind + Prisma + PayPal). |
| [`fivem-shop/`](./fivem-shop) | Ressource FiveM QBCore qui livre en jeu les items achetes sur la boutique (armes, vehicules, items, argent, VIP). |

## Boutique FRZ RP

Les joueurs peuvent acheter des mods avec de la vraie monnaie (PayPal) et les
recoivent automatiquement en jeu sur le serveur FiveM. La boutique est
utilisable :

- depuis n'importe quel navigateur (Google, mobile, PC) — site web Next.js
  standard ;
- depuis GTA V via le NUI de FiveM (commande `/shop` in-game qui affiche
  l'URL) — le site fonctionne dans le navigateur integre de FiveM.

Authentification par **Discord OAuth** (le meme compte Discord que le joueur
utilise pour FiveM), ce qui permet de retrouver automatiquement son
personnage en jeu.

Voir [`shop/README.md`](./shop/README.md) (a la racine du sous-projet) pour
le setup detaille.

## Installation des ressources FiveM

1. Cloner ce depot dans `resources/[frz]/` de votre serveur FiveM :
   ```bash
   cd resources
   mkdir -p [frz]
   cd [frz]
   git clone https://github.com/matheo667-RMC/frz.git frz
   ```
   Puis copier les sous-dossiers :
   ```bash
   cp -r frz fiz-rp-spawn
   cp -r frz/fivem-shop .
   ```
2. Ajouter au `server.cfg` :
   ```
   ensure frz-rp-spawn
   ensure frz-rp-shop
   ```
3. Editer `fivem-shop/config.lua` pour renseigner l'URL du site et le token
   partage avec le `.env` du site (`FIVEM_API_TOKEN`).
4. Redemarrer le serveur.

## Licence

© FRZ — Tous droits reserves. Ces ressources sont reservees a un usage interne
FRZ RP.
