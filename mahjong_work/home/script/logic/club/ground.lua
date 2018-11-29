local modPropMgr = import("common/propmgr.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modClubMgr = import("logic/club/main.lua")
local modUserData = import("logic/userdata.lua")
local modClubMgr = import("logic/club/main.lua")
local modBattleRpc = import("logic/battle/rpc.lua")

pGroundObj = pGroundObj or class(modPropMgr.propmgr)

pGroundObj.init = function(self, clubId, groundInfo)
	modPropMgr.propmgr.init(self)
	self.clubId = clubId
	self:initValues(groundInfo)
end

pGroundObj.initValues = function(self, groundInfo)
	if not groundInfo then return end
	self.id = groundInfo.id
	self.minGold = groundInfo.min_gold_coin_count
	self.costGold = groundInfo.cost_gold_coin_count
	self.roomInfo = groundInfo.room_creation_info
	self.pokerInfo = groundInfo.poker_room_creation_info
	self.date = groundInfo.created_date
	self.totalCost = groundInfo.total_room_card_cost
	self.gameType = groundInfo.game_type
	self.playerInfos = {}
end

pGroundObj.getGroundId = function(self)
	return self.id
end

pGroundObj.getClubId = function(self)
	return self.clubId
end

pGroundObj.getClubInfo = function(self)
	return modClubMgr.getCurClub():getClubById(self.clubId)
end

pGroundObj.getGameType = function(self)
	return self.gameType
end

pGroundObj.getGameTypeToMacros = function(self)
	if self.gameType == modLobbyProto.POKER then 
		return T_POKER_ROOM
	else
		return T_MAHJONG_ROOM
	end
end

pGroundObj.getPlayerInfos = function(self, callback)
	if self.playerInfos and table.getn(self.playerInfos) > 0 then 
		if callback then
			callback(self.playerInfos)
		end
	end
	modClubMgr.getCurClub():getGroundPlayers(self.clubId, self.id, function(idReply)
		local uids = idReply.player_user_ids
		modBattleRpc.getMultiUserProps(uids, { "name" }, function(success, reason, reply) 
			if success then
				local props = reply.multi_user_props
				for _, prop in ipairs(props) do
					table.insert(self.playerInfos, prop)
				end
				if callback then
					callback(self.playerInfos)
				end
			else
				infoMessage(reason)
			end
		end)
	end)	
end

pGroundObj.getMinGold = function(self)
	return self.minGold
end

pGroundObj.getCostGold = function(self)
	return self.costGold
end

pGroundObj.getRoomInfo = function(self)
	if self.gameType == modLobbyProto.POKER then
		return self.pokerInfo
	end
	return self.roomInfo
end

pGroundObj.getIsPoker = function(self)
	return self.gameType == modLobbyProto.POKER	
end

pGroundObj.getDate = function(self)
	return self.date
end

pGroundObj.getTotalCost = function(self)
	return self.totalCost
end

pGroundObj.destroy = function(self)
	self.id = nil 
	self.minGold = nil 
	self.costGold = nil 
	self.roomInfo = nil 
	self.date = nil 
	self.pokerInfo = nil 
	self.gameType = nil 
	self.totalCost = nil
	self.playerInfos = nil
end
