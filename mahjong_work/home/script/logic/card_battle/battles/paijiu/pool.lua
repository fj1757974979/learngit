local modCardPoolBase = import("logic/card_battle/pool.lua")
local modPaijiuCard = import("logic/card_battle/battles/paijiu/card.lua")

pPaijiuCardPoolBase = pPaijiuCardPoolBase or class(modCardPoolBase.pCardPoolBase)

pPaijiuCardPoolBase.newCard = function(self, cardId, player)
	return modPaijiuCard.pPaijiuCard:new(cardId, player)
end

pPaijiuCardPoolBase.needSort = function(self)
	return false
end

pPaijiuCardPoolBase.refreshCard = function(self, idx, cardId)
	local card = self.cards[idx]
	if card then
		card:updateCardId(cardId)
	end
end
----------------------------------------------------------
pPaijiuHandCardPool = pPaijiuHandCardPool or class(pPaijiuCardPoolBase)

pPaijiuHandCardPool.init = function(self, player)
	pPaijiuCardPoolBase.init(self, player)
end
----------------------------------------------------------
pPaijiuTableCardPool = pPaijiuTableCardPool or class(modCardPoolBase.pBattleCardPoolBase)

pPaijiuTableCardPool.needSort = function(self)
	return false
end

pPaijiuTableCardPool.newCard = function(self, cardId, battle)
	return modPaijiuCard.pPaijiuBattleCard:new(cardId, battle)
end

pPaijiuTableCardPool.refreshCard = function(self, idx, cardId)
	local card = self.cards[idx]
	if card then
		card:updateCardId(cardId)
	end
end
