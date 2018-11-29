local modBattleMgr = import("logic/battle/main.lua")
local modPokerBattleMgr = import("logic/card_battle/main.lua")
local modUserData = import("logic/userdata.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modPokerRpc = import("logic/card_battle/rpc.lua")

pDismissMgr = pDismissMgr or class(pSingleton)

pDismissMgr.init = function(self, t)
	self.t = t
end

pDismissMgr.getIsOwner = function(self)
	local battle = self:getDismissBattle()
	if not battle then
		return
	end
	return battle:getOwnerId() == modUserData.getUID()
end

pDismissMgr.getIsGaming = function(self)
	local battle = self:getDismissBattle()
	if not battle then
		return
	end
	return battle:getIsGaming()
end

pDismissMgr.getIsVideoState = function(self)
	local battle = self:getDismissBattle()
	if not battle or not battle.getIsVideoState then
		return
	end
	return battle:getIsVideoState()
end

pDismissMgr.getRpc = function(self)
	if self.t == T_MAHJONG_ROOM	then
		return modBattleRpc
	else
		return modPokerRpc
	end
end

pDismissMgr.getPlayers = function(self)
	local battle = self:getDismissBattle()
	if not battle then return end
	if battle.getAllPlayersByPid then
		return battle:getAllPlayersByPid()
	end
	return battle:getAllPlayers()
end

pDismissMgr.getGameType = function(self)
	return self.t
end

pDismissMgr.getBattleInstance = function(self)
	if self.t == T_MAHJONG_ROOM then
		return modBattleMgr.pBattleMgr:instance()
	elseif self.t == T_POKER_ROOM then
		return modPokerBattleMgr.pBattleMgr:instance()
	end
	return nil
end

pDismissMgr.getDismissParent = function(self)
	local battle = self:getDismissBattle()
	if not battle then return end
	return battle:getBattleUI()
end

pDismissMgr.getDismissBattle = function(self)
	if self.t == T_MAHJONG_ROOM then
		return modBattleMgr.getCurBattle()
	else
		return modPokerBattleMgr.getCurBattle()
	end
	return nil
end

pDismissMgr.isClubRoom = function(self)
	local battle = self:getDismissBattle()
	if not battle then return end
	if self.t == T_MAHJONG_ROOM then
		return battle:getCurGame():isClubRoom()
	else
		return battle:isClubRoom()
	end
end

pDismissMgr.isObserver = function(self)
	local battle = self:getDismissBattle()
	if not battle then
		return false
	end
	if self.t == T_MAHJONG_ROOM then
		return false
	else
		return battle:getMyself():isObserver()
	end
end

pDismissMgr.getDisTime = function(self)
	local battle = self:getDismissBattle()
	if not battle then return 1 end
	if not battle.getTimeOut then return 60 end
	return battle:getTimeOut()
end

pDismissMgr.battleDestroy = function(self)
	local battleInstance = self:getBattleInstance()
	if battleInstance then
		battleInstance:battleDestroy()
	end
end

pDismissMgr.answerCloseRoom = function(self, yesOrNo, callback)
	local rpc = self:getRpc()
	rpc.answerCloseRoom(yesOrNo, function(success, reason)
		if success then
			if callback then
				callback(success)
			end
		else
			infoMessage(reason)
		end
	end)
end

pDismissMgr.leaveRoom = function(self, callback)
	local rpc = self:getRpc()
	if self:isObserver() then
		rpc.observerLeaveRoom(function(success, reason)
			if success then
				self:battleDestroy()
				self:destroy()
				infoMessage(TEXT("您已经离开房间"))
			else
				infoMessage(reason)
			end
			if callback then
				callback(success, reason)
			end
		end)
	else
		rpc.leaveRoom(function(success, reason)
			if success then
				self:battleDestroy()
				self:destroy()
				infoMessage("您已经离开房间")
			else
				infoMessage(reason)
			end
			if callback then
				callback(success, reason)
			end
		end)
	end
end

pDismissMgr.dismissRoom = function(self, callback)
	local rpc = self:getRpc()
	rpc.dismissRoom(self:getDisTime(), function(success, reason)
		if success then
			if callback then
				callback(success)
			end
		else
			infoMessage(reason)
		end
	end)
end

pDismissMgr.disOwnerRoom = function(self, roomId, callback)
	local rpc = self:getRpc()
	rpc.dismissOwnerRoom(roomId, function(success, reason)
		if success then
			if callback then
				callback(success)
			end
		else
			infoMessage(reason)
		end
	end)
end

pDismissMgr.getRoomId = function(self)
	local battle = self:getDismissBattle()
	if not battle then return end
	return battle:getRoomId()
end

pDismissMgr.destroy = function(self)
	self.t = nil
	pDismissMgr:cleanInstance()
end

-------------------------------------------------
