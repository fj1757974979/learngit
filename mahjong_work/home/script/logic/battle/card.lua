pCard = pCard or class()

pCard.init = function(self, id, seat, t)
	self.id = id
	self.seat = seat
	self.t = t
end

pCard.getId = function(self)
	return self.id
end

pCard.getSeat = function(self)
	return self.seat
end

pCard.getType = function(self)
	return self.t
end

----------------------------------------------------------

pCardMgr = pCardMgr or class(pSingleton)

pCardMgr.init = function(self)
end

pCardMgr.newCard = function(self, id, seat, t)
	return pCard:new(id, seat, t)
end

