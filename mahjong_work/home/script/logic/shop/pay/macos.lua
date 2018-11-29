local modPayBase = import("logic/shop/pay/base.lua")
local modPayProto = import("data/proto/rpc_pb2/pay_pb.lua")
local modUtil = import("util/util.lua")

pPayMgr = pPayMgr or class(modPayBase.pPayBase)

pPayMgr.getPayType = function(self)
	return T_PAY_TEST
end
