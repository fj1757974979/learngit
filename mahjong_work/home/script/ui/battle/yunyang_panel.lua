local modMainPanel = import("ui/battle/main.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")

local maxChooseCard = 3
local mainPanelName = modMainPanel.pBattlePanel 

pYunyangPanel = pYunyangPanel or class(mainPanelName)

pYunyangPanel.init = function(self)
	mainPanelName.init(self)
	self.btn_change_san:addListener("ec_mouse_click", function() 
		self:changeSanZhang()
	end)
end

pYunyangPanel.clearPlayerExtrasWnds = function(self)
	self:clearExtrasWnd()
end

pYunyangPanel.destroy = function(self)
	mainPanelName.destroy(self)
	self:clearExtrasWnd()
end

pYunyangPanel.notChooseCard = function(self, cardWnd)
	-- 最大只能选三张
	if modBattleMgr.getCurBattle():isPhaseHuanSanZhang() and table.getn(self.curChooseWnds) >= maxChooseCard then
		return true
	end
	-- 不同花色不能选
	return not self:isSameType(self.curChooseWnds, cardWnd)
end

pYunyangPanel.chooseSetColor = function(self, card)
	if not card then return end
	modMainPanel.pBattlePanel.chooseSetColor(self, card)
	-- 不能选的
	self:hasQueFlagSetColor()
end

pYunyangPanel.chooseCardSetColor = function(self, cardWnd)
	if not cardWnd then return end
	mainPanelName.updateCardIsShow(self, -1, true)
	mainPanelName.chooseCardSetColor(self, cardWnd)
	-- 不能选的缺压暗
	self:notChangeCardsSetTingColor(cardWnd)
end

pYunyangPanel.notChangeCardsSetTingColor = function(self, cardWnd)
	if not modBattleMgr.getCurBattle():isPhaseHuanSanZhang() then
		return
	end
	local modUIUtil = import("ui/common/util.lua")
	local hands = mainPanelName.getAllCardWnds(self, T_SEAT_MINE, T_CARD_HAND)
	-- 少于两张
	local ids = {}
	local tingColorList = {}
	-- 不同花色
	local tmps = mainPanelName.getNewTable(self, self.curChooseWnds)
	if cardWnd then
		table.insert(tmps, cardWnd)
	end
	for _, wnd in pairs(hands) do
		if not self:isSameType(tmps, wnd) then
			table.insert(tingColorList, wnd)	
		end
	end
	-- 压暗
	mainPanelName.setTingColorCard(self, tingColorList)
end

pYunyangPanel.changeSanZhang = function(self)
	if not modBattleMgr.getCurBattle():isPhaseHuanSanZhang() then
		return 
	end
	-- 不足三张
		if not self.curChooseWnds or table.size(self.curChooseWnds) < maxChooseCard then
		infoMessage("请选择三张您要换的牌")
		return
	end
	-- 不在可选列表
	local cardIds = modBattleMgr.getCurBattle():getCurGame():getChooseWndProp(modBattleMgr.getCurBattle():getMyPlayerId(), "ids")
	if not cardIds then return end
	local values = {}
	for _, card in pairs(self.curChooseWnds) do
		table.insert(values, card:getCardId())
		if not self:findCardIsInList(card, cardIds) then 
			infoMessage("请选择手牌中的三张牌")
			return 
		end
	end
	-- 换牌
	self:answerChoosedCard(values)
end

pYunyangPanel.showChangeSan = function(self)
	if modBattleMgr.getCurBattle():getCurGame():getIsHuansanzhang() then 
		self.btn_change_san:show(true)
		self:showHuanPaiTipWnd()
	end
end


pYunyangPanel.changeSanZhangEvent = function(self, wnd, cardToCount)
	if not modBattleMgr.getCurBattle():isPhaseHuanSanZhang() then return end
	if not cardToCount or not wnd then return end
	local modUIUtil = import("ui/common/util.lua")
	local id = wnd:getCardId()
	local changeCardIds = modBattleMgr.getCurBattle():getCurGame():getChangeSanZhangIds()
	for _, cid in pairs(changeCardIds) do
		if id == cid and cardToCount[cid] and cardToCount[cid] > 0 then
