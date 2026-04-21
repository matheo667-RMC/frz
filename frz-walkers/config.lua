-- FRZ RP (frz-walkers) - Config du directeur de spawn rodeurs.
-- Tous les spawns sont COTE CLIENT : chaque client gere ses propres rodeurs
-- autour de lui (scalable, pas de sync serveur massif). Les morsures sont
-- validees par le serveur pour eviter les triches.

FrzWalkers = FrzWalkers or {}
FrzWalkers.Config = FrzWalkers.Config or {}

-- Liste des modeles de peds utilises pour les rodeurs.
-- IMPORTANT : 's_m_y_zombie_01' existe dans GTA V de base (flux Halloween).
-- Si tu installes un pack de skins zombies (voir MODS.md), ajoute ici leurs
-- noms de modele (ex: 'zombie_apoc_1', 'walker_rotten', etc.).
FrzWalkers.Config.PedModels = {
    's_m_y_zombie_01',
}

-- Nombre max de rodeurs actifs autour d'un joueur en meme temps.
FrzWalkers.Config.MaxPerPlayer = 12

-- Distance (m) autour du joueur ou les rodeurs peuvent spawner.
FrzWalkers.Config.SpawnMinDistance = 25.0
FrzWalkers.Config.SpawnMaxDistance = 70.0

-- Distance au-dela de laquelle un rodeur est supprime (cleanup).
FrzWalkers.Config.DespawnDistance = 120.0

-- Intervalle (ms) entre deux tentatives de spawn.
FrzWalkers.Config.SpawnInterval = 4000

-- Nombre max de tentatives de placement (on cherche un ground valide).
FrzWalkers.Config.MaxPlacementAttempts = 6

-- Probabilite qu'un spawn reussisse a chaque tick (0.0 - 1.0).
-- Permet de lisser la densite dans le temps au lieu de tout spawner d un coup.
FrzWalkers.Config.SpawnChance = 0.6

-- Sante et degats des rodeurs.
FrzWalkers.Config.WalkerHealth       = 140
FrzWalkers.Config.WalkerAccuracy     = 5    -- imprecis si ils sont armes
FrzWalkers.Config.WalkerMeleeDamage  = 12
FrzWalkers.Config.WalkerMovementClipset = 'move_m@drunk@verydrunk'

-- Distance (m) a partir de laquelle un rodeur attaque le joueur.
FrzWalkers.Config.DetectionRange = 40.0
-- Distance a laquelle la morsure declenche un event serveur.
FrzWalkers.Config.BiteRange = 1.6
-- Cooldown entre deux morsures du meme rodeur (ms).
FrzWalkers.Config.BiteCooldown = 2500

-- Zones "chaudes" ou la densite est x2 (ex: centre ville, hopitaux).
-- Format : { center = vector3, radius = float, multiplier = float }
FrzWalkers.Config.HotZones = {
    { center = vector3(250.0, -1360.0, 30.0),  radius = 150.0, multiplier = 1.5 }, -- centre medical
    { center = vector3(-1100.0, -1700.0, 5.0), radius = 200.0, multiplier = 1.3 }, -- Vespucci
}

-- Zones interdites (aucun spawn meme si joueur a proximite). Alimentees
-- dynamiquement par frz-safezones via export. Format identique aux HotZones.
FrzWalkers.Config.NoSpawnZones = {}

-- Ambient moans : interval aleatoire (ms) entre deux grognements par rodeur.
FrzWalkers.Config.MoanIntervalMin = 5000
FrzWalkers.Config.MoanIntervalMax = 15000

-- Sound set natif GTA utilise pour les grognements (bruit generique zombie
-- stock du jeu). Tu peux override via un pack audio custom (voir MODS.md).
FrzWalkers.Config.MoanSoundSet = 'MP_BRIBE_SOUND_SET'
FrzWalkers.Config.MoanSoundName = 'BOOM'
