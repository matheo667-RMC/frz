-- Dead Zone RP - Spawn resource configuration
-- Modifie ces valeurs pour ajuster le comportement de la cinematique.

Config = {}

-- Coordonnees de spawn final du joueur (a l'interieur du terminal LSIA).
-- Format : vector4(x, y, z, heading)
Config.SpawnCoords = vector4(-1037.5, -2738.0, 20.17, 328.0)

-- Modele de l'avion qui atterrit (private jet Luxor Deluxe par defaut).
-- Autres bons choix : 'luxor', 'nimbus', 'jet', 'titan'
Config.PlaneModel = 'luxor2'

-- Modele du pilote a l'interieur de l'avion.
Config.PilotModel = 's_m_m_pilot_01'

-- Position initiale de l'avion (sur la trajectoire d'approche, en altitude).
-- Format : vector4(x, y, z, heading). Heading pointe vers le debut de piste.
Config.PlaneSpawn = vector4(570.0, -3646.0, 250.0, 72.0)

-- Vitesse initiale de l'avion (moderee pour permettre un bon atterrissage).
Config.PlaneSpeed = 55.0

-- Coordonnees de la piste d'atterrissage LSIA (depart / fin).
Config.RunwayStart = vector3(-1336.0, -3044.0, 13.95)
Config.RunwayEnd   = vector3(-1659.0, -2942.0, 13.95)

-- Position et rotation de la camera cinematique pendant l'atterrissage.
Config.CameraPosition = vector3(-1100.0, -3150.0, 55.0)
Config.CameraRotation = vector3(-8.0, 0.0, 235.0)

-- Delai (ms depuis le debut de la cinematique) avant de declencher le son
-- d'atterrissage (bruit d'avion + touchdown). Calibre pour correspondre
-- au moment ou l'avion touche la piste visuellement.
Config.LandingSoundDelay = 7500

-- Duree du title card affiche au debut (ms).
Config.TitleCardDuration = 3000

-- Duree totale de la cinematique (ms) : title card + observation de l'avion.
-- Doit etre superieur a TitleCardDuration + LandingSoundDelay + ~2 s.
Config.CinematicDuration = 12000

-- Duree d'affichage de la banniere d'annonce (ms).
-- Doit etre >= duree du fichier audio 'html/welcome_fr.ogg' (~16 s).
Config.AnnouncementDuration = 17000

-- Textes affiches.
Config.TitleCardMain      = 'Dead Zone RP'
Config.TitleCardSub       = 'Los Santos International Airport'
Config.WelcomeMessage     = 'Bienvenue sur Dead Zone RP'
Config.WelcomeSubtitle    = 'Aeroport international de Los Santos'
Config.WelcomeBackMessage = 'Content de vous revoir sur Dead Zone RP'

-- Si true, la cinematique complete sera rejouee a chaque connexion (debug).
-- Si false (defaut), seul le premier join declenche la cinematique.
Config.AlwaysPlayIntro = false

-- Prefixe utilise pour stocker l'etat "deja joue" (conserve pour compat,
-- mais la persistance passe desormais par html/joined_players.json - voir server/main.lua).
Config.KvpPrefix = 'frz-rp-spawn:joined:'
