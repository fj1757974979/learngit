local modUtil = import("util/util.lua")
local modSessionMgr = import("net/mgr.lua")
local modGroupProto = import("data/proto/rpc_pb2/group_pb.lua")
local modGroupImplProto = import("data/proto/rpc_pb2/group_impl_pb.lua")
local modUserData = import("logic/userdata.lua")

joinGroup = function(grpId, leftWords, callback)
	local request = modGroupProto.SendJoinGroupMailRequest()
	request.group_id = grpId
	request.left_words = leftWords
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modGroupProto.SEND_JOIN_GROUP_MAIL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modGroupProto.SendJoinGroupMailReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGroupProto.SendJoinGroupMailReply.SUCCESS then
				callback(true, "")
			else
				local reason = ""
				if reply.error_code == modGroupProto.SendJoinGroupMailReply.REPEATED then
					reason = TEXT("已经申请过了，请等待俱乐部管理员通过验证")
				elseif reply.error_code == modGroupProto.SendJoinGroupMailReply.NO_GROUP then
					reason = TEXT("该俱乐部已不存在")
				elseif reply.error_code == modGroupProto.SendJoinGroupMailReply.GROUP_MEMBER_EXISTS then
					reason = TEXT("您已经加入了该俱乐部")
				else
					reason = TEXT("申请失败")
				end
				callback(false, reason)
			end
		else
			callback(false, reason)
		end
	end)
end

leaveGroup = function(grpId, callback)
	local request = modGroupImplProto.GroupLeaveRequest()
	request.channel_id = modUtil.getOpChannel()
	request.group_id = grpId
	request.user_id = modUserData.getUID()
	callGroupMethod(modGroupImplProto.GROUP_LEAVE, request, function(success, reason, ret)
		if success then
			local reply = modGroupImplProto.GroupLeaveReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGroupImplProto.GroupLeaveReply.SUCCESS then
				callback(true, "")
			else
				if reply.error_code == modGroupImplProto.GroupLeaveReply.NO_GROUP then
					callback(false, TEXT("俱乐部不存在"))
				elseif reply.error_code == modGroupImplProto.GroupLeaveReply.NO_GROUP_MEMBER then
					callback(false, TEXT("你已不在该俱乐部中"))
				else
					callback(false, TEXT("操作失败"))
				end
			end
		else
			callback(false, reason)
		end
	end)
end

kickMemberFromGroup = function(grpId, userId, callback)
	local request = modGroupImplProto.GroupLeaveRequest()
	request.channel_id = modUtil.getOpChannel()
	request.group_id = grpId
	request.user_id = userId
	callGroupMethod(modGroupImplProto.GROUP_LEAVE, request, function(success, reason, ret)
		if success then
			local reply = modGroupImplProto.GroupLeaveReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGroupImplProto.GroupLeaveReply.SUCCESS then
				callback(true, "")
			else
				if reply.error_code == modGroupImplProto.GroupLeaveReply.NO_GROUP then
					callback(false, TEXT("俱乐部不存在"))
				elseif reply.error_code == modGroupImplProto.GroupLeaveReply.NO_GROUP_MEMBER then
					callback(false, TEXT("该成员已不在俱乐部中"))
				else
					callback(false, TEXT("操作失败"))
				end
			end
		else
			callback(false, reason)
		end
	end)
end

createGroup = function(name, brief, callback)
	local request = modGroupImplProto.GroupCreateRequest()
	request.group.creator_uid = modUserData.getUID()
	request.group.name = name
	request.group.brief_intro = brief
	request.group.avatar = modUserData.getUserAvatarUrl()
	request.group_member.user_id = modUserData.getUID()
	callGroupMethod(modGroupImplProto.GROUP_CREATE, request, function(success, reason, ret)
		if success then
			local reply = modGroupImplProto.GroupCreateReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGroupImplProto.GroupCreateReply.SUCCESS then
				callback(true, "", reply.group_id)
			else
				if reply.error_code == modGroupImplProto.GroupCreateReply.TOO_MANY_GROUPS then
					callback(false, TEXT("俱乐部数量超过上限"))
				elseif reply.error_code == modGroupImplProto.GroupCreateReply.NO_ROOM_CARD then
					callback(false, TEXT("房卡不足"))
				else
					callback(false, TEXT("创建失败"))
				end
			end
		else
			callback(false, reason)
		end
	end)
end

destroyGroup = function(grpId, callback)
	local request = modGroupImplProto.GroupDestroyRequest()
	request.channel_id = modUtil.getOpChannel()
	request.group_id = grpId
	callGroupMethod(modGroupImplProto.GROUP_DESTROY, request, function(success, reason, ret)
		local reply = modGroupImplProto.GroupDestroyReply()
		reply:ParseFromString(ret)
		if success then
			if reply.error_code == modGroupImplProto.GroupDestroyReply.SUCCESS then
				callback(true, "")
			else
				if reply.error_code == modGroupImplProto.GroupDestroyReply.NO_GROUP then
					callback(false, TEXT("俱乐部不存在"))
				else
					callback(false, TEXT("操作失败"))
				end
			end
		else
			callback(false, reason)
		end
	end)
