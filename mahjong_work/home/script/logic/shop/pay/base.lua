local modUtil = import("util/util.lua")
local modPayProto = import("data/proto/rpc_pb2/pay_pb.lua")
local modShopRpc = import("logic/shop/rpc.lua")
local modSessionMgr = import("net/mgr.lua")

pPayBase = pPayBase or class()

pPayBase.init = function(self, shopMgr)
	self.shopMgr = shopMgr
	self.productInfos = {}
end

pPayBase.getProductInfo = function(self, pid)
	return self.productInfos[pid]
end

pPayBase.getAllProductInfos = function(self)
	return self.productInfos
end

pPayBase.initProductInfos = function(self, callback)
	if table.size(self.productInfos) > 0 then
		callback(true, "")
		return
	end
	modShopRpc.fetchProductInfos(function(success, reason, ret)
		if success then
			self.productInfos = ret
		end
		callback(success, reason)
	end)
end

pPayBase.purchaseProduct = function(self, pid, callback)
	self:notifyPayment(pid, nil, callback)
end

pPayBase.notifyPayment = function(self, pid, orderId, callback)
	self:certifyPay(pid, nil, callback)
end

pPayBase.notifyPayFail = function(self, pid, orderId, callback)
	callback(TEXT("充值失败"))
end

pPayBase.certifyPay = function(self, pid, requestMsg, callback)
	callback(false, TEXT("充值接口未实现"))
end

pPayBase.getPayType = function(self)
	return T_PAY_NONE
end

pPayBase.getCurrency = function(self)
	return "CNY"
end

pPayBase.getRealPid = function(self, pid)
	local opChannel = modUtil.getOpChannel()
	local pos = string.find(pid, opChannel)
	if pos == nil then
		return pid
	else
		return string.sub(pid, pos + string.len(opChannel) + 1, -1)
	end
end

pPayBase.getProductPrice = function(self, pid)
	local info = self:getProductInfo(pid) 
	if info then
		return info[K_PAY_PRICE]
	else
		return -1
	end
end

pPayBase.getProductNum = function(self, pid)
	local info = self:getProductInfo(pid) 
	if info then
		return info[K_PAY_NUM]
	else
		return -1
	end
end

pPayBase.getProductName = function(self, pid)
	local info = self:getProductInfo(pid)
	if info then
		return info[K_PAY_NAME]
	else
		return ""
	end
end
