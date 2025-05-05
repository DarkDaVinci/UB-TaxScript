ESX = exports["es_extended"]:getSharedObject()

-- runtime davki, se preberejo iz DB
local baseTax, vehicleTax = Config.BaseTax, Config.VehicleTax

-- varna notifikacija
local function SafeNotify(target, data)
  if lib then
    lib.notify(target, data)
  else
    TriggerClientEvent('ox_lib:notify', target, data)
  end
end

-- 0) ob zagonu naloži davke iz tax_config
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

-- 1) Periodični pobirki davka
CreateThread(function()
  while true do
    Wait(Config.TaxInterval * 60000)

    for _, playerId in ipairs(ESX.GetPlayers()) do
      local xP = ESX.GetPlayerFromId(playerId)
      if not xP then goto cont end

      local oId = xP.getIdentifier()
      if not oId:find("^char%d+:") then oId = "char1:"..oId end

      -- preštej vozila
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

            -- posodobi Cityhall balance
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

-- 2) Snapshot statistike vsakih 30 min
local function SaveSnapshot(pc, avgV)
  exports.oxmysql:execute(
    'INSERT INTO tax_statistics (timestamp, player_count, avg_vehicles) VALUES (?, ?, ?)',
    { os.time(), pc, avgV }
  )
end

CreateThread(function()
  while true do
    Wait(30 * 60 * 1000)  -- 30 minut
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

-- 3) Callback za UI: pridobi davke, interval in statistiko
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

-- 4) Event: shranjevanje novih davkov + persistenca
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
    -- shrani v DB
    exports.oxmysql:execute(
      'UPDATE tax_config SET base_tax = ?, vehicle_tax = ? WHERE id = 1',
      { baseTax, vehicleTax }
    )
    -- sporoči clientu in zapri UI
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
