local modPlayerBase = import("logic/card_battle/player.lua")
local modPaijiuCardPool = import("logic/card_battle/battles/paijiu/pool.lua")
local modPaijiuExecutor = import("logic/card_battle/battles/paijiu/executor.lua")
local modPaijiuProto = import("data/proto/rpc_pb2/pokers/paijiu_pb.lua")

pPaijiuPlayer = pPaijiuPlayer or class(modPlayerBase.pPlayerBase)

pPaijiuPlayer.init = function(self, userId, playerId, battle)
	modPlayerBase.pPlayerBase.init(self, userId, playerId, battle)
	self.pjType = 0
end

pPaijiuPlayer.getHandCardPoolCls = function(self)
	return modPaijiuCardPool.pPaijiuHandCardPool
end

pPaijiuPlayer.newExecutorMgr = function(self)
	return modPaijiuExecutor.pPaijiuPlayerExecutorMgr:new(self)
end

pPaijiuPlayer.setPjType = function(self, pjType)
	self.pjType = pjType
end

pPaijiuPlayer.getPjType = function(self)
	return self.pjType
end

pPaijiuPlayer.setBet2 = function(self, bet2)
	self:setProp("bet2", bet2)
end

pPaijiuPlayer.initData = function(self, state)
	modPlayerBase.pPlayerBase.initData(self, state)
	self:setBet2(state.bet2)
end

pPaijiuPlayer.getBets = function(self)
	return self:getProp("bet"), self:getProp("bet2")
end

pPaijiuPlayer.saveKzwfAntesUIData = function(self, data)
	self.kzwfAntesUIData = data
end

pPaijiuPlayer.getKzwfAntesUIData = function(self)
	return self.kzwfAntesUIData
end

---------------------------------------------------------

pPaijiuFakePlayer = pPaijiuFakePlayer or class(modPlayerBase.pFakePlayer)

pPaijiuFakePlayer.getHandCardPoolCls = function(self)
	return modPaijiuCardPool.pPaijiuHandCardPool
end

pPaijiuFakePlayer.setPjType = function(self, pjType)
	self.pjType = pjType
end

pPaijiuFakePlayer.getPjType = function(self)
	return self.pjType
end

---------------------------------------------------------

pPaijiuObserver = pPaijiuObserver or class(modPlayerBase.pObserver)

pPaijiuObserver.init = function(self, userId, playerId, battle)
	modPlayerBase.pObserver.init(self, userId, playerId, battle)
	self.pick1 = nil
	self.pick2 = nil
end

pPaijiuObserver.getFirstPick = function(self)
	return self.pick1
end

pPaijiuObserver.getSecondPick = function(self)
	return self.pick2
end

pPaijiuObserver.pickCard = function(self, idx, card)
	if idx == 1 then
		self.pick1 = card
	else
		self.pick2 = card
	end
	self:onPickCard(idx)
end

pPaijiuObserver.cleanPick = function(self)
	if self.pick1 then
		local cardWnd = self.pick1:getCardWnd()
		if cardWnd then
			cardWnd:setShowState(cardWnd:getShowState())
		end
		self.pick1 = nil
	end

	if self.pick2 then
		local cardWnd = self.pick2:getCardWnd()
		if cardWnd then
			cardWnd:setShowState(cardWnd:getShowState())
		end
		self.pick2 = nil
	end
	self:onCleanPick()
end

pPaijiuObserver.onPickCard = function(self)
	if self.pick1 and self.pick2 then
		if self.menu then
			self.menu:setParent(nil)
			self.menu = nil
		end
		local modGmMenu = import("ui/card_battle/battles/paijiu/menus/gm.lua")
		self.menu = modGmMenu.pGmMenu:new()
		self.menu:setObserver(self)
		self.menu:setParent(self.battle:getTableWnd():getMenuParent())
	end
end

pPaijiuObserver.onCleanPick = function(self)
	if self.menu then
		self.menu:setParent(nil)
		self.menu = nil
	end
end
