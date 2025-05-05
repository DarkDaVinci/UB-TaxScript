RegisterCommand("upravljaj_davke", function()
    ESX.TriggerServerCallback("davki:canManageTaxes", function(can)
        if can then
            SetNuiFocus(true, true)
            SendNUIMessage({ action = "open" })
        else
            ESX.ShowNotification("Nimaš dovoljenja za upravljanje davkov.")
        end
    end)
end)

RegisterNUICallback("saveTaxes", function(data, cb)
    TriggerServerEvent("davki:updateTaxes", data)
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("close", function(_, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)
