local modInfoMain = import("logic/menu/player_info_mgr.lua")
local modPokerBattleMgr = import("logic/card_battle/main.lua")
local modBattleRpc = import("logic/card_battle/rpc.lua")

pPokerInfo = pPokerInfo or class(modInfoMain.pPlayerInfoMain)

pPokerInfo.init = function(self, uid, t)
	modInfoMain.pPlayerInfoMain.init(self, uid, t)
end

pPokerInfo.getBattle = function(self)
	return modPokerBattleMgr.getCurBattle()
end

pPokerInfo.fetchGeoLocations = function(self, uids, callback)
	modBattleRpc.fetchGeoLocations(uids, callback)
end

pPokerInfo.isClubRoom = function(self)
	local battle = self:getBattle()
	if not battle then return end
	return battle:isClubRoom()
end

pPokerInfo.playerInfo = function(self)
	if not self.player then return end
	self.name = self.player:getName()
	self.avatarUrl = self.player:getAvatarUrl()
	self.ip = self.player:getIP()
	self.cardCount = self.player:getRoomCard()
	self.goldCount = self.player:getGoldCount()
	self.gender = self.player:getGender()
end

pPokerInfo.destroy = function(self)
	modInfoMain.pPlayerInfoMain.destroy(self)
end

