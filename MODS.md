# Mods GTA V recommandés pour Dead Zone RP (survie / zombies)

Les scripts de ce repo (`frz-walkers`, `frz-survival`, etc.) **fonctionnent tels quels** avec GTA V de base : le modèle `s_m_y_zombie_01` est déjà présent dans le flux Halloween du jeu, et les sons d'ambiance utilisent des natives GTA.

Mais pour un rendu vraiment **Walking Dead**, tu peux (c'est toi qui installes, moi je ne fais que les scripts) ajouter les mods ci-dessous côté GTA V. Ils vont s'intégrer automatiquement à mes scripts sans aucune modification de code — il suffit d'ajuster quelques lignes dans `config.lua`.

> ⚠️ **Important :** tous ces mods doivent être **streamés côté serveur** (dossier `stream/` d'une ressource FiveM) pour que **tous les joueurs** les voient. N'installe **pas** les .oiv côté client comme en solo, ils ne passeront pas en multi.

---

## 1. Skins de rôdeurs (zombies)

### Option recommandée — Zombie Ped Pack

- **Mod** : "Zombie Peds" / "Walking Dead Zombie Pack" (cherche sur [gta5-mods.com](https://www.gta5-mods.com/search/zombie) ou LCPDFR)
- **Format** : YDD / YFT / YTD (ped streams)
- **Où le mettre** : crée une ressource `[frz]/frz-stream-peds/stream/` et colle les fichiers dedans, puis crée un `fxmanifest.lua` minimal :
  ```lua
  fx_version 'cerulean'
  game 'gta5'
  files { 'stream/**/*' }
  ```
  et `ensure frz-stream-peds` dans ton `server.cfg`.
- **Ajout dans `frz-walkers/config.lua`** :
  ```lua
  FrzWalkers.Config.PedModels = {
      's_m_y_zombie_01',   -- zombie vanilla GTA V (garde-le en fallback)
      'zombie_rotten_01',  -- ← ajoute ici le nom de chaque modèle que tu as streamé
      'walker_burnt_02',
      'walker_bloody_03',
  }
  ```

### Option plus simple — Réutiliser des peds vanilla

Si tu ne veux pas streamer de packs, tu peux utiliser des peds "pauvres / abîmés" déjà présents dans GTA V pour varier l'apparence des rôdeurs :

```lua
FrzWalkers.Config.PedModels = {
    's_m_y_zombie_01',
    'a_m_m_afriamer_01',
    'a_m_m_tramp_01',
    'a_m_m_tranvest_01',
    'a_m_y_vinewood_01',
    'a_m_y_beach_03',
}
```

---

## 2. Armes custom (mêlée + armes à feu "Walking Dead")

### Armes conseillées

- **Machette "Michonne"** : cherche "Michonne Katana" ou "Walking Dead Katana" sur gta5-mods.
- **Batte cloutée "Negan / Lucille"** : "Lucille Bat" / "Nail Bat".
- **Arbalète silencieuse "Daryl"** : "Crossbow Daryl" (mod basé sur le `weapon_musket` ou custom).

### Installation

Chaque arme mod = un dossier `stream/` avec les fichiers `.ydr`, `.ymt`, `.meta` (`weapons.meta`, `weaponcomponents.meta`). Même principe que les peds : crée `[frz]/frz-stream-weapons/` et place les fichiers dedans.

### Intégration avec mes scripts

- **Batte cloutée craftable** (`/craft melee_bat`) : déjà branchée dans `frz-craft/config.lua`, recette = 2 bois + 5 clous. Elle donne l'item `melee_bat`. Pour qu'elle équipe réellement une arme en jeu, tu peux :
  - éditer `frz-craft/server/craft.lua` pour faire `GiveWeaponToPed(ped, <hashArme>, 1, false, true)` au lieu de (ou en plus de) l'item.
  - ou simplement demander à un script type `[qb/esx]-weapons` d'émettre l'arme.

---

## 3. Textures / ambiance post-apo

### Options visuelles

- **Apocalypse LA / Dead Los Santos** (map edit) : rues abandonnées, voitures épaves, graffitis. Cherche sur gta5-mods la catégorie "Map Editor / Menyoo XML" qui remplace Downtown LS.
- **ReShade + ENB** : à installer **côté client** uniquement (pas stream server), par chaque joueur, pour un filtre grisâtre / désaturé.
- **Blood decals** : packs de décalques de sang sur les murs / sols.

### Intégration

Les ambiances visuelles ne nécessitent **aucune** modif de mes scripts. Ce sont des ressources purement cosmétiques.

---

## 4. Sons custom (grognements de rôdeurs)

Par défaut, `frz-walkers` utilise le sound set natif `MP_BRIBE_SOUND_SET` (sound `BOOM`) — pas très zombie mais fonctionnel.

Pour vrai son de Walker :
1. Récupère des `.ogg` (grognements, râles) — des packs libres existent sur itch.io ou freesound.org.
2. Crée une ressource `[frz]/frz-stream-audio/` avec les `.ogg` dans un dossier `sounds/`.
3. Dans `frz-walkers/client/sounds.lua`, remplace `PlaySoundFromEntity` par `PlaySoundFromCoord` pointant vers un fichier HTML NUI qui joue l'`.ogg` (pattern NUI audio, comme ce qui est fait dans `frz-rp-spawn/html/app.js` pour l'annonce FR).

Si tu veux, je peux te faire cette partie NUI audio dans un prochain PR — envoie-moi juste les `.ogg` (ou dis-moi "prends des sons libres" et je trouve).

---

## 5. Récap — Ordre d'installation côté serveur

```
resources/
└── [frz]/
    ├── frz-core/             ← ce repo (mes scripts)
    ├── frz-survival/         ← ce repo
    ├── frz-walkers/          ← ce repo
    ├── frz-loot/             ← ce repo
    ├── frz-craft/            ← ce repo
    ├── frz-safezones/        ← ce repo
    ├── frz-rp-spawn/         ← ce repo
    ├── frz-stream-peds/      ← TOI (skins zombies streamés)
    ├── frz-stream-weapons/   ← TOI (armes custom streamées)
    └── frz-stream-audio/     ← TOI (grognements custom - optionnel)
```

Et dans `server.cfg`, `ensure` chaque ressource dans l'ordre. Les ressources `frz-stream-*` n'ont pas d'ordre critique.

---

## Tu bloques sur un mod ?

Envoie-moi le nom du mod que tu veux utiliser ou un lien, et je te dis comment l'intégrer précisément avec mes scripts (quel nom de modèle mettre dans `PedModels`, quel hash d'arme mettre dans la recette, etc.).
