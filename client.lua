ESX = nil

CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Wait(100)
    end
end)

RegisterCommand("upravljaj_davke", function()
    ESX.TriggerServerCallback("davki:canManageTaxes", function(can)
        if can then
            SetNuiFocus(true, true)
            SendNUIMessage({ action = "open" })
        else
            lib.notify({
                title = "Napaka",
                description = "Nimaš dovoljenja za urejanje davkov.",
                type = "error"
            })
        end
    end)
end)

RegisterNUICallback("saveTaxes", function(data, cb)
    TriggerServerEvent("davki:updateTaxes", data)
    cb("ok")
end)

RegisterNUICallback("close", function(_, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNetEvent("davki:closeMenu")
AddEventHandler("davki:closeMenu", function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
end)
