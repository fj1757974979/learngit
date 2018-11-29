local modMainPanel = import("ui/battle/main.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modMingGuo = import("ui/battle/mingguo.lua")

pXiangyangPanel = pXiangyangPanel or class(modMainPanel.pBattlePanel)

pXiangyangPanel.init = function(self)
	modMainPanel.pBattlePanel.init(self)	
	-- 是否明牌了
	self.isMingState = false
end

pXiangyangPanel.destroy = function(self)
	modMainPanel.pBattlePanel.destroy(self)
	self.isMingState = false
	self:clearCanelBtn()
end

pXiangyangPanel.clearMingPaiSelecteCards = function(self)
	self.curChooseWnds = {}
end

pXiangyangPanel.autoPlayingClear = function(self)
	modMainPanel.pBattlePanel.autoPlayingClear(self)
	self:clearCanelBtn()
	self:clearMingGuo()
end

pXiangyangPanel.chooseCardWork = function(self)
	modMainPanel.pBattlePanel.chooseCardWork(self)
	self:updateKoupaiIndex()
end

pXiangyangPanel.speicalChooseCard = function(self, cardWnd)
	if not modBattleMgr.getCurBattle():getCurGame():getIsMingCombSelectMode() then return end
	if not cardWnd then return end
	local hands = modMainPanel.pBattlePanel.getHandCards(self)
	local tmps = {}
	local count = 3
	for _, wnd in pairs(hands) do
		if wnd:getCardId() == cardWnd:getCardId() and count > 0 then
			table.insert(tmps, wnd)
			count = count - 1
		end
	end
	return tmps
end

pXiangyangPanel.notChooseCard = function(self, cardWnd) 
	if not cardWnd then return end
	if self.isMingState then 
		return self:mingStateNotChooseCard(cardWnd)
	end
	return self:selectModeNotChooseCard(cardWnd)
end

pXiangyangPanel.mingStateNotChooseCard = function(self, cardWnd)
	if not cardWnd then return end
	if not self.isMingState then return end
	local notInlist = self:getNotInSuggestionListCards()
	if not notInlist then return end
	return self:findCardIsInList(cardWnd, notInlist)
end

pXiangyangPanel.selectModeNotChooseCard = function(self, cardWnd)
	if not cardWnd then return end
	if not modBattleMgr.getCurBattle():getCurGame():getIsMingCombSelectMode() then return end
	local modUIUtil = import("ui/common/util.lua")
	local tmps = modMainPanel.pBattlePanel.getNewTable(self, self.curChooseWnds)
	local hands = modMainPanel.pBattlePanel.getHandCards(self)
	-- 少于三张的不能选
	local ids = {}
	for _, wnd in pairs(hands) do
		table.insert(ids, wnd:getCardId())
	end
	local idToCount = modUIUtil.getListIdToCount(ids)
	if idToCount[cardWnd:getCardId()] < 3 then return true end
	local count = 3
	for _, wnd in pairs(hands) do
		if wnd:getCardId() == cardWnd:getCardId() and count > 0 then
			table.insert(tmps, wnd)
			count = count - 1
		end
	end
	-- 匹配成功则可选
	local combs = modBattleMgr.getCurBattle():getCurGame():getMingPaiCombs()
	if not combs then return end
	return not self:mateCardsInCombs(tmps, combs)[1]
end

pXiangyangPanel.showMingGuoWnd = function(self)
	self:clearMingGuo()
	if not modBattleMgr.getCurBattle():getCurGame():getIsPreting() then return end
	modMingGuo.pMingGuo:instance():open(self.wnd_comb_parent)
end

pXiangyangPanel.notSameCardChoose = function(self, cardWnd, removeCards)
	if modBattleMgr.getCurBattle():getCurGame():getIsMingCombSelectMode() then
		return
	end
	modMainPanel.pBattlePanel.notSameCardChoose(self, cardWnd, removeCards)
end

pXiangyangPanel.showMingPaiSelectTipWnd = function(self)
	if not modBattleMgr.getCurBattle():getCurGame():getIsMingPaiSelectMode() then return end
	local wnd = pWindow():new()
	wnd:load("data/ui/texttip.lua")
	wnd:setParent(self.wnd_table)
	wnd:setZ(C_BATTLE_UI_Z)
	wnd:setAlignY(ALIGN_MIDDLE)
	wnd:setAlignX(ALIGN_CENTER)
	wnd:setText("请选择要扣的牌（扣牌可杠）")
	wnd:setSize(500, wnd:getHeight())
	wnd:setText(wnd:getText() or "" .. str .. "\n")
	self["select_tip"] = wnd
end

pXiangyangPanel.updateKoupaiIndex = function(self)
	local combs = modBattleMgr.getCurBattle():getCurGame():getMingPaiCombs()
	local result = self:mateCardsInCombs(self.curChooseWnds, combs)
	if result[1] and result[2] then
		modBattleMgr.getCurBattle():getCurGame():setKoupaiIndex(result[2])
	else
		modBattleMgr.getCurBattle():getCurGame():setKoupaiIndex(nil)
	end
end

pXiangyangPanel.mateCardsInCombs = function(self, mingCards, combs)
	if not mingCards then return end
	local mids = {}
	local hands = self:getHandCards() 
	local wnds = self:getHasNotTableInTable(mingCards, hands)
	for _, wnd in pairs(wnds) do
		table.insert(mids, wnd:getCardId())
	end
	self:sortCards(mids)
	local isSame = false
	local index = nil
	for idx, comb in ipairs(combs) do
		local ids  = {}
		local cids = comb.card_ids
		for _, id in ipairs(cids) do
			table.insert(ids, id)
		end
		self:sortCards(ids)
		if self:isSameTables(mids, ids) then
			isSame = true
			index = idx - 1
			break
		end
	end
	return { isSame, index }
end

pXiangyangPanel.isSameTables = function(self, mingIds, ids)
	if not mingIds or not ids then return end
	if table.getn(mingIds) ~= table.getn(ids) then return end
	for i = 1, table.getn(mingIds) do
		if mingIds[i] ~= ids[i] then 
			return false
		end
	end
	return true
end

pXiangyangPanel.removeCardsInMingPaiSelectedCards = function(self)
	for _, wnd in pairs(self.curChooseWnds) do
		wnd:resetEvent(wnd)
	end
	self.curChooseWnds = {}
end

pXiangyangPanel.getMingPaiSelectCard = function(self)
	return self.curChooseWnds
end
pXiangyangPanel.showCancelMingpai = function(self)
	self:clearCanelBtn()
	local btn = pButton:new()
	btn:setParent(self.wnd_comb_parent)
	btn:setImage("ui:battle/cancel.png")
	btn:setSize(127, 124)
	btn:setAlignX(ALIGN_RIGHT)
	btn:setAlignY(ALIGN_MIDDLE)
	btn:setZ(C_BATTLE_UI_Z)
	btn:setOffsetX(-100)
	btn:addListener("ec_mouse_click", function()
	end)
	self["cancel_mingpai"] = btn
end

pXiangyangPanel.setIsMingState = function(self, isMing)
	self.isMingState = isMing
	modBattleMgr.getCurBattle():getCurGame():setIsPreting(isMing)	
end

pXiangyangPanel.notSelectCardSetTingColorWork = function(self)
	if not modBattleMgr.getCurBattle():getCurGame():getIsMingCombSelectMode() then return end
	-- 区别各张牌张数
	local modUIUtil = import("ui/common/util.lua")
	local ids = {}
	local hands = self:getHandCards()
	for _, wnd in pairs(hands) do
		table.insert(ids, wnd:getCardId())
	end
	local idTocount = modUIUtil.getListIdToCount(ids)
	local twolist = {}
	local threelist = {}
	for _, wnd in pairs(hands) do
		local id = wnd:getCardId()
		if idTocount[id] < 3 then
			table.insert(twolist, wnd)
		else
			if not threelist[id] then threelist[id] = {} end
			if table.getn(self:findSameIdCard(id, threelist[id])) < 3 then
				table.insert(threelist[id], wnd)
			end
		end
	end
	-- 少于两张直接压暗
	self:setTingColorCard(twolist)
	-- 三张牌先匹配
	local combs = modBattleMgr.getCurBattle():getCurGame():getMingPaiCombs()
	for id, list in pairs(threelist) do
		if not self:mateCardsInCombs(list, combs)[1] then
			self:setTingColorCard(list)
		end
	end
end

pXiangyangPanel.setMingPaiSelectCard = function(self, card)
	if not card then return end
	local hands = self:getAllCardWnds(T_SEAT_MINE, T_CARD_HAND)
	local wnds = self:findSameCardInHandsByMax(card, 3) 
	if not wnds or table.getn(wnds) < 3 then return end
	-- 已选过
	if self:findCardIncards(card, self.curChooseWnds) then
		return 
	end
	-- 预加入
	local tmps = self:getNewTable(self.curChooseWnds)
	for _, wnd in pairs(wnds) do
		table.insert(tmps, wnd)
	end
	-- 是否在可选列表
	local combs = modBattleMgr.getCurBattle():getCurGame():getMingPaiCombs()
	local result = self:mateCardsInCombs(tmps, combs)
	if not result[1] then
		local wresult = self:mateCardsInCombs(wnds, combs)
		if wresult[1] then
			self:removeCardsInMingPaiSelectedCards()
			for _, wnd in pairs(wnds) do
				wnd:choosedEvent()
				table.insert(self.curChooseWnds, wnd)
			end
		end
	elseif result[1] and result[2] then
		modBattleMgr.getCurBattle():getCurGame():setKoupaiIndex(result[2])	
		for _, wnd in pairs(wnds) do
			wnd:choosedEvent()
			table.insert(self.curChooseWnds, wnd)
		end
	end
end

pXiangyangPanel.checkRemoveCard = function(self, card)
	if not card then return end
	local lists = {
		self.curChooseWnds,
	}
	for _, l in pairs(lists) do
		self:removeCardsInCardlist({card}, l)
	end
end

pXiangyangPanel.sortCards = function(self, cards)
	table.sort(cards, function(c1, c2)
		local id1, id2 = c1, c2
		return c1 < c2
	end)	
end

pXiangyangPanel.updateAllPlayersTingCard = function(self)
	modMainPanel.pBattlePanel.updateAllPlayersTingCard(self)
end

pXiangyangPanel.getMaxChooseCardCount = function(self)
	if modBattleMgr.getCurBattle():getCurGame():getIsMingPaiSelectMode() then 
		return 999
	end
	return 1
end

pXiangyangPanel.parsonalRestCard = function(self, cardWnd)
	if not cardWnd then return end
	if not modBattleMgr.getCurBattle():getCurGame():getIsMingCombSelectMode() then
		modMainPanel.pBattlePanel.parsonalRestCard(self, cardWnd)
		return
	end
	local removeCards = {}
	for _, wnd in pairs(self.curChooseWnds) do
		if wnd:getCardId() == cardWnd:getCardId() and
			wnd:isOnChoose() then
			table.insert(removeCards, wnd)
		end
	end
	for _, wnd in pairs(removeCards) do
		modMainPanel.pBattlePanel.parsonalRestCard(self, wnd)
	end
	self:updateKoupaiIndex()
end

pXiangyangPanel.clearCanelBtn = function(self)
	if self["cancel_mingpai"] then
		self["cancel_mingpai"]:setParent(nil)
		self["cancel_mingpai"] = nil
	end
end

pXiangyangPanel.discardSuccessWork = function(self)
	modMainPanel.pBattlePanel.discardSuccessWork(self)
	self:clearCanelBtn()
	-- 清除明过项
	self:clearMingGuo()
end

pXiangyangPanel.discardFailedWork = function(self, player)
	if not player then return end
	modMainPanel.pBattlePanel.discardFailedWork(self, player)
	self:showMingGuoWnd()
end

pXiangyangPanel.updatePlayerTingColor = function(self)
	modMainPanel.pBattlePanel.updatePlayerTingColor(self)
	-- 建议打的牌除
	self:setSuggestionTingColor()
end

pXiangyangPanel.setSuggestionTingColor = function(self)
	if not self.isMingState then return end
	modMainPanel.pBattlePanel.setSuggestionTingColor(self)
end

pXiangyangPanel.chooseSetColor = function(self, card)
	if not card then return end
	modMainPanel.pBattlePanel.chooseSetColor(self, card)
	-- 建议打的牌
	self:setSuggestionTingColor()
	-- 不能打的牌
	self:notInDiscardListSetTingColor()	
	-- 不能选的
	self:notSelectCardSetTingColorWork()
end

pXiangyangPanel.clearMingGuo = function(self)
	if modMingGuo.pMingGuo:getInstance() then
		modMingGuo.pMingGuo:instance():close()
	end
end

