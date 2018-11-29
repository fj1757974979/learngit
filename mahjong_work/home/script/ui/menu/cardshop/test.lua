local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")
local modMainCardshop = import("ui/menu/cardshop/cardshop.lua")

local mainCardShop = modMainCardshop.pCardShop

pShopTest = pShopTest or class(mainCardShop)

pShopTest.init = function(self, shopMgr)
	mainCardShop.init(self, shopMgr)
end

pShopTest.appStore = function(self)
	mainCardShop.appStore(self)
end

pShopTest.android = function(self)
	mainCardShop.android(self)
end

pShopTest.setText = function(self)

end

pShopTest.close = function(self)
	mainCardShop.close(self)
end

