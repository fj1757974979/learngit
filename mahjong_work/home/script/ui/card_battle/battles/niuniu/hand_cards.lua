local modNiuniuProto = import("data/proto/rpc_pb2/pokers/niuniu_pb.lua")
local modPokerUtil = import("logic/card_battle/util.lua")
local modEasing = import("common/easing.lua")

pHandCards = pHandCards or class(pWindow)

pHandCards.init = function(self, player)
	self:load(self:getTemplate())
	self.wnd_niu:show(false)
	self:enableEvent(false)
	self.idx = 1
	self.player = player
end

pHandCards.getTemplate = function(self)
	return "data/ui/card/niuniu_hand_pool_other.lua"
end

pHandCards.showNiuType = function(self, flag, niuType)
	log("warn", "showNiuType", flag, niuType)
	if flag then
		local img = modPokerUtil.getNiuImageByType(niuType)
		log("info", "++++++++ ", img)
		--self.img_niu:setImage(img)
		self.img_niu:showSelf(false)
		self:playNiuType(self.img_niu, niuType)
	end
	self.wnd_niu:show(flag)
	self.wnd_niu:showSelf(false)
end

pHandCards.playNiuType = function(self, parent, niuType)
	if self.effect then
		self.effect:setParent(nil)
		self.effect = nil
	end
	local img = modPokerUtil.getNiuImageByType(niuType)
	local effect = pSprite()
	effect:setTexture(img, 0)
	effect:setParent(parent)
	effect:setZ(C_BATTLE_UI_Z)
	--effect:setAlignY(ALIGN_MIDDLE)
	--effect:setAlignX(ALIGN_CENTER)
	--effect:setScale(2, 2)
	effect:setPosition(parent:getWidth()/2, parent:getHeight()/2)
	effect:play(1, false)
	self.effect = effect
end

