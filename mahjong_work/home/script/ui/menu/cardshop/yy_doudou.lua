local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")
local modMainCardshop = import("ui/menu/cardshop/cardshop.lua")

local mainCardShop = modMainCardshop.pCardShop

pShopYydoudou = pShopYydoudou or class(mainCardShop)

pShopYydoudou.init = function(self, shopMgr)
	mainCardShop.init(self, shopMgr)
end

pShopYydoudou.appStore = function(self)
	mainCardShop.appStore(self)
end

pShopYydoudou.android = function(self)
	mainCardShop.android(self)
end

pShopYydoudou.setText = function(self)

end

pShopYydoudou.close = function(self)
	mainCardShop.close(self)
end

