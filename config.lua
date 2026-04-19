-- FRZ RP - Spawn resource configuration
-- Modifie ces valeurs pour ajuster le comportement de la cinematique.

Config = {}

-- Coordonnees de spawn final du joueur : centre du rond en pave devant
-- l'entree principale du terminal LSIA (entre les deux poteaux, cote route).
-- Format : vector4(x, y, z, heading). Utilise uniquement lors du premier join
-- quand aucune derniere position n'est sauvegardee.
-- Heading 157 = le joueur regarde vers la route (taxis / vendeur sur sa
-- droite), cote par lequel il est "arrive" de l'avion.
Config.SpawnCoords = vector4(-1037.5, -2738.0, 20.17, 157.0)

-- Intervalle (en ms) auquel le client envoie sa position au serveur pour sauvegarde.
-- Mise a jour frequente = couverture en cas de crash, mais plus de traffic reseau.
Config.PositionSaveInterval = 20000

-- Si true, le joueur est teleporte a sa derniere position connue apres la banniere
-- "bon retour" (comportement demande : on reapparait la ou on s'est deconnecte).
-- Si aucune position n'est sauvegardee, on ne teleporte pas (spawn par defaut).
Config.RestoreLastPosition = true

-- Modele de l'avion qui atterrit (private jet Luxor Deluxe par defaut).
-- Autres bons choix : 'luxor', 'nimbus', 'jet', 'titan'
Config.PlaneModel = 'luxor2'

-- Modele du pilote a l'interieur de l'avion.
Config.PilotModel = 's_m_m_pilot_01'

-- Position initiale de l'avion (sur la trajectoire d'approche, en altitude).
-- Format : vector4(x, y, z, heading). Heading pointe vers le debut de piste.
-- On demarre TRES proche (~350 m du seuil de piste) et bas (60 m d'altitude)
-- pour avoir un plan ferme et cinematique type "Paris Live RP" : l'avion
-- passe gros a l'ecran, descend vers la piste, puis fade to black avant
-- le touchdown reel.
Config.PlaneSpawn = vector4(-1025.0, -3151.0, 60.0, 245.0)

-- Vitesse initiale de l'avion (approche rapide pour que ca soit dynamique).
Config.PlaneSpeed = 65.0

-- Coordonnees de la piste d'atterrissage LSIA (depart / fin).
Config.RunwayStart = vector3(-1336.0, -3044.0, 13.95)
Config.RunwayEnd   = vector3(-1659.0, -2942.0, 13.95)

-- Position et rotation de la camera cinematique pendant l'atterrissage.
-- Camera ~110 m a cote de la trajectoire d'approche, tres proche du spawn
-- de l'avion, legerement en contrebas pour voir l'avion passer au-dessus /
-- devant. PointCamAtEntity suit l'avion automatiquement.
Config.CameraPosition = vector3(-1155.0, -3080.0, 25.0)
Config.CameraRotation = vector3(-3.0, 0.0, 220.0)

-- Delai (ms depuis le debut de la cinematique) avant de declencher le son
-- d'atterrissage. Plus tot car la camera est plus proche de l'avion des
-- les premieres secondes.
Config.LandingSoundDelay = 3500

-- Duree du title card affiche au debut (ms).
Config.TitleCardDuration = 3000

-- Instant (ms depuis le debut de la cinematique) auquel on declenche le
-- fade to black. L'atterrissage "visuel" se passe pendant le noir, avec
-- le son qui peak, comme dans les serveurs FiveM RP style Paris Live.
Config.FadeToBlackAt = 9000

-- Duree totale de la cinematique (ms) : observation puis noir + son.
-- = FadeToBlackAt + duree du noir avant le fade-in au terminal.
Config.CinematicDuration = 12500

-- Duree d'affichage de la banniere d'annonce (ms).
-- Doit etre >= duree du fichier audio 'html/welcome_fr.ogg' (~16 s).
Config.AnnouncementDuration = 17000

-- Textes affiches.
Config.TitleCardMain      = 'FRZ RP'
Config.TitleCardSub       = 'Los Santos International Airport'
Config.WelcomeMessage     = 'Bienvenue sur FRZ RP'
Config.WelcomeSubtitle    = 'Aeroport international de Los Santos'
Config.WelcomeBackMessage = 'Content de vous revoir sur FRZ RP'

-- Si true, la cinematique complete sera rejouee a chaque connexion (debug).
-- Si false (defaut), seul le premier join declenche la cinematique.
Config.AlwaysPlayIntro = false

-- Prefixe utilise pour stocker l'etat "deja joue" (conserve pour compat,
-- mais la persistance passe desormais par html/joined_players.json - voir server/main.lua).
Config.KvpPrefix = 'frz-rp-spawn:joined:'

