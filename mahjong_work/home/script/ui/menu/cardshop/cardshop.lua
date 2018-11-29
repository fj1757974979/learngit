local modUIUtil = import("ui/common/util.lua")
local modUtil = import("util/util.lua")
local modUserData = import("logic/userdata.lua")
local modMainBattle = import("logic/battle/main.lua")
local modShopMain = import("logic/shop/main.lua")
local modClipBoardMgr = import("logic/clipboard/mgr.lua")

pCardShop = pCardShop or class(pWindow)

pCardShop.init = function(self, shopMgr)
	self:show(false)
	self:loadTemplate()
	self:setParent(gWorld:getUIRoot())
	self.shopMgr = shopMgr 
	self:initUI()
	self:setText()
	self:android()
	self:regEvent()
	self:appStore()
	modUIUtil.makeModelWindow(self, false, false)
end
--不同渠道
pCardShop.loadTemplate = function(self)
	local channel = modUtil.getOpChannel()
	self:load("data/ui/cardshop_" .. channel .. ".lua")
end

pCardShop.setText = function(self)
	return
end

pCardShop.open = function(self)
	self:show(true)
end

pCardShop.appStore = function(self)
	if modUtil.isAppstoreExamineVersion() then
		self.wnd_weixin:show(false)
		self.wnd_card_bg_1:show(true)
		self.wnd_card_bg_2:show(true)
		self.wnd_card_bg_3:show(true)
	end
end

pCardShop.android = function(self)
	return
end

pCardShop.doBuy = function(self, pid)
	if pid then
		self.shopMgr:purchaseProduct(pid, function(success, reason)
			if not success then
				infoMessage(reason)
			end
		end)
	end
end


pCardShop.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click",function() 
		self:close() 
	end)

	self.btn_buy_1:addListener("ec_mouse_click", function()
		self:doBuy(self.btn_buy_1.__product_id)
	end)
	self.btn_buy_2:addListener("ec_mouse_click", function()
		self:doBuy(self.btn_buy_2.__product_id)
	end)
	self.btn_buy_3:addListener("ec_mouse_click", function()
		self:doBuy(self.btn_buy_3.__product_id)
	end)

	self:copyBtnEvent()
end

pCardShop.copyBtnEvent = function(self, btn, weixinCode)
	if not btn or not weixinCode then return end
	btn:addListener("ec_mouse_click", function()
		modClipBoardMgr.pClipBoardMgr:instance():setClipBoardText(weixinCode, TEXT("复制成功！，赶快加微信吧"))
	end)
end

pCardShop.showSuccess = function(self, callback)
	local modAuthSuccess = import("ui/menu/authsuccess.lua")
	if modAuthSuccess.pAuthSuccess:getInstance() then
		modAuthSuccess.pAuthSuccess:instance():show(true)
	else
		modAuthSuccess.pAuthSuccess:instance():open()
	end
end

pCardShop.initUI = function(self)
	self.shopMgr:getAllProductInfos(function(success, reason, ret)
		if success then
			local pinfos = table.values(ret)
			table.sort(pinfos, function(i1, i2)
				return i1[K_PAY_PRICE] < i2[K_PAY_PRICE]
			end)
			for idx, info in ipairs(pinfos) do
				local btn = self[sf("btn_buy_%d", idx)]
				if btn then
					btn.__product_id = info[K_PAY_PID]
				end
				local txt = self[sf("wnd_price_%d", idx)]
				local key = K_PAY_PRICE
				logv("info", info)
				if isAppstoreExamineVersion() then
					key = K_PAY_STORE_PRICE 
				end 
				if txt then
					txt:setText(sf(TEXT("#cffffdc%s\n%d元#n"), info[K_PAY_NAME], info[key]/100))
				end
			end
		else
			infoMessage(reason)
		end
	end)
end

pCardShop.close = function(self)
	self:show(false)
end
