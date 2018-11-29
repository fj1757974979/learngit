local modUtil = import("util/util.lua")
local modSessionMgr = import("net/mgr.lua")
local modRoomProto = import("data/proto/rpc_pb2/room_pb.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modClubProto = import("data/proto/rpc_pb2/club_pb.lua")
local modClubImplProto = import("data/proto/rpc_pb2/club_impl_pb.lua")
local modNiuniuProto = import("data/proto/rpc_pb2/pokers/niuniu_pb.lua")
local modCardBattleCreate = import("logic/card_battle/create.lua")

quiteClubClearWnds = function()
	local modMainDesk = import("ui/club/main_desk.lua")
	if modMainDesk.pMainDesk:getInstance() then
		modMainDesk.pMainDesk:instance():close()
	end
	local modClubMgr = import("logic/club/main.lua")
	modClubMgr.getCurClub():refreshMgrClubs()
	infoMessage("该俱乐部已解散")
end

refreshSelfMemberInfos = function(self)
	local modMainDesk = import("ui/club/main_desk.lua")
	if modMainDesk.pMainDesk:getInstance() then
		modMainDesk.pMainDesk:instance():updateSelfMemberInfo()
	end
end

getClubFromClubInfo = function(club, list)
	for name, value in pairs(list) do
		club[name] = value
	end
end

refreshGrounds = function(id)
	local modMainDesk = import("ui/club/main_desk.lua")
	if modMainDesk.pMainDesk:getInstance() then
		modMainDesk.pMainDesk:instance():refreshGrounds()
	end
end

getCallClubImplRequest = function(implId, implRequest)
	local request = modClubProto.CallClubImplRequest()
	request.club_impl_method_id = implId
	request.club_impl_request = implRequest:SerializeToString()
	return request
end

callClubImplResult = function(success, reason, ret, callback)
	if success then
		local reply = modClubProto.CallClubImplReply()
		reply:ParseFromString(ret)
		local code = reply.error_code
		if code == modClubProto.CallClubImplReply.SUCCESS then
			callback(true, reply)
		elseif code == modClubProto.CallClubImplReply.NO_AUTH then
			infoMessage("只有俱乐部管理员才能这样做哦！")
		else
			infoMessage("获取信息消失在云海，请稍后再尝试。")
		end
	else
		infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
	end
end

getClubRelated = function(uid, callback)
	local impl = modClubImplProto.ClubGetRelatedRequest()
	impl.user_id = uid
	local request = getCallClubImplRequest(modClubImplProto.CLUB_GET_RELATED, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubGetRelatedReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubGetRelatedReply.SUCCESS then
					callback(true, "", implReply)
				else
					callback(false, "俱乐部信息消失在云海，请稍后再尝试。")
				end
			end)
		end
	end)
end

newClubData = function(list, request)
	if not list then return end
	local modclubimplproto = import("data/proto/rpc_pb2/club_impl_pb.lua")
	local nameToProto = {
		["club_id"] = "id",
		["uid"] = "creator_uid",
		["province_code"] = "province_code",
		["city_code"] = "city_code",
		["club_name"] = "name",
		["club_text"] = "brief_intro",
		["avatar"] = "avatar",
		["gold"] = "gold_coin_count",
		["max_member_count"] = "max_member_count",
		["ground_ids"] = "ground_ids",
		["member_uids"] = "member_uids",
		["created_date"] = "created_date",
	}
	for name, value in pairs(list) do
		if nameToProto[name] then
			if type(value) == "table" then
				for _, v in pairs(value) do
					request[nameToProto[name]]:append(v)
				end
			else
				request[nameToProto[name]] = value
			end
		else
			log("error", "not prop:", nameToProto[name])
		end
	end
end