-- ============================================================================
-- Location / vente de voitures (vendeur PNJ pres du terminal)
-- ============================================================================
Config.CarRental = {
    enabled = true,

    -- Somme de depart (GTA $) creditee a chaque nouveau joueur au premier join.
    startingCash = 1000,

    -- Position du PNJ vendeur (colle au poteau du terminal, au bord
    -- du plateau, en face de la route ou spawn la voiture).
    pedPos = vector4(-1034.2, -2735.2, 20.17, 155.0),

    -- Modele du PNJ. Exemples : 's_m_m_lsmetro_01' (employe LS Metro),
    -- 'a_m_y_business_03' (businessman), 'ig_rashcosvki' (dealer).
    pedModel = 's_m_m_lsmetro_01',

    -- Point d'apparition de la voiture achetee : sur la VOIE de drop-off
    -- devant le terminal (pas sur les marches, pas sur le trottoir).
    -- L'altitude z=13.2 correspond au niveau de la route, pas du plateau
    -- du terminal (z=20.17). Le joueur est mis automatiquement au volant.
    spawnPos = vector4(-1046.5, -2749.0, 13.20, 145.0),

    -- Distance (m) a laquelle le prompt d'interaction apparait.
    interactionDistance = 2.5,

    -- Touche d'interaction. 38 = E (code GTA control). Autres exemples : 51 = E,
    -- Utilise IsControlJustReleased avec INPUT_PICKUP.
    interactionKey = 38,

    -- Si true, le joueur est place directement au volant du vehicule livre.
    -- Si false, le vehicule spawn vide a cote du vendeur.
    putPlayerInVehicle = true,

    -- Couleurs GTA utilisees pour colorer les vehicules au spawn.
    -- Les valeurs sont des IDs de couleur GTA (voir natives SetVehicleColours).
    -- Clefs utilisees dans le champ `color` des vehicules ci-dessous.
    colors = {
        black = 0,    -- Metallic Black
        white = 134,  -- Utility Off White (blanc casse, bien visible)
        red   = 27,   -- Metallic Red
    },

    -- Categories disponibles dans le menu. La cle est utilisee dans le champ
    -- `category` de chaque vehicule. L'ordre controle l'ordre des onglets.
    categories = {
        { key = 'bike', label = 'Velos'    },
        { key = 'moto', label = 'Motos'    },
        { key = 'car',  label = 'Voitures' },
    },

    -- Liste des vehicules proposes. Prix 0 = gratuit.
    -- Champ `category` : 'bike' / 'moto' / 'car' (cf. `categories` au-dessus).
    -- Champ `color`    : 'black' / 'white' / 'red' (cf. `colors` au-dessus).
    vehicles = {
        -- Velos (gratuits)
        { label = 'BMX',        model = 'bmx',        category = 'bike', price = 0,   color = 'black' },
        { label = 'Cruiser',    model = 'cruiser',    category = 'bike', price = 0,   color = 'white' },
        -- Motos (1 gratuite, 1 payante)
        { label = 'Sanchez',    model = 'sanchez',    category = 'moto', price = 0,   color = 'black' },
        { label = 'Bagger',     model = 'bagger',     category = 'moto', price = 200, color = 'red'   },
        -- Voitures (1 gratuite, 1 payante)
        { label = 'Blista',     model = 'blista',     category = 'car',  price = 0,   color = 'white' },
        { label = 'Sultan',     model = 'sultan',     category = 'car',  price = 500, color = 'black' },
    },
}