--			wnd:choosedEvent()
			wnd:setColor(0xFFEEEE00)
			cardToCount[cid] = cardToCount[cid] - 1
			modUIUtil.timeOutDo(modUtil.s2f(1), nil, function() 
--				wnd:resetEvent(wnd)
			end)
			break
		end
	end
end

pYunyangPanel.setCardCountToList = function(self, list) 
	local cards = modBattleMgr.getCurBattle():getCurGame():getChangeSanZhangIds()
	if not cards then return {} end
	for _, id in pairs(cards) do
		if not list[id] then list[id] = 0 end
		if list[id] then list[id] = list[id] + 1 end
	end
end
pYunyangPanel.updateQueFlagWnds = function(self, isGameStart)
	local players = modBattleMgr.getCurBattle():getAllPlayers()
	local isVideo = modBattleMgr.getCurBattle():getIsVideoState()
	if not players then return end
	for _, player in pairs(players) do
		local wnd = self[sf("wnd_piao_%d", player:getSeat())]
		if not wnd then break end
		local fv = modBattleMgr.getCurBattle():getCurGame():getSelfHasQue(player)
		if fv then
			if isGameStart or isVideo then
				self:setPiaoText(player:getSeat(), fv)
				wnd:show(true)
			else
				wnd:show(false)
				if player:getSeat() == T_SEAT_MINE then
					self:setPiaoText(player:getSeat(), fv)
					wnd:show(true)
				end
			end
		else
			if isGameStart or isVideo then
				wnd:show(false)
			else
				wnd:show(true)
			end
		end
	end
end

pYunyangPanel.changePiaoWndProp = function(self, seatId, value)
	if modBattleMgr.getCurBattle():getCurGame():isQueFlag(value) then
		self:queFlagChangeWndProp(seatId)
	else
		self:yunYangNormalWndProp(seatId)
	end
end

pYunyangPanel.queFlagChangeWndProp = function(self, seatId)
	if not seatId then return end
	local wnd = self[sf("wnd_piao_%d", seatId)]
	if wnd then
		wnd:setSize(52, 52)
		wnd:setAlignX(ALIGN_RIGHT)
		wnd:setOffsetX(wnd:getWidth() / 3)
		wnd:setPosition(0, - wnd:getHeight() / 3)
	end
end

pYunyangPanel.yunYangNormalWndProp = function(self, seatId)
	if not seatId then return end
	local wnd = self[sf("wnd_piao_%d", seatId)]
	if wnd then
		wnd:setSize(87, 33)
		wnd:setAlignX(ALIGN_CENTER)
		wnd:setAlignX(0)
		wnd:setPosition(0, - wnd:getHeight())
	end
end
pYunyangPanel.hideSelectQue = function(self)
	if not modBattleMgr.getCurBattle():isPhaseDingQue() then
		return 
	end
	for i = T_SEAT_RIGHT, T_SEAT_LEFT do
		local player = modBattleMgr.getCurBattle():getAllPlayers()[i]
		if modBattleMgr.getCurBattle():getCurGame():getSelfHasQue(player) then
			local wnd = self[sf("wnd_piao_%d", i)]
			if wnd then
				wnd:show(false)
			end
		end
	end
end

pYunyangPanel.notSameCardChoose = function(self, card, removeCards)
	if not card or not removeCards then return end
	if not modBattleMgr.getCurBattle():isPhaseHuanSanZhang() then
		mainPanelName.notSameCardChoose(self, card, removeCards)
	end
end

pYunyangPanel.afterSetPiaoText = function(self, seatId, value)
	if modBattleMgr.getCurBattle():getCurGame():isQueFlag(value) then
		self:queFlagChangeWndProp(seatId)
	else
		self:yunYangNormalWndProp(seatId)
	end
