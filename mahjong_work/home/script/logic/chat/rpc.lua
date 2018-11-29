local modSessionMgr = import("net/mgr.lua")
local modChatProto = import("data/proto/rpc_pb2/chat_pb.lua")
local modUtil = import("util/util.lua")

subscribeTopic = function(topicType, param, callback)
	local request = modChatProto.SubscribeToTopicRequest()
	request.topic_type = topicType
	request.get_state_request = param
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modChatProto.SUBSCRIBE_TO_TOPIC, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modChatProto.SubscribeToTopicReply()
			reply:ParseFromString(ret)
			if reply.error_code == modChatProto.SubscribeToTopicReply.SUCCESS then
				callback(true, "", reply.topic_name, reply.get_state_reply)
			else
				callback(false, TEXT("订阅失败"))
			end
		else
			callback(false, reason)
		end
	end)
end

unsubscribeTopic = function(topicName, callback)
	local request = modChatProto.UnsubscribeFromTopicRequest()
	request.topic_name = topicName
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modChatProto.UNSUBSCRIBE_FROM_TOPIC, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modChatProto.UnsubscribeFromTopicReply()
			reply:ParseFromString(ret)
			if reply.error_code == modChatProto.UnsubscribeFromTopicReply.SUCCESS then
				callback(true, "")
			else
				callback(false, TEXT("取消订阅失败"))
			end
		else
			callback(false, reason)
		end
	end)
end
