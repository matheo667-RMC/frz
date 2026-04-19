-- FRZ Phone - configuration
Config = Config or {}

-- Touche pour ouvrir le telephone.
Config.OpenKey = 'F1'

-- Style par defaut si le joueur n'a pas encore choisi : 'iphone' ou 'android'.
Config.DefaultOS = 'iphone'

-- Si true, le joueur doit avoir l'item 'phone' dans l'inventaire pour l'ouvrir.
-- Si frz-inventory n'est pas present, on ignore ce check.
Config.RequirePhoneItem = true

-- Plage de numeros generes (6 chiffres : 555-XXXX, style FiveM RP).
Config.NumberPrefix = '555-'
Config.NumberDigits = 4

-- Persistance serveur.
Config.PhoneDataFile = 'phones.json'
Config.MessagesFile = 'messages.json'
Config.CallsFile = 'calls.json'

-- Apps disponibles (nom -> icone emoji + label).
Config.Apps = {
    { id = 'phone',    label = 'Téléphone', icon = '📞', color = '#2ecc71' },
    { id = 'messages', label = 'Messages',  icon = '💬', color = '#3498db' },
    { id = 'contacts', label = 'Contacts',  icon = '👥', color = '#95a5a6' },
    { id = 'bank',     label = 'Banque',    icon = '🏦', color = '#e74c3c' },
    { id = 'wallet',   label = 'Cartes',    icon = '💳', color = '#9b59b6' },
    { id = 'settings', label = 'Réglages',  icon = '⚙️',  color = '#7f8c8d' },
}