end

pYunyangPanel.initHuanSanZhangPiaoText = function(self)
	if not modBattleMgr.getCurBattle():isPhaseHuanSanZhang() then
		return
	end
	self:initPiaoWndText(true, -1)
	for i = T_SEAT_MINE, T_SEAT_LEFT do
		local cards = self:getAllCardWnds(i, T_CARD_DISCARD)
		if table.size(cards) == 3 then
			local wnd = self[sf("wnd_piao_%d", i)]
			if wnd then
				wnd:show(false)
			end
		end
	end
end

pYunyangPanel.isShowPhaseTipWnd = function(self)
	return modBattleMgr.getCurBattle():isPhaseHouSi() 
end

pYunyangPanel.setPhaseInitPiaoWnds = function(self)
	if modBattleMgr.getCurBattle():isPhaseHuanSanZhang() then
		-- 初始化为选牌中
		self:initPiaoWndText(true, -1)
		-- 隐藏已经选过的
		self:updatePhaseHuanSanZhangPiaoWnds()
	elseif modBattleMgr.getCurBattle():isPhaseDingQue() then
		-- 云阳麻将定缺
		self:initPiaoWndText(true, "que")
		-- 云阳麻将显示已定缺的玩家标志
		self:updateQueFlagWnds()
	elseif modBattleMgr.getCurBattle():isNormalDiscardPhase() then
		mainPanelName.normalDiscardPhase(self)
		self:updateQueFlagWnds(true)
	end
end

pYunyangPanel.updatePhaseHuanSanZhangPiaoWnds = function(self)
	if not modBattleMgr.getCurBattle():isPhaseHuanSanZhang() then
		return 
	end
	local players = modBattleMgr.getCurBattle():getAllPlayers()
	for _, player in pairs(players) do
		local cards = player:getAllCardsFromPool(T_POOL_DISCARD)
		local isShow = true
		if table.size(cards) == 3 then
			isShow = false
		end
		mainPanelName.showPiaoWndBySeatId(self, player:getSeat(), isShow)
	end
end

pYunyangPanel.priorityHuan = function(self)
	if modBattleMgr.getCurBattle():getCurGame():isSelectedHuanSanZhang() then 
		return 
	end
	local T_CARD_TONG = 0
	local T_CARD_SUO = 1
	local T_CARD_WAN = 2
	local curPriority = self:getSelfHuanPriority()
	if curPriority then
		local numbers = {
			[T_CARD_TONG] = {0, 8},
			[T_CARD_SUO] = {9, 17},
			[T_CARD_WAN] = {18, 26},
		} 
		local hands = self:getAllCardWnds(T_SEAT_MINE, T_CARD_HAND)
		local selected = {}
		for i = 1, 3 do
			for _, card in pairs(hands) do
			local cnum = numbers[curPriority]
				if card:getCardId() >= cnum[1] 
					and card:getCardId() <= cnum[2] 
					and (not self:findCardIsInList(card, selected))
					then
					card:chooseWork()
					table.insert(self.curChooseWnds, card)
					table.insert(selected, card)
					break
				end
			end
		end
		selected = {}
	end
end


pYunyangPanel.getSelfHuanPriority = function(self)
	if not modBattleMgr.getCurBattle():getCurGame():getIsHuansanzhang() then 
		return
	end
	local modPriority = import("logic/priority.lua")
	local player = modBattleMgr.getCurBattle():getCurGame():getCurPlayer()
	local cards = player:getAllCardsFromPool(T_POOL_HAND)
	local ids = {}
	for _, card in pairs(cards) do
		table.insert(ids, card:getId())
	end
	return modPriority.pPriority:instance():getHuanPriority(ids)
end

