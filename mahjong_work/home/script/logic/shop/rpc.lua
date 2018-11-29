local modUtil = import("util/util.lua")
local modSessionMgr = import("net/mgr.lua")
local modPayProto = import("data/proto/rpc_pb2/pay_pb.lua")

getPaymentMethod = function(callback)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	local message = modPayProto.GetPaymentMethodRequest()
	local platform = app:getPlatform()
	if platform == "macos" then
		callback(false, TEXT("该平台不需要切支付！"))
		return
	elseif platform == "ios" then
		message.os_type = modPayProto.GetPaymentMethodRequest.IOS
	else
		message.os_type = modPayProto.GetPaymentMethodRequest.ANDROID
	end
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modPayProto.GET_PAYMENT_METHOD, message, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modPayProto.GetPaymentMethodReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modPayProto.GetPaymentMethodReply.SUCCESS then
				callback(true, "", reply.payment_method)
			else
				callback(false, TEXT("获取支付方式失败"))
			end
		else
			callback(false, reason)
		end
	end)
end

fetchProductInfos = function(callback)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modPayProto.GET_PRODUCT_INFO, nil, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modPayProto.ProductInfos()
			reply:ParseFromString(ret)
			local infos = {}
			for _, info in ipairs(reply.infos) do
				infos[info.product_id] = {
					[K_PAY_PID] = info.product_id,
					[K_PAY_PRICE] = info.price,
					[K_PAY_STORE_PRICE] = info.store_price,
					[K_PAY_NUM] = info.num,
					[K_PAY_NAME] = info.name,
				}
			end
			callback(true, "", infos)
		else
			callback(false, reason)
		end
	end)
end

wechatCreateOrder = function(pid, callback)
	local wnd = modUtil.loadingMessage(TEXT("正在生成订单..."))
	local message = modPayProto.WeixinUnifiedOrderRequest()
	message.product_id = pid
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modPayProto.WEIXIN_UNIFIED_ORDER, message, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modPayProto.WeixinUnifiedOrderReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modPayProto.WeixinUnifiedOrderReply.SUCCESS then
				callback(true, "", {
					appid = reply.weixin_pay_req.appid,
					partnerid = reply.weixin_pay_req.partnerid,
					prepayid = reply.weixin_pay_req.prepayid,
					package = reply.weixin_pay_req.package,
					noncestr = reply.weixin_pay_req.noncestr,
					timestamp = reply.weixin_pay_req.timestamp,
					sign = reply.weixin_pay_req.sign,
					orderid = reply.out_trade_no,
				})
			else
				local errorMsg = ""
				if code == modPayProto.WeixinUnifiedOrderReply.FAILURE then
					errorMsg = TEXT("下单失败")
				elseif code == modPayProto.WeixinUnifiedOrderReply.NOAUTH then
					errorMsg = TEXT("商户无此接口权限，请联系客服")
				elseif code == modPayProto.WeixinUnifiedOrderReply.NOTENOUGH then
					errorMsg = TEXT("账户余额不足")
				elseif code == modPayProto.WeixinUnifiedOrderReply.ORDERPAID then
					errorMsg = TEXT("商户订单已支付")
				elseif code == modPayProto.WeixinUnifiedOrderReply.ORDERCLOSED then
					errorMsg = TEXT("订单已关闭")
				else
					errorMsg = TEXT("生成订单失败")
				end
				callback(false, errorMsg)
			end
		else
			callback(false, reason)
		end
	end)
end

wechatQueryOrder = function(orderId, callback)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	local message = modPayProto.WeixinOrderQueryRequest()
	message.out_trade_no = orderId
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modPayProto.WEIXIN_ORDER_QUERY, message, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modPayProto.WeixinOrderQueryReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modPayProto.WeixinOrderQueryReply.SUCCESS then
				callback(true, "", reply.product_id)
			else
				local errorMsg = ""
				if code == modPayProto.WeixinOrderQueryReply.FAILURE then
					errorMsg = TEXT("支付失败")
				elseif code == modPayProto.WeixinOrderQueryReply.REFUND then
					errorMsg = TEXT("转入退款")
				elseif code == modPayProto.WeixinOrderQueryReply.NOTPAY	then
					errorMsg = TEXT("未支付")
				elseif code == modPayProto.WeixinOrderQueryReply.CLOSED then
					errorMsg = TEXT("订单已关闭")
				elseif code == modPayProto.WeixinOrderQueryReply.REVOKED then
					errorMsg = TEXT("支付已撤销")
				elseif code == modPayProto.WeixinOrderQueryReply.USERPAYING then
					errorMsg = TEXT("支付中")
				elseif code == modPayProto.WeixinOrderQueryReply.PAYERROR then
					errorMsg = TEXT("支付返回失败")
				else
					errorMsg = TEXT("支付失败")
				end
				callback(false, errorMsg)
			end
		else
			callback(false, reason)
		end
	end)
end

verifyAppStoreReceipt = function(pid, receipt, callback)
	local message = modPayProto.AppstoreVerifyReceiptRequest()
	message.product_id = pid
	message.receipt = receipt
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modPayProto.APPSTORE_VERIFY_RECEIPT, message, OPT_NONE, function(success, reason, ret)
		if success then
			local reply = modPayProto.AppstoreVerifyReceiptReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modPayProto.AppstoreVerifyReceiptReply.SUCCESS then
				callback(true, "")
			else
				callback(false, TEXT("订单验证失败"))
			end
		else
			callback(false, reason)
		end
	end)
end

