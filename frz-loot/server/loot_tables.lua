-- FRZ RP (frz-loot) - Fonctions utilitaires pour tirer du loot.
-- Isolees du handler d'event pour etre testables plus facilement et pour
-- pouvoir exposer un tirage comme export (utilise par d'autres ressources qui
-- voudraient generer un loot, ex: mission quetes futures).

FrzLoot = FrzLoot or {}
FrzLoot.Server = FrzLoot.Server or {}

function FrzLoot.Server.rollTable(tableId)
    local tbl = FrzLoot.Config.LootTables[tableId]
    if not tbl then return {} end

    local result = {}
    for _, entry in ipairs(tbl) do
        if math.random() <= (entry.chance or 1.0) then
            local min = entry.min or 1
            local max = entry.max or min
            if max < min then max = min end
            local count = math.random(min, max)
            if count > 0 then
                result[#result + 1] = { item = entry.item, count = count }
            end
        end
    end
    return result
end

exports('rollTable', FrzLoot.Server.rollTable)