end

setGroup = function(group, callback)
	local request = modGroupImplProto.GroupSetRequest()
	request.channel_id = modUtil.getOpChannel()
	group:assembleProto(request.group)
	callGroupMethod(modGroupImplProto.GROUP_SET, request, function(success, reason, ret)
		if success then
			local reply = modGroupImplProto.GroupSetReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGroupImplProto.GroupSetReply.SUCCESS then
				callback(true, "")
			else
				if reply.error_code == modGroupImplProto.GroupSetReply.NO_GROUP then
					callback(false, TEXT("俱乐部不存在"))
				else
					callback(false, TEXT("操作失败"))
				end
			end
		else
			callback(false, reason)
		end
	end)
end

getGroups = function(callback)
	local request = modGroupImplProto.GroupGetRelatedRequest()
	request.channel_id = modUtil.getOpChannel()
	request.user_id = modUserData.getUID()
	callGroupMethod(modGroupImplProto.GROUP_GET_RELATED, request, function(success, reason, ret)
		if success then
			local reply = modGroupImplProto.GroupGetRelatedReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGroupImplProto.GroupGetRelatedReply.SUCCESS then
				callback(true, "", reply.created_group_ids, reply.joined_group_ids)
			else
				callback(false, TEXT("操作失败"))
			end
		else
			callback(false, reason)
		end
	end)
end

getGroupsDetail = function(grpIds, callback)
	local request = modGroupImplProto.GroupGetSomeRequest()
	request.channel_id = modUtil.getOpChannel()
	for _, grpId in ipairs(grpIds) do
		request.group_ids:append(grpId)
	end
	callGroupMethod(modGroupImplProto.GROUP_GET_SOME, request, function(success, reason, ret)
		if success then
			local reply = modGroupImplProto.GroupGetSomeReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGroupImplProto.GroupGetSomeReply.SUCCESS then
				callback(true, "", reply.groups)
			else
				callback(false, TEXT("获取俱乐部失败"))
			end
		else
			callback(false, reason)
		end
	end)
end

getMembers = function(grpId, userIds, callback)
	local request = modGroupImplProto.GroupGetMembersRequest()
	request.channel_id = modUtil.getOpChannel()
	request.group_id = grpId
	for _, uid in ipairs(userIds) do
		request.group_member_uids:append(uid)
	end
	callGroupMethod(modGroupImplProto.GROUP_GET_MEMBERS, request, function(success, reason, ret)
		if success then
			local reply = modGroupImplProto.GroupGetMembersReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGroupImplProto.GroupGetMembersReply.SUCCESS then
				callback(true, "", reply.group_members)
			else
				if reply.error_code == modGroupImplProto.GroupGetMembersReply.NO_GROUP then
					callback(false, TEXT("找不到俱乐部"))
				else
					callback(false, TEXT("获取成员信息失败"))
				end
			end
		else
			callback(false, reason)
		end
	end)
end

setMember = function(member, callback)
	local request = modGroupImplProto.GroupSetMemberRequest()
	request.channel_id = modUtil.getOpChannel()
	member:assembleProto(request.group_member)
	callGroupMethod(modGroupImplProto.GROUP_SET_MEMBER, request, function(success, reason, ret)
		if success then
			local reply = modGroupImplProto.GroupSetMemberReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGroupImplProto.GroupSetMemberReply.SUCCESS then
				callback(true, "")
			else
				if reply.error_code == modGroupImplProto.GroupSetMemberReply.NO_GROUP then
					callback(false, TEXT("俱乐部已不存在"))
				elseif reply.error_code == modGroupImplProto.GroupSetMemberReply.NO_GROUP_MEMBER then
					callback(false, TEXT("该成员已不在俱乐部中"))
				else
					callback(false, TEXT("操作失败"))
				end
			end
		else
			callback(false, reason)
		end
	end)
end

callGroupMethod = function(method, request, callback)
	local message = modGroupProto.CallGroupImplRequest()
	message.group_impl_method_id = method
	message.group_impl_request = request:SerializeToString()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modGroupProto.CALL_GROUP_IMPL, message, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modGroupProto.CallGroupImplReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGroupProto.CallGroupImplReply.SUCCESS then
				callback(true, "", reply.group_impl_reply)
			else
				if reply.error_code == modGroupProto.CallGroupImplReply.NO_AUTH then
					local modGroupMgr = import("logic/group/mgr.lua")
					modGroupMgr.pGroupMgr:instance():initGroups(function()
						callback(false, TEXT("没有权限执行此操作"))
					end)
				else
					callback(false, TEXT("操作失败"))
				end
			end
		else
			callback(false, reason)
		end
	end)
end
