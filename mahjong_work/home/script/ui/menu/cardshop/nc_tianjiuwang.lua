local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")
local modMainCardshop = import("ui/menu/cardshop/cardshop.lua")

local mainCardShop = modMainCardshop.pCardShop

pShopNctianjiuwang = pShopNctianjiuwang or class(mainCardShop)

pShopNctianjiuwang.init = function(self, shopMgr)
	mainCardShop.init(self, shopMgr)
end

pShopNctianjiuwang.appStore = function(self)
	mainCardShop.appStore(self)
end

pShopNctianjiuwang.android = function(self)
	mainCardShop.android(self)
end

pShopNctianjiuwang.setText = function(self)
	self.wnd_weixin:setText("申请代理或充值请咨询客服微信：" .. "\n" .. "官方公众号：  tjw8888tjw" .. "\n" .. "客服微信号：  tjw8888tjw")
end

pShopNctianjiuwang.copyBtnEvent = function(self)
	mainCardShop.copyBtnEvent(self, self.btn_copy, "tjw8888tjw")
end

pShopNctianjiuwang.close = function(self)
	mainCardShop.close(self)
end

