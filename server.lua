ESX = exports["es_extended"]:getSharedObject()

local baseTax = Config.BaseTax
local vehicleTax = Config.VehicleTax


lib.addCommand('upravljaj_davke', {
    help = 'Upravljaj davke (samo za zupana)',
    restricted = false
}, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    if xPlayer.job.name ~= Config.AllowedJob or xPlayer.job.grade < Config.AllowedGrade then
        return lib.notify(source, { type = 'error', description = 'Nimaš dovoljenja.' })
    end

    lib.inputDialog('Upravljanje davkov', {
        { type = 'number', label = 'Osnovni davek ($)', default = baseTax, min = 0 },
        { type = 'number', label = 'Davek na vozilo ($)', default = vehicleTax, min = 0 }
    }, function(data)
        if not data then return end
        baseTax = tonumber(data[1]) or baseTax
        vehicleTax = tonumber(data[2]) or vehicleTax
        lib.notify(source, { type = 'success', description = 'Davki posodobljeni.' })
    end)
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

                     ------ Notification ------------
                        lib.notify(playerId, {
                            title = 'Davčna Uprava',
                            description = ('Plačal si davek v višini: $%s'):format(totalTax),
                            type = 'success'
                        })
                     --------------------------------


                        -- Pridobi trenutni balance iz JSON `data` stolpca
                        exports.oxmysql:execute('SELECT data FROM '..Config.BusinessTable..' WHERE id = ?', {
                            Config.BusinessId
                        }, function(businessResult)
                            if businessResult[1] then
                                local businessData = json.decode(businessResult[1].data)
                                businessData.balance = (businessData.balance or 0) + totalTax
                                local newData = json.encode(businessData)

                                exports.oxmysql:execute('UPDATE '..Config.BusinessTable..' SET data = ? WHERE id = ?', {
                                    newData, Config.BusinessId
                                })
                            end
                        end)
                    else
                        lib.notify(playerId, {
                            title = 'Davčna Uprava',
                            description = 'Nimaš dovolj denarja za plačilo davka!',
                            type = 'error'
                        })
                    end
                end)
            end
        end
    end
end)
