local modPlayerBase = import("logic/card_battle/player.lua")
local modNiuniuCardPool = import("logic/card_battle/battles/niuniu/pool.lua")
local modNiuniuExecutor = import("logic/card_battle/battles/niuniu/executor.lua")
local modNiuniuProto = import("data/proto/rpc_pb2/pokers/niuniu_pb.lua")

pNiuniuPlayer = pNiuniuPlayer or class(modPlayerBase.pPlayerBase)

pNiuniuPlayer.init = function(self, userId, playerId, battle)
	modPlayerBase.pPlayerBase.init(self, userId, playerId, battle)
	self.niuType = 0
	self.niuCardIds = {}
end

pNiuniuPlayer.getHandCardPoolCls = function(self)
	return modNiuniuCardPool.pNiuniuHandCardPool
end

pNiuniuPlayer.newExecutorMgr = function(self)
	return modNiuniuExecutor.pNiuniuPlayerExecutorMgr:new(self)
end

pNiuniuPlayer.setNiuInfo = function(self, niuType, niuCardIds)
	if niuType 
		and niuType > modNiuniuProto.T_NN_NONE 
		and #niuCardIds > 0 then
		self.niuType = niuType
		self.niuCardIds = niuCardIds
	else
		self.niuType = 0
		self.niuCardIds = {}
		logv("error", niuType, niuCardIds)
	end
end

pNiuniuPlayer.getNiuCardIds = function(self)
	return self.niuCardIds
end

pNiuniuPlayer.getNiuType = function(self)
	return self.niuType
end
