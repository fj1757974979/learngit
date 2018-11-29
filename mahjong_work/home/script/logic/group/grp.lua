local modPropMgr = import("common/propmgr.lua")
local modMember = import("logic/group/member.lua")
local modUserData = import("logic/userdata.lua")
local modGroupRpc = import("logic/group/rpc.lua")
local modTopicMgr = import("logic/chat/topic.lua")
local modDesk = import("logic/group/desk.lua")
local modGroupImplProto = import("data/proto/rpc_pb2/group_impl_pb.lua")

pGroupObserver = pGroupObserver or class()

pGroupObserver.onAddDesk = function(self, desk)
end

pGroupObserver.onDelDesk = function(self, roomId)
end

----------------------------------------------------------

pGroup = pGroup or class(modPropMgr.propmgr, modTopicMgr.pTopicObserver)

pGroup.init = function(self, groupInfo, mgr)
	modPropMgr.propmgr.init(self)
	self.grpId = groupInfo.id
	self.mgr = mgr
	self:updateProps(groupInfo)
	self.members = {}
	-- roomId --> desk
	self.desks = {}
	self.deskIdx = 1
	self.observers = {}
end

pGroup.updateProps = function(self, groupInfo)
	self:setProp("name", groupInfo.name)
	self:setProp("desc", groupInfo.brief_intro)
	self:setProp("avatar", groupInfo.avatar)
	self:setProp("createdDate", groupInfo.created_date)
	local uids = {}
	for _, uid in ipairs(groupInfo.member_uids) do
		table.insert(uids, uid)
	end
	self.memberUserIds = uids
	self:setProp("memberCnt", #uids)
	self:setProp("maxMemberCnt", groupInfo.max_member_count)
	self:setProp("deskCnt", 0)
	self.groupInfo = groupInfo
end

pGroup.assembleProto = function(self, proto)
	proto.id = self.grpId
	proto.creator_uid = self.groupInfo.creator_uid
	proto.name = self:getProp("name")
	proto.brief_intro = self:getProp("desc")
	proto.avatar = self:getProp("avatar")
	proto.max_member_count = self:getProp("maxMemberCnt")
	proto.created_date = self:getProp("createdDate")
end

pGroup.saveInfoToSvr = function(self, callback)
	modGroupRpc.setGroup(self, callback)
end

pGroup.kickMember = function(self, userId, callback)
	modGroupRpc.kickMemberFromGroup(self:getGrpId(), userId, function(success, reason)
		if success then
			self:fetchDetail(callback)
		end
		callback(success, reason)
	end)
end

pGroup.fetchDetail = function(self, callback)
	modGroupRpc.getGroupsDetail({self:getGrpId()}, function(success, reason, groupInfos)
		if success then
			local groupInfo = groupInfos[1]
			self:updateProps(groupInfo)
			self:initMembers(function(success, reason)
				callback(success, reason)
			end)
		else
			callback(false, reason)
		end
	end)
end

pGroup.initMembers = function(self, callback)
	modGroupRpc.getMembers(self.grpId, self.memberUserIds, function(success, reason, memberInfos)
		if success then
			self.members = {}
			for _, memberInfo in ipairs(memberInfos) do
				self:addMember(memberInfo)
			end
			self.creator = self.members[self.groupInfo.creator_uid]
		end
		callback(success, reason)
	end)
end

pGroup.addMember = function(self, memberInfo)
	local member = modMember.pGrpMember:new(self, memberInfo)
	self.members[member:getUserId()] = member
end

pGroup.delMember = function(self, userId)
	self.members[userId] = nil
end

pGroup.getMember = function(self, userId)
	return self.members[userId]
end

pGroup.getAllMembers = function(self)
	return self.members
end

pGroup.subscribe = function(self, callback)
	modTopicMgr.pTopicMgr:instance():subscribeGroupTopic(self, function(success, reason, state)
		if success then
			local available = {}
			for _, roomInfo in ipairs(state.rooms) do
				local desk = self:addDesk(roomInfo)
				local roomId = desk:getRoomId()
				available[roomId] = true
			end
			local unavailable = {}
			for roomId, desk in pairs(self.desks) do
				if not available[roomId] then
					table.insert(unavailable, roomId)
				end
			end
			for _, roomId in ipairs(unavailable) do
				self:delDesk(roomId)
			end
		end
		if callback then
			callback(success, reason)
		end
	end)
end

pGroup.unsubscribe = function(self, callback)
	modTopicMgr.pTopicMgr:instance():unsubscribeGroupTopic(self, function(success, reason)
		if success then
			self.desks = {}
		end
		if callback then
			callback(success, reason)
		end
	end)
end

pGroup.onTopicUpdate = function(self, payload)
	local notify = modGroupImplProto.GroupUpdateStateRequest()
	notify:ParseFromString(payload)
	if notify.group_id ~= self:getGrpId() then
		log("info", "topic not for me, skip it")
		return
	end
	local actType = notify.action_type
	log("info", "fjijfwifjwif", payload, actType)
	if actType == modGroupImplProto.GroupUpdateStateRequest.ADD_ROOM then
		local data = modGroupImplProto.GroupState.Room()
		data:ParseFromString(notify.action_data)
		self:addDesk(data)
	elseif actType == modGroupImplProto.GroupUpdateStateRequest.REMOVE_ROOM then
		local data = modGroupImplProto.GroupState.Room()
		data:ParseFromString(notify.action_data)
		self:delDesk(data.id)
	elseif actType == modGroupImplProto.GroupUpdateStateRequest.ADD_ROOM_PLAYER then
		local data = modGroupImplProto.GroupState.RoomPlayer()
		data:ParseFromString(notify.action_data)
		local desk = self:getDesk(data.room_id)
		if desk then
			desk:addPlayer(data)
		end
	elseif actType == modGroupImplProto.GroupUpdateStateRequest.REMOVE_ROOM_PLAYER then
		local data = modGroupImplProto.GroupState.RoomPlayer()
		data:ParseFromString(notify.action_data)
		local desk = self:getDesk(data.room_id)
		if desk then
			desk:delPlayer(data.user_id)
		end
	elseif actType == modGroupImplProto.GroupUpdateStateRequest.SET_ROOM_GAME then
		local data = modGroupImplProto.GroupState.RoomGame()
		data:ParseFromString(notify.action_data)
		local desk = self:getDesk(data.room_id)
		if desk then
			desk:setProp("gameCount", data.time_count)
		end
	end
end

pGroup.getCreator = function(self)
	return self.creator
end

pGroup.isMyselfCreator = function(self)
	return self.groupInfo.creator_uid == modUserData.getUID()
end

pGroup.getMyself = function(self)
	return self.members[modUserData.getUID()]
end

pGroup.getGrpId = function(self)
	return self.grpId
end

pGroup.addDesk = function(self, roomInfo)
	local roomId = roomInfo.id
	if self.desks[roomId] then
		self.desks[roomId]:updateProps(roomInfo)
		return self.desks[roomId]
	else
		self.deskIdx = self.deskIdx + 1
		local desk = modDesk.pDesk:new(roomInfo, self, self.deskIdx)
		local roomId = desk:getRoomId()
		if not self.desks[roomId] then
			self.desks[roomId] = desk
			for observer, _ in pairs(self.observers) do
				observer:onAddDesk(desk)
			end
			local cnt = self:getProp("deskCnt")
			self:setProp("deskCnt", cnt + 1)
		end
		return desk
	end
end

pGroup.delDesk = function(self, roomId)
	log("info", "delDesk", roomId)
	if self.desks[roomId] then
		for observer, _ in pairs(self.observers) do
			observer:onDelDesk(roomId)
		end
		self.desks[roomId] = nil
		local cnt = self:getProp("deskCnt")
		self:setProp("deskCnt", cnt - 1)
	end
end

pGroup.getDesk = function(self, roomId)
	return self.desks[roomId]
end

pGroup.addObserver = function(self, observer)
	self.observers[observer] = true
end

pGroup.delObserver = function(self, observer)
	self.observers[observer] = nil
end

pGroup.getAllDesks = function(self)
	return self.desks
end

pGroup.onDismiss = function(self)
	self.mgr:onGroupDismiss(self)
end

pGroup.onLeave = function(self)
	self.mgr:onLeaveGroup(self)
end
