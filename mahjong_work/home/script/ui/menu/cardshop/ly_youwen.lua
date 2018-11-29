local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")
local modMainCardshop = import("ui/menu/cardshop/cardshop.lua")

local mainCardShop = modMainCardshop.pCardShop

pShopLyyouwen = pShopLyyouwen or class(mainCardShop)

pShopLyyouwen.init = function(self, shopMgr)
	mainCardShop.init(self, shopMgr)
end

pShopLyyouwen.appStore = function(self)
	mainCardShop.appStore(self)
end

pShopLyyouwen.android = function(self)
	mainCardShop.android(self)
end

pShopLyyouwen.setText = function(self)

end

pShopLyyouwen.close = function(self)
	mainCardShop.close(self)
end

