local modUserData = import("logic/userdata.lua")
local modExecutor = import("logic/card_battle/executor.lua")
local modCardPool = import("logic/card_battle/pool.lua")
local modCardPoolBase = import("logic/card_battle/pool.lua")
local modPropMgr = import("common/propmgr.lua")
local modUserPropCache = import("logic/userpropcache.lua")
local modPrepareMenu = import("ui/card_battle/prepare.lua")
local modUtil = import("util/util.lua")

local allProp = {
	"name", "avatarurl", "gender", "gold", "invite", "realname", "phone", "ip", "roomcard"
}

pPlayerBase = pPlayerBase or class(modPropMgr.propmgr, modExecutor.pExecutorHost)

pPlayerBase.init = function(self, userId, playerId, battle)
	modPropMgr.propmgr.init(self)
	self.userId = userId
	self.playerId = playerId
	self.seatId = nil
	self.battle = battle
	self.cardPools = {}
	self:setOnlineFlag(true)
	self:setBanker(false)
	self:setRandomBanker(false)
	self:initUserProp()
	if not self:isFake() and not self:isObserver() then
		self.executorMgr = self:newExecutorMgr()
		--self.executorMgr:run()
	end
end

pPlayerBase.getHostType = function(self)
	return T_EXE_HOST_PLAYER
end

pPlayerBase.getExecutorMgr = function(self)
	return self.executorMgr
end

pPlayerBase.initUserProp = function(self)
	modUserPropCache.pUserPropCache:instance():getPropAsync(self.userId, allProp, function(success, propData)
		if success then
			for k, v in pairs(propData) do
				self:setProp(k, v)
			end
			self:dismissPropFireEvent()
		else
			infoMessage(sf(TEXT("获取玩家数据%d失败"), self.userId))
		end
	end)
end

pPlayerBase.dismissPropFireEvent = function(self)
	local modEvent = import("common/event.lua")
	modEvent.fireEvent(EV_UPDATE_DISSROOM_NAME, self.playerId, self:getName(), self:getAvatarUrl())
end

pPlayerBase.getUserId = function(self)
	return self.userId
end

pPlayerBase.getUid = function(self)
	return self.userId
end

pPlayerBase.getPlayerId = function(self)
	return self.playerId
end

pPlayerBase.getBattle = function(self)
	return self.battle
end

pPlayerBase.getTableWnd = function(self)
	return self.battle:getTableWnd()
end

pPlayerBase.getHostName = function(self)
	return sf("player %d", self:getUserId())
end

pPlayerBase.getName = function(self)
	return self:getProp("name", "")
end

pPlayerBase.getRealName = function(self)
	return self:getProp("realname", "")
end

pPlayerBase.getPhoneNo = function(self)
	return self:getProp("phone", "")
end

pPlayerBase.setOnlineFlag = function(self, isOnline)
	log("info", "pPlayerBase.setOnlineFlag", self:getUserId(), isOnline)
	self:setProp("online", isOnline)
end

pPlayerBase.isOnline = function(self)
	return self:getProp("online")
end

pPlayerBase.isBanker = function(self)
	return self:getProp("banker", false)
end

pPlayerBase.setBanker = function(self, flag)
	log("info", "pPlayerBase.setBanker", flag)
	self:setProp("banker", flag)
end

pPlayerBase.setRandomBanker = function(self, flag)
	self:setProp("randomBanker", flag)
end

pPlayerBase.setBet = function(self, bet)
	self:setProp("bet", bet)
end

pPlayerBase.ready = function(self, isReady)
	log("error", "====== ", self:getUserId(), " is ready: ", isReady)
	self:setProp("ready", isReady)
end

pPlayerBase.isReady = function(self)
	return self:getProp("ready", false)
end

pPlayerBase.bankrupt = function(self)
	log("error", "=====", self:getUserId(), " is bankrupt")
	self:setProp("bankrupt", true)
end

pPlayerBase.isBankrupt = function(self)
	return self:getProp("bankrupt", false)
end

