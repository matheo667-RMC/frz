-- FRZ RP (frz-walkers) - Grognements aleatoires des rodeurs (ambient).
-- On utilise PlaySoundFromEntity avec un sound set natif GTA V. Si tu
-- installes un pack audio custom (voir MODS.md), override le sound set dans
-- config.lua.

FrzWalkers = FrzWalkers or {}

CreateThread(function()
    while true do
        Wait(1000)
        local now = GetGameTimer()
        for walker, meta in pairs(FrzWalkers.Client.active or {}) do
            if DoesEntityExist(walker) and not IsPedDeadOrDying(walker, true) then
                if (meta.moanAt or 0) <= now then
                    PlaySoundFromEntity(-1,
                        FrzWalkers.Config.MoanSoundName or 'BOOM',
                        walker,
                        FrzWalkers.Config.MoanSoundSet or 'MP_BRIBE_SOUND_SET',
                        false, 0)
                    meta.moanAt = now + math.random(
                        FrzWalkers.Config.MoanIntervalMin,
                        FrzWalkers.Config.MoanIntervalMax)
                end
            end
        end
    end
end)
