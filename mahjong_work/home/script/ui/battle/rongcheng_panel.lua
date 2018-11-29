local modMainPanel = import("ui/battle/main.lua")
local modSound = import("logic/sound/main.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modMingGuo = import("ui/battle/mingguo.lua")

pRongchengPanel = pRongchengPanel or class(modMainPanel.pBattlePanel)

pRongchengPanel.init = function(self)
	modMainPanel.pBattlePanel.init(self)	
	-- 是否明牌了
	self.isMingState = false
	self:initBtnGuo()
	self.btn_change_san:addListener("ec_mouse_click", function() 
		self:rongchengChange()	
	end)
end

pRongchengPanel.notSameCardChoose = function(self, cardWnd, removeCards)
	if not cardWnd then return end
	if not self:getCurGame():getIsMingPaiSelectMode() then
		modMainPanel.pBattlePanel.notSameCardChoose(self, cardWnd, removeCards)
		return
	end
end

pRongchengPanel.notChooseCard = function(self, cardWnd) 
	if not cardWnd then return end
	if self.isMingState then 
		return self:mingStateNotChooseCard(cardWnd)
	end
	return false
end

pRongchengPanel.mingStateNotChooseCard = function(self, cardWnd)
	if not cardWnd then return end
	if not self.isMingState then return end
	local notInlist = self:getNotInSuggestionListCards()
	if not notInlist then return end
	return self:findCardIsInList(cardWnd, notInlist)
end

pRongchengPanel.destroy = function(self)
	modMainPanel.pBattlePanel.destroy(self)
	self.isMingState = false
end

pRongchengPanel.chooseSetColor = function(self, card)
	if not card then return end
	modMainPanel.pBattlePanel.chooseSetColor(self, card)
	-- 建议打的牌
	self:setSuggestionTingColor()
	-- 听牌压暗
	self:updateAllPlayersTingCard()

end

pRongchengPanel.showMingPaiSelectTipWnd = function(self)
	if not self:getCurGame():getIsMingPaiSelectMode() then return end
	local wnd = pWindow():new()
	wnd:load("data/ui/texttip.lua")
	wnd:setParent(self.wnd_table)
	wnd:setZ(C_BATTLE_UI_Z)
	wnd:setAlignY(ALIGN_MIDDLE)
	wnd:setAlignX(ALIGN_CENTER)
	wnd:setText("请选择你要放倒的牌")
	wnd:setSize(500, wnd:getHeight())
	wnd:setText(wnd:getText() or "" .. str .. "\n")
	self["select_tip"] = wnd
end

pRongchengPanel.rongchengChange = function(self)
	if not modBattleMgr.getCurBattle():getCurGame():getIsMingPaiSelectMode() then
		return 
	end
	-- 没有牌相当于不明
	if not self.curChooseWnds or table.size(self.curChooseWnds) <= 0 then
		self.btn_guo:show(true)
		infoMessage("请选择您要放倒的牌")
		return
	end
	local values = {}
	for _, card in pairs(self.curChooseWnds) do
		table.insert(values, card:getCardId())
	end
	self:answerChoosedCard(values)
end

pRongchengPanel.showChangeGuo = function(self, isShow)
	self.btn_guo:show(isShow)
	self.btn_change_san:show(isShow)
end

pRongchengPanel.initBtnGuo = function(self)
	self.btn_guo:show(false)
	self.btn_guo:addListener("ec_mouse_click", function() 
		self:answerChoosedCard({})
	end)
end

pRongchengPanel.showChangeSan = function(self)
	self:showChangeGuo(true)
	self:showMingPaiSelectTipWnd()
	self.btn_change_san:setImage("ui:battle/fangdao.png")
	self.btn_change_san:setSize(150, 124)
end

pRongchengPanel.autoPlayingClear = function(self)
	modMainPanel.pBattlePanel.autoPlayingClear(self)
	local curBattleUI = modBattleMgr.getCurBattle():getBattleUI()
	curBattleUI:clearChooseWnds()
	curBattleUI:clearSelectTipWnd()
	self:clearMingGuo()
end

pRongchengPanel.clearRongchengSelectCardList = function(self)
	if not self.curChooseWnds then return end
	self.curChooseWnds = {}
end

pRongchengPanel.showJieBaoWnd = function(self)
	self:jiebaoEffect()
	modSound.getCurSound():playSound("sound:kaibao.mp3")
end

pRongchengPanel.jiebaoEffect = function(self)
	local modUIUtil = import("ui/common/util.lua")
	local wnd = pWindow:new()
	wnd:setParent(self.wnd_table)
	wnd:setSize(502, 329)
	local x, y = gGameWidth / 2 - wnd:getWidth() / 2.5, gGameHeight / 2 - wnd:getHeight() / 2.5
	wnd:setPosition(0, 0)
	wnd:setImage("ui:battle_kaibao.png")
	wnd:setZ(C_BATTLE_UI_Z)
	modUIUtil.jiebaoEffect(wnd, 40, x, y, 502 * 0.7, 329 * 0.7, 3)
end

pRongchengPanel.answerChoosedCard = function(self, values)
	if not values then return end
	modBattleRpc.answerChooseCardRequest(values, function(success, reason) 
		if success then
			self:answerChoosedSuccess()
		else
			infoMessage(TEXT(reason))
		end
	end)
end

pRongchengPanel.answerChoosedSuccess = function(self)
	local curBattleUI = modBattleMgr.getCurBattle():getBattleUI()
	curBattleUI:clearChooseWnds()
	modBattleMgr.getCurBattle():getCurGame():clearChooseWndProps()
	curBattleUI:showChangeGuo(false)
	curBattleUI:clearSelectTipWnd()
	modBattleMgr.getCurBattle():getCurGame():closeSelectMode()
end

pRongchengPanel.setIsMingState = function(self, isMing)
	self.isMingState = isMing
	modBattleMgr.getCurBattle():getCurGame():setIsPreting(isMing)	
end


pRongchengPanel.getIsShowFlowerCard = function(self, seatId)
	if not seatId then return end	
	return seatId == T_SEAT_MINE or modBattleMgr.getCurBattle():getIsVideoState()
end

pRongchengPanel.updateAllPlayersTingCard = function(self)
	if modBattleMgr.getCurBattle():getCurGame():getIsMingPaiSelectMode() then
		return
	end
	modMainPanel.pBattlePanel.updateAllPlayersTingCard(self)
end

pRongchengPanel.getMaxChooseCardCount = function(self)
	if modBattleMgr.getCurBattle():getCurGame():getIsMingPaiSelectMode() then 
		return 999
	end
	return 1
end

pRongchengPanel.getIsShowDiscardMagic = function(self)
	return false
end

pRongchengPanel.getIsCombShowTipMagicWnd = function(self)
	return false
end

pRongchengPanel.isShowPhaseBlackBG = function(self)
	return not modBattleMgr.getCurBattle():isPhasePiao() 
end

pRongchengPanel.speicalGuoWork = function(self, btnPass)
	if not btnPass then return end 
	btnPass:setImage("ui:battle/shuai.png")
	btnPass:setSize(127, 124)
	return "shuai"
end

pRongchengPanel.getPiaoType = function(self)
	return "piaofen"
end

pRongchengPanel.getCurGame = function(self)
	return modBattleMgr.getCurBattle():getCurGame()
end

pRongchengPanel.discardSuccessWork = function(self)
	modMainPanel.pBattlePanel.discardSuccessWork(self)
	self:clearMingGuo()
	self:showChangeGuo(false)
end

pRongchengPanel.updatePlayerTingColor = function(self)
	-- 父类函数
	modMainPanel.pBattlePanel.updatePlayerTingColor(self)
	-- 建议打的牌除
	self:setSuggestionTingColor()
end

pRongchengPanel.setSuggestionTingColor = function(self)
	if not self.isMingState then return end
	modMainPanel.pBattlePanel.setSuggestionTingColor(self)
end

pRongchengPanel.updateAllPlayersTingCard = function(self)
	if modBattleMgr.getCurBattle():getCurGame():getIsMingPaiSelectMode() then
		return
	end
	modMainPanel.pBattlePanel.updateAllPlayersTingCard(self, card)
end

pRongchengPanel.showMingGuoWnd = function(self)
	self:clearMingGuo()
	if not modBattleMgr.getCurBattle():getCurGame():getIsPreting() then return end
	modMingGuo.pMingGuo:instance():open(self.wnd_comb_parent)
end

pRongchengPanel.discardFailedWork = function(self, player)
	if not player then return end
	modMainPanel.pBattlePanel.discardFailedWork(self, player)
	self:showMingGuoWnd()
end

pRongchengPanel.clearMingGuo = function(self)
	if modMingGuo.pMingGuo:getInstance() then
		modMingGuo.pMingGuo:instance():close()
	end
end

pRongchengPanel.showPhaseTipWnd = function(self, phase)
	if not phase then return end
	if modBattleMgr.getCurBattle():isPhaseRongchengHaidi() then
		self:newTipWnd(phase, "#co" .. "海底" .. "#n" .. "阶段开始", nil, -100)
	end
end
