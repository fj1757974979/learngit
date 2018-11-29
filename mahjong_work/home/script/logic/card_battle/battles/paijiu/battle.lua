local modBattleBase = import("logic/card_battle/battle.lua")
local modCardPool = import("logic/card_battle/battles/paijiu/pool.lua")
local modPaijiuPlayer = import("logic/card_battle/battles/paijiu/player.lua")
local modPaijiuTableWnd = import("ui/card_battle/battles/paijiu/table.lua")
local modPaijiuExecutor = import("logic/card_battle/battles/paijiu/executor.lua")
local modPaijiuProto = import("data/proto/rpc_pb2/pokers/paijiu_pb.lua")
local modCreate = import("logic/card_battle/create.lua")

pPaijiuBattle = pPaijiuBattle or class(modBattleBase.pBattleBase)

pPaijiuBattle.newPlayer = function(self, userId, playerId, battle)
	return modPaijiuPlayer.pPaijiuPlayer:new(userId, playerId, battle)
end

pPaijiuBattle.newFakePlayer = function(self, userId, playerId, battle)
	return modPaijiuPlayer.pPaijiuFakePlayer:new(userId, playerId, battle)
end

pPaijiuBattle.newObserver = function(self, userId, playerId, battle)
	return modPaijiuPlayer.pPaijiuObserver:new(userId, playerId, battle)
end

pPaijiuBattle.getRoomDesc = function(self)
	return modCreate.getRoomDesc(self.createInfo)
end

pPaijiuBattle.getTurnDesc = function(self)
	if self:isKzwf() then
		if self:getCurTurnNum() <= 0 then
			return ""
		else
			return sf("第%d局", self:getCurTurnNum())
		end
	else
		return modBattleBase.pBattleBase.getTurnDesc(self)
	end
end

pPaijiuBattle.getGameName = function(self)
	return TEXT("牌九")
end

pPaijiuBattle.getGameVoiceName = function(self)
	return "paijiu"
end

pPaijiuBattle.newTableWnd = function(self)
	return modPaijiuTableWnd.pPaijiuTableWnd:new(self)
end

pPaijiuBattle.newExecutorMgr = function(self)
	return modPaijiuExecutor.pPaijiuBattleExecutorMgr:new(self)
end

pPaijiuBattle.isKzwf = function(self)
	if self.gameMode == nil then
		local createParam = modPaijiuProto.PaijiuCreateParam()
		createParam:ParseFromString(self.gameParam)
		self.gameMode = createParam.game_mode
	end
	return self.gameMode == modPaijiuProto.PaijiuCreateParam.GAME_KZWF
end

pPaijiuBattle.getMenuParent = function(self)
	return self:getTableWnd():getMenuParent()
end

pPaijiuBattle.setPlayerBets = function(self, userIds, bets, bets2)
	for idx, userId in ipairs(userIds) do
		local player = self:getPlayer(userId)
		if player then
			player:setBet(bets[idx])
			player:setBet2(bets2[idx])
		end
	end
end

pPaijiuBattle.isLastTurn = function(self)
	if self:isKzwf() then
		return false
	else
		return modBattleBase.pBattleBase.isLastTurn(self)
	end
end

pPaijiuBattle.shouldResetBankerOnReset = function(self)
	return not self:isKzwf()
end

pPaijiuBattle.updateTableCards = function(self, cardInfos)
	if not self.battleCardPool then
		self.battleCardPool = modCardPool.pPaijiuTableCardPool:new(self)
	end
	self.battleCardPool:reset()
	local tableWnd = self:getTableWnd()
	for idx, cardInfo in ipairs(cardInfos) do
		local card = self.battleCardPool:addCard(cardInfo.card_id)
		card:getCardWnd():setShowState(cardInfo.state)
		if tableWnd then
			tableWnd:updateTableCard(idx, card)
		end
	end
end

pPaijiuBattle.initBattleUI = function(self)
	modBattleBase.pBattleBase.initBattleUI(self)
	if self.battleCardPool then
		local cards = self.battleCardPool:getAllCards()
		local tableWnd = self:getTableWnd()
		for idx, card in ipairs(cards) do
			tableWnd:updateTableCard(idx, card)
		end
	end
end

pPaijiuBattle.onNotifyCardChange = function(self, info)
	local userId = info.user_id
	local handCardIdx = info.src_card_idx
	local poolCardIdx = info.dst_card_idx
	local handCardId = info.src_card_id
	local poolCardId = info.dst_card_id
	local pjType = info.hand_type
	local player = self:getPlayer(userId)
	if player then
		local handPool = player:getHandCardPool()
		if handPool then
			handPool:refreshCard(handCardIdx, handCardId)
			player:setPjType(pjType)
		end
		local battlePool = self.battleCardPool
		battlePool:refreshCard(poolCardIdx, poolCardId)
	end
end

pPaijiuBattle.destroy = function(self)
	modBattleBase.pBattleBase.destroy(self)
	if self.battleCardPool then
		self.battleCardPool:destroy()
		self.battleCardPool = nil
	end
end
