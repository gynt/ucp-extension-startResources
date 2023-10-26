
-- int[3][25]
local addr_StartGoods = core.AOBScan("64 00 00 00 00 00 00 00 32 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3C 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 64 00 00 00 00 00 00 00 32 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3C 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 96 00 00 00 14 00 00 00 96 00 00 00 00 00 00 00 19 00 00 00 30 00 00 00 00 00 00 00 19 00 00 00 C8 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 0A 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
local StartGoods_size = 4 * 3 * 25

local GAME_MODE_INDEX = {
  normal      = 0,
  crusader    = 1,
  deathmatch  = 2,
}

local StartingResource = {
  wood = 0,
  hop = 1,
  stone = 2,
  
  iron = 4,
  pitch = 5,

  wheat = 7,
  bread = 8,
  cheese = 9,
  meat = 10,
  fruit = 11,
  beer = 12,
  gold = 13,
  flour = 14,
  bows = 15,
  crossbows = 16,
  spears = 17,
  pikes = 18,
  maces = 19,
  swords = 20,
  leatherarmor = 21,
  metalarmor = 22,
}

local function translateResourceKey(k) 
  if type(k) == "string" then
    local tk = StartingResource[k]
    if tk == nil then
      error("Unknown key: " .. tostring(k))
    end

    return tk
  end

  if type(k) == "number" then return k end

  error("Invalid key: " .. tostring(k))
end

local IntegerArrayMarshal = {
  new = function(offset, translateKey)

    return setmetatable(
      {},
      {
        __index = function(self, k)
          local addr = offset + (translateKey(k)*4)
          log(2, "[startGoods] Reading: " .. tostring(addr))
          return core.readInteger(string.format("0x%X", addr))
        end,
        __newindex = function(self, k, v)
          local addr = offset + (translateKey(k)*4)
          v = tonumber(v)
          if v == nil then return end
          log(2, "[startGoods] Writing: " .. tostring(string.format("0x%X", addr)) .. " value: " .. tostring(v))
          core.writeInteger(addr, v)
        end
      }
    )
  end
}

local StartGoodsMarshal = {}
for k, v in pairs(GAME_MODE_INDEX) do
  StartGoodsMarshal[k] = IntegerArrayMarshal.new(addr_StartGoods + (4*25*v), translateResourceKey)
end

local vanillaStartGoods = core.readBytes(addr_StartGoods, StartGoods_size)

--[[



--]]

local balance = {
  majorHumanAdvantage = 0,
  minorHumanAdvantage = 1,
  noAdvantage = 2,
  minorComputerAdvantage = 3,
  majorComputerAdvantage = 4,
}

local playerTypes =  {
  human = 0,
  computer = 1,
}

-- int[3][5][2]
local addr_StartGold = core.AOBScan("40 1F 00 00 D0 07 00 00 A0 0F 00 00 D0 07 00 00 D0 07 00 00 D0 07 00 00 D0 07 00 00 A0 0F 00 00 D0 07 00 00 40 1F 00 00 40 1F 00 00 D0 07 00 00 A0 0F 00 00 D0 07 00 00 D0 07 00 00 D0 07 00 00 D0 07 00 00 A0 0F 00 00 D0 07 00 00 40 1F 00 00 40 9C 00 00 B8 0B 00 00 20 4E 00 00 58 1B 00 00 10 27 00 00 10 27 00 00 58 1B 00 00 20 4E 00 00 B8 0B 00 00 40 9C 00 00")
local StartGoldMarshal = {}

for gamemode, gamemodeindex in pairs(GAME_MODE_INDEX) do
  StartGoldMarshal[gamemode] = {}
  local gamemodeOffset = 4 * gamemodeindex * 5 * 2
  for balancelevel, balancelevelindex in pairs(balance) do
    StartGoldMarshal[gamemode][balancelevel] = {}
    local balanceOffset = 4 * balancelevelindex * 2
    local offset = addr_StartGold + gamemodeOffset + balanceOffset
    StartGoldMarshal[gamemode][balancelevel] = IntegerArrayMarshal.new(offset, function(k) 

      k = playerTypes[k]
      if k == nil then
        log(WARNING, "[startGoods] Invalid player type key: " .. tostring(k))
      end

      return k
    end)
  end
  
end

local namespace = {
  enable = function(self, config) 
    if config.startGoods ~= nil then
      for gamemode, goods in pairs(config.startGoods) do
        if StartGoodsMarshal[gamemode] ~= nil then
          for goodname, count in pairs(goods) do
            if StartingResource[goodname] ~= nil then
                if tonumber(count) ~= nil then
                  log(2, "[startGoods] Setting: " .. tostring(gamemode) .. " "  .. tostring(goodname) .. " value: " .. tostring(count))
                  StartGoodsMarshal[gamemode][goodname] = count
                else
                  log(WARNING, string.format("%s is not a valid good count: %s.%s", count, gamemode, goodname))
                end
            else
              log(WARNING, string.format("%s is not a valid goodname: %s.%s", goodname, gamemode, goodname))
            end
            
          end
        else
          log(WARNING, string.format("%s is not a valid gamemode", gamemode))
        end
      end
    end
    if config.startGold ~= nil then
      for gamemode, fairnesses in pairs(config.startGold) do
        if GAME_MODE_INDEX[gamemode] ~= nil then


          for fairness, playertypes in pairs(fairnesses) do

            if balance[fairness] ~= nil then

              for playertype, count in pairs(playertypes) do
                if playerTypes[playertype] ~= nil then
                  if tonumber(count) ~= nil then
                    log(2, "[startGoods] Setting gold: " .. tostring(gamemode) .. " " .. tostring(fairness) .. " " .. tostring(playertype) .. " value: " .. tostring(count))
                    StartGoldMarshal[gamemode][fairness][playertype] = count
                  else
                    log(WARNING, string.format("%s is not a valid gold count", count))
                  end
                else
                  log(WARNING, string.format("%s is not a valid player type", playertype))
                end
              end
            else
              log(WARNING, string.format("%s is not a valid fairness level", fairness))
            end

          end

        else
          log(WARNING, string.format("%s is not a valid gamemode", gamemode))
        end
      end
    end
  end,
  disable = function(self, config) end,

  getStartGood = function(self, gamemode, goodname)
    return StartGoodsMarshal[gamemode][goodname]
  end,

  setStartGood = function(self, gamemode, goodname, goodcount)
    StartGoodsMarshal[gamemode][goodname] = goodcount
  end,
  
  resetStartGoods = function(self) core.writeBytes(addr_StartGoods, vanillaStartGoods) end,
}

return namespace