
pPaijiuCardWnd = pPaijiuCardWnd or class(pWindow)

pPaijiuCardWnd.init = function(self, card)
	self:load("data/ui/card/paijiu_card.lua")
	self.card = card
	self:show(false)

	self:addListener("ec_mouse_click", function()
		self.card:onClick()
	end)
end

pPaijiuCardWnd.getCard = function(self)
	return self.card
end

pPaijiuCardWnd.onUpdateCardId = function(self)
	if self.st ~= ST_CARD_BACK then
		self:setImage(self.card:getCardImagePath())
	end
end

pPaijiuCardWnd.setShowState = function(self, st)
	st = self.card:fixShowState(st)
	self:setAlpha(0xff)
	self:setHSVMutiply(1, 1, 1)
	if st == ST_CARD_SHOW then
		-- 正面
		self:setImage(self.card:getCardImagePath())
		self:show(true)
	elseif st == ST_CARD_BACK then
		-- 背面
		self:setImage(self.card:getBgImagePath())
		self:show(true)
	elseif st == ST_CARD_OB then
		-- ob视角
		self:setImage(self.card:getCardImagePath())
		self:show(true)
		self:setAlpha(0xff/2)
	elseif st == ST_CARD_PICK then
		self:setHSVMutiply(1, 1, 2)
	else
		-- 隐藏
		self:show(false)
	end
	if st ~= ST_CARD_PICK then
		self.st = st
	end
end

pPaijiuCardWnd.getShowState = function(self)
	return self.st
end

pPaijiuCardWnd.destroy = function(self)
	self.card = nil
	self:setParent(nil)
end
