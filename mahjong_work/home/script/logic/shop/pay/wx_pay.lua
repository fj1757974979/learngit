local modPayBase = import("logic/shop/pay/base.lua")
local modPayProto = import("data/proto/rpc_pb2/pay_pb.lua")
local modUtil = import("util/util.lua")
local modSessionMgr = import("net/mgr.lua")
local modShopRpc = import("logic/shop/rpc.lua")

local disablePurchaseChannel = {
	za_queyue = true,
	qs_pinghe = true,
}

pPayMgr = pPayMgr or class(modPayBase.pPayBase)

pPayMgr.init = function(self, shopMgr)
	modPayBase.pPayBase.init(self, shopMgr)
	self.payment = puppy.pPayment.getPayment()
end

pPayMgr.purchaseProduct = function(self, pid, callback)
	local channelId = modUtil.getOpChannel()
	if disablePurchaseChannel[channelId] then
		callback(false, TEXT("充值请联系群主或管理员"))
		return
	end
	if not self.payment then
		callback(false, TEXT("不支持内购"))
		return
	end
	if not self.payment:canMakePurchase() then
		callback(false, TEXT("内购尚未开放"))
		return
	end
	local pinfo = self:getProductInfo(pid)
	if not pinfo then
		callback(false, TEXT("商品信息错误"))
		return
	end
	modShopRpc.wechatCreateOrder(pid, function(success, reason, ret)
		if success then
			local pname = self:getProductName(pid)
			local recharge = self:getProductPrice(pid)
			local num = self:getProductNum(pid)
			modSessionMgr.instance():setDeamonMode(true)
			local param = sf([[{"productName":"%s", "appid":"%s", "partnerid":"%s", "prepayid":"%s", "package":"%s", "noncestr":"%s", "timestamp":"%d", "sign":"%s", "orderid":"%s"}]], pname, ret.appid, ret.partnerid, ret.prepayid, ret.package, ret.noncestr, ret.timestamp, ret.sign, ret.orderid)
			self.payment:payProduct(pid, recharge, num, param)
			callback(true, "")
		else
			callback(false, reason)
		end
	end)
end

pPayMgr.notifyPayment = function(self, pid, orderId, callback)
	modShopRpc.wechatQueryOrder(orderId, function(success, reason, pid)
		callback(success, reason, pid)
	end)
end

pPayMgr.notifyPayFail = function(self, pid, orderId, callback)
	modShopRpc.wechatQueryOrder(orderId, function(success, reason, pid)
		callback(reason)
	end)
end

pPayMgr.getPayType = function(self)
	return T_PAY_WX_IOS
end
