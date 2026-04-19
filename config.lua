-- FRZ RP - Spawn resource configuration
-- Modifie ces valeurs pour ajuster le comportement de la cinematique.

Config = {}

-- Coordonnees de spawn final du joueur (devant les portes du terminal LSIA).
-- Format : vector4(x, y, z, heading). Utilise uniquement lors du premier join
-- quand aucune derniere position n'est sauvegardee.
Config.SpawnCoords = vector4(-1034.6, -2733.6, 20.17, 327.0)

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
-- On demarre proche (~700 m du seuil de piste) et bas (90 m d'altitude) pour
-- que l'avion soit GROS et bien visible a la camera, puis descend et touche
-- la piste avant la fin de la cinematique.
Config.PlaneSpawn = vector4(-703.0, -3255.0, 90.0, 245.0)

-- Vitesse initiale de l'avion (plus rapide = on voit bien l'avion descendre).
Config.PlaneSpeed = 70.0

-- Coordonnees de la piste d'atterrissage LSIA (depart / fin).
Config.RunwayStart = vector3(-1336.0, -3044.0, 13.95)
Config.RunwayEnd   = vector3(-1659.0, -2942.0, 13.95)

-- Position et rotation de la camera cinematique pendant l'atterrissage.
-- Camera placee a mi-chemin entre le spawn de l'avion et la piste, sur le cote,
-- pour un shot cinematique 3/4 arriere pendant que l'avion descend.
Config.CameraPosition = vector3(-1050.0, -3120.0, 55.0)
Config.CameraRotation = vector3(-5.0, 0.0, 245.0)

-- Delai (ms depuis le debut de la cinematique) avant de declencher le son
-- d'atterrissage (bruit d'avion + touchdown). Calibre pour correspondre
-- au moment ou l'avion touche la piste visuellement.
Config.LandingSoundDelay = 9000

-- Duree du title card affiche au debut (ms).
Config.TitleCardDuration = 3000

-- Duree totale de la cinematique (ms) : title card + observation de l'avion.
-- On laisse assez de temps pour que l'avion descende de 90m a 15m sur ~700m.
Config.CinematicDuration = 15000

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

    -- Position du PNJ vendeur (pres du poteau du terminal, cote route).
    pedPos = vector4(-1031.5, -2731.5, 20.17, 145.0),

    -- Modele du PNJ. Exemples : 's_m_m_lsmetro_01' (employe LS Metro),
    -- 'a_m_y_business_03' (businessman), 'ig_rashcosvki' (dealer).
    pedModel = 's_m_m_lsmetro_01',

    -- Point d'apparition de la voiture achetee (sur la voie devant le terminal).
    -- Le joueur est mis automatiquement au volant (siege conducteur).
    spawnPos = vector4(-1041.0, -2743.5, 19.95, 145.0),

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
