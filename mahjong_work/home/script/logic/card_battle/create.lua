local modNiuniuProto = import("data/proto/rpc_pb2/pokers/niuniu_pb.lua")
local modPaijiuProto = import("data/proto/rpc_pb2/pokers/paijiu_pb.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modUtil = import("util/util.lua")

local ruleTypeInfo = {
	niuniu = {
		max_users = 5,
		t = modLobbyProto.NIUNIU,
	},
	paijiu_kzwf = {
		max_users = 4,
		t = modLobbyProto.PAIJIU,
	},
	paijiu_mpqz = {
		max_users = 4,
		t = modLobbyProto.PAIJIU,
	},
}

createNiuniuParam = function(valueList, ruleType)
	--[[
	message NiuniuCreateParam
	{
		enum GameMode { // 算分模式
			GAME_CLASSIC = 0; // 经典
			GAME_INSANE = 1;   // 加倍
		}

		enum BankerMode { // 庄闲模式
			BANKER_STRIVE = 0; // 抢庄
			BANKER_IN_TURN = 1; // 轮庄
			BANKER_FIXED = 2; // 固定庄
		}

		enum BetMode { // 倍率模式
			BET_FIXED = 0; // 固定倍率
			BET_CHOOSE = 1; // 可选倍率
		}

		enum BetRate {
			BET_1_to_3 = 0; // 1、2、3倍
			BET_1_2 = 1; // 1、2倍
			BET_2_4 = 2; // 2、4倍
			BET_4_8 = 3; // 4、8倍
		}

		optional GameMode game_mode = 1 [default = GAME_CLASSIC];
		optional BankerMode banker_mode = 2 [default = BANKER_IN_TURN];
		optional BetMode bet_mode = 3 [default = BET_CHOOSE];
		optional BetRate bet_rate = 4 [default = BET_1_to_3];
	}
	]]--

	local param = modNiuniuProto.NiuniuCreateParam()
	param.game_mode = valueList["game_mode"]
	param.banker_mode = valueList["banker_mode"]
	param.bet_rate = valueList["bet_rate"] or 0
	param.bet_mode = 0
	return param:SerializeToString()
end

createPaijiuParam = function(valueList, ruleType)
	--[[
	message PaijiuCreateParam
	{
		enum GameMode { // 玩法模式
			GAME_KZWF = 0; // 开庄玩法
			GAME_MPQZ = 1; // 明牌抢庄
		}

		enum DoubleType {
			DOUBLE_NONE = 0; // 无翻
			DOUBLE_NORMAL = 1; // 标翻
			DOUBLE_CRAZY = 2; // 豪翻
		}

		enum TianJiuWangType {
			TIANJIU_IS_WANG = 0; // 天九为大
			TIANJIU_IS_ONE = 1; // 天九为一
		}

		enum BankerMode { // 庄家模式
			BANKER_STRIVE = 0; // 抢庄
			BANKER_RANDOM = 1; // 随机为庄
			BANKER_FIXED = 2; // 房主为庄
		}

		required GameMode game_mode = 1;
		optional uint32 max_grab_rate = 2 [default = 1]; // 抢庄倍数
		optional uint32 antes_rate = 3;	// 下注倍数范围 1,1--4  2,5--8
		optional uint32 tui_antes_rate = 4 [default = 0]; // 推注倍数
		optional DoubleType double_type = 5 [default = DOUBLE_NONE]; // 翻倍类型
		optional uint32 init_banker_score = 6 [default = 100]; // 开庄分数
		optional TianJiuWangType tianjiu_type = 7 [default = TIANJIU_IS_WANG]; // 天九为大或一
		required BankerMode banker_mode = 8; // 庄家模式
	}
	]]--

	local param = modPaijiuProto.PaijiuCreateParam()
	param.game_mode = valueList["game_mode"]
	if ruleType == "paijiu_kzwf" then
		-- kzwf
		param.init_banker_score = valueList["init_banker_score"]
		param.banker_mode = valueList["banker_mode"]
		param.tianjiu_type = valueList["tianjiu_type"]
	else
		-- mpqz
		param.max_grab_rate = valueList["max_grab_rate"]
		param.antes_rate = valueList["antes_rate"]
		param.tui_antes_rate = valueList["tui_antes_rate"]
		param.double_type = valueList["double_type"]
		param.banker_mode = 0
	end
	return param:SerializeToString()
end

genCreatePokerRoomRequest = function(valueList, ruleType, request)
	--[[
	message CreatePokerRoomRequest
	{
		enum RoomType {
			NORMAL = 0; // 普通房间
			SHARED = 1; // 代开房间
			AA = 2; // 普通房间
			MATCH = 3; // 匹配房间
		}
		optional uint32 owner_user_id = 1; // 房主
		required RoomType room_type = 2; // 房间类型
		required PokerType poker_type = 3; // 牌类型
		required uint32 max_number_of_users = 4; // 房间满员人数
		required uint32 number_of_game_times = 5; // 打多少局
		required bytes create_param = 6; // 创建参数
	}
	]]--

	logv("info", valueList, ruleType)

	request = request or modLobbyProto.CreatePokerRoomRequest()
	request.room_type = valueList["room"]
	request.poker_type = ruleTypeInfo[ruleType].t
	request.max_number_of_users = ruleTypeInfo[ruleType].max_users
	request.number_of_game_times = valueList["round"] or 1
	request.dibei = valueList["dibei"] or 1
	if ruleType == "niuniu" then
		request.create_param = createNiuniuParam(valueList, ruleType)
	elseif ruleType == "paijiu_kzwf" or ruleType == "paijiu_mpqz" then
		request.create_param = createPaijiuParam(valueList, ruleType)
	end
	request.group_id = valueList["grpId"] or -1
	return request
end

getRoomTypeDesc = function(roomType)
	local roomTypeName = {
		"普通房间",
		"代开房间",
		"AA房间",
		"匹配房间",
		"俱乐部房间",
	}
	return roomTypeName[roomType + 1]
end

getRoomDesc = function(createInfo, noRoomTypeStr)
	local pokerType = createInfo.poker_type
	local roomType = getRoomTypeDesc(createInfo.room_type)
	if noRoomTypeStr then
		roomType = ""
	end
	if pokerType == modLobbyProto.NIUNIU then
		local gameMode = { "经典模式", "疯狂加倍"}
		local bankerMode = {"抢庄", "轮庄", "固定庄"}
		local createParam = modNiuniuProto.NiuniuCreateParam()
		createParam:ParseFromString(createInfo.create_param)
		return sf("%s %s %s", roomType, gameMode[createParam.game_mode + 1], bankerMode[createParam.banker_mode + 1])

	elseif pokerType == modLobbyProto.PAIJIU then
		local gameMode = { "开庄玩法", "明牌抢庄"}
		local doubleType = {"无翻", "标翻", "豪翻"}
		local tianjiuType = {"天九为大", "天九为一"}
		local bankerMode = {"抢庄", "随机为庄", "房主为庄"}

		local createParam = modPaijiuProto.PaijiuCreateParam()
		createParam:ParseFromString(createInfo.create_param)

		local gameModeStr = gameMode[createParam.game_mode + 1]
		local bankerModeStr = bankerMode[createParam.banker_mode + 1]
		if createParam.game_mode == modPaijiuProto.PaijiuCreateParam.GAME_KZWF then
			local tianjiuTypeStr = tianjiuType[createParam.tianjiu_type + 1]
			local bankerScoreStr = sf(TEXT("开庄%d分"), createParam.init_banker_score)
			return sf("%s %s %s %s %s", roomType, gameModeStr, bankerScoreStr, tianjiuTypeStr, bankerModeStr)
		else
			local doubleTypeStr = doubleType[createParam.double_type + 1]
			return sf("%s %s %s %s", roomType, gameModeStr, doubleTypeStr, bankerModeStr)
		end

	else
		return ""
	end
end

getClubRoomDesc = function(createInfo)
	local ruleStr = getRoomDesc(createInfo, true)
	if createInfo.poker_type == modLobbyProto.NIUNIU then
		ruleStr = sf("%d局 %s", createInfo.number_of_game_times, ruleStr)
		local opChannel = modUtil.getOpChannel()
		if opChannel == "nc_tianjiuwang" or
			opChannel == "test" then
			ruleStr = sf("%s\n【金豆低于入场数一半时会离开房间】", ruleStr)
		end
	end
	return ruleStr
end

needRateWnd = function(createInfo)
	local pokerType = createInfo.poker_type
	if not pokerType then
		return true
	elseif pokerType == modLobbyProto.NIUNIU then
		return true
	else
		return false
	end
end

