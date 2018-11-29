local modChatProto = import("data/proto/rpc_pb2/chat_pb.lua")
local modGroupProto = import("data/proto/rpc_pb2/group_pb.lua")
local modChatRpc = import("logic/chat/rpc.lua")

pTopicObserver = pTopicObserver or class()

pTopicObserver.onTopicUpdate = function(self, payload)
end

pTopicMgr = pTopicMgr or class(pSingleton)

pTopicMgr.init = function(self)
	self.groupIdToTopicName = {}
	self.topicNameToObservers = {}
end

pTopicMgr.subscribeGroupTopic = function(self, group, callback)
	local request = modGroupProto.GetGroupStateRequest()
	local groupId = group:getGrpId()
	request.group_id = groupId
	modChatRpc.subscribeTopic(T_TOPIC_GROUP, request:SerializeToString(), function(success, reason, topicName, ret)
		if success then
			local reply = modGroupProto.GetGroupStateReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGroupProto.GetGroupStateReply.SUCCESS then
				self.groupIdToTopicName[groupId] = topicName
				if not self.topicNameToObservers[topicName] then
					self.topicNameToObservers[topicName] = {}
				end
				self.topicNameToObservers[topicName][group] = true
				callback(true, "", reply.group_state)
			else
				local reason = ""
				if reply.error_code == modGroupProto.GetGroupStateReply.NO_GROUP then
					reason = TEXT("群组不存在")
				elseif reply.error_code == modGroupProto.GetGroupStateReply.NO_AUTH	then
					reason = TEXT("权限不足")
				else
					reason = TEXT("请求失败")
				end
				callback(false, reason)
			end
		else
			callback(false, reason)
		end
	end)
end

pTopicMgr.unsubscribeGroupTopic = function(self, group, callback)
	local groupId = group:getGrpId()
	local topicName = self.groupIdToTopicName[groupId]
	if not topicName then
		callback(false, TEXT("无法取消订阅"))
		return
	end
	modChatRpc.unsubscribeTopic(topicName, function(success, reason)
		if success then
			self.groupIdToTopicName[groupId] = nil
			if self.topicNameToObservers[topicName] then
				self.topicNameToObservers[topicName][group] = nil
			end
			callback(true, "")
		else
			callback(false, reason)
		end
	end)
end

pTopicMgr.publishMessageToTopic = function(self, topicName, payload)
	local observers = self.topicNameToObservers[topicName]
	if observers then
		for observer, _ in pairs(observers) do
			observer:onTopicUpdate(payload)
		end
	end
end
