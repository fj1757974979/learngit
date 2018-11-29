local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")
local modMainCardshop = import("ui/menu/cardshop/cardshop.lua")

local mainCardShop = modMainCardshop.pCardShop

pShopTjlexian = pShopTjlexian or class(mainCardShop)

pShopTjlexian.init = function(self, shopMgr)
	mainCardShop.init(self, shopMgr)
end

pShopTjlexian.appStore = function(self)
	mainCardShop.appStore(self)
end

pShopTjlexian.android = function(self)
	mainCardShop.android(self)
end

pShopTjlexian.setText = function(self)

end

pShopTjlexian.close = function(self)
	mainCardShop.close(self)
end