pYunyangPanel.rollDices = function(self, message)
	if not message then return end
	if not modBattleMgr.getCurBattle():isPhaseHuanSanZhang() then
		return
	end
	local rollPoint = message.dice_values[table.getn(message.dice_values)]
	local rollRules = {
		[1] = "本局顺时针换牌",
		[2] = "本局逆时针换牌",
		[3] = "本局对家换牌",
		[4] = "本局对家换牌",
		[5] = "本局顺时针换牌",
		[6] = "本局逆时针换牌",
	}
	if rollRules[rollPoint] then
		self.wnd_huan_rule:setText("#cm"..rollRules[rollPoint].."#n")
		self.wnd_huan_rule:show(true)
	end
end

pYunyangPanel.answerChoosedCard = function(self, values)
	if not values then return end
	local modBattleRpc = import("logic/battle/rpc.lua")
	modBattleRpc.answerChooseCardRequest(values, function(success, reason) 
		if success then
			self:answerChoosedCardSuccess()
		else
			infoMessage(TEXT(reason))
		end
	end)
end

pYunyangPanel.answerChoosedCardSuccess = function(self)
	local curBattleUI =  modBattleMgr.getCurBattle():getBattleUI()
	curBattleUI:clearChooseWnds()
	modBattleMgr.getCurBattle():getCurGame():clearChooseWndProps()
	curBattleUI.btn_change_san:show(false)
	curBattleUI.btn_guo:show(false)
	curBattleUI:clearSelectTipWnd()
end

pYunyangPanel.autoPlayingClear = function(self)
	modMainPanel.pBattlePanel.autoPlayingClear(self)
	self:clearChooseWnds()
	self:clearSelectTipWnd()
end

pYunyangPanel.showHuanPaiTipWnd = function(self)
	if not modBattleMgr.getCurBattle():isPhaseHuanSanZhang() then return end
	local wnd = pWindow():new()
	wnd:load("data/ui/texttip.lua")
	wnd:setParent(self.wnd_table)
	wnd:setZ(C_BATTLE_UI_Z)
	wnd:setAlignY(ALIGN_MIDDLE)
	wnd:setAlignX(ALIGN_CENTER)
	wnd:setOffsetY(-80)
	wnd:setText("请选择你要换出的三张牌")
	wnd:setSize(500, wnd:getHeight())
	wnd:setText(wnd:getText() or "" .. str .. "\n")
	self["select_tip"] = wnd
end

pYunyangPanel.rollDices = function(self, message)
	if not message then return end
	if not modBattleMgr.getCurBattle():isPhaseHuanSanZhang() then
		return
	end
	if not message then return end
	local rollPoint = message.dice_values[1] 
	local pcount = table.size(modBattleMgr.getCurBattle():getAllPlayers())
	local rollRules = {
		[2] = {
			[1] = "本局对家换牌",	
		},
		[3] = {
			[1] = "本局顺时针换牌",
			[2] = "本局逆时针换牌",
		},
		[4] = {
			[1] = "本局顺时针换牌",
			[2] = "本局对家换牌",
			[3] = "本局逆时针换牌",
		}
	}
	if rollRules[pcount] and rollRules[pcount][rollPoint] then
		self.wnd_huan_rule:setText("#cm"..rollRules[pcount][rollPoint].."#n")
		self.wnd_huan_rule:show(true)
	end

end

pYunyangPanel.hasQueFlagSetColor = function(self) 
	if modBattleMgr.getCurBattle():getCurGame():getSelfHasQue() then
		self:setHandCardTingColor()
	end
end

