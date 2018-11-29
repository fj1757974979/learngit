
pNiuniuCardWnd = pNiuniuCardWnd or class(pWindow)

pNiuniuCardWnd.init = function(self, card)
	self:load("data/ui/card/niuniu_card.lua")
	self.card = card
	self:show(false)
end

pNiuniuCardWnd.getCard = function(self)
	return self.card
end

pNiuniuCardWnd.setBackMode = function(self)
	self:setImage(self.card:getBgImagePath())
	self:show(true)
end

pNiuniuCardWnd.setShowMode = function(self)
	self:setImage(self.card:getCardImagePath())
	self:show(true)
end

pNiuniuCardWnd.destroy = function(self)
	self.card = nil
	self:setParent(nil)
end

