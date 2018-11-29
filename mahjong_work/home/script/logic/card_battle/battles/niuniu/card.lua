local modCardBase = import("logic/card_battle/card.lua")
local modNiuniuCardWnd = import("ui/card_battle/battles/niuniu/card.lua")

pNiuniuCard = pNiuniuCard or class(modCardBase.pPokerBase)

pNiuniuCard.newCardWnd = function(self)
	return modNiuniuCardWnd.pNiuniuCardWnd:new(self)
end
