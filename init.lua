
local goods = require("goods")
local troops = require("troops")

local namespace = {
  enable = function(self, config) 
    if config.startGoods ~= nil then
      goods.setStartGoods(config.startGoods)
    end
    if config.startGold ~= nil then
      goods.setStartGold(config.startGold)
    end
    if config.startTroops ~= nil then
      troops.setStartTroopsFromConfig(config.startTroops)
    end
  end,
  disable = function(self, config) end,

  
}

return namespace