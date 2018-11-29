local modBattleMgr = import("logic/battle/main.lua")
local modPokerBattleMgr = import("logic/card_battle/main.lua")
local modUserData = import("logic/userdata.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modPokerRpc = import("logic/card_battle/rpc.lua")

pPlayerInfoMain = pPlayerInfoMain or class()

pPlayerInfoMain.init = function(self, uid, t)
	self.uid = uid
	self.t = t
	self:initMyPlayer()
	self:initPlayerInfos()
end

pPlayerInfoMain.getBattle = function(self)
	return
end

pPlayerInfoMain.isClubRoom = function(self)
	return
end

pPlayerInfoMain.getPlayers = function(self)
	local battle = self:getBattle()
	if not battle then return end
	return battle:getAllPlayers()
end

pPlayerInfoMain.initUidToPlayer = function(self)
	local players = self:getPlayers()
	if not players then return end
	self.uidToPlayer = {}
	for _, player in pairs(players) do
		self.uidToPlayer[player:getUid()] = player
	end
end

pPlayerInfoMain.initMyPlayer = function(self)
	local players = self:getPlayers()
	if not players then return end
	self.player = nil
	for _, player in pairs(players) do
		if player:getUid() == self.uid then
			self.player = player
		end
	end
end

pPlayerInfoMain.playerInfo = function(self)
	return
end

pPlayerInfoMain.initPlayerInfos = function(self)
	if self.player then
		self:playerInfo()
		self:newPanel()
	else
		self:updateUserInfos()
	end
end

pPlayerInfoMain.updateUserInfos = function(self)
	modBattleRpc.updateUserProps(self.uid, function(success, reply)
		if success then
			self.name = reply.nickname
			self.avatarUrl = reply.avatar_url
			self.ip = reply.ip_address
			self.inviteCode = reply.invite_code
			self.realName = reply.real_name
			self.phoneNo = reply.phone_no
			self.cardCount = reply.room_card_count
			self.goldCount = reply.gold_coin_count
			self.gender = reply.gender
			self:newPanel()
		end
	end)
end

pPlayerInfoMain.newPanel = function(self)
	local modInfoPanel = import("ui/menu/player_info.lua")
	if self.panel then
		self.panel:close()
		self.panel = nil
	end
	self.panel = modInfoPanel.pPlayerInfo:instance():open(self)
end

pPlayerInfoMain.getParnentPanel = function(self)
	local battle  = self:getBattle()
	if not battle then return end
	return battle:getBattleUI()
end

pPlayerInfoMain.getVideoState = function(self)
	return
end

pPlayerInfoMain.getVideoLocation = function(self)
	return
end

pPlayerInfoMain.commitLocation = function(self)

end

pPlayerInfoMain.getName = function(self)
	return self.name
end

pPlayerInfoMain.getAvatarUrl = function(self)
	return self.avatarUrl
end

pPlayerInfoMain.getIP = function(self)
	return self.ip
end

pPlayerInfoMain.getInviteCode = function(self)
	return self.inviteCode
end

pPlayerInfoMain.getRealName = function(self)
	return self.realName
end

pPlayerInfoMain.getPhoneNo = function(self)
	return self.phoneNo
end

pPlayerInfoMain.getRoomCard = function(self)
	return self.cardCount
end

pPlayerInfoMain.getGoldCount = function(self)
	return self.goldCount
end

pPlayerInfoMain.getMyPlayer = function(self)
	return self.player
end

pPlayerInfoMain.getUidToPlayer = function(self)
	if not self.uidToPlayer then
		self:initUidToPlayer()
	end
	return self.uidToPlayer
end

pPlayerInfoMain.getUid = function(self)
	return self.uid
end

pPlayerInfoMain.getGender = function(self)
	return self.gender
end

pPlayerInfoMain.isBattleClick = function(self)
	return self:getBattle()
end

pPlayerInfoMain.fetchGeoLocations = function(self, uids, callback)
end

pPlayerInfoMain.destroy = function(self)
	self.name = nil
	self.avatarUrl = nil
	self.ip = nil
	self.inviteCode = nil
	self.realName = nil
	self.phoneNo = nil
	self.cardCount = nil
	self.goldCount = nil
	self.uidToPlayer = nil
end


----------------------------------------------------
pPlayerInfoMgr = pPlayerInfoMgr or class(pSingleton)

pPlayerInfoMgr.init = function(self, uid, t)
end

pPlayerInfoMgr.initCurInfo = function(self, uid, t)
	local modMahjongInfo = import("logic/menu/mahjong_info.lua")
	local modPokerInfo = import("logic/menu/poker_info.lua")
	local infos = {
		[T_MAHJONG_ROOM] = modMahjongInfo.pMahjongInfo,
		[T_POKER_ROOM] = modPokerInfo.pPokerInfo,
	}
	if infos[t] then
		self.curInfo = infos[t]:new(uid, t)
	end
end

pPlayerInfoMgr.destroy = function(self)
	if self.curInfo then
		self.curInfo:destroy()
		self.curInfo = nil
	end
	pPlayerInfoMgr:cleanInstance()
end

newMgr = function(uid, t)
	if not pPlayerInfoMgr:instance().curInfo then
		pPlayerInfoMgr:instance():initCurInfo(uid, t)
	end
	return pPlayerInfoMgr:instance().curInfo
end
