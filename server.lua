ESX = exports["es_extended"]:getSharedObject()

-- davki se sedaj berejo iz DB ker je lažje spremenit potem iz NUI
local baseTax, vehicleTax = Config.BaseTax, Config.VehicleTax


local function SafeNotify(target, data)
  if lib then
    lib.notify(target, data)
  else
    TriggerClientEvent('ox_lib:notify', target, data)
  end
end

---- ob zagunu nalozi presetane davke
CreateThread(function()
  exports.oxmysql:execute('SELECT base_tax, vehicle_tax FROM tax_config WHERE id = 1', {}, function(res)
    if res and res[1] then
      baseTax    = res[1].base_tax
      vehicleTax = res[1].vehicle_tax
      print(("[UB-TaxScript] Naloženi davki: base=%s, vehicle=%s"):format(baseTax, vehicleTax))
    else
      print("[UB-TaxScript] Uporabljeni privzeti davki iz config.lua")
    end
  end)
end)

----- Funkcija ki zbira davke vaske tolko časa recimo (20min) --- basicly main fun.
CreateThread(function()
  while true do
    Wait(Config.TaxInterval * 60000)

    for _, playerId in ipairs(ESX.GetPlayers()) do
      local xP = ESX.GetPlayerFromId(playerId)
      if not xP then goto cont end

      local oId = xP.getIdentifier()
      if not oId:find("^char%d+:") then oId = "char1:"..oId end

      -- ta del je da bere koliko avtov ima uporabnik da mu da dolocen davek recimo ce ima 3 avte je to 3x100 in placa 300$
      exports.oxmysql:execute(
        'SELECT COUNT(*) as cnt FROM owned_vehicles WHERE owner = ?',
        { oId },
        function(r)
          local vc = r[1].cnt or 0
          local total = baseTax + vc * vehicleTax

          if xP.getAccount('bank').money >= total then
            xP.removeAccountMoney('bank', total)
            SafeNotify(playerId, {
              title       = "Davčna Uprava",
              description = ("Plačal si davek: $%s"):format(total),
              type        = "inform"
            })

            -- to posodablja racun od vms_cityhalla, sicer sem mislo naredi posebej "trezor" (databazo) za shranjen denar ampak nasemu serverju to bolj pase. Komot lahko sami spremenite.
            exports.oxmysql:execute(
              'SELECT data FROM '..Config.BusinessTable..' WHERE id = ?',
              { Config.BusinessId },
              function(br)
                if br[1] then
                  local bd = json.decode(br[1].data)
                  bd.balance = (bd.balance or 0) + total
                  exports.oxmysql:execute(
                    'UPDATE '..Config.BusinessTable..' SET data = ? WHERE id = ?',
                    { json.encode(bd), Config.BusinessId }
                  )
                end
              end
            )
          else
            SafeNotify(playerId, {
              title       = "Davčna Uprava",
              description = "Nimaš dovolj sredstev za davek!",
              type        = "error"
            })
          end
        end
      )

      ::cont::
    end
  end
end)

---- vsake 30 min bere statistiko ogralcev na strezniku da oceni prihodke naslednjega intervala
local function SaveSnapshot(pc, avgV)
  exports.oxmysql:execute(
    'INSERT INTO tax_statistics (timestamp, player_count, avg_vehicles) VALUES (?, ?, ?)',
    { os.time(), pc, avgV }
  )
end

CreateThread(function()
  while true do
    Wait(30 * 60 * 1000)  -- 30 m
    local pls = ESX.GetPlayers()
    local tp, tv, done = #pls, 0, 0

    if tp == 0 then
      SaveSnapshot(0, 0)
    else
      for _, pid in ipairs(pls) do
        local xP = ESX.GetPlayerFromId(pid)
        if xP then
          local oId = xP.getIdentifier()
          if not oId:find("^char%d+:") then oId = "char1:"..oId end
          exports.oxmysql:execute(
            'SELECT COUNT(*) as cnt FROM owned_vehicles WHERE owner = ?',
            { oId },
            function(r)
              tv = tv + (r[1].cnt or 0)
              done = done + 1
              if done == tp then
                SaveSnapshot(tp, tv/tp)
              end
            end
          )
        else
          done = done + 1
        end
      end
    end
  end
end)




ESX.RegisterServerCallback("davki:getTaxData", function(src, cb)
  local xP = ESX.GetPlayerFromId(src)
  if not (xP and xP.job.name == Config.AllowedJob and xP.job.grade >= Config.AllowedGrade) then
    return cb(nil)
  end

  exports.oxmysql:execute([[
    SELECT AVG(player_count) AS avg_players,
           AVG(avg_vehicles) AS avg_vehicles
    FROM tax_statistics
    WHERE timestamp >= UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 7 DAY))
  ]], {}, function(res)
    local ap = math.floor(res[1].avg_players or 0)
    local av = tonumber(res[1].avg_vehicles or 0)
    cb({
      baseTax    = baseTax,
      vehicleTax = vehicleTax,
      interval   = Config.TaxInterval,
      stats      = { avgPlayers=ap, avgVehicles=av }
    })
  end)
end)



RegisterServerEvent("davki:updateTaxes")
AddEventHandler("davki:updateTaxes", function(data)
  local src = source
  local xP  = ESX.GetPlayerFromId(src)
  if not (xP and xP.job.name == Config.AllowedJob and xP.job.grade >= Config.AllowedGrade) then
    return DropPlayer(src, "Neavtoriziran poskus spreminjanja davkov.")
  end

  local nb, nv = tonumber(data.base), tonumber(data.vehicle)
  if nb and nv then
    baseTax, vehicleTax = nb, nv
    ---- shrani v DB
    exports.oxmysql:execute(
      'UPDATE tax_config SET base_tax = ?, vehicle_tax = ? WHERE id = 1',
      { baseTax, vehicleTax }
    )

      
    TriggerClientEvent("davki:closeMenu", src)
    SafeNotify(src, {
      title       = "Davčna Uprava",
      description = "Davki uspešno posodobljeni!",
      type        = "success"
    })
  else
    SafeNotify(src, {
      title       = "Napaka",
      description = "Neveljavna vnosna polja.",
      type        = "error"
    })
  end
end)