pYunyangPanel.setHandCardTingColor = function(self)
	local numbers = modBattleMgr.getCurBattle():getCurGame():getHuaSeFanWei()
	local nums = nil
	if modBattleMgr.getCurBattle():getCurGame():isQueTongFlag() then
		nums = numbers[modGameProto.YUNYANG_QUE_TONG]
	elseif modBattleMgr.getCurBattle():getCurGame():isQueSuoFlag() then
		nums = numbers[modGameProto.YUNYANG_QUE_SUO]
	elseif modBattleMgr.getCurBattle():getCurGame():isQueWanFlag() then
		nums = numbers[modGameProto.YUNYANG_QUE_WAN]
	end
	if not nums then return end
	-- 手牌
	local wnds = self:getAllCardWnds(T_SEAT_MINE, T_CARD_HAND)
	if not wnds then return end
	-- 检查是否有缺的牌
	local isSet = false
	for _, wnd in pairs(wnds) do
		if wnd:getCardId() >= nums[1] and wnd:getCardId() <= nums[2] then
			isSet = true
		end
	end
	if not isSet then return end
	-- 设置暗色
	for _, wnd in pairs(wnds) do
		local cardId = wnd:getCardId()
		if cardId < nums[1] or cardId > nums[2] then
			wnd:setColor(0xFFC4C4C4)
		end
	end
end

pYunyangPanel.askFlagShowPiaoWnds = function(self, flags, message)
	if not flags or not message then return end
	mainPanelName.askFlagShowPiaoWnds(self, flags, message)
	self:hideSelectQue()
end

pYunyangPanel.isSameType = function(self, cards, td)
	if not cards or not td then return end
	if table.size(cards) == 0 then return true end
	local numbers = {
		[1] = {0, 8},
		[2] = {9, 17},
		[3] = {18, 26},
	}
	-- 取第一张牌
	local scard = nil
	for _, card in pairs(cards) do
		if not scard then 
			scard = card 
			break
		end
	end
	if not scard then return end
	-- 第一张牌是什么花色
	local key = nil
	for k, nums in pairs(numbers) do
		if scard:getCardId() >= nums[1]	and scard:getCardId() <= nums[2] then
			key = k
			break
		end
	end
	-- 判定所有牌是否为统一花色
	if not key then return end
	local id = td:getCardId()
	if id < numbers[key][1] or id > numbers[key][2] then
		return false
	end
	return true
end

pYunyangPanel.isShowPhaseBlackBG = function(self)
	return true
end

pYunyangPanel.tableClickSetColor = function(self)
	mainPanelName.tableClickSetColor(self)
	
	if modBattleMgr.getCurBattle():isPhaseHuanSanZhang() then
		mainPanelName.updateCardIsShow(self, -1, true)
		self:notChangeCardsSetTingColor()
		return
	end
	self:setHandCardTingColor()
end

pYunyangPanel.showPlayerExtrasWnds = function(self, player)
	if not modBattleMgr.getCurBattle():getIsGaming() or modBattleMgr.getCurBattle():getIsCalculate() then
		return
	end
	if not player then return end

	local extras = player:getExtras()
	if not extras then return end
	local modHuansanzhang = import("ui/battle/huan_san_zhang.lua")
	local playerCount = table.size(modBattleMgr.getCurBattle():getAllPlayers())
	local selfPid = modBattleMgr.getCurBattle():getMyPlayerId()
	local offset = extras.player_offset
	local toCards = extras.out_card_ids
	local fromCards = extras.in_card_ids
	local fromPid = (selfPid + offset) % playerCount
	local toPid = ((selfPid + playerCount) - offset) % playerCount
	local fromPlayer = modBattleMgr.getCurBattle():getPlayerByPlayerId(fromPid)
	local toPlayer = modBattleMgr.getCurBattle():getPlayerByPlayerId(toPid)
	modHuansanzhang.pHuansanzhang:instance():open(fromPlayer, toPlayer, fromCards, toCards)
	modHuansanzhang.pHuansanzhang:instance():setParentWnd(self.wnd_table)
end

pYunyangPanel.clearExtrasWnd = function(self)

	local modHuansanzhang = import("ui/battle/huan_san_zhang.lua")	
	if modHuansanzhang.pHuansanzhang:getInstance() then
		modHuansanzhang.pHuansanzhang:instance():close()
	end
end

pYunyangPanel.showPhaseTipWnd = function(self, phase)
	if modBattleMgr.getCurBattle():isPhaseHouSi() then
		self:newTipWnd(phase, "#co" .. "后四" .. "#n" .. "阶段开始", nil, -100)
	end
end

