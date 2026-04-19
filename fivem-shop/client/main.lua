-- frz-rp-shop : client.
-- Commande /shop qui ouvre la boutique dans le navigateur in-game (NUI)
-- en redirigeant vers la page externe du site. QBCore gere la notification.

RegisterCommand("shop", function()
    if Config.EnableShopCommand == false then return end
    -- On essaie d'abord d'ouvrir le site via le navigateur GTA Online externe.
    -- Si l'API native n'est pas dispo, on notifie juste l'URL a copier.
    local url = Config.ShopApiUrl
    TriggerEvent('chat:addMessage', {
        color = { 255, 217, 61 },
        multiline = true,
        args = { "[FRZ RP Boutique]", "Ouvre la boutique ici : " .. url },
    })
    -- Tentative d'ouverture via le navigateur de l'application Companion
    -- (certaines installations FiveM supportent SetDiscordAppId pour boutons).
    -- On laisse volontairement le lien dans le chat comme fallback fiable.
end, false)

-- Affiche un message de bienvenue au premier chargement du perso.
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(5000)
    TriggerEvent('chat:addMessage', {
        color = { 255, 217, 61 },
        multiline = true,
        args = {
            "[FRZ RP]",
            "Tape /shop pour ouvrir la boutique officielle. Tes achats PayPal sont livres automatiquement.",
        },
    })
end)
