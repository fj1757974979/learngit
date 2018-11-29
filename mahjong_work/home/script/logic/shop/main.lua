local modUtil = import("util/util.lua")
local modConfirm = import("ui/common/confirm.lua")
local modSessionMgr = import("net/mgr.lua")
local modShopRpc = import("logic/shop/rpc.lua")

pShopMgr = pShopMgr or class(pSingleton)

pShopMgr.init = function(self)
	self.initFlag = false
	self.shopPanel = nil
end

pShopMgr.initShopPanel = function(self)
	local channelId = modUtil.getOpChannel()
	local modCardPanel = import("ui/menu/cardshop/" .. channelId .. ".lua")
	local channelToName = {
		["openew"] = modCardPanel.pShopOpenew,
		["ds_queyue"] = modCardPanel.pShopDsqueyue,
		["tj_lexian"] = modCardPanel.pShopTjlexian,
		["ly_youwen"] = modCardPanel.pShopLyyouwen,
		["jz_laiba"] = modCardPanel.pShopJzlaiba,
		["rc_xianle"] = modCardPanel.pShopRcxianle,
		["test"] = modCardPanel.pShopTest,
		["xy_hanshui"] = modCardPanel.pShopXyhanshui,
		["yy_doudou"] = modCardPanel.pShopYydoudou,
		["nc_tianjiuwang"] = modCardPanel.pShopNctianjiuwang,
		["za_queyue"] = modCardPanel.pShopZaqueyue,
		["qs_pinghe"] = modCardPanel.pShopQspinghe,
	}
	self.shopPanel = channelToName[channelId]:new(self)
end

pShopMgr.getShopPanel = function(self, getIsNil)
	if getIsNil then
		return self.shopPanel
	else
		if not self.shopPanel then
			self:initShopPanel()
		end
		return self.shopPanel
	end
end

pShopMgr.close = function(self)
	self.initFlag = false
	self.shopPanel:close()
	pShopMgr:cleanInstance()
end

pShopMgr.initPayMgr = function(self, callback)
	local mod = nil
	if app:getPlatform() == "android" then
		local channelId = modUtil.getChannel()
		if channelId == "weixin" then
			mod = import("logic/shop/pay/wx_pay.lua")
		else
			mod = import("logic/shop/pay/android.lua")
		end
		if mod then
			self.payMgr = mod.pPayMgr:new(self)
		end
		self.initFlag = true
		callback(true, "")
	elseif app:getPlatform() == "ios" then
		if modUtil.isSDKPurchase() then
			puppy.sys.enableSDKPurchase(true)
		else
			puppy.sys.enableSDKPurchase(false)
		end
		--[[
		modShopRpc.getPaymentMethod(function(success, reason, payMethod)
			if success then
				if payMethod == T_PAY_METHOD_WEIXIN then
					puppy.sys.enableSDKPurchase(true)
				else
					puppy.sys.enableSDKPurchase(false)
				end
		]]--
				if puppy.sys.isSDKPay() then
					local channelId = modUtil.getChannel()
					if channelId == "weixin" then
						mod = import("logic/shop/pay/wx_pay.lua")
					else
						mod = import("logic/shop/pay/sdk_ios.lua")
					end
				else
					mod = import("logic/shop/pay/ios.lua")
				end
				if mod then
					self.payMgr = mod.pPayMgr:new(self)
				end
				self.initFlag = true
			--end
			callback(true, "")
		--end)
	elseif app:getPlatform() == "macos" then
		mod = import("logic/shop/pay/macos.lua")
		if mod then
			self.payMgr = mod.pPayMgr:new(self)
		end
		self.initFlag = true
		callback(true, "")
	end
end

pShopMgr.getAllProductInfos = function(self, callback)
	local doGet = function()
		if not self.payMgr then
			callback(false, TEXT("不支持内购"))
		else
			self.payMgr:initProductInfos(function(success, reason)
				if success then
					callback(true, "", self.payMgr:getAllProductInfos())
				else
					callback(false, reason)
				end
			end)
		end
	end
	if not self.initFlag then
		self:initPayMgr(function(success, reason)
			if success then
				doGet()
			else
				callback(success, reason)
			end
		end)
	else
		doGet()
	end
end

pShopMgr.purchaseProduct = function(self, pid, callback)
	if not pid then
		callback(false, TEXT("内购信息错误"))
		return
	end
	if self.payMgr then
		if not self.payMgr:getProductInfo(pid) then
			callback(false, TEXT("等待拉取内购信息"))
			return
		end
		self.payMgr:purchaseProduct(pid, function(success, reason)
			callback(success, reason)
		end)
	else
		callback(false, TEXT("不支持内购!"))
	end
end

pShopMgr.paySuccessHint = function(self, pid)
	modConfirm.pForceConfirmDialog:instance():open(sf(TEXT("购买成功，获得%s"), self.payMgr:getProductName(pid)))
end

pShopMgr.notifySdkOrder = function(self, success, orderId, pid)
	modSessionMgr.instance():setDeamonMode(false)
	if success then
		self.payMgr:notifyPayment(pid, orderId, function(success, reason)
			if success then
				self:paySuccessHint(pid)
			else
				infoMessage(reason)
			end
		end)
	else
		infoMessage(TEXT("充值失败"))
		--[[
		self.payMgr:notifyPayFail(pid, orderId, function(reason)
			infoMessage(reason)
		end)
		]]--
	end
end

pShopMgr.getPayMgr = function(self)
	return self.payMgr
end

