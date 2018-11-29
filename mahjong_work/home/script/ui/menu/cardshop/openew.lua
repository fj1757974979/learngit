local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")
local modMainCardshop = import("ui/menu/cardshop/cardshop.lua")

local mainCardShop = modMainCardshop.pCardShop

pShopOpenew = pShopOpenew or class(mainCardShop)

pShopOpenew.init = function(self, shopMgr)
	mainCardShop.init(self, shopMgr)
end

pShopOpenew.appStore = function(self)
	mainCardShop.appStore(self)
end

pShopOpenew.android = function(self)
	mainCardShop.android(self)
end

pShopOpenew.setText = function(self)
	self.wnd_weixin:setText("客服微信：kxmj2048" .. "\n" .. "代理咨询：kxmj2048")
end

pShopOpenew.close = function(self)
	mainCardShop.close(self)
end
