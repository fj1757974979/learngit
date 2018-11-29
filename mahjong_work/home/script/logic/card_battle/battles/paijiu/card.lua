local modCardBase = import("logic/card_battle/card.lua")
local modPaijiuCardWnd = import("ui/card_battle/battles/paijiu/card.lua")

local fixPaijiuCardShowTypeForOb = function(battle, st)
	if st ~= ST_CARD_HIDE and battle:getMyself():isObserver() then
		if st == ST_CARD_BACK then
			return ST_CARD_OB
		else
			return st
		end
	else
		return st
	end
end

pPaijiuCard = pPaijiuCard or class(modCardBase.pPokerBase)

pPaijiuCard.newCardWnd = function(self)
	return modPaijiuCardWnd.pPaijiuCardWnd:new(self)
end

pPaijiuCard.fixShowState = function(self, st)
	return fixPaijiuCardShowTypeForOb(self.player:getBattle(), st)
end

pPaijiuCard.onClick = function(self)
	local battle = self.player:getBattle()
	local myself = battle:getMyself()
	if not myself:isObserver() then
		return
	end
	if self.cardWnd:getShowState() ~= ST_CARD_OB then
		return
	end
	local followee = myself:getFollowee()
	if self.player:getUserId() ~= followee:getUserId() then
		return
	end
	if myself:getFirstPick() == nil and myself:getSecondPick() == nil then
		myself:pickCard(1, self)
		self.cardWnd:setShowState(ST_CARD_PICK)
	end
end
-----------------------------------------------------
pPaijiuBattleCard = pPaijiuBattleCard or class(modCardBase.pPokerBattleBase)

pPaijiuBattleCard.newCardWnd = function(self)
	return modPaijiuCardWnd.pPaijiuCardWnd:new(self)
end

pPaijiuBattleCard.fixShowState = function(self, st)
	return fixPaijiuCardShowTypeForOb(self.battle, st)
end

pPaijiuBattleCard.onClick = function(self)
	local battle = self.battle
	local myself = battle:getMyself()
	if not myself:isObserver() then
		return
	end
	if self.cardWnd:getShowState() ~= ST_CARD_OB then
		return
	end
	if myself:getFirstPick() ~= nil and myself:getSecondPick() == nil then
		myself:pickCard(2, self)
		self.cardWnd:setShowState(ST_CARD_PICK)
	end
end
