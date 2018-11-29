local modPropMgr = import("common/propmgr.lua")
local modUserPropCache = import("logic/userpropcache.lua")

local allProp = {
	"name", "avatarurl"
}

pPlayer = pPlayer or class(modPropMgr.propmgr)

pPlayer.init = function(self, playerInfo, desk)
	modPropMgr.propmgr.init(self)
	self.userId = playerInfo.user_id
	self.id = playerInfo.id
	self.desk = desk
	self:initUserProp()
end

pPlayer.getUserId = function(self)
	return self.userId
end

pPlayer.getId = function(self)
	return self.id
end

pPlayer.initUserProp = function(self)
	modUserPropCache.pUserPropCache:instance():getPropAsync(self.userId, allProp, function(success, propData)
		if success then
			for k, v in pairs(propData) do
				logv("info", k, v)
				self:setProp(k, v)
			end
		else
			infoMessage(sf(TEXT("获取玩家数据%d失败"), self.userId))
		end
	end)
end

----------------------------------------------------------

pDesk = pDesk or class(modPropMgr.propmgr)

pDesk.init = function(self, roomInfo, group, idx)
	modPropMgr.propmgr.init(self)
	self.roomInfo = roomInfo
	self.group = group
	self.roomId = roomInfo.id
	self.idx = idx
	self:updateProps(roomInfo)
end

pDesk.updateProps = function(self, roomInfo)
	self:setProp("players", {})
	self:setProp("gameCount", self.roomInfo.game.time_count)
	self.players = {}
	self:initPlayers()
end

pDesk.getRoomId = function(self)
	return self.roomId
end

pDesk.getIdx = function(self)
	return self.idx
end

pDesk.getGameType = function(self)
	return self.roomInfo.game_type
end

pDesk.getCreateParam = function(self, gameType)
	if gameType == T_MAHJONG_ROOM then
		return self.roomInfo.creation_info
	else
		return self.roomInfo.poker_creation_info
	end
end

pDesk.initPlayers = function(self)
	for _, playerInfo in ipairs(self.roomInfo.players) do
		self:addPlayer(playerInfo)
	end
end

pDesk.addPlayer = function(self, playerInfo)
	local player = pPlayer:new(playerInfo, self)
	local players = self:getProp("players")
	players[player:getUserId()] = player
	self:setProp("players", players)
end

pDesk.delPlayer = function(self, userId)
	local players = self:getProp("players")
	players[userId] = nil
	self:setProp("players", players)
end
