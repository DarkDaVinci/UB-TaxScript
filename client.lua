ESX = nil

CreateThread(function()
  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Wait(50)
  end
  -- ob zagonu poskrbimo, da UI ni prikazan in fokus ni zaklenjen
  SetNuiFocus(false, false)
  SendNUIMessage({ action = "close" })
end)

RegisterCommand("upravljaj_davke", function()
  ESX.TriggerServerCallback("davki:getTaxData", function(d)
    if not d then
      return lib.notify({
        title       = "Napaka",
        description = "Nimaš dovoljenja.",
        type        = "error"
      })
    end
    -- pošlji parametre v NUI
    SetNuiFocus(true, true)
    SendNUIMessage({
      action     = "open",
      baseTax    = d.baseTax,
      vehicleTax = d.vehicleTax,
      interval   = d.interval,
      stats      = d.stats
    })
  end)
end)

RegisterNUICallback("saveTaxes", function(data, cb)
  TriggerServerEvent("davki:updateTaxes", data)
  cb("ok")
end)

RegisterNUICallback("close", function(_, cb)
  SendNUIMessage({ action = "close" })
  SetNuiFocus(false, false)
  cb("ok")
end)

RegisterNetEvent("davki:closeMenu")
AddEventHandler("davki:closeMenu", function()
  SendNUIMessage({ action = "close" })
  SetNuiFocus(false, false)
end)

-- Za hitro čiščenje UI overlay-a
RegisterCommand("resetui", function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
  end, false)
  