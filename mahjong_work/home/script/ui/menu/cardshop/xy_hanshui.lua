local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")
local modMainCardshop = import("ui/menu/cardshop/cardshop.lua")

local mainCardShop = modMainCardshop.pCardShop

pShopXyhanshui = pShopXyhanshui or class(mainCardShop)

pShopXyhanshui.init = function(self, shopMgr)
	mainCardShop.init(self, shopMgr)
end

pShopXyhanshui.appStore = function(self)
	mainCardShop.appStore(self)
end

pShopXyhanshui.android = function(self)
	mainCardShop.android(self)
end

pShopXyhanshui.setText = function(self)

end

pShopXyhanshui.close = function(self)
	mainCardShop.close(self)
end

