-- FRZ Inventaire - drops au sol (cote client)
-- Le serveur envoie la liste des drops proches, le client spawn un prop local
-- (non-networked : chaque client voit son propre prop, c'est suffisant car on
-- utilise uniquement les coords pour l'interaction).

local localProps = {}  -- drop_id -> prop handle

local function removeLocalProp(dropId)
    local h = localProps[dropId]
    if h and DoesEntityExist(h) then
        DeleteEntity(h)
    end
    localProps[dropId] = nil
end

local function spawnLocalProp(drop)
    if localProps[drop.id] then return end
    local model = GetHashKey(Config.DropProp)
    RequestModel(model)
    local t0 = GetGameTimer()
    while not HasModelLoaded(model) do
        Wait(10)
        if GetGameTimer() - t0 > 3000 then return end
    end
    local obj = CreateObject(model, drop.x, drop.y, drop.z - 0.9, false, false, false)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(model)
    localProps[drop.id] = obj
end

RegisterNetEvent('frz-inventory:drops:sync', function(drops)
    -- Retire les props qui ne sont plus dans la liste.
    local keep = {}
    for _, d in ipairs(drops) do keep[d.id] = true end
    for id, _ in pairs(localProps) do
        if not keep[id] then removeLocalProp(id) end
    end
    -- Ajoute les nouveaux.
    for _, d in ipairs(drops) do
        spawnLocalProp(d)
    end
end)

RegisterNetEvent('frz-inventory:drops:remove', function(dropId)
    removeLocalProp(dropId)
end)

-- Thread d'interaction : help text + touche E.
CreateThread(function()
    while true do
        local sleep = 750
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local closestId, closestDist = nil, math.huge
        for id, h in pairs(localProps) do
            if DoesEntityExist(h) then
                local d = #(coords - GetEntityCoords(h))
                if d < Config.PickupDistance and d < closestDist then
                    closestId, closestDist = id, d
                end
            end
        end
        if closestId then
            sleep = 0
            SetTextComponentFormat('STRING')
            AddTextComponentString('Appuyez sur ~INPUT_PICKUP~ pour ramasser')
            DisplayHelpTextFromStringLabel(0, 0, 1, -1)
            if IsControlJustReleased(0, 38) then -- E
                TriggerServerEvent('frz-inventory:drops:pickup', closestId)
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id, _ in pairs(localProps) do removeLocalProp(id) end
end)
