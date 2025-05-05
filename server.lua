ESX = exports["es_extended"]:getSharedObject()

local baseTax = Config.BaseTax
local vehicleTax = Config.VehicleTax


ESX.RegisterServerCallback("davki:canManageTaxes", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local hasAccess = xPlayer and xPlayer.job.name == Config.AllowedJob and xPlayer.job.grade >= Config.AllowedGrade
    cb(hasAccess)
end)


RegisterServerEvent("davki:updateTaxes")
AddEventHandler("davki:updateTaxes", function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if xPlayer and xPlayer.job.name == Config.AllowedJob and xPlayer.job.grade >= Config.AllowedGrade then
        local newBase = tonumber(data.base)
        local newVehicle = tonumber(data.vehicle)

        if newBase and newVehicle then
            baseTax = newBase
            vehicleTax = newVehicle
            lib.notify(src, {
                title = "Davčna Uprava",
                description = "Davki uspešno posodobljeni!",
                type = "success"
            })
        else
            lib.notify(src, {
                title = "Napaka",
                description = "Neveljavna vrednost davkov.",
                type = "error"
            })
        end
    else
        DropPlayer(src, "Poskus manipulacije z davki brez dovoljenja.")
    end
end)


CreateThread(function()
    while true do
        Wait(Config.TaxInterval * 60000)

        for _, playerId in ipairs(ESX.GetPlayers()) do
            local xPlayer = ESX.GetPlayerFromId(playerId)
            if xPlayer then
                local identifier = xPlayer.getIdentifier()
                local totalTax = baseTax

                exports.oxmysql:execute('SELECT COUNT(*) as count FROM user_vehicles WHERE owner = ?', {
                    identifier
                }, function(result)
                    local vehicleCount = result[1].count or 0
                    totalTax = totalTax + (vehicleCount * vehicleTax)

                    if xPlayer.getAccount('bank').money >= totalTax then
                        xPlayer.removeAccountMoney('bank', totalTax)

                        -- notification
                        lib.notify(playerId, {
                            title = "Davčna Uprava",
                            description = ("Plačal si davek v višini: $%s"):format(totalTax),
                            type = "inform"
                        })

                        ----- doda dnar cityhallu  
                        exports.oxmysql:execute('SELECT data FROM ' .. Config.BusinessTable .. ' WHERE id = ?', {
                            Config.BusinessId
                        }, function(businessResult)
                            if businessResult[1] then
                                local businessData = json.decode(businessResult[1].data)
                                businessData.balance = (businessData.balance or 0) + totalTax
                                local newData = json.encode(businessData)

                                exports.oxmysql:execute('UPDATE ' .. Config.BusinessTable .. ' SET data = ? WHERE id = ?', {
                                    newData, Config.BusinessId
                                })
                            end
                        end)
                    else
                        lib.notify(playerId, {
                            title = "Davčna Uprava",
                            description = "Nimaš dovolj denarja za plačilo davka!",
                            type = "error"
                        })
                    end
                end)
            end
        end
    end
end)
