local modPokerUtil = import("logic/card_battle/util.lua")
local modSound = import("logic/sound/main.lua")

SCALE = 1.5
pHandCards = pHandCards or class(pWindow)

pHandCards.init = function(self, player)
	local seat = player:getSeatId()

	if seat == 1 then
		self:load("data/ui/card/paijiu_hand_pool2.lua")

		local w, h = self.txt_pj_type:getWidth(), self.txt_pj_type:getHeight()
		self.txt_pj_type:setKeyPoint(w/2, h/2)

		self.txt_pj_type:setOffsetX(w/2)
	else
		self:load("data/ui/card/paijiu_hand_pool.lua")

		local w, h = self.txt_pj_type:getWidth(), self.txt_pj_type:getHeight()
		self.txt_pj_type:setKeyPoint(w/2, h/2)

		self.txt_pj_type:setOffsetX(w + w/2)
	end
	self:enableEvent(true)
	self.idx = 1
	self.cards = {}
	self.player = player
	self.wnd_card1.canDrag = false
	self.wnd_card1:addListener("ec_mouse_drag", function(e)
		if not self.wnd_card1.canDrag then return end
		local dx, dy = e:dx(), e:dy()
		self.wnd_card1:move(dx, dy)
		self:checkCuoPai(0.95)
	end)

	self.wnd_card1:addListener("ec_mouse_left_up", function(e)
		if not self.wnd_card1.canDrag then return end
		self:checkCuoPai(0.5)
	end)
end

pHandCards.showPjType = function(self, flag, pjType)
	if flag then
		if self.player:isFake() or self.player:isBankrupt() then
			return
		end
		local cardIds = {}
		for _, card in ipairs(self.cards) do
			table.insert(cardIds, card:getCardId())
		end
		local pjName = modPokerUtil.getPaijiuHandTypeName(pjType, cardIds)
		self.txt_pj_type:setText(pjName)
		local soundPath = modPokerUtil.getPaijiuSoundPath(pjType, cardIds, self.player:getGender())
		modSound.getCurSound():playSound(soundPath)
	end
	self.txt_pj_type:show(flag)
	self:playTypeEffect()
end

pHandCards.playTypeEffect = function(self)
	runProcess(1, function()
		for i=2,1,-0.1 do
			self.txt_pj_type:setScale(i, i)
			yield()
		end
		for i=1,1.2, 0.05 do
			self.txt_pj_type:setScale(i, i)
			yield()
		end
		for i=1.2,1, -0.1 do
			self.txt_pj_type:setScale(i, i)
		end
	end)
end

pHandCards.addCards = function(self, cards)
	if #cards <= 0 then
		return
	end
	if self.savePos then
		self.wnd_card1:setPosition(self.savePos[1][1], self.savePos[1][2])
		self.wnd_card2:setPosition(self.savePos[2][1], self.savePos[2][2])
	end

	for _, card in ipairs(cards) do
		logv("info", "=========== addCards: ", card:getCardId())
		table.insert(self.cards, card)
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
			self:onAddCard(card)
		end
	end
end

pHandCards.onAddCard = function(self, card)
	local player = card:getOwner()
	local tableWnd = player:getTableWnd()
	local fromCard = tableWnd:getNextFlyCard()
	local cardWnd = card:getCardWnd()

	if not fromCard then
		if self.idx > 2 then
			cardWnd:setShowState(ST_CARD_BACK)
		else
			cardWnd:setShowState(ST_CARD_SHOW)
		end
		return
	end
	local wnd = fromCard.__card_wnd
	local fx, fy = fromCard:getX(true), fromCard:getY(true)
	local tx, ty = cardWnd:getX(true), cardWnd:getY(true)
	local dx, dy = fx - tx, fy - ty
	local x, y = cardWnd:getX(), cardWnd:getY()
	local idx = self.idx
	cardWnd:setShowState(ST_CARD_BACK)
	cardWnd:show(false)
	local start_scale = 0.647
	runProcess(1, function()
		if idx > 2 then
			wait(6)
		end
		if wnd then
			wnd:setShowState(ST_CARD_HIDE)
		end
		cardWnd:show(true)
		local modSound = import("logic/sound/main.lua")
		modSound.getCurSound():playSound("sound:card_game/pushcard.mp3")
		for i=1,0,-0.2 do
			local scale = start_scale + (1-i) * (1 - start_scale)
			cardWnd:setScale(scale, scale)
			cardWnd:setPosition(x + dx * i, y + dy * i)
			yield()
		end
		cardWnd:setPosition(x, y)

		if not player:isMyself() then
			cardWnd:setShowState(ST_CARD_BACK)
		else
			--if player:getBattle():isKzwf() then
			--	cardWnd:setShowState(ST_CARD_SHOW)
			--else
				if idx > 2 then
					cardWnd:setShowState(ST_CARD_BACK)
				else
					cardWnd:setShowState(ST_CARD_SHOW)
				end
			--end
		end

	end)
