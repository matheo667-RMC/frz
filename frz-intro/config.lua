-- Dead Zone RP (frz-intro) - Config de l'animation de bienvenue.

FrzIntro = FrzIntro or {}
FrzIntro.Config = {
    -- Texte principal.
    Title       = 'DEAD ZONE',
    Subtitle    = 'Bienvenue dans la',
    Tagline     = "Les morts sont sortis. Tiens bon.",

    -- Duree totale de l'animation (ms). L'anim CSS est calibree sur cette duree.
    TotalDuration = 6500,

    -- Fenetre ou on desactive les controles du joueur pendant l'intro.
    FreezePlayer = true,

    -- Delai apres le spawn avant de lancer l'intro (ms). Laisse le temps au
    -- jeu de finir le fade-in natif.
    StartDelay  = 1500,

    -- Si true, l'intro se joue a chaque connexion au serveur. Si false, une
    -- seule fois par session client (pas rejouee apres un respawn).
    PlayOnEveryConnect = true,
}
