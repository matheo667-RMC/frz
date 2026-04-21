-- FRZ RP (frz-core) - Helpers clavier / controles partages.
-- Fournit des constantes et un helper pour poser des commandes liees a une
-- touche, afin que les autres ressources n'aient pas a re-declarer les memes
-- hashes Citizen controls.

FrzCore = FrzCore or {}
FrzCore.Client = FrzCore.Client or {}

-- Quelques hashes Citizen.Input courants (mapping clavier AZERTY ou QWERTY).
-- Voir https://docs.fivem.net/docs/game-references/controls/ pour la liste.
FrzCore.Client.Keys = {
    E     = 38,
    F     = 23,
    G     = 47,
    H     = 74,
    INTERACT = 38, -- alias E
}

function FrzCore.Client.isKeyJustPressed(key)
    return IsControlJustReleased(0, key)
end

exports('isKeyJustPressed', FrzCore.Client.isKeyJustPressed)
