local modPayBase = import("logic/shop/pay/base.lua")
local modPayProto = import("data/proto/rpc_pb2/pay_pb.lua")
local modUtil = import("util/util.lua")
local modSessionMgr = import("net/mgr.lua")

pPayMgr = pPayMgr or class(modPayBase.pPayBase)

pPayMgr.init = function(self, shopMgr)
	modPayBase.pPayBase.init(self, shopMgr)
	self.payment = puppy.pPayment.getPayment()
end

pPayMgr.purchaseProduct = function(self, pid, callback)
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

	local pname = self:getProductName(pid)
	local recharge = self:getProductPrice(pid)
	local num = self:getProductNum(pid)
	modSessionMgr.instance():setDeamonMode(true)
	local param = sf([[{"productName":"%s"}]], pname)
	self.payment:payProduct(pid, recharge, num, param)
	-- 不走回调，由sdk回调触发
end

pPayMgr.getPayType = function(self)
	return T_PAY_SDK_IOS
end

