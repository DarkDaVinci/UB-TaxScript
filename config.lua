Config = {}

-- Privzete vrednosti, lahko se spremenijo runtime
Config.TaxInterval = 20 -- minut
Config.BaseTax = 50 ---- ne potreno (spreminjaj v sql)
Config.VehicleTax = 100 -- ne potreno (spreminjaj v sql)

-- Clerk dostop
Config.AllowedJob = "clerk"
Config.AllowedGrade = 5

-- Lokacija denarja
Config.BusinessTable = "vms_business"
Config.BusinessId = "Cityhall"