pPlayerBase.modifyScore = function(self, mod)
	local score = self:getProp("score", 0)
	score = score + mod
	self:setProp("score", score)
	self:playModifyScoreHint(mod)
end

pPlayerBase.playModifyScoreHint = function(self, mod)
	if mod == 0 then
		return
	end
	local battle = self:getBattle()
	local tableWnd = battle:getTableWnd()
	if tableWnd then
		local seatWnd = tableWnd:getSeatWnd(self:getUid())
		if seatWnd then
			seatWnd:playModifyScoreHint(mod)
		end
	end
end

pPlayerBase.setScore = function(self, score)
	self:setProp("score", score)
end

pPlayerBase.getScore = function(self)
	return self:getProp("score", 0)
end

pPlayerBase.getAvatarUrl = function(self)
	local url = self:getProp("avatarurl")
	if not url or url == "" then
		url = "ui:image_default_female.png"
	end
	return url
end

pPlayerBase.isMyself = function(self)
	return self:getUserId() == modUserData.getUID()
end

pPlayerBase.sitDown = function(self, seatId)
	self.seatId = seatId
end

pPlayerBase.getSeatId = function(self)
	return self.seatId
end

pPlayerBase.getIP = function(self)
	return self:getProp("ip")
end

pPlayerBase.getRoomCard = function(self)
	return self:getProp("roomcard")
end

pPlayerBase.getGoldCount = function(self)
	return self:getProp("gold")
end

pPlayerBase.getGender = function(self)
	return self:getProp("gender", T_GENDER_FEMALE)
end

pPlayerBase.initCardPools = function(self, state)
	log("info", "++++++++++ initCardPools ", self:getUserId())
	local cls = self:getHandCardPoolCls()
	self.cardPools[T_CARD_HAND] = cls:new(self)
	if state then
		local cardIds = {}
		for _, cardId in ipairs(state.hand_card_ids) do
			table.insert(cardIds, cardId)
		end
		self:addHandCards(cardIds)
	end
end

pPlayerBase.getHandCardPoolCls = function(self)
	log("error", "[pPlayerBase.getHandCardPoolCls] not implemented!", debug.traceback())
end

pPlayerBase.getHandCardPool = function(self)
	if not self.cardPools[T_CARD_HAND] then
		self:initCardPools()
	end
	return self.cardPools[T_CARD_HAND]
end

pPlayerBase.addHandCards = function(self, cardIds)
	if #cardIds <= 0 then
		return
	end
	logv("info", sf("[pPlayerBase.addHandCards] userId = %d", self:getUserId()), cardIds)
	local handCardPool = self:getHandCardPool()
	local newCards = {}
	for _, cardId in ipairs(cardIds) do
		local card = handCardPool:addCard(cardId)
		table.insert(newCards, card)
	end
	local battle = self.battle
	local tableWnd = battle:getBattleUI():getTableWnd()
	tableWnd:addHandCards(self, newCards)
end

pPlayerBase.initState = function(self, state)
	if not state.is_ready then
		self:enterPrepareState()
	elseif state.state_info then
		self:enterState(state.state_info)
	end
	self:ready(state.is_ready)
	if state.is_bankrupt then
		self:bankrupt()
		self:setBankruptHint()
	end
end

pPlayerBase.setBankruptHint = function(self)
	local battle = self:getBattle()
	local tableWnd = battle:getTableWnd()
	if tableWnd then
		local seatWnd = tableWnd:getSeatWnd(self:getUid())
		if seatWnd then
			seatWnd:bankruptHintText(TEXT("破产"))
		end
	end
end

pPlayerBase.initData = function(self, state)
	self:setBet(state.bet)
	self:modifyScore(state.score)
end

pPlayerBase.onBattleInitDone = function(self)
	if self:isBankrupt() then
		self:setBankruptHint()
	end
end

pPlayerBase.enterState = function(self, stateInfo)
	if self.executorMgr then
		self.executorMgr:addExecutor(stateInfo)
	end
end

pPlayerBase.enterPrepareState = function(self)
	if self.executorMgr then
		self.executorMgr:addPrepareExecutor()
	end
