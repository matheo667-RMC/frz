# Dead Zone RP

Ressources FiveM pour le serveur **Dead Zone RP** — ambiance **survie post-apo / The Walking Dead** (rôdeurs, ressources, craft, zones refuges).

Ce dépôt est un **monorepo** : chaque sous-dossier est une ressource FiveM autonome que tu peux activer / désactiver individuellement via `server.cfg`.

## Ressources

| Nom | Description |
| --- | --- |
| `frz-core` | Noyau partagé : état joueur (faim / soif / fatigue / infection), inventaire en kg, persistance JSON, commandes admin. |
| `frz-survival` | Boucle de survie (ticks de faim / soif / fatigue), effets visuels (blur, cam shake, dégâts), infection, HUD NUI en français, consommables (`/eat`, `/drink`, `/use`). |
| `frz-walkers` | Rôdeurs (zombies) : spawn dynamique autour des joueurs, IA hostile en mêlée, morsures → infection, grognements, cleanup auto. |
| `frz-loot` | Loot des bennes / poubelles / toolboxes / cartons du monde + fouille des corps de rôdeurs. Tables de loot configurables. |
| `frz-craft` | Craft de bandages, kits de soin, batte cloutée, barricades, munitions. Menu chat `/craft`. |
| `frz-safezones` | Zones refuges (LSIA, Paleto, Altruist camp) : pas de spawns de rôdeurs, regen lente HP + faim + soif, blips sur la map. |
| `frz-intro` | Animation NUI « Bienvenue dans la Dead Zone » au premier spawn (fade + glitch + tagline). Pas de caméra ni d'avion, juste un overlay léger. |
| `frz-rp-spawn` | **Optionnel** — spawn forcé à LSIA au premier join avec cinématique d'atterrissage d'avion. Désactivé par défaut pour laisser des spawns aléatoires plus cohérents avec le mode survie. |

## Installation

1. Clone le repo dans le dossier `resources/` de ton serveur FiveM, sous un conteneur `[frz]` (les crochets indiquent à FXServer qu'il contient plusieurs ressources) :
   ```bash
   cd resources
   git clone https://github.com/matheo667-RMC/frz.git [frz]
   ```
2. Ajoute les `ensure` à ton `server.cfg` (voir [`server.cfg.example`](server.cfg.example)) :
   ```
   # Dead Zone RP - ordre important : frz-core avant les autres
   ensure frz-core
   ensure frz-survival
   ensure frz-walkers
   ensure frz-loot
   ensure frz-craft
   ensure frz-safezones
   ensure frz-intro
   # ensure frz-rp-spawn  # optionnel : decommente pour activer le spawn LSIA cinematique
   ```
3. (Optionnel mais conseillé) Installe les mods GTA V recommandés côté client pour le rendu : voir [`MODS.md`](MODS.md).
4. Redémarre ton serveur : `restart [frz]` ou redémarrage complet.

## Commandes joueur

| Commande | Description |
| --- | --- |
| `/inv` | Affiche ton inventaire (items + poids en kg). |
| `/eat <item>`, `/drink <item>`, `/use <item>` | Consomme un item (ex: `canned_food`, `water_bottle`, `bandage`, `medkit`, `antibiotics`). |
| `/craft` | Liste les recettes disponibles. |
| `/craft <id>` | Lance un craft (ex: `/craft bandage`, `/craft melee_bat`, `/craft barricade`). |
| `/placebarricade` | Pose une barricade devant toi (nécessite l'item `barricade`). |

Les props lootables (bennes, poubelles…) sont détectés quand tu passes à côté, appuie sur **E** pour fouiller. Idem sur les corps de rôdeurs abattus.

## Commandes admin (console serveur ou `FrzCore.Config.Admins`)

| Commande | Description |
| --- | --- |
| `frzgive <playerId> <itemId> [count]` | Donne un item. |
| `frzsetstat <playerId> <stat> <0-100>` | Force une stat (`hunger`, `thirst`, `fatigue`, `infection`). |
| `frzwipe <playerId>` | Efface les données d'un joueur. |
| `frzwipeall` | Efface toutes les données joueurs. |
| `frzwalkerkills` | Top 10 des tueurs de rôdeurs. |
| `frzresetspawn <playerId>` / `frzresetspawnall` | Remet à zéro l'intro du spawn LSIA (uniquement si `frz-rp-spawn` est activé). |

## Configuration

Chaque ressource a son propre `config.lua` à la racine de son dossier. Tout est en français, commenté, prêt à être modifié sans toucher au code :

- `frz-core/config.lua` — poids des items, labels FR, capacité max, admins.
- `frz-survival/config.lua` — vitesse de dégradation des stats, seuils de dégâts, effets de consommation.
- `frz-walkers/config.lua` — densité, portée de détection, modèles de peds, hot zones.
- `frz-loot/config.lua` — props fouillables, tables de loot, cooldowns.
- `frz-craft/config.lua` — recettes.
- `frz-safezones/config.lua` — zones refuges et regen.

## Dépendances

Aucune. Les ressources sont **standalone** (pas d'ESX, pas de QBCore). Elles utilisent uniquement l'API native FiveM et s'écrivent leur propre persistance JSON dans le dossier de `frz-core`.

## Licence

© Dead Zone RP — Tous droits réservés. Ces ressources sont réservées à un usage interne Dead Zone RP.
