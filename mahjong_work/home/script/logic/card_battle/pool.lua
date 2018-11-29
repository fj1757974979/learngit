
pCardPoolBase = pCardPoolBase or class()

pCardPoolBase.init = function(self, player)
	self.cards = {}
	self.player = player
end

pCardPoolBase.needSort = function(self)
	return true
end

pCardPoolBase.getAllCards = function(self)
	return self.cards
end

pCardPoolBase.newCard = function(self, cardId, player)
	log("error", "[pCardPoolBase.newCard] not implemented!")
end

pCardPoolBase.genCard = function(self, cardId)
	return self:newCard(cardId, self.player)
end

pCardPoolBase.addCard = function(self, cardId)
	local card = self:genCard(cardId)
	if card then
		local idx = #self.cards + 1
		table.insert(self.cards, card)
		card:setIdx(idx)
		if self:needSort() then
			self:sort()
		end
	end
	return card
end

pCardPoolBase.delCard = function(self, cardId)
	local idx = nil
	for _idx, card in ipairs(self.cards) do
		if card:getCardId() == cardId then
			idx = _idx
			break
		end
	end
	if idx then
		table.remove(self.cards, idx)
	end
end

pCardPoolBase.sort = function(self)
	table.sort(self.cards, function(card1, card2)
		return card1:getCardId() > card2:getCardId()
	end)
end

pCardPoolBase.reset = function(self)
	for _, card in ipairs(self.cards) do
		card:destroy()
	end
	self.cards = {}
end

pCardPoolBase.destroy = function(self)
	self:reset()
	self.player = nil
end
----------------------------------------------------------
pBattleCardPoolBase = pBattleCardPoolBase or class(pCardPoolBase)

pBattleCardPoolBase.init = function(self, battle)
	self.cards = {}
	self.battle = battle
end

pBattleCardPoolBase.genCard = function(self, cardId)
	return self:newCard(cardId, self.battle)
end

pBattleCardPoolBase.newCard = function(self, cardId, battle)
	log("error", "[pBattleCardPoolBase.newCard] not implemented!")
end

pBattleCardPoolBase.destroy = function(self)
	self:reset()
	self.battle = nil
end
