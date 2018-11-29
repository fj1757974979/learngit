local modUIUtil = import("ui/common/util.lua")
local modUtil = import("util/util.lua")
local modCardWnd = import("ui/battle/card.lua")
local modEvent = import("common/event.lua")

pHuansanzhang = pHuansanzhang or class(pWindow, pSingleton)

pHuansanzhang.init = function(self)
	self:load("data/ui/huansanzhang.lua")
	self.isOpen = true
	self.cardWnds = {}
	self.openPos = self.wnd_open:getX()
	self:addListener("ec_mouse_click", function() 
		self:openClose()
	end)
	self:setZ(C_BATTLE_UI_Z)
	self:regEvent()
end

pHuansanzhang.regEvent = function(self) 
	self.__update_user_prop = modEvent.handleEvent(EV_UPDATE_USER_PROP,function(seatId, name, avatarUrl, ip, pid)
		if modUIUtil.utf8len(name) > 6 then
			name = modUIUtil.getMaxLenString(name, 5)
		end

		if pid == self.fromPlayer:getPlayerId() then
			self.wnd_from_name:setText("#cm 换回自" .. "#n" .. "\n" .. name)
		end
		if pid == self.toPlayer:getPlayerId() then
			self.wnd_to_name:setText("#cm 换出给" .. "#n" .. "\n" .. name)
		end
	end)
end

pHuansanzhang.open = function(self, fromPlayer, toPlayer, fromCards, toCards)
	self.fromCards = fromCards
	self.toCards = toCards
	self.fromPlayer = fromPlayer
	self.toPlayer = toPlayer
	if fromPlayer:getName() then
		local name = fromPlayer:getName()
		if modUIUtil.utf8len(name) > 6 then
			name = modUIUtil.getMaxLenString(name, 5)
		end
		self.wnd_from_name:setText("#cm 换回自" .. "#n" .. "\n" .. name)
	end
	if toPlayer:getName() then
		local name = toPlayer:getName()
		if modUIUtil.utf8len(name) > 6 then
			name = modUIUtil.getMaxLenString(name, 5)
		end
		self.wnd_to_name:setText("#cm 换出给" .. "#n" .. "\n" .. name)
	end
	self:showCards()
	self:showHide()
	local fream = modUtil.s2f(2)
	modUIUtil.timeOutDo(fream, nil, function() 
		if self.isOpen then
			self.isOpen = false
			self:showHide()
		end
	end)
end

pHuansanzhang.openClose = function(self)
	self.isOpen = not self.isOpen
	self:showHide()
end

pHuansanzhang.showHide = function(self)
	if self.isOpen then
		self:showSelf(true)
		self.wnd_open:setPosition(self.openPos, 0)
		self.wnd_open:setImage("ui:battle_huan_close.png")
	else
		self:showSelf(false)
		self.wnd_open:setImage("ui:battle_huan_open.png")
		self.wnd_open:setPosition(self.openPos + self:getWidth(), 0)
	end
	self:showWnds(self.isOpen)
end

pHuansanzhang.showWnds = function(self, isShow)
	self:showSelf(isShow)
	for _, wnd in pairs(self.cardWnds) do
		wnd:show(isShow)
	end
	self.wnd_from_name:show(isShow)
	self.wnd_to_name:show(isShow)
end

pHuansanzhang.showCards = function(self)
	-- 换回
	self:drawCards(self.fromCards, self.wnd_from_card)
	-- 换出
	self:drawCards(self.toCards, self.wnd_to_card)
end

pHuansanzhang.drawCards = function(self, cards, parentWnd)
	if not cards or not parentWnd then return end
	local scale = 0.45
	local width, height = 89 * scale, 135 * scale
	local x, y = 0, 0
	for _, id in ipairs(cards) do
		local wnd = modCardWnd.pCardWnd:new(T_SEAT_MINE, id, width, height, T_CARD_SHOW)
		wnd:enableEvent(false)
		wnd:setParent(parentWnd)
		wnd:setAlignX(ALIGN_RIGHT)
		wnd:setAlignY(ALIGN_MIDDLE)
		wnd:setOffsetX(x)
		x = x - width
		table.insert(self.cardWnds, wnd)
	end
end

pHuansanzhang.setPos = function(self, x, y)
	if x then self:setOffsetX(x) end
	if y then self:setPosition(0, y) end
end

pHuansanzhang.setParentWnd = function(self, parentWnd)
	if parentWnd then
		self:setParent(parentWnd)
	end
end

pHuansanzhang.close = function(self)
	if self.__update_user_prop then
		modEvent.removeListener(self.__update_user_prop)
		self.__update_user_prop = nil
	end
	pHuansanzhang:cleanInstance()
end