end

pPlayerBase.onServerNotifyExecutorFinish = function(self, stateInfo)
	if self.executorMgr and not self:isMyself() then
		local cls, stateMessage = self.executorMgr:parseExecutorInfo(stateInfo)
		self.executorMgr:onServerNotifyExecutorFinish(stateMessage)
	end
end

pPlayerBase.setNextTimeoutTime = function(self, timestamp)
	self.nextTimeout = timestamp
	if self.nextTimeout > 0 then
		if not self:isOnline() then
			self:startOfflineCountdown()
		end
	end
end

pPlayerBase.startOfflineCountdown = function(self)
	self:stopOfflineCountdown()
	if self:isFake() then
		return
	end
	if self.nextTimeout and self.nextTimeout > 0 then
		local cur = modUtil.getServerTime()
		local rest = math.floor(self.nextTimeout - cur)
		local battle = self:getBattle()
		local tableWnd = battle:getTableWnd()
		local userId = self:getUserId()
		if rest > 0 then
			self.__offline_count_down = setInterval(s2f(1), function()
				if rest <= 0 then
					tableWnd:setOfflineCountdown(userId, "")
					self.__offline_count_down = nil
					return "release"
				else
					tableWnd:setOfflineCountdown(userId, rest)
				end
				rest = rest - 1
			end):update()
		end
	end
end

pPlayerBase.stopOfflineCountdown = function(self)
	if self.__offline_count_down then
		self.__offline_count_down:stop()
		self.__offline_count_down = nil
	end
	local battle = self:getBattle()
	local tableWnd = battle:getTableWnd()
	tableWnd:setOfflineCountdown(self:getUserId(), "")
end

pPlayerBase.pause = function(self)
	if self.executorMgr then
		self.executorMgr:pause()
	end
end

pPlayerBase.resume = function(self)
	if self.executorMgr then
		self.executorMgr:resume()
	end
end

pPlayerBase.newExecutorMgr = function(self)
	log("error", "[pPlayerBase.newExecutorMgr] not implemented!")
end

pPlayerBase.isFake = function(self)
	return false
end

pPlayerBase.isObserver = function(self)
	return false
end

pPlayerBase.isRobot = function(self)
	return false
end

pPlayerBase.reset = function(self)
	if self.executorMgr then
		self.executorMgr:reset()
	end
	for _, pool in pairs(self.cardPools) do
		pool:reset()
	end
	if self.battle:shouldResetBankerOnReset() then
		self:setBanker(false)
	end
	self:setBet(0)
	self:setNextTimeoutTime(0)
	--self:stopOfflineCountdown()
end

pPlayerBase.prepareCancel = function(self)
	if self.executorMgr then
		self.executorMgr:prepareCancel()
	end
end

pPlayerBase.destroy = function(self)
	if self.executorMgr then
		self.executorMgr:destroy()
		self.executorMgr = nil
	end
	for _, pool in pairs(self.cardPools) do
		pool:destroy()
	end
	self.cardPools = {}
	self:stopOfflineCountdown()
	self.battle = nil
end

---------------------------------------------------------

pFakePlayer = pFakePlayer or class(pPlayerBase)

pFakePlayer.init = function(self, userId, playerId, battle)
	pPlayerBase.init(self, userId, playerId, battle)
end

pFakePlayer.isFake = function(self)
	return true
end

pFakePlayer.isReady = function(self)
	return true
end

pFakePlayer.initUserProp = function(self)
end

---------------------------------------------------------

pObserver = pObserver or class(pPlayerBase)

pObserver.init = function(self, userId, playerId, battle)
	pPlayerBase.init(self, userId, playerId, battle)
	self.followee = nil
end

pObserver.isObserver = function(self)
	return true
end

pObserver.isFake = function(self)
	return false
end

pObserver.isReady = function(self)
	return true
end

pObserver.setFollowee = function(self, player)
	self.followee = player
end

pObserver.getFollowee = function(self)
	return self.followee
end

pObserver.reset = function(self)
	self:cleanPick()
end
