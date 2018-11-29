local modVideoParser = import("logic/card_battle/videos/parser.lua")
local modUserData = import("logic/userdata.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modPokerUtil = import("logic/card_battle/util.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modPaijiuProto = import("data/proto/rpc_pb2/pokers/paijiu_pb.lua")
local modNiuniuProto = import("data/proto/rpc_pb2/pokers/niuniu_pb.lua")

pRecordItemBase = pRecordItem or class(pWindow)

pRecordItemBase.init = function(self, playerInfo, score, gameInfo, createParam)
	self.isBanker = playerInfo.isBanker
	self.playerInfo = playerInfo
	self.score = score
	self.gameInfo = gameInfo
	self.createParam = createParam
	self:load(self:getTemplate())
	self:handlePlayerInfo()
	self:handleCalcInfo()
	self:handleGameInfo()
end

pRecordItemBase.getTemplate = function(self)
	return "data/ui/card/video_entry_card.lua"
end

pRecordItemBase.handlePlayerInfo = function(self)
	local info = self.playerInfo
	self.icon_zhuang:show(self.isBanker)
	self.wnd_image:setImage(info.avatarUrl)
	self.wnd_name:setText(info.name)
	if info.userId == modUserData.getUID() then
		self.wnd_name:getTextControl():setColor(0xFF800000)
	end
end

pRecordItemBase.handleCalcInfo = function(self)
	if self.score > 0 then
		self.wnd_score:setText(sf("+%d", self.score))
	elseif self.score == 0 then
		self.wnd_score:setText(0)
	else
		self.wnd_score:setText(tostring(self.score))
	end
end

pRecordItemBase.handleGameInfo = function(self)
end
-----------------------------
pNiuniuRecordItem = pNiuniuRecordItem or class(pRecordItemBase)

pNiuniuRecordItem.handleGameInfo = function(self)
	local info = self.gameInfo
	if self.isBanker then
		if info.grabingOrNot then
			self.wnd_info1:setText(TEXT("抢庄"))
		else
			self.wnd_info1:setText(TEXT("不抢"))
		end
	else
		self.wnd_info1:setText(sf(TEXT("底x%d"), info.bet))
	end
	local cardw = 53
	local cardh = 63
	local cardgap = 15
	local cardIds = info.cardIds
	for idx, cardId in ipairs(cardIds) do
		local img = modPokerUtil.getPokerCardImage(cardId)
		local wnd = pWindow:new()
		wnd:setImage(img)
		wnd:setParent(self.wnd_card_bottom)
		wnd:setSize(cardw, cardh)
		wnd:setPosition((idx - 1) * cardgap, 0)
		wnd:setAlignY(ALIGN_TOP)
	end
	self.wnd_type:setText(modPokerUtil.getNiuNameByType(info.handType))
end
-----------------------------
pPaijiuRecordItem = pPaijiuRecordItem or class(pRecordItemBase)

pPaijiuRecordItem.handleGameInfo = function(self)
	local info = self.gameInfo
	local gameMode = self.createParam.game_mode
	if self.isBanker then
		if gameMode == modPaijiuProto.PaijiuCreateParam.GAME_KZWF then
		else
			local grabRate = info.grabRate
			if grabRate == 0 then
				self.wnd_info1:setText(TEXT("不抢"))
			else
				self.wnd_info1:setText(sf(TEXT("抢x%d"), grabRate))
			end
		end
	else
		if gameMode == modPaijiuProto.PaijiuCreateParam.GAME_KZWF then
			self.wnd_info1:setText(sf(TEXT("头套%d"), info.antes1))
			self.wnd_info2:setText(sf(TEXT("二套%d"), info.antes2))
		else
			local grabRate = info.grabRate
			if grabRate == 0 then
				self.wnd_info1:setText(TEXT("不抢"))
			else
				self.wnd_info1:setText(sf(TEXT("抢x%d"), grabRate))
			end
			self.wnd_info2:setText(sf(TEXT("底x%d"), info.antes1))
		end
	end
	local cardw = 57
	local cardh = 138 local cardgap = 60
	local cardIds = info.cardIds
	for idx, cardId in ipairs(cardIds) do
		local img = modPokerUtil.getPaijiuCardImage(cardId)
		local wnd = pWindow:new()
		wnd:setImage(img)
		wnd:setParent(self.wnd_card_bottom)
		wnd:setSize(cardw, cardh)
		wnd:setPosition((idx - 1) * cardgap, 0)
		wnd:setAlignY(ALIGN_MIDDLE)
	end
	self.wnd_type:setText(modPokerUtil.getPaijiuHandTypeName(info.handType, cardIds))
end
-----------------------------------------------------------



-----------------------------------------------------------
local pokerType2RecordItemCls = {
	[modLobbyProto.NIUNIU] = pNiuniuRecordItem,
	[modLobbyProto.PAIJIU] = pPaijiuRecordItem,
}

pRecordWnd = pRecordWnd or class(pWindow)

pRecordWnd.init = function(self, idx, recordInfo, playersInfo, groupParam)
	self:load("data/ui/card/video_entry.lua")
	self.playersInfo = playersInfo
	self.idx = idx
	self.cardWidth = 240
	self.groupInfo = groupParam.groupInfo
	self.createInfo = groupParam.createInfo
	self.createParam = groupParam.createParam
	self.pokerType = groupParam.pokerType
	self.parser = modVideoParser.newRecordParser(self.pokerType, recordInfo)
	self:initUI()
	self:fetchRecordData()
end

pRecordWnd.newRecordItem = function(self, playerInfo, score, gameInfo, createParam)
	local cls = pokerType2RecordItemCls[self.pokerType]
	if cls then
		return cls:new(playerInfo, score, gameInfo, createParam)
	else
		return nil
	end
end

pRecordWnd.initUI = function(self)
	self.wnd_round:setText(sf("第%d局", self.idx))
	self.wnd_time:setText(sf("录像时间：%s", self.parser:getCreateDateStr()))
end

pRecordWnd.fetchRecordData = function(self)
	local recordId = self.parser:getRecordId()
	modBattleRpc.getGameVideo(recordId, function(success, reason, ret)
		if success then
			local recordInfos = self.parser:parseRecordData(ret.data)
			local gameInfos = recordInfos.userInfos
			local bankerUserId = recordInfos.bankerUserId
			local scoreInfos = self.parser:getCalcData()
			--logv("info", gameInfos)
			local playerCnt = #self.playersInfo
			self.wnd_list:setSize(self.cardWidth * playerCnt, self.wnd_list:getHeight())
			for idx, info in ipairs(self.playersInfo) do
				local userId = info.userId
				if userId == bankerUserId then
					info["isBanker"] = true
				else
					info["isBanker"] = false
				end
				local wnd = self:newRecordItem(info, scoreInfos[userId], gameInfos[userId], self.createParam)
				wnd:setParent(self.wnd_list)
				wnd:setPosition((idx - 1) * self.cardWidth, 0)
			end
		else
			infoMessage(reason)
		end
	end)
end
