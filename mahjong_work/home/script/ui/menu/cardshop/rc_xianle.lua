local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")
local modMainCardshop = import("ui/menu/cardshop/cardshop.lua")

local mainCardShop = modMainCardshop.pCardShop

pShopRcxianle = pShopRcxianle or class(mainCardShop)

pShopRcxianle.init = function(self, shopMgr)
	mainCardShop.init(self, shopMgr)
end

pShopRcxianle.appStore = function(self)
	mainCardShop.appStore(self)
end

pShopRcxianle.android = function(self)
	mainCardShop.android(self)
end

pShopRcxianle.setText = function(self)

end

pShopRcxianle.close = function(self)
	mainCardShop.close(self)
end

