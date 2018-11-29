local modPokerUtil = import("logic/card_battle/util.lua")

pCardBase = pCardBase or class()

pCardBase.init = function(self, cardId, player)
	self.cardId = cardId
	self.player = player
	self.cardWnd = self:newCardWnd()
	self.idx = nil
end

pCardBase.setIdx = function(self, idx)
	self.idx = idx
end

pCardBase.getIdx = function(self)
	return self.idx
end

pCardBase.getCardId = function(self)
	return self.cardId
end

pCardBase.getCardWnd = function(self)
	return self.cardWnd
end

pCardBase.getOwner = function(self)
	return self.player
end

pCardBase.newCardWnd = function(self)
	log("error", "[pCardBase.newCardWnd] not implemented!")
end

pCardBase.destroy = function(self)
	if self.cardWnd then
		self.cardWnd:destroy()
		self.cardWnd = nil
	end
end

pCardBase.updateCardId = function(self, cardId)
	self.cardId = cardId
	if self.cardWnd then
		self.cardWnd:onUpdateCardId()
	end
end

-----------------------------------------------------
pBattleCardBase = pBattleCardBase or class()

pBattleCardBase.init = function(self, cardId, battle)
	self.cardId = cardId
	self.battle = battle
	self.cardWnd = self:newCardWnd()
	self.idx = nil
end

pBattleCardBase.setIdx = function(self, idx)
	self.idx = idx
end

pBattleCardBase.getIdx = function(self)
	return self.idx
end

pBattleCardBase.updateCardId = function(self, cardId)
	self.cardId = cardId
	if self.cardWnd then
		self.cardWnd:onUpdateCardId()
	end
end

pBattleCardBase.getCardId = function(self)
	return self.cardId
end

pBattleCardBase.getCardWnd = function(self)
	return self.cardWnd
end

pBattleCardBase.getBattle = function(self)
	return self.battle
end

pBattleCardBase.newCardWnd = function(self)
	log("error", "[pBattleCardBase.newCardWnd] not implemented!")
end

pBattleCardBase.destroy = function(self)
	if self.cardWnd then
		self.cardWnd:destroy()
		self.cardWnd = nil
	end
end
-----------------------------------------------------

pPokerBase = pPokerBase or class(pCardBase)

pPokerBase.getCardImagePath = function(self)
	local cardId = self:getCardId()
	return modPokerUtil.getPokerCardImageById(cardId, self.player:getBattle():getPokerType())
end

pPokerBase.getBgImagePath = function(self)
	return modPokerUtil.getPokerCardBgImage(self.player:getBattle():getPokerType())
end

-----------------------------------------------------
pPokerBattleBase = pPokerBattleBase or class(pBattleCardBase)

pPokerBattleBase.getCardImagePath = function(self)
	local cardId = self:getCardId()
	return modPokerUtil.getPokerCardImageById(cardId, self.battle:getPokerType())
end

pPokerBattleBase.getBgImagePath = function(self)
	return modPokerUtil.getPokerCardBgImage(self.battle:getPokerType())
end
