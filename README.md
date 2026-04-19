# FRZ

Ressources FiveM pour le serveur **FRZ RP**.

Ce dépôt est un **monorepo** contenant plusieurs ressources custom.

## Ressources

| Nom              | Description                                                                                          |
| ---------------- | ---------------------------------------------------------------------------------------------------- |
| `frz-rp-spawn`   | Spawn à l'aéroport (LSIA) au premier join : cinématique d'atterrissage d'avion + annonce vocale FR. |
| `frz-inventory`  | Inventaire type "grid" avec slots de vêtements autour du personnage + drop au sol (touche `E`).     |
| `frz-phone`      | Smartphone FiveM (iPhone / Android au choix) : appels, SMS, contacts, app Banque, réglages.         |
| `frz-bank`       | Comptes bancaires, ATMs sur la map, comptoirs de banque (touche `E`). Intégré au phone.             |

## Installation

1. Cloner ce dépôt dans votre dossier `resources/` :
   ```bash
   cd resources
   git clone https://github.com/matheo667-RMC/frz.git [frz]
   ```
2. Ajouter dans votre `server.cfg` (dans l'ordre ci-dessous pour respecter les dépendances) :
   ```
   ensure frz-inventory
   ensure frz-phone
   ensure frz-bank
   ensure frz-rp-spawn
   ```
3. (Optionnel) Ajuster les `config.lua` dans chaque ressource (touches, blips, soldes de départ, etc.).
4. Redémarrer le serveur.

Les crochets dans `[frz]` indiquent à FiveM que le dossier est un **resource group** : il scannera tous les sous-dossiers comme des ressources indépendantes.

## Touches par défaut

| Ressource       | Touche | Action                                   |
| --------------- | ------ | ---------------------------------------- |
| `frz-inventory` | `I`    | Ouvrir / fermer l'inventaire              |
| `frz-inventory` | `E`    | Ramasser un drop au sol                   |
| `frz-phone`     | `F1`   | Ouvrir / fermer le téléphone              |
| `frz-bank`      | `E`    | Ouvrir l'ATM / le comptoir de banque      |

Les touches sont configurables via `RegisterKeyMapping` : les joueurs peuvent les modifier dans le menu **Paramètres > Commandes clavier** de FiveM.

## Architecture

Toutes les ressources sont **standalone** (pas de dépendance obligatoire à ESX / QBCore) et utilisent :
- la persistance par fichier JSON dans le dossier de la ressource (`*.json` — auto-créés),
- des `exports` Lua pour interopérer entre elles (ex : `frz-phone` lit le solde via `exports['frz-bank']:getAccount(src)`).

Exports principaux (côté serveur sauf mention contraire) :

```lua
-- frz-inventory
exports['frz-inventory']:addItem(src, itemName, count)
exports['frz-inventory']:removeItem(src, itemName, count)
exports['frz-inventory']:countItem(src, itemName)
exports['frz-inventory']:hasItem(src, itemName, minCount)
exports['frz-inventory']:getInventory(src)

-- frz-phone
exports['frz-phone']:getPhoneNumber(src)
exports['frz-phone']:getSourceByNumber(number)
exports['frz-phone']:sendNotification(src, msg, type)
exports['frz-phone']:refreshPhone(src)

-- frz-bank
exports['frz-bank']:getBalance(src)
exports['frz-bank']:getAccount(src)
exports['frz-bank']:deposit(src, amount)
exports['frz-bank']:withdraw(src, amount)
exports['frz-bank']:transfer(src, targetPhoneNumber, amount)
```

## Commandes admin (console serveur)

```
frz_giveitem <playerId> <itemName> [count]   # frz-inventory
frz_bank_set <playerId> <balance>             # frz-bank
```

## Licence

© FRZ — Tous droits réservés. Ces ressources sont réservées à un usage interne FRZ RP.
