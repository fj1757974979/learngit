local modCardPoolBase = import("logic/card_battle/pool.lua")
local modNiuniuCard = import("logic/card_battle/battles/niuniu/card.lua")

pNiuniuCardPoolBase = pNiuniuCardPoolBase or class(modCardPoolBase.pCardPoolBase)

pNiuniuCardPoolBase.newCard = function(self, cardId, player)
	return modNiuniuCard.pNiuniuCard:new(cardId, player)
end

pNiuniuCardPoolBase.needSort = function(self)
	return false
end

----------------------------------------------------------

pNiuniuHandCardPool = pNiuniuHandCardPool or class(pNiuniuCardPoolBase)

pNiuniuHandCardPool.init = function(self, player)
	pNiuniuCardPoolBase.init(self, player)
end
