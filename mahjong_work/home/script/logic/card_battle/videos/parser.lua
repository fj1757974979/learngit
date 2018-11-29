local modPokerProto = import("data/proto/rpc_pb2/pokers/poker_pb.lua")
local modNiuniuProto = import("data/proto/rpc_pb2/pokers/niuniu_pb.lua")
local modPaijiuProto = import("data/proto/rpc_pb2/pokers/paijiu_pb.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modUIUtil = import("ui/common/util.lua")

pGroupParserBase = pGroupParserBase or class()

pGroupParserBase.init = function(self, createInfo, groupInfo)
	self.createInfo = createInfo
	self.groupInfo = groupInfo
	self.players = {}
	self.createParam = self:parseCreateParam()
end

pGroupParserBase.getGroupId = function(self)
	return self.groupInfo.id
end

pGroupParserBase.getGroupInfo = function(self)
	return self.groupInfo
end

pGroupParserBase.getRoomId = function(self)
	return self.groupInfo.room_id
end

pGroupParserBase.getRoomCreateDateStr = function(self)
	return os.date("%m-%d %H:%M", self.groupInfo.room_created_date)
end

pGroupParserBase.getPokerType = function(self)
	return self.createInfo.poker_type
end

pGroupParserBase.getName = function(self)
	log("error", "[pGroupParserBase.getName] not implemented!")
end

pGroupParserBase.getGroupParam = function(self)
	return {
		createInfo = self.createInfo,
		groupInfo = self.groupInfo,
		createParam = self.createParam,
		pokerType = self.createInfo.poker_type,
	}
end

pGroupParserBase.initPlayers = function(self, callback)
	local userIds = {}
	for _, userId in ipairs(self.groupInfo.user_ids) do
		table.insert(userIds, userId)
	end
	local props = {"gender", "avatarurl", "name"}
	modBattleRpc.getMultiUserProps(userIds, props, function(success, reason, ret)
		if not success then
			infoMessage(reason)
		else
			for _, prop in ipairs(ret.multi_user_props) do
				local userId = prop.user_id
				local gender = prop.gender
				local avatarUrl = prop.avatar_url
				if not avatarUrl or avatarUrl == "" then
					avatarUrl = modUIUtil.getDefaultImage(gender)
				end
				local name = prop.nickname
				if modUIUtil.utf8len(name) > 6 then
					name = modUIUtil.getMaxLenString(name, 6)
				end
				table.insert(self.players, {
					userId = userId,
					gender = gender,
					name = name,
					avatarUrl = avatarUrl,
				})
			end
			if callback then
				callback()
			end
		end
	end)
end

pGroupParserBase.getPlayerInfos = function(self)
	return self.players
end

pGroupParserBase.parseEndCalcData = function(self, message)
	local infos = {}
	local userIds = {}
	for _, userId in ipairs(message.user_ids) do
		table.insert(userIds, userId)
	end
	local scores = {}
	for _, score in ipairs(message.win_scores) do
		table.insert(scores, score)
	end
	for idx, userId in ipairs(userIds) do
		infos[userId] = scores[idx]
	end
	return infos
end

pGroupParserBase.getEndCalcData = function(self)
	log("error", "[pGroupParserBase.getEndCalcData] not implemented!")
end
-----------------------------
pNiuniuGroupParser = pNiuniuGroupParser or class(pGroupParserBase)

pNiuniuGroupParser.parseCreateParam = function(self)
	local createParam = self.createInfo.create_param
	local message = modNiuniuProto.NiuniuCreateParam()
	message:ParseFromString(createParam)
	return message
end

pNiuniuGroupParser.getName = function(self)
	return TEXT("牛牛")
end

pNiuniuGroupParser.getEndCalcData = function(self)
	local message = modNiuniuProto.NNTableEndData()
	message:ParseFromString(self.groupInfo.room_closure_info)
	return self:parseEndCalcData(message)
end
-----------------------------
pPaijiuGroupParser = pPaijiuGroupParser or class(pGroupParserBase)

pPaijiuGroupParser.parseCreateParam = function(self)
	local createParam = self.createInfo.create_param
	local message = modPaijiuProto.PaijiuCreateParam()
	message:ParseFromString(createParam)
	return message
end

pPaijiuGroupParser.getName = function(self)
	if self.createParam.game_mode == modPaijiuProto.PaijiuCreateParam.GAME_KZWF then
		return TEXT("开庄玩法")
	else
		return TEXT("明牌抢庄")
	end
end

pPaijiuGroupParser.getEndCalcData = function(self)
	local message = modPaijiuProto.PJTableEndData()
	message:ParseFromString(self.groupInfo.room_closure_info)
	return self:parseEndCalcData(message)
end
-----------------------------------------------------------



-----------------------------------------------------------
pRecordParserBase = pRecordParserBase or class()

pRecordParserBase.init = function(self, recordInfo)
	self.recordInfo = recordInfo
end

pRecordParserBase.getRecordId = function(self)
	return self.recordInfo.id
end

pRecordParserBase.getCreateDateStr = function(self)
	return os.date("%m-%d %H:%M", self.recordInfo.started_date)
end

pRecordParserBase.getCalcData = function(self)
	log("error", "[pRecordParserBase.getCalcData] not implemented!!")
end

pRecordParserBase.parseCalcData = function(self, message)
	local infos = {}
	for _, info in ipairs(message) do
		infos[info.user_id] = info.score_modify
	end
	return infos
end

pRecordParserBase.parseRecordData = function(self, data)
	local message = modPokerProto.DefaultRecordData()
	message:ParseFromString(data)
	local infos = {}
	infos["bankerUserId"] = message.banker_user_id
	infos["userInfos"] = {}
	for _, info in ipairs(message.user_data) do
		local _info = {}
		_info["userId"] = info.uer_id
		_info["handType"] = info.hand_type
		_info["cardIds"] = {}
		for _, cardId in ipairs(info.card_ids) do
			table.insert(_info["cardIds"], cardId)
		end
		self:parseGameData(_info, info.gaming_data)
		infos["userInfos"][info.user_id] = _info
	end
	return infos
end

pRecordParserBase.parseGameData = function(self, collect, data)
	log("error", "[pRecordParserBase.parseGameData] not implemented!!")
end
-----------------------------
pNiuniuRecordParser = pNiuniuRecordParser or class(pRecordParserBase)

pNiuniuRecordParser.getCalcData = function(self)
	local message = modNiuniuProto.NNTableCalcData()
	message:ParseFromString(self.recordInfo.game_over_info)
	return self:parseCalcData(message.data)
end

pNiuniuRecordParser.parseGameData = function(self, collect, data)
	if not data then
		return
	end
	local message = modNiuniuProto.DefNiuniuRecordData()
	message:ParseFromString(data)
	collect["bet"] = message.bet
	collect["grabingOrNot"] = message.grabing_or_not
end
-----------------------------
pPaijiuRecordParser = pPaijiuRecordParser or class(pRecordParserBase)

pPaijiuRecordParser.getCalcData = function(self)
	local message = modPaijiuProto.PJTableCalcData()
	message:ParseFromString(self.recordInfo.game_over_info)
	return self:parseCalcData(message.calc_infos)
end

pPaijiuRecordParser.parseGameData = function(self, collect, data)
	if not data then
		return
	end
	local message = modPaijiuProto.DefPaijiuRecordData()
	message:ParseFromString(data)
	collect["grabRate"] = message.grab_rate
	collect["antes1"] = message.antes1
	collect["antes2"] = message.antes2
end
-----------------------------------------------------------



-----------------------------------------------------------
local pokerTypeToGroupParserCls = {
	[modLobbyProto.NIUNIU] = pNiuniuGroupParser,
	[modLobbyProto.PAIJIU] = pPaijiuGroupParser,
}

newGroupParser = function(groupInfo)
	local createData = groupInfo.room_creation_info
	local message = modLobbyProto.CreatePokerRoomRequest()
	message:ParseFromString(createData)
	local pokerType = message.poker_type
	local cls = pokerTypeToGroupParserCls[pokerType]
	if cls then
		return cls:new(message, groupInfo)
	else
		return nil
	end
end
-----------------------------
local pokerTypeToRecordParserCls = {
	[modLobbyProto.NIUNIU] = pNiuniuRecordParser,
	[modLobbyProto.PAIJIU] = pPaijiuRecordParser,
}

newRecordParser = function(pokerType, recordInfo)
	local cls = pokerTypeToRecordParserCls[pokerType]
	if cls then
		return cls:new(recordInfo)
	else
		return nil
	end
end
-----------------------------------------------------------