end

pHandCards.startCuoPai = function(self, callback)
	if self.cuoPaing then return end

	self.callback =  callback

	if not self.savePos then
		local x1, y1 = self.wnd_card1:getX(), self.wnd_card1:getY()
		local x2, y2 = self.wnd_card2:getX(), self.wnd_card2:getY()
		self.savePos = {{x1, y1}, {x2, y2}}
	end
	local x1, y1 = self.savePos[1][1], self.savePos[1][2]
	local x2, y2 = self.savePos[2][1], self.savePos[2][2]

	local scale = SCALE
	local h = self.wnd_card1:getHeight()
	runProcess(1, function()
		for i=0,1,0.2 do
			local s = 1 + scale * i
			self.wnd_card1:setPosition(x1 + (x2 - x1) * i/2, y1 + (y2 - y1) * i/2 - h * scale * i )
			self.wnd_card1:setScale(s, s)
			self.wnd_card2:setPosition(x2 + (x1-x2)*i/2, y2 + (y1-y2) * i/2 - h * scale * i)
			self.wnd_card2:setScale(s, s)
			yield()
		end
		self.wnd_card2.__card_wnd:setShowState(ST_CARD_SHOW)
		self.wnd_card1.canDrag = true
	end)
	self.cuoPaing = true
end

pHandCards.endCuoPai = function(self)
	if not self.cuoPaing then return end
	self.wnd_card1.canDrag = false
	self.cuoPaing = false
	if not self.savePos then return end
	local x1, y1 = self.wnd_card1:getX(), self.wnd_card1:getY()
	local x2, y2 = self.wnd_card2:getX(), self.wnd_card2:getY()
	local ci1, ci2 = 1, 2
	if x1 > x2 then
		ci1, ci2 = 2, 1
	end
	local scale = self.wnd_card1:getSX() - 1
	runProcess(1, function()
		for i=0,1,0.05 do
			local s = 1 + scale * (1 - i)
			self.wnd_card1:setPosition(x1 + (self.savePos[ci1][1] - x1) * i,
						   y1 + (self.savePos[ci1][2] - y1) * i)
			self.wnd_card1:setScale(s, s)
			self.wnd_card2:setPosition(x2 + (self.savePos[ci2][1] - x2) * i,
						   y2 + (self.savePos[ci2][2] - y2) * i)
			self.wnd_card2:setScale(s, s)
			yield()
		end
		self.wnd_card2:setScale(1, 1)
		self.wnd_card1:setScale(1, 1)
		self.wnd_card1:setPosition(self.savePos[ci1][1], self.savePos[ci1][2])
		self.wnd_card2:setPosition(self.savePos[ci2][1], self.savePos[ci2][2])
	end)
	--self.wnd_card1:setPosition(self.savePos[1][1], self.savePos[1][2])
	--self.wnd_card2:setPosition(self.savePos[2][1], self.savePos[1][2])
end

pHandCards.checkCuoPai = function(self, scale)
	local x1 = self.wnd_card1:getX()
	local x2 = self.wnd_card2:getX()

	local y1 = self.wnd_card1:getY()
	local y2 = self.wnd_card2:getY()
	if math.abs(x2 - x1) >= self.wnd_card1:getWidth() * (1 + SCALE) * scale or math.abs(y2 - y1) >= self.wnd_card1:getHeight() * (1 + SCALE) * scale then
		-- 交换
		if self.callback then
			self.callback()
		end

		-- self:endCuoPai()
	end
end

pHandCards.showHands = function(self, pjType)
	for i = 1, 2 do
		local parent = self[sf("wnd_card%d", i)]
		if parent and parent.__card_wnd then
			parent.__card_wnd:setShowState(ST_CARD_SHOW)
		end
	end
	self:showPjType(true, pjType)
end

pHandCards.reset = function(self)
	for i = 1, 2 do
		local parent = self[sf("wnd_card%d", i)]
		if parent and parent.__card_wnd then
			parent.__card_wnd:setParent(nil)
			parent.__card_wnd = nil
		end
	end
	self.idx = 1
	self:showPjType(false)
	self.cards = {}
end

pHandCards.destroy = function(self)
	self:reset()
	self:setParent(nil)
end
