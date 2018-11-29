local modPayBase = import("logic/shop/pay/base.lua")
local modPayProto = import("data/proto/rpc_pb2/pay_pb.lua")
local modUtil = import("util/util.lua")
local modShopRpc = import("logic/shop/rpc.lua")

local payErrorStr = function(code)
	local sys = os.getSysName()
	local machine = os.getMachine()
	log("info", sys, machine)
	if code == 0 then
		return TEXT("购买发生错误")
	elseif code == 1 then
		return TEXT("不允许该请求")
	elseif code == 2 then
		return TEXT("购买取消")
	elseif code == 3 then
		return TEXT("商品已过期")
	elseif code == 4 then
		return TEXT("该设备应用内购买已被禁止")
	elseif code == 5 then
		return TEXT("当前AppStore区域无效")
	else
		return TEXT("购买发生错误")
	end
end

pPayMgr = pPayMgr or class(modPayBase.pPayBase)

pPayMgr.init = function(self, shopMgr)
	modPayBase.pPayBase.init(self, shopMgr)
	self.payment = puppy.pPayment.getPayment()
	self.loadingWnd = modUtil.loadingMessage("")
	self.loadingWnd:setParent(gWorld:getUIRoot())
	self.loadingWnd:setZ(-10000)
	self.loadingWnd:show(false)

	self.onGetProductInfoReqs = {}
	self.onPayProductFinishReqs = {}

	self.productInfoInitFlag = false
	self:initPay()
end

pPayMgr.initPay = function(self)
	if self.payment then
		self.payment.onErrorCb = function(code, reason)
		end

		self.payment.onGetProductInfoCb = function(sid, code, reason)
			self.loadingWnd:show(false)
			logv("error", "+++++++++++", sid, code, reason)
			local reqInfo = self.onGetProductInfoReqs[sid]
			if code >= 0 then
				modUtil.safeCallBack(reqInfo, true, "")
				self.productInfoInitFlag = true
				self.inProcess = false
			else
				log("error", "get product error!", code, reason)
				modUtil.safeCallBack(reqInfo, false, TEXT("拉取商品信息失败"), {})
			end
			self.onGetProductInfoReqs[sid] = nil
		end

		self.payment.onPayProductFinishCb = function(sid, code, productId, receipt)
			-- 若购买成功，reason表示productId
			if code == 10000 or
				code == 9999 then
				local reqInfo = self.onPayProductFinishReqs[sid]
				modUtil.safeCallBack(reqInfo, true, "", productId, receipt)
				self.onPayProductFinishReqs[sid] = nil
			else
				self.loadingWnd:show(false)
				local reqInfo = self.onPayProductFinishReqs[sid]
				local reason = payErrorStr(code)
				modUtil.safeCallBack(reqInfo, false, reason)
				self.onPayProductFinishReqs[sid] = nil
			end
		end
	end
end

pPayMgr.initProductInfos = function(self, callback)
	modPayBase.pPayBase.initProductInfos(self, function(success, reason)
		if success then
			if not self.productInfoInitFlag then
				local allPids = {}
				for pid, _ in pairs(self.productInfos) do
					local newPid = self:makeAppStorePid(pid)
					table.insert(allPids, newPid)
				end
				local val = table.concat(allPids, ";")
				local sid = self.payment:reqProductInfos(val)
				if sid > 0 then
					self.onGetProductInfoReqs[sid] = callback
				else
					callback(false, TEXT("请求商品信息失败"))
				end
			else
				callback(true, "")
			end
		else
			callback(success, reason)
		end
	end)
end

pPayMgr.purchaseProduct = function(self, pid, callback)
	if not self.payment then
		callback(false, TEXT("当前系统不支持应用内购买"))
		return
	end
	if not self.payment:canMakePurchase() then
		callback(false, TEXT("当前设备禁止了应用内购买"))
		return
	end
	local pinfo = self:getProductInfo(pid)
	if not pinfo then
		callback(false, TEXT("等待拉取内购信息"))
		return
	end
	local newPid = self:makeAppStorePid(pid)
	local sid = self.payment:payProduct(newPid, 0, 0, "")
	if sid > 0 then
		self.loadingWnd:show(true)
		self.loadingWnd:setMsg(TEXT("正在请求购买"))
		self.onPayProductFinishReqs[sid] = function(success, reason, pid, receipt)
			if success then
				self.loadingWnd:setMsg(TEXT("正在验证购买请求"))
				self:notifyPayment(pid, receipt, function(success, reason)
					self.loadingWnd:show(false)
					callback(success, reason)
				end)
			else
				callback(false, reason)
			end
		end
	else
		callback(false, TEXT("发送购买请求失败"))
	end
end

pPayMgr.notifyPayment = function(self, pid, receipt, callback)
	local realPid = self:getRealPid(pid)
	modShopRpc.verifyAppStoreReceipt(self:getRealPid(pid), receipt, function(success, reason)
		if success then
			self.shopMgr:paySuccessHint(realPid)
		end
		callback(success, reason)
	end)
end

pPayMgr.getPayType = function(self)
	return T_PAY_APPSTORE
end

pPayMgr.makeAppStorePid = function(self, pid)
	local opChannel = modUtil.getOpChannel()
	return sf("%s.%s", opChannel, pid)
end
