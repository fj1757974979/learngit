local modInfoMain = import("logic/menu/player_info_mgr.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modBattleMgr = import("logic/battle/main.lua")

pMahjongInfo = pMahjongInfo or class(modInfoMain.pPlayerInfoMain)

pMahjongInfo.init = function(self, uid, t)
	modInfoMain.pPlayerInfoMain.init(self, uid, t)
end

pMahjongInfo.getBattle = function(self)
	return modBattleMgr.getCurBattle()
end

pMahjongInfo.isClubRoom = function(self)
	local battle = self:getBattle()
	if not battle then return end
	return battle:getCurGame():isClubRoom()
end

pMahjongInfo.getVideoState = function(self)
	return modBattleMgr.getCurBattle():getIsVideoState()
end

pMahjongInfo.getVideoLocation = function(self)
	return modBattleMgr.getCurBattle():getVideoLocations()
end

pMahjongInfo.playerInfo = function(self)
	if not self.player then return end
	self.name = self.player:getName()
	self.avatarUrl = self.player:getAvatarUrl()
	self.ip = self.player:getIP()
	self.inviteCode = self.player:getInviteCode()
	self.realName = self.player:getRealName()
	self.phoneNo = self.player:getPhoneNo()
	self.cardCount = self.player:getRoomCardCount()
	self.goldCount = self.player:getGoldCount()
	self.gender = self.player:getGender()
end

pMahjongInfo.fetchGeoLocations = function(self, uids, callback)
	modBattleRpc.fetchGeoLocations(uids, callback)
end

pMahjongInfo.destroy = function(self)
	modInfoMain.pPlayerInfoMain.destroy(self)
end
