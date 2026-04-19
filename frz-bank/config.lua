-- FRZ Bank - configuration
Config = Config or {}

-- Solde de depart offert au premier compte.
Config.StartingBalance = 2500.0

-- Max cash au retrait (par operation).
Config.MaxWithdraw = 10000.0

-- Max au virement.
Config.MaxTransfer = 50000.0

-- Fichier de persistance.
Config.PersistenceFile = 'bank.json'

-- Emplacements des banques (interieur pour interaction comptoir).
-- Coords Pacific Standard + Fleeca (Legion Square) + Paleto + Sandy Shores.
Config.Banks = {
    { name = 'Pacific Standard',       x = 235.0,   y = 217.0,   z = 106.2866, h = 340.0,  marker = true },
    { name = 'Fleeca Legion',          x = 150.266, y = -1040.20,z = 29.3746,  h = 160.0,  marker = true },
    { name = 'Fleeca Vinewood',        x = -1212.98,y = -330.84, z = 37.787,   h = 25.0,   marker = true },
    { name = 'Fleeca Rockford',        x = -351.533,y = -49.529, z = 49.0421,  h = 340.0,  marker = true },
    { name = 'Fleeca Great Ocean',     x = -2962.58,y = 482.628, z = 15.7031,  h = 87.0,   marker = true },
    { name = 'Fleeca Paleto Bay',      x = -112.202,y = 6469.295,z = 31.6267,  h = 135.0,  marker = true },
    { name = 'Fleeca Grand Senora',    x = 1175.061,y = 2706.64, z = 38.0949,  h = 0.0,    marker = true },
}

-- Rayon d'interaction avec le comptoir (touche E).
Config.BankInteractDistance = 1.8

-- Hash des props "ATM" du jeu (utilises pour spawn les blips et l'interaction).
-- Liste standard FiveM des ATMs : prop_atm_01, prop_atm_02, prop_atm_03, prop_fleeca_atm.
Config.ATMModels = {
    'prop_atm_01',
    'prop_atm_02',
    'prop_atm_03',
    'prop_fleeca_atm',
}

-- Rayon pour detecter un ATM devant le joueur (E).
Config.ATMInteractDistance = 1.2

-- Blips sur la carte.
Config.ShowBankBlips = true
Config.ShowATMBlips = false  -- il y en a beaucoup, souvent desactive par defaut.

-- Frais de virement (% ou montant fixe ; ici fixe).
Config.TransferFee = 0.0