pHandCards.addCards = function(self, cards)
	if #cards <= 0 then
		return
	end
	runProcess(10, function()
		for _, card in ipairs(cards) do
			local cardWnd = card:getCardWnd()
			local parent = self[sf("wnd_card%d", self.idx)]
			if parent then
				self.idx = self.idx + 1
				cardWnd:setParent(parent)
				cardWnd:setSize(parent:getWidth(), parent:getHeight())
				if parent.__card_wnd then
					parent.__card_wnd:setParent(nil)
				end
				parent.__card_wnd = cardWnd
				self:onAddCard(card, #cards == 1)
				yield()
			end
		end
	end)
end

pHandCards.onAddCard = function(self, card, backMode)
	card:getCardWnd():setBackMode()
	local cardWnd = card:getCardWnd()
	local cx,cy = gGameWidth/2 - cardWnd:getWidth()/2, gGameHeight/2 - cardWnd:getHeight()/2
	cardWnd:setPosition(0, 0)
	local dx, dy = cx - cardWnd:getX(true), cy - cardWnd:getY(true)
	cardWnd:setPosition(dx, dy)
	local modSound = import("logic/sound/main.lua")
	modSound.getCurSound():playSound("sound:card_game/pushcard.mp3")
	runProcess(1, function()
		for i=1, 0, -0.1 do
			cardWnd:setPosition(dx * i, dy * i)
			yield()
		end
	end)
end

pHandCards.hintNiuCards = function(self, cardIds)
	return
end

pHandCards.resetNiuCards = function(self)
	return
end

pHandCards.getChosenCards = function(self)
	return {}
end

pHandCards.showHands = function(self, niuType)
	-- TODO
	-- 播放声音（先后顺序）
	for i = 1, 5 do
		local parent = self[sf("wnd_card%d", i)]
		if parent and parent.__card_wnd then
			parent.__card_wnd:setShowMode()
		end
	end
	self:showNiuType(true, niuType)
end

pHandCards.reset = function(self)
	for i = 1, 5 do
		local parent = self[sf("wnd_card%d", i)]
		if parent and parent.__card_wnd then
			parent.__card_wnd:setParent(nil)
			parent.__card_wnd = nil
		end
		if parent and parent.__lsn then
			parent:removeListener(parent.__lsn)
			parent.__lsn = nil
		end
	end
	self.idx = 1
	self:showNiuType(false)
end

pHandCards.destroy = function(self)
	self:reset()
	self:setParent(nil)
end

------------------------------------------------------------

pHandCardsSelf = pHandCardsSelf or class(pHandCards)

pHandCardsSelf.init = function(self)
	pHandCards.init(self)
	self.chosenCards = {}
	for i = 1, 5 do
		local parent = self[sf("wnd_card%d", i)]
		if parent then
			parent:addListener("ec_mouse_click", function()
				if not self.__cuo_pai_mode then
					parent:setChosen(not parent:isChosen())
				end
			end)
			parent.setChosen = function(wnd, flag)
				if flag then
					if wnd.__card_wnd then
						wnd:setOffsetY(-50)
						self.chosenCards[wnd] = true
						wnd.__chosen = flag
					end
				else
					wnd:setOffsetY(0)
					self.chosenCards[wnd] = nil
					wnd.__chosen = flag
				end
			end
			parent.isChosen = function(wnd)
				return wnd.__chosen
			end
		end
	end
end

pHandCardsSelf.getTemplate = function(self)
	return "data/ui/card/niuniu_hand_pool_self.lua"
end

pHandCardsSelf.getChosenCardIds = function(self)
	local ret = {}
	for wnd, _ in pairs(self.chosenCards) do
		if wnd.__card_wnd then
			table.insert(ret, wnd.__card_wnd:getCard():getCardId())
		end
	end
	logv("info", "======== getChosenCardIds", ret)
	return ret
end

pHandCardsSelf.playNiuType = function(self, parent, niuType)
	pHandCards.playNiuType(self, parent, niuType)
	self.effect:setScale(1.5, 1.5)
end

pHandCardsSelf.onAddCard = function(self, card, backMode)
	card:getCardWnd():setBackMode()
	local cardWnd = card:getCardWnd()
	local cx,cy = gGameWidth/2 - cardWnd:getWidth()/2, gGameHeight/2 - cardWnd:getHeight()/2
	cardWnd:setPosition(0, 0)
	local dx, dy = cx - cardWnd:getX(true), cy - cardWnd:getY(true)
	cardWnd:setPosition(dx, dy)
	local modSound = import("logic/sound/main.lua")
	modSound.getCurSound():playSound("sound:card_game/pushcard.mp3")
	runProcess(1, function()
		for i=1, 0, -0.1 do
			cardWnd:setPosition(dx * i, dy * i)
			yield()
		end
		cardWnd:setKeyPoint(cardWnd:getWidth()/2, 0)
		cardWnd:setPosition(cardWnd:getWidth()/2, 0)
		if not backMode then
			for i=0,math.pi,0.2 do
				cardWnd:setRot(0,i,0)
				if i>math.pi/2 then
					cardWnd:setRot(0,math.pi+i,0)
					card:getCardWnd():setShowMode()
				end
				yield()
			end
			cardWnd:setKeyPoint(0, 0)
			cardWnd:setRot(0,0,0)
			cardWnd:setPosition(0, 0)
			card:getCardWnd():setShowMode()
		end
	end)
end

pHandCardsSelf.hintNiuCards = function(self, cardIds)
	log("error", "======== hintNiuCards", cardIds)
	if #cardIds > 0 then
		local mapCardIds = {}
		for _, cardId in ipairs(cardIds) do
			mapCardIds[cardId] = true
		end
		for i = 1, 5 do
			local parent = self[sf("wnd_card%d", i)]
			if parent and parent.__card_wnd then
				local card = parent.__card_wnd:getCard()
				if mapCardIds[card:getCardId()] then
					parent:setChosen(true)
				end
			end
		end
	end
	self:enableEvent(true)
end

pHandCardsSelf.resetNiuCards = function(self)
	for i = 1, 5 do
		local parent = self[sf("wnd_card%d", i)]
		if parent and parent.__card_wnd then
			parent:setChosen(false)
		end
	end
	self:enableEvent(false)
end

pHandCardsSelf.showHands = function(self, niuType)
	-- TODO
	-- 播放声音（先后顺序）
	for i = 1, 5 do
		local parent = self[sf("wnd_card%d", i)]
		if parent and parent.__card_wnd then
			parent.__card_wnd:setShowMode()
		end
	end
	self:showNiuType(true, niuType)
end

pHandCardsSelf.setCuoPaiMode = function(self, flag, callback)
	local one = self.wnd_card4
	local hide = self.wnd_card5
	if not one.__x then
		one.__x = one:getX()
	end
	if not hide.__x then
		hide.__x = hide:getX()
	end
	self.__cuo_pai_mode = flag
	if flag then
		self:enableEvent(false)
		one:setKeyPoint(one:getWidth()/2, one:getHeight()/2)
		hide:setKeyPoint(hide:getWidth()/2, hide:getHeight()/2)
		one:setOffsetX(one:getWidth()/2)
		hide:setOffsetX(hide:getWidth()/2)
		one:setZ(-11)
		hide:setZ(-10)
		hide.__card_wnd:setShowMode()
		runProcess(1, function()
			local offy = -100
			local tx = self.wnd_card3:getX()
			local ts = 1.5
			local t = 10
			for i = 1, t do
				local s = modEasing.linear(i, 1, ts - 1, t)
				local x1 = modEasing.linear(i, one:getX(), tx - one:getX(), t)
				local x2 = modEasing.linear(i, hide:getX(), tx - hide:getX(), t)
				local oy = modEasing.linear(i, 0, offy, t)
				one:setScale(s, s)
				one:setPosition(x1, 0)
				one:setOffsetY(oy)
				hide:setScale(s, s)
				hide:setPosition(x2, 0)
				hide:setOffsetY(oy)
				yield()
			end
			local diffx = 0
			local diffy = 0
			self:enableEvent(true)
			one.__lsn = one:addListener("ec_mouse_drag", function(e)
				if self.__cuo_pai_mode then
					one:setOffsetX(e:dx() + one:getOffsetX())
					one:setOffsetY(e:dy() + one:getOffsetY())
					diffx = e:dx() + diffx
					diffy = e:dy() + diffy
					if math.abs(diffx) >= hide:getWidth() * hide:getSX() or
						math.abs(diffy) >= hide:getHeight() * hide:getSY() then
						diffx = 0
						diffy = 0
						if callback then
							callback()
						end
					end
				end
			end)
		end)
	else
		self:enableEvent(false)
		runProcess(1, function()
			local t = 10
			local foffx1 = one:getOffsetX()
			local foffy1 = one:getOffsetY()
			local foffx2 = hide:getOffsetX()
			local foffy2 = hide:getOffsetY()
			local fx1 = one:getX()
			local fx2 = hide:getX()
			for i = 1, t do
				local offx1 = modEasing.linear(i, foffx1, - foffx1, t)
				local offy1 = modEasing.linear(i, foffy1, - foffy1, t)
				one:setOffsetX(offx1)
				one:setOffsetY(offy1)

				local offx2 = modEasing.linear(i, foffx2, - foffx2, t)
				local offy2 = modEasing.linear(i, foffy2, - foffy2, t)
				hide:setOffsetX(offx2)
				hide:setOffsetY(offy2)

				local s = modEasing.linear(i, 1.5, -0.5, t)
				one:setScale(s, s)
				hide:setScale(s, s)

				local x1 = modEasing.linear(i, fx1, one.__x - fx1, t)
				local x2 = modEasing.linear(i, fx2, hide.__x - fx2, t)
				one:setPosition(x1, 0)
				hide:setPosition(x2, 0)
				yield()
			end
			one:setOffsetX(0)
			hide:setOffsetX(0)
			one:setOffsetY(0)
			hide:setOffsetY(0)
			one:setPosition(one.__x, 0)
			hide:setPosition(hide.__x, 0)
			one:setKeyPoint(0, 0)
			hide:setKeyPoint(0, 0)
			one:setZ(-4)
			hide:setZ(-5)
			one:setScale(1, 1)
			hide:setScale(1, 1)
			one:setAlignX(ALIGN_LEFT)
			hide:setAlignX(ALIGN_LEFT)
		end)
	end
end
