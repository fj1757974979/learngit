local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")
local modMainCardshop = import("ui/menu/cardshop/cardshop.lua")

local mainCardShop = modMainCardshop.pCardShop

pShopQspinghe = pShopQspinghe or class(mainCardShop)

pShopQspinghe.init = function(self, shopMgr)
	mainCardShop.init(self, shopMgr)
end

pShopQspinghe.appStore = function(self)
	mainCardShop.appStore(self)
end

pShopQspinghe.android = function(self)
	-- mainCardShop.android(self)
	local platform = app:getPlatform()
	if not (platform == "android")  then return end
	self.wnd_card_bg_1:show(false)
	self.wnd_card_bg_2:show(false)
	self.wnd_card_bg_3:show(false)

	self.wnd_weixin_android:getTextControl():setColor(0xFF431416)
	self.wnd_weixin:setPosition(gGameWidth * 0.33, gGameHeight * 0.22)
	self.wnd_weixin:setText("")	
	self.wnd_weixin_android:setText("申请代理或充值请咨询客服微信：" .. "\n" .. "官方公众号：  雀神本地娱乐" .. "\n" .. "客服微信号： Phmj0596")
	self.wnd_weixin_android:setTextColor(0xFF000000)
end

pShopQspinghe.setText = function(self)
	self.wnd_weixin:setTextColor(0xFF000000)
	self.wnd_weixin:setText("申请代理或充值请咨询客服微信：" .. "\n" .. "官方公众号：  雀神本地娱乐" .. "\n" .. "客服微信号：  Phmj0596")
end

pShopQspinghe.close = function(self)
	mainCardShop.close(self)
end

