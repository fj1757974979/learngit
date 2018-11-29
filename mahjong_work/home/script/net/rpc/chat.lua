local modSessionMgr = import("net/mgr.lua")
local modChatProto = import("data/proto/rpc_pb2/chat_pb.lua")
local modTopicMgr = import("logic/chat/topic.lua")

local register = function()
	modSessionMgr.instance():regRpcMethod(modChatProto.PUBLISH_MESSAGE_TO_TOPIC, function(payload)
		local notify = modChatProto.PublishMessageToTopicRequest()
		notify:ParseFromString(payload)
		modTopicMgr.pTopicMgr:instance():publishMessageToTopic(notify.topic_name, notify.message)
	end)
end

__init__ = function()
	register()
end
