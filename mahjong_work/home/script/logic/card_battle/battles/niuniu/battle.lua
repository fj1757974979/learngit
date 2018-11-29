local modBattleBase = import("logic/card_battle/battle.lua")
local modNiuniuPlayer = import("logic/card_battle/battles/niuniu/player.lua")
local modNiuniuTableWnd = import("ui/card_battle/battles/niuniu/table.lua")
local modNiuniuExecutor = import("logic/card_battle/battles/niuniu/executor.lua")
local modNiuniuProto = import("data/proto/rpc_pb2/pokers/niuniu_pb.lua")
local modCreate = import("logic/card_battle/create.lua")

pNiuniuBattle = pNiuniuBattle or class(modBattleBase.pBattleBase)

pNiuniuBattle.newPlayer = function(self, userId, playerId, battle)
	return modNiuniuPlayer.pNiuniuPlayer:new(userId, playerId, battle)
end

pNiuniuBattle.getRoomDesc = function(self)
	return modCreate.getRoomDesc(self.createInfo)
end

pNiuniuBattle.getGameName = function(self)
	return TEXT("牛牛")
end

pNiuniuBattle.getGameVoiceName = function(self)
	return "niuniu"
end

pNiuniuBattle.newTableWnd = function(self)
	return modNiuniuTableWnd.pNiuniuTableWnd:new(self)
end

pNiuniuBattle.newExecutorMgr = function(self)
	return modNiuniuExecutor.pNiuniuBattleExecutorMgr:new(self)
end

