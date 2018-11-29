local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modUIUtil = import("ui/common/util.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modCardWnd = import("ui/battle/card.lua")

pHuCardWnd = pHuCardWnd or class(pWindow)

pHuCardWnd.init = function(self, x, y, pid, ids)
	self:load("data/ui/huwnd.lua")
	self:setParent(modBattleMgr.getCurBattle():getBattleUI().wnd_table)
	self:setPosition(x, y)
	self.pid = pid
	self.isExpend = true
	self.originWidth = self:getWidth() - 60 + self.wnd_right:getWidth()
	self.expendWidth = nil
	self.cardIds = ids
	self:setZ(C_BATTLE_UI_Z)
	self:addListener("ec_mouse_click", function() 
		self.isExpend = not self.isExpend
		self:updateExpend()
	end)
	-- 取张数
	self:updateCountText()
	self:showCards()
end

pHuCardWnd.updateExpend = function(self)
	if self.isExpend then 
		self.wnd_list:show(true)
		self.wnd_right:setImage("ui:daikai_back.png")
		self:setSize(self.expendWidth, self:getHeight())
	else
		self.wnd_list:show(false)
		self.wnd_right:setImage("ui:daikai_next.png")
		self:setSize(self.originWidth, self:getHeight())
	end
end

pHuCardWnd.showCards = function(self)
	if not self.pid or not self.cardIds then return end
	
	local battle = modBattleMgr.getCurBattle()
	local battleUI = battle:getBattleUI()
	local pidToSeat = battle:getSeatMap()	
	local seatId = pidToSeat[self.pid]
	local width, height = battleUI:getShowCardSize(T_SEAT_MINE)
	local maxCardCount = 10
	
	local scale = 0.5
	local maxX = 4
	local x, y = 0, 0
	local bgWidth, bgHeight = self:getWidth() + (table.getn(self.cardIds) - 1) * width * scale + self.wnd_right:getWidth(), self:getHeight() 	
	for idx, id in pairs(self.cardIds) do
		local wnd = modCardWnd.pCardWnd:new(T_SEAT_MINE, id, width * scale, height * scale, T_CARD_SHOW, battleUI)
		wnd:setParent(self.wnd_list)
		wnd:enableEvent(false)
		wnd:setAlignY(ALIGN_MIDDLE)
		wnd:setPosition(x, y)
		x = x + wnd:getWidth() - 3.5
		if idx > maxCardCount then 
			bgWidth = self:getWidth() + (maxCardCount - 1) * width * scale + self.wnd_right:getWidth()
			break
		end
	end
	self:setSize(bgWidth, bgHeight)
	self.expendWidth = bgWidth
end

pHuCardWnd.findCardCount = function(self, id)
	if not id then return 0 end
	local count = 4
	for i = T_SEAT_MINE, T_SEAT_LEFT do
		local num = modUIUtil.findCardBySeat(i, id)
		if num then
			count = count - num 
		end
	end
	if count < 0 then
		count = 0
	end
	return count	
end

pHuCardWnd.updateCountText = function(self)
	local count = 0
	for _, id in pairs(self.cardIds) do
		count = count + self:findCardCount(id) 
	end
	self.wnd_count:setText(count)
end