createClub = function(list, callback)
	local impl = modClubImplProto.ClubCreateRequest()
	newClubData(list, impl.club)
	impl.club_member.gold_coin_count = 1
	local request = getCallClubImplRequest(modClubImplProto.CLUB_CREATE, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubCreateReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubCreateReply.SUCCESS then
					callback(true, "", implReply)
				elseif implCode == modClubImplProto.ClubCreateReply.TOO_MANY_CLUBS then
					callback(false, "已创建的俱乐部数量已达上限。")
				elseif implCode == modClubImplProto.ClubCreateReply.NO_ROOM_CARD then
					callback(false, "钻石不够啦，无法创建新的俱乐部。")
				else
					callback(false, "创建信息消失在云海，请稍后再尝试。")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end


joinClub = function(uid, clubId, callback)
	local impl = modClubImplProto.ClubJoinRequest()
	impl.club_member.club_id = clubId
	impl.club_member.user_id = uid
	local request = getCallClubImplRequest(modClubImplProto.CLUB_JOIN, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubJoinReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubJoinReply.SUCCESS then
					callback(true, "", implReply)
				else
					callback(false, "申请信息消失在云海，请稍后再尝试。")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

getClubInfos = function(clubIds, callback)
	local impl = modClubImplProto.ClubGetSomeRequest()
	for _, id in pairs(clubIds) do
		impl.club_ids:append(id)
	end
	local request = getCallClubImplRequest(modClubImplProto.CLUB_GET_SOME, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubGetSomeReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubGetSomeReply.SUCCESS then
					if table.getn(implReply.clubs) <= 0 then
						callback(false, "查询的俱乐部信息消失在云海")
					else
						callback(true, "", implReply)
					end
				else
					callback(false, "俱乐部信息消失在云海，请稍后再尝试。")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

searchClubs = function(provinceCode, cityCode, name, callback)
	local impl = modClubImplProto.ClubLookupByGeoRequest()
	impl.province_code = provinceCode or 0
	impl.city_code = cityCode or 0
	local request = getCallClubImplRequest(modClubImplProto.CLUB_LOOKUP_BY_GEO, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubLookupByGeoReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubLookupByGeoReply.SUCCESS then
					callback(true, "", implReply)
				else
					callback(false, "没有找到对应的俱乐部。")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

sendJoinRequest = function(id, text, callback)
	local request = modClubProto.SendJoinClubMailRequest()
	request.club_id = id
	request.left_words = text or ""
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.SEND_JOIN_CLUB_MAIL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modClubProto.SendJoinClubMailReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modClubProto.SendJoinClubMailReply.SUCCESS then
				callback(true, "", reply)
			elseif code == modClubProto.SendJoinClubMailReply.REPEATED then
				callback(false, "已经申请过该俱乐部，不用重复申请啦！")
			elseif code == modClubProto.SendJoinClubMailReply.NO_CLUB then
				callback(false, "俱乐部不存在啦")
			elseif code == modClubProto.SendJoinClubMailReply.CLUB_MEMBER_EXISTS then
				callback(false, "已经加入该俱乐部")
			else
				callback(false, "申请加入失败")
			end
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

getMemberInfo = function(clubId, uids, callback)
	local impl = modClubImplProto.ClubGetMembersRequest()
	impl.club_id = clubId
	for _, uid in pairs(uids) do
		impl.club_member_uids:append(uid)
	end
	local request = getCallClubImplRequest(modClubImplProto.CLUB_GET_MEMBERS, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubGetMembersReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubGetMembersReply.SUCCESS then
					callback(true, "", implReply)
				elseif implCode == modClubImplProto.ClubGetMembersReply.NO_CLUB then
					callback(false, "俱乐部已经解散，不能再查看俱乐部成员。")
					quiteClubClearWnds()
				else
					callback(false, "当前信息消失在云海，请稍后再尝试。")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

getClubGounds = function(clubId, ids, callback)
	local impl = modClubImplProto.ClubGetGroundsRequest()
	impl.club_id = clubId
	for _, id in ipairs(ids) do
		impl.club_ground_ids:append(id)
	end
	local request = getCallClubImplRequest(modClubImplProto.CLUB_GET_GROUNDS, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubGetGroundsReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubGetGroundsReply.SUCCESS then
					callback(true, "", implReply)
				elseif implCode == modClubImplProto.ClubGetGroundsReply.NO_CLUB then
					callback(false, "该俱乐部已经解散，重新加入一个俱乐部吧。")
					quiteClubClearWnds()
				else
					callback(false, "当前信息消失在云海，请稍后再尝试。")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

getCreateInfo = function(valueList, gameType, ruleType, request)
	local modBattleRpc = import("logic/battle/rpc.lua")
	if gameType == modLobbyProto.MAHJONG then
		modBattleRpc.createList(valueList, request.room_creation_info, ruleType)
	else
		--pokerCreateRoomRequst(valueList, request.poker_room_creation_info)
		modCardBattleCreate.genCreatePokerRoomRequest(valueList, ruleType, request.poker_room_creation_info)
	end
end

createClubGround = function(clubId, valueList, ruleType, gameType, callback)
	local impl = modClubImplProto.ClubCreateGroundRequest()
	impl.club_ground.club_id = clubId
	impl.club_ground.game_type = gameType
	impl.club_ground.min_gold_coin_count = valueList["enter"] or 0
	impl.club_ground.cost_gold_coin_count = valueList["cost"] or 0
	getCreateInfo(valueList, gameType, ruleType, impl.club_ground)
	local request = getCallClubImplRequest(modClubImplProto.CLUB_CREATE_GROUND, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubCreateGroundReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubCreateGroundReply.SUCCESS then
					callback(true, "", implReply)
				elseif implCode == modClubImplProto.ClubCreateGroundReply.NO_CLUB then
					callback(false, "俱乐部已经解散，无法再创建牌局。")
					quiteClubClearWnds()
				elseif implCode == modClubImplProto.ClubCreateGroundReply.TOO_MANY_CLUB_GROUNDS  then
					callback(false, "当前牌局数量已达上限，无法创建新的牌局。")
				elseif implCode == modClubImplProto.ClubCreateGroundReply.NO_ROOM_CARD then
					callback(false, "钻石不足，无法继续创建牌局，已有牌局也将暂停，请及时购入钻石。")
				else
					callback(false, "当前信息消失在云海，请稍后再尝试。")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

getGroundPlayers = function(clubId, groundId, callback)
	local request = modClubProto.GetClubGroundPlayersRequest()
	request.club_id = clubId
	request.club_ground_id = groundId
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.GET_CLUB_GROUND_PLAYERS, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modClubProto.GetClubGroundPlayersReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modClubProto.GetClubGroundPlayersReply.SUCCESS then
				callback(reply)
			else
				infoMessage("无法获取玩家信息，请稍后再尝试。")
			end
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

getGroundMemberCount = function(clubId, groundIds, callback)
	local request = modClubProto.GetNumbersOfClubGroundPlayersRequest()
	request.club_id = clubId
	for _, id in ipairs(groundIds) do
		request.club_ground_ids:append(id)
	end
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.GET_NUMBERS_OF_CLUB_GROUND_PLAYERS, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modClubProto.GetNumbersOfClubGroundPlayersReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modClubProto.GetNumbersOfClubGroundPlayersReply.SUCCESS then
				callback(true, "", reply)
			else
				callback(false, "无法获取玩家信息，请稍后再尝试。")
			end
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

clubJoinMatch = function(clubId, groundId, uid, rematch, callback)
	if not clubId or not groundId or not uid then return end
	local impl = modClubImplProto.ClubJoinMatchRequest()
	impl.club_id = clubId
	impl.club_ground_id = groundId
	impl.club_member_uid = uid
	impl.rematch = rematch
	local request = getCallClubImplRequest(modClubImplProto.CLUB_JOIN_MATCH, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubJoinMatchReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubJoinMatchReply.SUCCESS then
					callback(true, "", implReply)
				elseif implCode == modClubImplProto.ClubJoinMatchReply.NO_CLUB then
					callback(false, "该俱乐部已经解散，重新加入一个俱乐部吧。")
					quiteClubClearWnds()
				elseif implCode == modClubImplProto.ClubJoinMatchReply.NO_CLUB_GROUND  then
					callback(false, "该牌局已经关闭，重新加入一个牌局吧。", implReply)
					refreshGrounds(clubId)
				elseif implCode == modClubImplProto.ClubJoinMatchReply.NO_CLUB_MEMBER then
					callback(false, "该玩家已经离开俱乐部。")
				elseif implCode == modClubImplProto.ClubJoinMatchReply.NO_GOLD_COIN then
					refreshSelfMemberInfos()
					callback(false, "金豆不足，未达到入场要求，无法上桌。")
				elseif implCode == modClubImplProto.ClubJoinMatchReply.NO_ROOM_CARD then
					callback(false, "管理员的钻石不足，俱乐部牌局将暂停，请联系俱乐部管理员。")
				else
					callback(false, "请稍后再尝试。")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

addClubGold = function(clubId, count, callback)
	local request = modClubProto.RechargeClubGoldCoinsRequest()
	request.club_id = clubId
	request.room_card_count = count
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.RECHARGE_CLUB_GOLD_COINS, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modClubProto.RechargeClubGoldCoinsReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modClubProto.RechargeClubGoldCoinsReply.SUCCESS then
				callback(true, "", reply)
			elseif code == modClubProto.RechargeClubGoldCoinsReply.LACK_OF_ROOM_CARDS then
				callback(false, "钻石不足，无法兑换该数量的金豆。")
			else
				callback(false, "兑换信息消失在云海，请稍后再尝试。")
			end
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

moveGold = function(clubId, fromUid, toUid, gold,  callback)
	if not clubId or not fromUid or not toUid or not gold then return end
	local impl = modClubImplProto.ClubMoveGoldCoinsRequest()
	impl.club_id = clubId
	impl.from_user_id = fromUid
	impl.to_user_id = toUid
	impl.gold_coin_count = gold
	impl.gold_coins_are_premoved = false
	local request = getCallClubImplRequest(modClubImplProto.CLUB_MOVE_GOLD_COINS, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubMoveGoldCoinsReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubMoveGoldCoinsReply.SUCCESS then
					callback(true, "", implReply)
				elseif implCode == modClubImplProto.ClubMoveGoldCoinsReply.NO_CLUB then
					quiteClubClearWnds()
					callback(false, "俱乐部已经解散，无法再发放金豆。")
				elseif implCode == modClubImplProto.ClubMoveGoldCoinsReply.NO_CLUB_MEMBER  then
					callback(false, "该玩家已经离开俱乐部。")
				elseif implCode == modClubImplProto.ClubMoveGoldCoinsReply.NO_GOLD_COIN then
					if fromUid == UID_CLUB_ID then
						callback(false, "俱乐部金豆不足，请先兑换金豆再发放。")
					else
						callback(false, "金豆不足，无法赠送")
					end
				else
					callback(false, "发放信息消失在云海，请稍后再尝试。")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

returnGold = function(clubId, gold, callback)
	local request = modClubProto.SendReturnGoldCoinsToClubMailRequest()
	request.club_id = clubId
	request.gold_coin_count = gold
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.SEND_RETURN_GOLD_COINS_TO_CLUB_MAIL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modClubProto.SendReturnGoldCoinsToClubMailReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modClubProto.SendReturnGoldCoinsToClubMailReply.SUCCESS then
				callback(true, "", reply)
			elseif code == modClubProto.SendReturnGoldCoinsToClubMailReply.LACK_OF_ROOM_CARDS then
				callabck(false, "") -- >>>>>>
			elseif code == modClubProto.SendReturnGoldCoinsToClubMailReply.NO_CLUB then
				callback(false, "该俱乐部已经解散，请联系俱乐部管理员。")
					quiteClubClearWnds()
			elseif code == modClubProto.SendReturnGoldCoinsToClubMailReply.NO_CLUB_MEMBER then
				callback(false, "从俱乐部的金豆只能捐献给对应的俱乐部。")
			elseif code == modClubProto.SendReturnGoldCoinsToClubMailReply.NO_GOLD_COIN then
				callback(false, "金豆不足，暂时无法捐献。")
			else
				callback(false, "捐赠信息消失在云海，请稍后再尝试。")
			end
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

destroyGround = function(clubId, groundId, callback)
	if not clubId or not groundId then return end
	local impl = modClubImplProto.ClubDestroyGroundRequest()
	impl.club_id = clubId
	impl.club_ground_id = groundId
	local request = getCallClubImplRequest(modClubImplProto.CLUB_DESTROY_GROUND, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubDestroyGroundReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubDestroyGroundReply.SUCCESS then
					callback(true, "", implReply)
				elseif implCode == modClubImplProto.ClubDestroyGroundReply.NO_CLUB then
					callback(false, "俱乐部不存在")
					quiteClubClearWnds()
				elseif implCode == modClubImplProto.ClubDestroyGroundReply.NO_CLUB_GROUND then
					callback(false, "牌局不存在")
					refreshGrounds(clubId)
				else
					callback(false, "关闭牌局失败")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

destroyClub = function(clubId, callback)
	if not clubId then return end
	local impl = modClubImplProto.ClubDestroyRequest()
	impl.club_id = clubId
	local request = getCallClubImplRequest(modClubImplProto.CLUB_DESTROY, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubDestroyReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubDestroyReply.SUCCESS then
					callback(true, "", implReply)
				elseif implCode == modClubImplProto.ClubDestroyReply.NO_CLUB then
					callback(false, "俱乐部不存在")
					quiteClubClearWnds()
				else
					callback(false, "解散俱乐部失败")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

getMemberWeeklyStat = function(clubId, uid, callback)
	if not clubId or not uid then return end
	local impl = modClubImplProto.ClubGetMemberWeeklyStatRequest()
	impl.club_id = clubId
	impl.club_member_uid = uid
	local request = getCallClubImplRequest(modClubImplProto.CLUB_GET_MEMBER_WEEKLY_STAT, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubGetMemberWeeklyStatReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubGetMemberWeeklyStatReply.SUCCESS then
					callback(true, "", implReply)
				elseif implCode == modClubImplProto.ClubGetMemberWeeklyStatReply.NO_CLUB then
					callback(false, "俱乐部不存在")
					quiteClubClearWnds()
				elseif implCode == modClubImplProto.ClubGetMemberWeeklyStatReply.NO_CLUB_MEMBER then
					callback(false, "玩家不存在")
				else
					callback(false, "获取玩家金豆信息失败")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

getClubDailyStat = function(clubId, callback)
	if not clubId then return end
	local impl = modClubImplProto.ClubGetDailyStatRequest()
	impl.club_id = clubId
	local request = getCallClubImplRequest(modClubImplProto.CLUB_GET_DAILY_STAT, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubGetDailyStatReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubGetDailyStatReply.SUCCESS then
					callback(true, "", implReply)
				elseif implCode == modClubImplProto.ClubGetDailyStatReply.NO_CLUB then
					callback(false, "俱乐部不存在")
					quiteClubClearWnds()
				else
					callback(false, "获取俱乐部金豆信息失败")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

getGoldTraces = function(clubId, callback)
	if not clubId then return end
	local impl = modClubImplProto.ClubGetGoldCoinTracesRequest()
	impl.club_id = clubId
	impl.from_user_id = UID_CLUB_ID
	impl.to_user_id = UID_CLUB_ID
	impl.from_or_to = true
	impl.page_size = 1000
	impl.page_number = 0
	local request = getCallClubImplRequest(modClubImplProto.CLUB_GET_GOLD_COIN_TRACES, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubGetGoldCoinTracesReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubGetGoldCoinTracesReply.SUCCESS then
					callback(true, "", implReply)
				elseif implCode == modClubImplProto.ClubGetGoldCoinTracesReply.NO_CLUB then
					callback(false, "俱乐部不存在")
					quiteClubClearWnds()
				else
					callback(false, "获取俱乐部交易信息失败")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

getClubRecords = function(clubId, callback)
	if not clubId then return end
	local request = modLobbyProto.GetAllGameRecordGroupsRequest()
	request.grgc = modLobbyProto.GRGC_GENERAL
	request.page_size = page_size or 100
	request.page_number = page_number or 0
	request.club_id = clubId or -1
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.GET_ALL_GAME_RECORD_GROUPS, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.GetGameRecordGroupsReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.GetGameRecordGroupsReply.SUCCESS then
				callback(true, "", reply)
			elseif code == modLobbyProto.GetGameRecordGroupsReply.FAILURE then
				callback(false, "请求游戏记录失败!")
			end
		else
		end
	end)
end

searchClubByName = function(name, callback)
	local impl = modClubImplProto.ClubLookupByNameRequest()
	impl.club_name = name
	local request = getCallClubImplRequest(modClubImplProto.CLUB_LOOKUP_BY_NAME, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubLookupByNameReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubLookupByNameReply.SUCCESS then
					callback(true, "", implReply)
				else
					callback(false, "没有找到对应的俱乐部。")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end


setClub = function(list, callback)
	local impl = modClubImplProto.ClubSetRequest()
	getClubFromClubInfo(impl.club, list)
	local request = getCallClubImplRequest(modClubImplProto.CLUB_SET, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubSetReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubSetReply.SUCCESS then
					callback(true, "", implReply)
				elseif implCode == modClubImplProto.ClubSetReply.NO_CLUB then
					callback(false, "没有找到对应的俱乐部。")
					quiteClubClearWnds()
				else
					callback(false, "修改俱乐部信息失败")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end

leaveClub = function(id, uid, callback)
	local impl = modClubImplProto.ClubLeaveRequest()
	impl.club_id = id
	impl.user_id = uid
	local request = getCallClubImplRequest(modClubImplProto.CLUB_LEAVE, impl)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modClubProto.CALL_CLUB_IMPL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			callClubImplResult(success, reason, ret, function(success_result, reply)
				local implReply = modClubImplProto.ClubLeaveReply()
				implReply:ParseFromString(reply.club_impl_reply)
				local implCode = implReply.error_code
				if implCode == modClubImplProto.ClubLeaveReply.SUCCESS then
					callback(true, "", implReply)
				elseif implCode == modClubImplProto.ClubLeaveReply.NO_CLUB then
					callback(false, "没有找到对应的俱乐部。")
					quiteClubClearWnds()
				elseif implCode == modClubImplProto.ClubLeaveReply.NO_CLUB_MEMBER then
					callback(false, "没有该玩家")
				elseif implCode == modClubImplProto.ClubLeaveReply.CLUB_CREATOR then
					callback(false, "创建者不能离开俱乐部")
				else
					callback(false, "修改俱乐部信息失败")
				end
			end)
		else
			infoMessage(TEXT("请求服务器失败，请稍后再尝试。"))
		end
	end)
end
