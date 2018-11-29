
pHandCards = pHandCards or class(pWindow) --

pHandCards.init = function(self)
	self:load("data/ui/card/hand_cards_other.lua")
end

pHandCards.show = function(self, flag)
	self:showChild(flag)
end

pHandCards.onUpdateCardId = function(self)
end

pHandCardsSelf = pHandCardsSelf or class(pWindow)

pHandCardsSelf.init = function(self)
	self:load("data/ui/card/hand_cards_self.lua")
end

pHandCardsSelf.show = function(self, flag)
	self:showChild(flag)
end

pHandCardsSelf.onUpdateCardId = function(self)
end
