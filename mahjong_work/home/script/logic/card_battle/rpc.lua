local modPokerProto = import("data/proto/rpc_pb2/pokers/poker_pb.lua")
local modRoomProto = import("data/proto/rpc_pb2/room_pb.lua")
local modUserData = import("logic/userdata.lua")
local modUtil = import("util/util.lua")
local modSessionMgr = import("net/mgr.lua")

roomcardText = function()
	local modChannelMgr = import("logic/channels/main.lua")
	return modChannelMgr.getCurChannel():getRoomcardText() or "钻石"
end

getUserStateInRoom = function(roomId, callback)
	local request = modPokerProto.GetPokerUserRoomStateRequest()
	request.user_id = modUserData.getUID()
	request.channel_id = modUtil.getOpChannel()
	request.room_id = roomId
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_POKER, modPokerProto.GET_POKER_USER_ROOM_STATE, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modPokerProto.GetPokerUserRoomStateReply()
			reply:ParseFromString(ret)
			callback(true, "", reply)
		else
			callback(false, reason)
		end
	end)
end

enterRoom = function(roomId, callback)
	local request = modPokerProto.EnterPokerRoomRequest()
	request.channel_id = modUtil.getOpChannel()
	request.user_id = modUserData.getUID()
	request.room_id = roomId
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_POKER, modPokerProto.ENTER_POKER_ROOM, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modPokerProto.EnterPokerRoomReply()
			reply:ParseFromString(ret)
			local isRoomCardError = false
			local code = reply.error_code
			if code == modPokerProto.EnterPokerRoomReply.SUCCESS then
				callback(true, reason, reply)
				return
			elseif code == modPokerProto.EnterPokerRoomReply.FAILURE then
				success = false
				reason = TEXT("进入房间失败")
			elseif code == modPokerProto.EnterPokerRoomReply.NO_ROOM then
				success = false
				reason = TEXT("找不到房间")
			elseif code ==modPokerProto.EnterPokerRoomReply. ROOM_FULL then
				success = false
				reason = TEXT("房间已满")
			elseif code == modPokerProto.EnterPokerRoomReply.IN_OTHER_ROOM then
				success = false
				reason = TEXT("已经在其他房间")
			elseif code == modPokerProto.EnterPokerRoomReply.GAME_STARTED then
				success = false
				reason = TEXT("牌局已经开始")
			elseif code == modPokerProto.EnterPokerRoomReply.ROOM_CLOSED then
				success = false
				reason = TEXT("房间已经关闭")
			elseif code == modPokerProto.EnterPokerRoomReply.LACK_OF_ROOM_CARDS then
				success = false
				reason = TEXT(sf("%s不足", roomcardText()))
				isRoomCardError = true
			else
				success = false
				reason = TEXT("进入房间失败")
			end
			callback(success, reason, nil, isRoomCardError)
		else
			callback(false, TEXT("请求错误"))
		end
	end, true)
end

followPlayer = function(roomId, followee, callback)
	local request = modPokerProto.FollowUserRequest()
	request.channel_id = modUtil.getOpChannel()
	request.user_id = modUserData.getUID()
	request.room_id = roomId
	request.ob_user_id = followee
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_POKER, modPokerProto.FOLLOW_USER, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modPokerProto.FollowUserReply()
			reply:ParseFromString(ret)
			if reply.success then
				callback(true, "", reply.enter_reply)
			else
				callback(false, TEXT("操作失败"))
			end
		else
			callback(false, reason)
		end
	end)
end

finishState = function(request, callback)
	local message = modPokerProto.UserFinishStateRequest()
	message.user_id = modUserData.getUID()
	if request then
		message.state_info = request:SerializeToString()
	end
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_POKER, modPokerProto.USER_FINISH_STATE, message, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modPokerProto.UserFinishStateReply()
			reply:ParseFromString(ret)
			callback(true, reply.success)
		else
			callback(false)
		end
	end, true)
end

prepareDone = function(callback)
	local message = modPokerProto.PokerPrepareDoneRequest()
	message.user_id = modUserData.getUID()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_POKER, modPokerProto.POKER_USER_PREPARE_DONE, message, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modPokerProto.UserFinishStateReply()
			reply:ParseFromString(ret)
			callback(reply.success)
		else
			callback(false)
		end
	end)
end

leaveRoom = function(callback)
	local message = modPokerProto.LeavePokerRoomRequest()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_POKER, modPokerProto.LEAVE_POKER_ROOM, message, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modPokerProto.LeavePokerRoomReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modPokerProto.LeavePokerRoomReply.SUCCESS then
				callback(true)
			elseif code == modPokerProto.LeavePokerRoomReply.GAMING then
				callback(false, "正在游戏中，无法离开游戏")
			elseif code == modPokerProto.LeavePokerRoomReply.OWNER then
				callback(false, "房主不能离开游戏")
			elseif code == modPokerProto.LeavePokerRoomReply.FAILURE then
				callback(false, "离开房间失败，请稍后在试")
			end
		else
			infoMessage("请求失败")
		end
	end)
end

