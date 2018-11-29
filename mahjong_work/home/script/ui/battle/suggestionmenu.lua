local modWndList = import("ui/common/list.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modUIUtil = import("ui/common/util.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modCardWnd = import("ui/battle/card.lua")

pSuggestionMenu = pSuggestionMenu or class(pWindow, pSingleton)

pSuggestionMenu.init = function(self)
	self:setParent(gWorld:getUIRoot())
	self:setAlignX(ALIGN_RIGHT)
	self:setZ(C_BATTLE_UI_Z)
	self:setColor(0)
	self.controls = {}
end

pSuggestionMenu.open = function(self, winCards, pWnd)
	if not winCards then return end
	self.battleUI = modBattleMgr.getCurBattle():getBattleUI()
	if not pWnd then pWnd = self.battleUI.wnd_comb_parent end
	self:setParent(pWnd)
	self.pWnd = pWnd
	-- 滑动窗口
	self.wnd_drag = self:createListWnd()
	self.wndlist = modWndList.pWndList:new(gGameWidth * 0.92, 150, 1, 0, 0, T_DRAG_LIST_HORIZONTAL)
	self.wndlist:setPosition(0, - 45)
	self.wndlist:setAlignX(ALIGN_RIGHT)

	-- 描画
	local x, y = 10, 0
	local distanceX, distanceY = 10, 10
	local maxX = 6
	-- 赋值并排序
	local swCards = {}
	for _, wCard in ipairs(winCards) do
		local card = {}
		card.id = wCard.id
		card.fan_count = wCard.fan_count
		table.insert(swCards, card)
	end
	-- 排序
	table.sort(swCards, function(card1, card2) 
		local fan1 = card1.fan_count
		local fan2 = card2.fan_count
		return fan1 < fan2
	end)
	-- 描画
	local huCount = 0
	for idx, wCard in ipairs(swCards) do
		local count = self:findCardCount(wCard.id)
		local fan = wCard.fan_count
		local bgWnd = self:newBgWnd(count, fan, x, y)
		local wnd = self:newCardWnd(wCard.id, bgWnd)
		x = x - bgWnd:getWidth() - distanceX
		huCount = huCount + count
	end
	if -x > self.wnd_drag:getWidth() then	
		self.wnd_drag:setSize(-x, self.wnd_drag:getHeight())
	end
	self.wndlist:addWnd(self.wnd_drag)
	self.wndlist:setParent(self)
	self.wndlist:setAlignX(ALIGN_RIGHT)
	-- 描画胡面
	if huCount <= 0 then return end
	local huBgWnd = self:newHuCount(huCount)
	local hWnd = self:newWnd(huBgWnd)
end


pSuggestionMenu.newWnd = function(self, pWnd)
	if not pWnd then return end
	local scale = 0.6
	local wnd = pWindow:new()
	wnd:setParent(pWnd)
	wnd:setColor(0xFFFFFFFF)
	wnd:setImage("ui:battle/hu.png")
	wnd:setAlignY(ALIGN_CENTER)
	wnd:setSize(149 * scale, 131 * scale)
	table.insert(self.controls, wnd)
	return wnd
end

pSuggestionMenu.newHuCount = function(self, count)
	local wnd = pWindow:new()
	wnd:load("data/ui/suggestion.lua")
	wnd:setParent(self)
	wnd:setAlignX(ALIGN_RIGHT)
	wnd:setPosition(0, - 150)
	wnd:setOffsetX(-10)
	wnd.wnd_num:setText(count)
	wnd:setSize(205, 100)
	wnd.wnd_num:setAlignY(ALIGN_CENTER)
	wnd.wnd_text:setAlignY(ALIGN_CENTER)
	wnd.wnd_text:setRX(0)
	wnd.wnd_fan:show(false)
	table.insert(self.controls, wnd)
	return wnd
end

pSuggestionMenu.newBgWnd = function(self, num, fan, x, y)
	local bgWnd = pWindow:new()
	bgWnd:load("data/ui/suggestion.lua")
	bgWnd:setParent(self.wnd_drag)
	bgWnd:setAlignX(ALIGN_RIGHT)
	bgWnd:setOffsetX(x)
	bgWnd:setPosition(0, y)
	bgWnd.wnd_num:setText(num)
	bgWnd.wnd_fan:setText(fan)
	if fan <= 0 then bgWnd.wnd_fan:show(false) end
	table.insert(self.controls, bgWnd)
	return bgWnd
end

pSuggestionMenu.newCardWnd = function(self, id, pWnd)
	if not id or not pWnd then return end
	local scale = 0.8
	local wnd = modCardWnd.pCardWnd:new(T_SEAT_MINE, id, 100 * scale, 139 * scale, T_CARD_SHOW, self.battleUI)
	wnd:setParent(pWnd)
	wnd:setAlignY(ALIGN_CENTER)
	wnd:setPosition(10, 0)
end

pSuggestionMenu.close = function(self)
	for _, wnd in pairs(self.controls) do
		wnd:setParent(nil)
	end
	self.controls = {}
	self.battleUI = nil
	if self.wndlist then
		self.wndlist:destroy()
	end
	self.wndlist = nil
	self.wnd_drag:setParent(nil)
	self.wnd_drag = nil
	pSuggestionMenu:cleanInstance()
end

pSuggestionMenu.findCardCount = function(self, id)
	if not id or not self.battleUI then return end
	local count = 4
	for i = T_SEAT_MINE, T_SEAT_LEFT do
		local num = modUIUtil.findCardBySeat(i, id)
		if num then
			count = count - num 
		end
	end
	if count < 0 then count = 0 end
	return count	
end

pSuggestionMenu.createListWnd = function(self)
	local pWnd = pWindow:new()
	pWnd:setName("wnd_drag")
	pWnd:setSize(gGameWidth * 0.9, 150)
	pWnd:setPosition(0,0)
	pWnd:setColor(0)
	self[pWnd:getName()] = pWnd
	return self[pWnd:getName()]
end
