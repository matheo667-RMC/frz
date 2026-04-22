-- Dead Zone RP (frz-walkers) - Configuration des relationships groups.
-- On cree un groupe 'FRZ_WALKERS' hostile a tout (joueurs, NPCs civils) pour
-- que les rodeurs attaquent sans distinction.

FrzWalkers = FrzWalkers or {}
FrzWalkers.Client = FrzWalkers.Client or {}

local WALKER_GROUP = GetHashKey('FRZ_WALKERS')
FrzWalkers.Client.GroupHash = WALKER_GROUP

CreateThread(function()
    AddRelationshipGroup('FRZ_WALKERS')

    -- Walker -> Player : hate (5)
    SetRelationshipBetweenGroups(5, WALKER_GROUP, GetHashKey('PLAYER'))
    SetRelationshipBetweenGroups(5, GetHashKey('PLAYER'), WALKER_GROUP)

    -- Walker -> Civilians : hate
    SetRelationshipBetweenGroups(5, WALKER_GROUP, GetHashKey('CIVMALE'))
    SetRelationshipBetweenGroups(5, WALKER_GROUP, GetHashKey('CIVFEMALE'))

    -- Walker <-> Walker : companion
    SetRelationshipBetweenGroups(1, WALKER_GROUP, WALKER_GROUP)
end)
