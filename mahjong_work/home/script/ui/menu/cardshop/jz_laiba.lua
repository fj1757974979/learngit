local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")
local modMainCardshop = import("ui/menu/cardshop/cardshop.lua")

local mainCardShop = modMainCardshop.pCardShop

pShopJzlaiba = pShopJzlaiba or class(mainCardShop)

pShopJzlaiba.init = function(self, shopMgr)
	mainCardShop.init(self, shopMgr)
end

pShopJzlaiba.appStore = function(self)
	mainCardShop.appStore(self)
end

pShopJzlaiba.android = function(self)
	mainCardShop.android(self)
end

pShopJzlaiba.setText = function(self)
	self.wnd_weixin:setText("申请代理请加微信：laibajizhou" )
end

pShopJzlaiba.close = function(self)
	mainCardShop.close(self)
end

