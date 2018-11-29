local modUIUtil = import("ui/common/util.lua")
local modUtil = import("util/util.lua")
local modSound = import("logic/sound/main.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modBattleRpc = import("logic/battle/rpc.lua")

pChangeCard = pChangeCard or class(pWindow)

pChangeCard.init = function(self, host)
	self.testChangeCardContorls = {}
	self:setParent(host.wnd_table)
	self:setColor(0)
	self:setAlignX(ALIGN_CENTER)
	self:setAlignY(ALIGN_TOP)
	self.host = host
	self:changeCard()
	self.host:resetTestChangeWnd()
	modUIUtil.makeModelWindow(self, true, true)
	self:setZ(-3)
end

pChangeCard.changeCard = function(self)
	-- 换牌list
	-- TODO
	self:initCards()
	-- 先清除
	self:clearTestChangeCardControls()

	-- 描画
	local bgWnd = self.host:showCard("test_change_card", 0, 0, self.cards, nil, nil, nil, T_SEAT_MINE, self.testChangeCardContorls)
	bgWnd:setAlignX(ALIGN_CENTER)
	bgWnd:setAlignY(ALIGN_TOP)
	bgWnd:setImage("ui:battle_change_card_bg.png")
	bgWnd:setParent(self)
	-- 排位子
	self:setTestChangeCardPos(bgWnd)
	-- 添加click
	for _, wnd in pairs(self.testChangeCardContorls) do
		wnd:setParent(self)
		if wnd ~= bgWnd then
			wnd:addListener("ec_mouse_click", function() 
				self:testChooseCardChange(wnd)
			end)	
		end
	end
end

pChangeCard.clearTestChangeCardControls = function(self)
	for _, wnd in pairs(self.testChangeCardContorls) do
		if wnd then wnd:setParent(nil) end
	end
	self.testChangeCardContorls = {}
end

pChangeCard.setTestChangeCardPos = function(self, bgWnd)
	local maxX = 11
	local cardCount = table.getn(self.testChangeCardContorls) - 1
	if cardCount <= 0 then return end
	-- 重新设置坐标
	local distanceX, distanceY = 10, 10
	local x, y = distanceX + 18, distanceY + 50
	local scale = 0.8
	local width, height = 89 * scale, 135 * scale
	local bgWidth, bgHeight = 0, 0
	local cardIndex = 0
	-- 描画 
	for idx, wnd in pairs(self.testChangeCardContorls) do
		if wnd ~= bgWnd then
			cardIndex = cardIndex + 1
			wnd:setAlignY(ALIGN_TOP)
			wnd:setPosition(x, y)
			wnd:setSize(width, height)
			x = x + width + distanceX
			if x > bgWidth then bgWidth = x end
			if cardIndex % maxX == 0 then
				x = distanceX + 18
				if idx <= cardCount + 1 then
					y = y + height + distanceY
				end
			end
			if y > bgHeight then bgHeight = y end
		end
	end
	bgHeight = bgHeight + height + distanceY
	bgWnd:setSize(bgWidth * 1.35, bgHeight * 1.35)
	self:setSize(bgWidth, bgHeight)

	-- 设置提示
	self:textWnd(bgWnd)
	-- 设置数量
	self:getUndealtCards()
end

pChangeCard.textWnd = function(self, parentWnd)
	local wnd = pWindow:new()
	wnd:setParent(parentWnd)
	wnd:setColor(0)
	wnd:setAlignX(ALIGN_CENTER)
	wnd:setAlignY(ALIGN_BOTTOM)
	wnd:setOffsetY(-130)
	wnd:getTextControl():setFontSize(50)
	wnd:getTextControl():setColor(0xFF8B0000)
	wnd:getTextControl():setAutoBreakLine(false)
	wnd:setText("此功能只存在内部测试版本，请放心游戏")
	wnd:enableEvent(false)
	wnd:setSize(50, 50)
end

pChangeCard.close = function(self)
	self:clearTestChangeCardControls()
	self.cards = {}
	self.host:clearTestWnds()
	self.host = nil
end


pChangeCard.testChooseCardChange =function(self, wnd)
	if not modBattleMgr.getCurBattle():getCurGame():canDiscardCard() then
		infoMessage("请在自己的回合更换")
		return 
	end
	local chooseCards = self.host:getMineHandCard()
	if not chooseCards then return end
	local curCard = nil
	for _, card in pairs(chooseCards) do
		curCard = card
	end
	if not curCard then
		infoMessage("请选择被替换的牌")
		return
	end
	
	log("warn", "change cards id:  "..curCard:getCardId().."  to:"..wnd.cardId)
	modBattleRpc.changeCard(curCard:getCardId(), wnd.cardId, function(success, reason) 
		if success then
			self:close()
		else
			infoMessage(TEXT(reason))
		end
	end)
end

pChangeCard.initCards = function(self)
	self.cards = {}
	local flowerId = 34
	local id = 0
	for i = 0, 33 do
		if id % 9 == 0 then
			for n = 1, 2 do
				if flowerId <= 41 then
					table.insert(self.cards, flowerId)
					flowerId = flowerId + 1
				end
			end
		end
		table.insert(self.cards, id)
		id = id + 1
	end

end

pChangeCard.getUndealtCards = function(self)
	modBattleRpc.getUndealtCards(function(success, reason, ret)
		if success then
			self:setCountToCards(ret.undealt_card_ids)
		else
			infoMessage(TEXT(reason))
		end
	end)	
end

pChangeCard.setCountToCards = function(self, undealtCards)
	for _, wnd in pairs(self.testChangeCardContorls) do
		local id = wnd.cardId
		if id then
			local count = self:findCountByCardId(id, undealtCards)
			self:newWnd(wnd, count, 0.6)
		end
	end
end

pChangeCard.findCountByCardId = function(self, id, undealtCards)
	local count = 0
	for _, undealtId in ipairs(undealtCards) do
		if undealtId == id then
			count = count + 1
		end
	end
	return count
end

pChangeCard.newWnd = function(self, parentWnd, count, scale)
	if count < 0 or count > 4 then return end 
	local width, height = 81 * (scale or 1), 102 * (scale or 1)
	local wnd = pWindow:new()
	wnd:setParent(parentWnd)
	wnd:setSize(width, height)
	wnd:setAlignX(ALIGN_RIGHT)
	wnd:setAlignY(ALIGN_BOTTOM)
	wnd:setColor(0xFFFFFFFF)
	wnd:setImage("ui:battle_number_" .. count .. ".png")
end
