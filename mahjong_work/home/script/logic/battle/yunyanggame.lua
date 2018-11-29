local modMajiangGame = import("logic/battle/majianggame.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")

pYunyangGame = pYunyangGame or class(modMajiangGame.pMajiangGame)

pYunyangGame.init = function(self, options)
	modMajiangGame.pMajiangGame.init(self, options)
	self.changeSanZhangIds = {}
end

pYunyangGame.setChangeSanZhangIds = function(self, ids)
	if not ids then return end
	self.changeSanZhangIds = ids
end

pYunyangGame.getChangeSanZhangIds = function(self)
	return self.changeSanZhangIds
end

pYunyangGame.getIsHuansanzhang = function(self)
	return self:getCurBattle():isPhaseHuanSanZhang()
end

pYunyangGame.clearChangeSanIds = function(self)
	self.changeSanZhangIds = {}
end

pYunyangGame.askCheckGameOver = function(self)
	self.changeSanZhangIds = {}	
	modMajiangGame.pMajiangGame.askCheckGameOver(self)
end

pYunyangGame.chooseCardsWork = function(self)
	--
	modMajiangGame.pMajiangGame.chooseCardsWork(self)
	self.battleUI:showChangeSan()
	-- 建议换牌
	self.battleUI:priorityHuan()
	-- 压暗
	self.battleUI:notChangeCardsSetTingColor()

end

pYunyangGame.destroy = function(self)
	modMajiangGame.pMajiangGame.destroy(self)
	self.changeSanZhangIds = {}
end

pYunyangGame.getIsDingQue = function(self)
	if not self.roomInfo then return end
	-- 云阳定缺
	if self.roomInfo.yunyang_extras then
		return self.roomInfo.yunyang_extras.dingque and self:getCurBattle():isPhaseDingQue()
	end
	return false
end

pYunyangGame.isSelectedHuanSanZhang = function(self, p)
	if not self:getIsHuansanzhang() then return end
	local player = self:getCurPlayer()
	if p then player = p end 
	local cards = player:getAllCardsFromPool(T_POOL_DISCARD)
	return table.size(cards) == 3
end

pYunyangGame.isQueFlag = function(self, f)
	if self:isQueTongFlag(f) or self:isQueSuoFlag(f) or self:isQueWanFlag(f) then
		return f
	end
	return nil
end

pYunyangGame.autoPlayingClearState = function(self)
	self:clearChangeSanIds()
end

pYunyangGame.phaseWork = function(self, gamePhase)
	if not gamePhase then return end
	modMajiangGame.pMajiangGame.phaseWork(self, gamePhase)
	self.battleUI:setPhaseInitPiaoWnds()	
end

pYunyangGame.isQueTongFlag = function(self, f)
	if f then
		return f == modGameProto.YUNYANG_QUE_TONG
	end
	
	local player = self:getCurBattle():getMyPlayer()
	local flags = player:getFlags()
	for _, f in pairs(flags) do
		if f == modGameProto.YUNYANG_QUE_TONG then 
			return true
		end
	end
	return false
end

pYunyangGame.isQueSuoFlag = function(self, f)
	if f then
		return f == modGameProto.YUNYANG_QUE_SUO
	end
	
	local player = self:getCurBattle():getMyPlayer()
	local flags = player:getFlags()
	for _, f in pairs(flags) do
		if f == modGameProto.YUNYANG_QUE_SUO then 
			return true
		end
	end
	return false
end

pYunyangGame.isQueWanFlag = function(self, f)
	if f then
		return f == modGameProto.YUNYANG_QUE_WAN
	end
	local player = self:getCurBattle():getMyPlayer()
	local flags = player:getFlags()
	for _, f in pairs(flags) do
		if f == modGameProto.YUNYANG_QUE_WAN then 
			return true
		end
	end
	return false
end

pYunyangGame.getSelfHasQue = function(self, p)
	local player = self:getCurBattle():getMyPlayer()
	if p then player = p end
	local flags = player:getFlags()
	for _, f in pairs(flags) do
		if self:isQueFlag(f) then
			return f
		end
	end
	return
end

pYunyangGame.updateCardPoolUpdate = function(self, message)
	if not message then return end
	modMajiangGame.pMajiangGame.updateCardPoolUpdate(self, message)
	-- 换三张	
	local battle = self:getCurBattle()
	local poolType = message.t
	local playerId = message.player_id
	local seatId = battle:getSeatByPlayerId(playerId)
	if battle:isPhaseHuanSanZhang() then
		if poolType == modGameProto.HELD_CARD_POOL then
			if playerId == battle:getMyPlayerId() then
				local cards = {} 
				for _, set in ipairs(message.add_set or {}) do
					for _, id in ipairs(set.card_ids) do
						table.insert(cards, id)
					end
				end
				if cards and table.getn(cards) == 3 then
					local tCards = {}
					for _, id in ipairs(cards) do
						table.insert(tCards, id)
					end
					self:setChangeSanZhangIds(tCards)
				end
			end
		elseif poolType == modGameProto.DISCARDED_CARD_POOL then
			local cards = {} 
			for _, set in ipairs(message.add_set or {}) do
				for _, id in ipairs(set.card_ids) do
					table.insert(cards, id)
				end
			end
			if cards and table.getn(cards) == 3 then
				self.battleUI:showPiaoWndBySeatId(seatId, false)
			end
		end
	end
end

pYunyangGame.resortYunYang = function(self)
	local pool = self:getCurPlayer():getHandPool()
	pool:sort()
end

pYunyangGame.afterSetParseGame = function(self)
	self:resortYunYang()
end

pYunyangGame.getIsShowPhaseWnd = function(self)
	return self:getCurBattle():isPhaseDingQue()
end

pYunyangGame.getIsShowPhaseBG = function(self)
	return true
end

pYunyangGame.personalStart = function(self)
	-- 是否有缺flag
	self.battleUI:hasQueFlagSetColor()
end

pYunyangGame.addFlagWork = function(self, flag, player)
	if not flag or not player then return end
	if self:getIsDingQue() then
		if self:isQueFlag(flag) then
			self.battleUI:queFlagChangeWndProp(player:getSeat(), true)
			self.battleUI:updateQueFlagWnds()
		end
	end
end

pYunyangGame.afterPhaseWork = function(self, phase)
	modMajiangGame.pMajiangGame.afterPhaseWork(self, phase)
	self.battleUI:showPhaseTipWnd(phase)
end

pYunyangGame.updateSpeicalFlag = function(self, player)
	modMajiangGame.pMajiangGame.updateSpeicalFlag(self, player)
	-- 更新自己缺牌后手牌排序
	if self:getSelfHasQue() and player:getPlayerId() == self:getCurBattle():getMyPlayerId() then
		self:resortYunYang()
		self.battleUI:updatePlayerFrontCards(self:getCurBattle():getCurPlayer())
		self.battleUI:setHandCardTingColor()
	end
--[[	-- 检测是否所有人都定完缺
	if not self:getIsDingQue() then return end
	local players = modBattleMgr.getCurBattle():getAllPlayers()
	local isOver = true
	for _, player in pairs(players) do
		if not self:getSelfHasQue(player) then
			isOver = false
			break
		end
	end
	-- 有人没定缺
	if not isOver then return end
	self.battleUI:updatePiaoText(players)	]]--
end

