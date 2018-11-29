local modMajiangGame = import("logic/battle/majianggame.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modBattleMgr = import("logic/battle/main.lua")

pRongchengGame = pRongchengGame or class(modMajiangGame.pMajiangGame)

pRongchengGame.init = function(self, options)
	modMajiangGame.pMajiangGame.init(self, options)
	-- 是否在明牌选牌模式中
	self.isMingPaiSelectMode = false
end

pRongchengGame.getIsMingPaiSelectMode = function(self)
	return self.isMingPaiSelectMode
end

pRongchengGame.destroy = function(self)
	modMajiangGame.pMajiangGame.destroy(self)
	self.isMingPaiSelectMode = false
end

pRongchengGame.openSelectMode = function(self)
	-- 明牌comb选牌
	self.isMingPaiSelectMode = true
end

pRongchengGame.closeSelectMode = function(self)
	self.isMingPaiSelectMode = false
end

pRongchengGame.chooseCardsWork = function(self)
	modMajiangGame.pMajiangGame.chooseCardsWork(self)
	self:openSelectMode()	
	self.battleUI:showChangeSan()
end

pRongchengGame.getIsMingPaiSelectMode = function(self)
	return self.isMingPaiSelectMode
end

pRongchengGame.pretingWork = function(self)
	self.battleUI:showMingGuoWnd()
end

pRongchengGame.getIsShowPhaseBG = function(self)
	return modBattleMgr.getCurBattle():isPhasePiao()
end

pRongchengGame.askCheckGameOver = function(self)
	self:closeSelectMode()
	self.battleUI:clearMingGuo()
	modMajiangGame.pMajiangGame.askCheckGameOver(self)
end

pRongchengGame.getIsShowPhaseWnd = function(self)
	return modBattleMgr.getCurBattle():isPhasePiao()
end

pRongchengGame.autoPlayingClearState = function(self)
	self:closeSelectMode()	
end

pRongchengGame.getIsShuaiQuan = function(self)
	if not self.roomInfo then return end
	if not self.roomInfo.rongcheng_extras then return end
	return self.roomInfo.rongcheng_extras.allow_shuaiquan
end

pRongchengGame.getIsLeaveFromtPhaseJieBao = function(self, top)
	local fromp = self:getCurBattle():getGamePhase()
	if (not self:getCurBattle():isPhaseJieBao()) or (not fromp) then
		return 
	end
	return fromp ~= top
end

pRongchengGame.gamePhaseFunction = function(self, phase)
	if not phase then return end
	local isLeaveJieBao = self:getIsLeaveFromtPhaseJieBao(phase)
	modMajiangGame.pMajiangGame.phaseWork(self, phase)
	if isLeaveJieBao then
		self.battleUI:showJieBaoWnd()
	end
	if self:getCurBattle():isPhaseNormal() then
		return 
	end
	modMajiangGame.pMajiangGame.afterPhaseWork(self, phase)
end

pRongchengGame.personalStart = function(self)
	modMajiangGame.pMajiangGame.personalStart(self)
	self.battleUI:showChangeGuo(false)
	self.battleUI:clearMingGuo()
end

pRongchengGame.getIsSetSpecialPosToDicardPos = function(self)
	return true
end

pRongchengGame.isPlayFlowerCardSound = function(self)
	return false
end

pRongchengGame.isSpecialGuo = function(self, drawCombTexts)
	if not self:getIsShuaiQuan() then return end
	if not drawCombTexts then return end
	if not self:getPlayerHasMingComb() then return end
	-- 取触发玩家pid 找到对应uid 匹配是否是自己自摸
	local modUserData = import("logic/userdata.lua")
	for _, comb in pairs(drawCombTexts) do
		if comb.t == modGameProto.HU then 
			local tpid = comb.trigger_player_id 
			local player = self:getCurBattle():getPlayerByPlayerId(tpid)
			if player:getUid() == modUserData.getUID() then
				return true
			end
		end
	end
	return false
end
