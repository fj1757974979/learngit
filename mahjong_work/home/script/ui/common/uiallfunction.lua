local modSessionMgr = import("net/mgr.lua")
local modRoomProto = import("data/proto/rpc_pb2/room_pb.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modEvent = import("common/event.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modUIUtil = import("ui/common/util.lua")
local modCalculate = import("ui/battle/calculate.lua")
local modFunctionManager = import("ui/common/uifunctionmanager.lua")
local modMainZhuaNiao = import("ui/battle/zhuaniao.lua")
local modEndCalculate = import("ui/battle/endcalculate.lua")
local modDisMissList = import("ui/battle/dismisslist.lua")
local modFlagMenu = import("ui/battle/flags.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modPokerBattleMgr = import("logic/card_battle/main.lua")
local modUserData = import("logic/userdata.lua")

createInstanceBattleMgr = function(roomId, roomHost, roomPort, gameType) 
	logv("warn","createInstanceBattleMgr")
	if gameType == T_MAHJONG_ROOM then
		modBattleMgr.pBattleMgr:instance():enterBattle(roomId, roomHost, roomPort)
	elseif gameType == T_POKER_ROOM then
		modPokerBattleMgr.pBattleMgr:instance():enterBattle(roomId, roomHost, roomPort)
	end
end

enterRoomConvert = function(roomid, reply, isVideo)
	local result = {}
	result[K_ROOM_UIDS] = {}
	result[K_ROOM_PLAYER_IDS] = {}
	result[K_ROOM_ONLINE_INFO] = {}
	local s = ipairs
	if isVideo then
		s = pairs
	end
	local temp = nil
	for idx, userInfo in s(reply.user_infos) do
		if not nil then
			temp = idx
		end
		local uid = userInfo.user_id
		local playerId = userInfo.player_id
		local isOnline = userInfo.is_online
		result[K_ROOM_UIDS][playerId] = uid
		result[K_ROOM_PLAYER_IDS][playerId] = uid
		if uid == modUserData.getUID() then
			result[K_ROOM_MY_PLAYER_ID] = playerId
		end
		result[K_ROOM_ONLINE_INFO][uid] = isOnline
	end
	if isVideo and not result[K_ROOM_MY_PLAYER_ID] then
		result[K_ROOM_MY_PLAYER_ID] = reply.user_infos[temp].player_id
	end
	result[K_ROOM_OWNER] = reply.room_creation_info.owner_user_id
	result[K_ROOM_IS_GAMING] = reply.is_gaming
	result[K_ROOM_STATE] = reply.game_state
	result[K_ROOM_TOTAL_CNT] = reply.room_creation_info.number_of_game_times
	if result[K_ROOM_IS_GAMING] == true then
		result[K_ROOM_CUR_CNT] = reply.game_state.time_count + 1
	else
		result[K_ROOM_CUR_CNT] = 0
	end
	result[K_ROOM_ID] = roomid
	result[K_ROOM_INFO] = reply.room_creation_info
	result[K_USER_INFO] = reply.user_infos
	return result
end


