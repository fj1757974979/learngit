local modMajiangGame = import("logic/battle/majianggame.lua")
local modBattleMgr = import("logic/battle/main.lua")

pXiangyangGame = pXiangyangGame or class(modMajiangGame.pMajiangGame)

pXiangyangGame.init = function(self, options)
	modMajiangGame.pMajiangGame.init(self, options)
	-- 选择扣牌的index
	self.koupaiIndex = nil
	-- 明牌combs
	self.mingPaiCombs = {}
	-- 明comb选牌
	self.hasMingCombSelectMode = false
end

pXiangyangGame.updateShowCombsUpdate = function(self, message)
	if not message then return end
	local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
	modMajiangGame.pMajiangGame.updateShowCombsUpdate(self, message)
	-- 卡五星服务器帮我打出mingcomb
	for _, comb in ipairs(message.added_combs) do
		if not self:isKawuxingMJ() then
			break
		end
		if comb.t == modGameProto.MING then
			self:clearDiscardBeforPorto()
		end
	end
end

pXiangyangGame.askCheckGameOver = function(self)
	self:closeSlecteMode()	
	self.koupaiIndex = nil
	self.battleUI:clearCanelBtn()
	self.battleUI:clearMingGuo()
	modMajiangGame.pMajiangGame.askCheckGameOver(self)
end

pXiangyangGame.setKoupaiIndex = function(self, idx)
	self.koupaiIndex = idx
end

pXiangyangGame.pretingWork = function(self)
	self.battleUI:showMingGuoWnd()
end

pXiangyangGame.getKoupaiIndex = function(self)
	return self.koupaiIndex
end

pXiangyangGame.destroy = function(self)
	modMajiangGame.pMajiangGame.destroy(self)
	self.koupaiIndex= nil
	self:closeSlecteMode()
end

pXiangyangGame.getIsMingCombSelectMode = function(self)
	return self.hasMingCombSelectMode
end

pXiangyangGame.askCombHasMingWork = function(self, combs)
	self:openSelectMode(combs)
end

pXiangyangGame.autoPlayingClearState = function(self)
	self:closeSlecteMode()	
end

pXiangyangGame.personalStart = function(self)
	modMajiangGame.pMajiangGame.personalStart(self)
	self.battleUI:clearMingGuo()
end

pXiangyangGame.openSelectMode = function(self, combs)
	if not combs then return end
	-- 设置匹配combs
	self:setMingPaiCombs(combs)
	-- 明牌comb选牌
	self.hasMingCombSelectMode = true
	-- 不能选的牌压暗
	self.battleUI:notSelectCardSetTingColorWork()
end

pXiangyangGame.closeSlecteMode = function(self)
	self.hasMingCombSelectMode = false
	self:clearMingPaiCombs()
end

pXiangyangGame.setMingPaiCombs = function(self, combs)
	if not combs then return end
	self.mingPaiCombs = combs
end

pXiangyangGame.getMingPaiCombs = function(self)
	return self.mingPaiCombs
end

pXiangyangGame.pretingEvent = function(self, combs, combWnd)
	if not combs or not combWnd then return end
	-- 检查是否选了牌
	local selectedCards = self.battleUI:getMingPaiSelectCard()
	local index = nil
	if table.getn(selectedCards) <= 0 then
		local result = self.battleUI:mateCardsInCombs({}, combs)
		if not result or not result[1] or not result[2] then
			log("error", "can not find index from combs")
			logv("error", result)
		else
			index = result[2]
		end
	else
		index = self:getKoupaiIndex()
	end
	if not index then
		log("error", "can not find index from combs")
		return
	end
	modMajiangGame.pMajiangGame.rpcChooseComb(self, index, combWnd:getVersionId())
	combWnd:close()
	self:closeSlecteMode()
	modBattleMgr.getCurBattle():getCurGame():setKoupaiIndex(nil)
	self.battleUI:clearChooseWnds()
	modBattleMgr.getCurBattle():getCurGame():clearCanDiscardCardIds()
end

pXiangyangGame.clearMingPaiCombs = function(self)
	self.mingPaiCombs = {}
end