observerLeaveRoom = function(callback)
	local messge = modPokerProto.ObserverLeavePokerRoomRequest()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_POKER, modPokerProto.OBSERVER_LEAVE_POKER_ROOM, message, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modPokerProto.ObserverLeavePokerRoomReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modPokerProto.ObserverLeavePokerRoomReply.SUCCESS then
				modUtil.safeCallBack(callback, true)
			elseif code == modPokerProto.ObserverLeavePokerRoomReply.ROOM_CLOSED then
				modUtil.safeCallBack(callback, false, TEXT("房间已关闭"))
			else
				modUtil.safeCallBack(callback, false, TEXT("退出失败"))
			end
		else
			infoMessage(reason)
		end
	end)
end

gmSwitchCard = function(userId, roomId, srcCardIdx, dstCardIdx, callback)
	log("error", "====== fuck ", userId, roomId, srcCardIdx, dstCardIdx)
	local message = modPokerProto.GmPokerSwitchCardRequest()
	message.user_id = userId
	message.room_id = roomId
	message.channel_id = modUtil.getOpChannel()
	message.src_card_idx = srcCardIdx
	message.dst_card_idx = dstCardIdx
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_POKER, modPokerProto.GM_POKER_SWITCH_CARD, message, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modPokerProto.GmPokerSwitchCardReply()
			reply:ParseFromString(ret)
			if reply.success then
				callback(true)
			else
				callback(false, TEXT("操作失败"))
			end
		else
			callback(false, reason)
		end
	end)
end

dismissRoom = function(time, callback)
	local request = modRoomProto.AskCloseRoomRequest()
	request.user_id = modUserData.getUID()
	request.timeout = time or 1
	local wnd = modUtil.loadingMessage(TEXT("通讯中.."))
	modSessionMgr.instance():callRpc(T_SESSION_POKER,modPokerProto.POKER_ASK_CLOSE_ROOM, request, OPT_NONE, function(success,reason,ret)
		wnd:setParent(nil)
		if success then
			local reply = modRoomProto.AskCloseRoomReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modRoomProto.AskCloseRoomReply.SUCCESS then
				callback(true,"")
			elseif code == modRoomProto.AskCloseRoomReply.FAILURE then
				callback(false,TEXT("解散失败."))
			elseif code == modRoomProto.AskCloseRoomReply.NOT_OWNER then
				callback(false,TEXT("您不是房主."))
			else
				callback(false,TEXT("操作失败."))
			end
		else
			infoMessage("请求失败")
		end
	end)
end

answerCloseRoom = function(yesOrCancel,callback)
	local request = modRoomProto.AnswerCloseRoomRequest()
	request.yes_or_no = yesOrCancel
	local wnd = modUtil.loadingMessage(TEXT("通讯中.."))
	modSessionMgr.instance():callRpc(T_SESSION_POKER,modPokerProto.POKER_ANSWER_CLOSE_ROOM,request,OPT_NONE,function(success,reason,ret)
		wnd:setParent(nil)
		if	success then
			local reply = modRoomProto.AnswerCloseRoomReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modRoomProto.AnswerCloseRoomReply.SUCCESS then
				callback(true,"")
			elseif code == modRoomProto.AnswerCloseRoomReply.FAILURE then
				callback(false,TEXT("请求失败"))
			else
				callback(false,TEXT("未知原因,请求失败"))
			end

		else
			infoMessage("请求失败")
		end
	end)
end

commitGeoLocation = function(longitude, latitude, callback)
	local request = modRoomProto.SetUserGeoLocationRequest()
	request.user_geo_location.user_id = modUserData.getUID()
	request.user_geo_location.latitude = tostring(sf("%.8f", latitude))
	request.user_geo_location.longitude = tostring(sf("%.8f", longitude))
	modSessionMgr.instance():callRpc(T_SESSION_POKER, modPokerProto.POKER_SET_USER_GEO_LOCATION, request, OPT_NONE, function(success, reason, ret)
		if success then
			callback(true, "")
		else
			callback(false, "上报位置失败")
		end
	end)
end

fetchGeoLocations = function(uids, callback)
	local request = modRoomProto.GetUserGeoLocationsRequest()
	for _, uid in ipairs(uids) do
		request.user_ids:append(tonumber(uid))
	end
	modSessionMgr.instance():callRpc(T_SESSION_POKER, modPokerProto.POKER_GET_USER_GEO_LOCATIONS, request, OPT_NONE, function(success, reason, ret)
		if success then
			local reply = modRoomProto.GetUserGeoLocationsReply()
			reply:ParseFromString(ret)
			if reply.error_code == modRoomProto.GetUserGeoLocationsReply.SUCCESS then
				local infos = {}
				for _, location in ipairs(reply.user_geo_locations) do
					local uid = location.user_id
					local longitude = tonumber(location.longitude)
					local latitude = tonumber(location.latitude)
					infos[uid] = {longitude, latitude}
				end
				callback(true, "", infos)
			else
				callback(false, "获取玩家位置失败")
			end
		else
			callback(false, "获取玩家位置失败")
		end
	end)
end
