local modSound = import("logic/sound/main.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modAskWnd = import("ui/common/askwindow.lua")
local modSuggMenu = import("ui/battle/suggestionmenu.lua")
local modUtil = import("util/util.lua")

pCardWnd = pCardWnd or class(pWindow)

pCardWnd.init = function(self, seatId, cardId, w, h, showType, host, magicCard, trueType)
	self.cardId = cardId
	self:setSize(w, h)
	self.w = w
	self.h = h
	self.seatId = seatId
	self.diCardId = modBattleMgr.getCurBattle():getCurGame():getDiCardId()
	self.chooseFlag = false
	local modUIUtil = import("ui/common/util.lua")
	if modUIUtil.getIsNormalCard then
		if not modUIUtil.getIsNormalCard(self.cardId) then
			showType = T_CARD_SHOW_HIDE
		end
	end
	self.showType = showType
	local img = ""
	if showType == T_CARD_SHOW_HIDE then
		img = sf("ui:card/%d/show_hide.png", seatId)
	elseif showType == T_CARD_SHOW or showType == T_CARD_DISCARD then
		if seatId == 0 then
			seatId = 2
		end
		img = sf("ui:card/%d/show_%d.png", seatId, cardId)
	else
		-- T_CARD_HAND
		if seatId == 0 then
			img = sf("ui:card/0/hand_%d.png", cardId)
		else
			img = sf("ui:card/hand_%d.png", seatId)
		end
	end
	self:setImage(img)

	-- 点击事件
	if seatId == T_SEAT_MINE then 
		if 	showType == T_CARD_HAND then
			self:addListener("ec_mouse_click", function()
				self:onChoose()
			end)
			self:addListener("ec_mouse_left_down", function(e)
				self.isDrag = false
				self.downPoint = {e:ax(), e:ay()}
			end)
			self:addListener("ec_mouse_left_up",function()
				if self.isDrag == true then
					if self:getOffsetY() < -100 then
						self:tryDiscardCard()
					end
					self:setOffsetY(0)
					self:setOffsetX(0)
				end
				self.isDrag = false
				self.downPoint = nil
			end)
			self:addListener("ec_mouse_drag",function(e)
				if self.host:getNotDragCard(self) then 
					return
				end
				if self.downPoint then
					local x = e:ax()
					local y = e:ay()
					if modUtil.distance(self.downPoint, {x, y}) > 20 then
						self.isDrag = true
						local dy = e:dy()
						local dx = e:dx()
						local y = math.min(self:getOffsetY() + dy, 0)
						local x = self:getOffsetX() + dx
						self:setOffsetY(y)
						self:setOffsetX(x)
					end
				end
				--	end
			end)
		else
			self:addClick(showType)
		end
	else
		self:addClick(showType)
	end
	self.host = host
	if  (showType ~= T_CARD_HAND -- 不是手牌
		or (self.seatId == T_SEAT_MINE)) and showType ~= T_CARD_SHOW_HIDE then-- 自己的明牌(combs)
		local gui = self:magicCard(self.seatId, showType, trueType)
--		local di = self:diCard(self.seatId, showType, trueType)
		-- 弃牌
		if showType == T_CARD_DISCARD and gui then
			if self.seatId == T_SEAT_MINE then			
				if (modBattleMgr:getCurBattle():getCurGame():getRuleType() == 14) then					
					gui:setImage("ui:calculate_gui_ph.png")
				else
					gui:setImage("ui:calculate_gui.png")
				end
				-- gui:setImage("ui:calculate_gui.png")
				gui:setSize(100 * 0.38,132 * 0.38)
				gui:setAlignY(ALIGN_BOTTOM)
				gui:setOffsetY(2)
				gui:setPosition(-1, -2)
			elseif self.seatId == T_SEAT_OPP then
				gui:setSize(100 * 0.38, 132 * 0.38)				
				if (modBattleMgr:getCurBattle():getCurGame():getRuleType() == 14) then
					gui:setImage("ui:calculate_gui_ph.png")
				else
					gui:setImage("ui:calculate_gui.png")
				end
				-- gui:setImage("ui:calculate_gui.png")
				gui:setAlignY(ALIGN_BOTTOM)
				gui:setOffsetY(2)
				gui:setPosition(-1, -2)
			elseif self.seatId == T_SEAT_LEFT then
				if (modBattleMgr:getCurBattle():getCurGame():getRuleType() == 14) then
					gui:setImage("ui:right_magic_ph.png")
				else
					gui:setImage("ui:right_magic.png")
				end	
				-- gui:setImage("ui:right_magic.png")
				gui:setSize(64, 48)
				gui:setPosition(0, -3.5)
			else
				if (modBattleMgr:getCurBattle():getCurGame():getRuleType() == 14) then
					gui:setImage("ui:left_magic_ph.png")
				else
					gui:setImage("ui:left_magic.png")
				end
				-- gui:setImage("ui:left_magic.png")
				gui:setSize(60, 48)
				gui:setPosition(gui:getX() - 2, gui:getY() - 1)
			end
		end
	end
end

pCardWnd.addClick = function(self, showType)
	self:addListener("ec_mouse_click", function()
		-- isOver
		if (showType ~= T_CARD_HAND and showType ~= T_CARD_SHOW_HIDE or modBattleMgr.getCurBattle():getIsCalculate()) then
			self.host:updateCardIsShow(self.cardId)
			self.host:updateAllPlayersTingCard()
		end
	end)
end

pCardWnd.magicCard = function(self, seatId, showType, trueType)
	if self:isMagicCard(self.cardId) then
		-- 默认手牌
		local gui = pWindow():new()
		gui:setName("wnd_gui")
		gui:setParent(self)
		gui:setPosition(-2, -2)
		gui:setAlignX(ALIGN_LEFT)
		gui:setSize(100 * 0.9, 132 * 0.9)
		--平和金牌用不同的UI		
		if (modBattleMgr:getCurBattle():getCurGame():getRuleType() == 14) then
			gui:setImage("ui:battle_magic_ph.png")
		else
			gui:setImage("ui:battle_magic.png")
		end				
		gui:setColor(0xFFFFFFFF)

		-- 明牌
		if showType == T_CARD_SHOW then
			if seatId == T_SEAT_MINE then
				if (modBattleMgr:getCurBattle():getCurGame():getRuleType() == 14) then			
					gui:setImage("ui:calculate_gui_ph.png")
				else
					gui:setImage("ui:calculate_gui.png")
				end	
				gui:setSize(self.w * 0.69,self.h * 0.69)
				gui:setAlignY(ALIGN_BOTTOM)
				gui:setOffsetY(2)
				gui:setPosition(-2, 0)
			elseif seatId ==T_SEAT_RIGHT then
				gui:setImage("ui:left_magic.png")
				gui:setSize(60, 48)
				gui:setPosition(gui:getX() - 2, gui:getY() - 1)
			elseif seatId == T_SEAT_OPP then
				if (modBattleMgr:getCurBattle():getCurGame():getRuleType() == 14) then			
					gui:setImage("ui:calculate_gui_ph.png")
				else
					gui:setImage("ui:calculate_gui.png")
				end		
				gui:setPosition(-2, 0)
				gui:setSize(100 * 0.41, 132 * 0.41)
				gui:setAlignY(ALIGN_BOTTOM)
				gui:setOffsetY(2)
			elseif seatId == T_SEAT_LEFT then
				gui:setImage("ui:right_magic.png")
				gui:setSize(64, 48)
				gui:setAlignX(ALIGN_RIGHT)
				gui:setPosition(0, gui:getY() - 1)
				gui:setOffsetX(4)
			end
		end
		self[gui:getName()] = gui
		self.magicCardWnd = gui
		return gui
	end
end

pCardWnd.getGuiMark = function(self)
	return self["wnd_gui"]
end

pCardWnd.diCard = function(self, seatId, showType, trueType)
	if modBattleMgr.getCurBattle():getCurGame():isRongChengMJ() then
		return 
	end
	if self.cardId == self.diCardId then
		-- 默认手牌
		local di = pWindow():new()
		di:setName("wnd_di")
		di:setParent(self)
		di:setPosition(-2, -2)
		di:setAlignX(ALIGN_LEFT)
		di:setSize(100 * 0.9, 139 * 0.9)
		di:setImage("ui:battle_di.png")
		di:setColor(0xFFFFFFFF)

		-- 明牌
		if showType == T_CARD_SHOW then
			if seatId == T_SEAT_MINE then
				di:setSize(100 * 0.63, 132 * 0.63)
				di:setPosition(-2, 0)
				di:setImage("ui:calculate_di.png")
				di:setOffsetY(3)
				di:setAlignY(ALIGN_BOTTOM)
			elseif seatId ==T_SEAT_LEFT then
				di:setImage("ui:left_di.png")
				di:setSize(60, 48)
				di:setAlignX(ALIGN_RIGHT)
				di:setPosition(0, - 3)
				di:setOffsetX(4)
			elseif seatId == T_SEAT_OPP then
				di:setImage("ui:calculate_di.png")
				di:setSize(100 * 0.41, 132 * 0.41)	
				di:setPosition(0, -1)	
				di:setOffsetY(2)
				di:setAlignY(ALIGN_BOTTOM)
			elseif seatId == T_SEAT_RIGHT then
				di:setImage("ui:right_di.png")
				di:setSize(60, 48)
				di:setPosition(di:getX() - 3, di:getY() - 3)

			end
		end
		self[di:getName()] = di
		return di
	end
end

pCardWnd.chooseWork = function(self, isNotUpdatePos)
	self.chooseFlag = true
	self:setColor(0xFFEEEE00)
	self.host:chooseSetColor(self)
	if isNotUpdatePos then return end
	self:updateChangePos()
end

pCardWnd.resetWork = function(self, isNotUpdatePos)
	self.chooseFlag = false
	self:setColor(0xFFFFFFFF)
	if self.host then self.host:resetSetColor(self) end
	if isNotUpdatePos then return end
	self:updateChangePos()
end

pCardWnd.updateChangePos = function(self)
	if self.chooseFlag then
		self:setOffsetY(-self:getHeight() / 6)
	else
		self:setOffsetY(0)
	end
end

pCardWnd.updateIsChoosePos = function(self)
	if self.chooseFlag then
		self:setOffsetY(-self:getHeight() / 6)
	else
		self:setOffsetY(0)
	end
end

pCardWnd.onChoose = function(self)
	self.host:setMineHandCard(self)
end

pCardWnd.setPos = function(self, pos)
	if self.seatId == T_SEAT_MINE then
		self:setPosition(pos, 0)
	elseif self.seatId == T_SEAT_OPP then
		self:setOffsetX(-pos)
	elseif self.seatId == T_SEAT_RIGHT then
		self:setOffsetY(-pos)
	else
		self:setPosition(0, pos)
	end
end

pCardWnd.getPos = function(self)
	if self.seatId == T_SEAT_MINE then
		return self:getX()
	elseif self.seatId == T_SEAT_OPP then
		return self:getOffsetX()
	elseif self.seatId == T_SEAT_RIGHT then
		return self:getOffsetY()
	else
		return self:getY()
	end
end


pCardWnd.getCardId = function(self)
	return self.cardId
end

pCardWnd.setChooseFlag = function(self,isChoose)
	self.chooseFlag = isChoose
end

pCardWnd.reSet =  function(self)
end

pCardWnd.getShowType = function(self)
	return self.showType 
end

pCardWnd.getIsMingState = function(self)
end

pCardWnd.getSelfIsNotInSuggestionList = function(self)
	local notCards = self.host:getNotInSuggestionListCards()
	return self.host:findCardIsInList(self, notCards)	
end

pCardWnd.tryDiscardCard = function(self)
	-- 是否可以打牌
	if not modBattleMgr.getCurBattle():getCurGame():getIsCanDiscardCard(self.cardId) then return end

	if self.askWnd then self.askWnd = nil end
	if self.host:getIsShowDiscardMagic(self) then
		local str = "您确定打出王牌吗?"
--[[		if self:isDiCard() then 
			str = "您确定要打出地牌吗?"
		end]]--
		self.askWnd = modAskWnd.pAskWnd:new(self, str, function(success) 
			if success then self:discard() end
			self:clearAskWnd()
		end)
		self.askWnd:setParent(self.host.wnd_table)
	else
		self:discard()
	end
end

pCardWnd.clearAskWnd = function(self)
	if not self.askWnd then return end
	self.askWnd:setParent(nil)
	self.askWnd = nil
end

pCardWnd.discard = function(self)
	self:show(false)
	self.host:tryDiscardCard(self, function(success)
		if success then
		else
			self:resetWork()	
			self:show(true)
		end
	end)
end

pCardWnd.isOnChoose = function(self)
	return self.chooseFlag
end

pCardWnd.isMagicCard = function(self)
	local cards = modBattleMgr.getCurBattle():getCurGame():getMagicCard()
	if not cards then return end
	local result = false
	for _, mId in pairs(cards) do
		if self.cardId == mId then
			result = true
			break
		end
	end
	return result
end

pCardWnd.isDiCard = function(self)
	local dId = modBattleMgr.getCurBattle():getCurGame():getDiCardId()
	if not dId then return false end
	return self.cardId == dId
end

pCardWnd.isOnChoose = function(self)
	return self.chooseFlag
end

pCardWnd.addSuggClick = function(self)
	if not self.winCards then return end
	if not self.chooseFlag then return end
	self:clearSuggMenuWnd()
	modSuggMenu.pSuggestionMenu:instance():open(self.winCards)
end

pCardWnd.clearSuggMenuWnd = function(self)
	if modSuggMenu.pSuggestionMenu:getInstance() then
		modSuggMenu.pSuggestionMenu:instance():close()
	end
end

pCardWnd.setWinCards = function(self, wCards)
	if not wCards then return end
	self.winCards = wCards
end
