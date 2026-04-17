-- FRZ RP - Spawn resource configuration
-- Modifie ces valeurs pour ajuster le comportement de la cinematique.

Config = {}

-- Coordonnees de spawn final du joueur (sortie du terminal LSIA).
-- Format : vector4(x, y, z, heading)
Config.SpawnCoords = vector4(-1034.6, -2733.6, 20.17, 327.0)

-- Modele de l'avion qui atterrit (private jet Luxor Deluxe par defaut).
-- Autres bons choix : 'luxor', 'nimbus', 'jet', 'titan'
Config.PlaneModel = 'luxor2'

-- Modele du pilote a l'interieur de l'avion.
Config.PilotModel = 's_m_m_pilot_01'

-- Position initiale de l'avion (haut et loin pour simuler l'approche).
-- Format : vector4(x, y, z, heading)
Config.PlaneSpawn = vector4(-800.0, -3600.0, 420.0, 310.0)

-- Coordonnees de la piste d'atterrissage LSIA (depart / fin).
Config.RunwayStart = vector3(-1336.0, -3044.0, 13.95)
Config.RunwayEnd   = vector3(-1659.0, -2942.0, 13.95)

-- Position de la camera cinematique pendant l'atterrissage.
Config.CameraPosition = vector3(-1200.0, -3100.0, 60.0)
Config.CameraRotation = vector3(-10.0, 0.0, 250.0)

-- Duree totale de la cinematique avant affichage de l'annonce (ms).
Config.CinematicDuration = 10000

-- Duree d'affichage de la banniere d'annonce (ms).
-- Doit etre >= duree du fichier audio 'html/welcome_fr.ogg' (~14 s).
Config.AnnouncementDuration = 14000

-- Textes affiches. Ne pas depasser ~60 caracteres par ligne.
Config.WelcomeMessage     = 'FRZ RP'
Config.WelcomeSubtitle    = "Bienvenue a l'aeroport international de Los Santos"
Config.WelcomeBackMessage = 'Content de vous revoir sur FRZ RP'

-- Si true, la cinematique complete sera rejouee a chaque connexion (debug).
-- Si false (defaut), seul le premier join declenche la cinematique.
Config.AlwaysPlayIntro = false

-- Prefixe utilise pour stocker l'etat "deja joue" dans le KVP serveur.
Config.KvpPrefix = 'frz-rp-spawn:joined:'
