local modUserData = import("logic/userdata.lua")
local modExecutor = import("logic/card_battle/executor.lua")
local modBattlePanel = import("ui/card_battle/battle.lua")
local modPlayerBase = import("logic/card_battle/player.lua")
local modChatMgr = import("logic/chat/mgr.lua")
local modUtil = import("util/util.lua")
local modBattleRpc = import("logic/card_battle/rpc.lua")
local modChannelMgr = import("logic/channels/main.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modEvent = import("common/event.lua")
local modCreate = import("logic/card_battle/create.lua")

pBattleBase = pBattleBase or class(modExecutor.pExecutorHost)

pBattleBase.init = function(self, roomId, createInfo)
	-- 房间号
	self.roomId = roomId
	-- userId --> player
	self.players = {}
	-- userId --> observer
	self.observers = {}
	-- followee --> observer
	self.reverseObservers = {}
	-- playerId --> seatId
	self.playerIdToSeat = {}
	self.myself = nil
	self.battleUI = nil
	-- 庄家uid
	self.bankerUserId = 0
	-- 当前局数
	self.curTurnNum = 1
	-- 总局数
	self.totalTurnNum = 0
	-- 房间参数
	self.createInfo = createInfo
	-- 玩法参数
	self.gameParam = createInfo.create_param
	-- 执行器
	self.executorMgr = self:newExecutorMgr()
	-- 是否开始游戏
	self.isStarted = false
	-- 观战的对象
	self.followeeUid = nil
end

pBattleBase.getHostType = function(self)
	return T_EXE_HOST_BATTLE
end

pBattleBase.getRoomDesc = function(self)
	return "房间类型"
end

pBattleBase.getRoomTypeDesc = function(self)
	local roomType = self.createInfo.room_type
	return modCreate.getRoomTypeDesc(roomType)
end

pBattleBase.getGameName = function(self)
	return ""
end

pBattleBase.getMyself = function(self)
	return self.myself
end

pBattleBase.getRoomId = function(self)
	return self.roomId
end

pBattleBase.getFolloweeUid = function(self)
	return self.followeeUid
end

pBattleBase.getPokerType = function(self)
	return self.pokerType
end

pBattleBase.getRoomType = function(self)
	return self.createInfo.room_type
end

pBattleBase.isClubRoom = function(self)
	return self:getRoomType() == modLobbyProto.CreatePokerRoomRequest.CLUB_SHARED
end

pBattleBase.getClubId = function(self)
	local clubContext = self:getClubContext()
	return clubContext.club_id
end

pBattleBase.getClubContext = function(self)
	return self.createInfo.club_context
end

pBattleBase.getMaxPlayerCnt = function(self)
	return self.createInfo.max_number_of_users
end

pBattleBase.getOwnerId = function(self)
	return self.createInfo.owner_user_id
end

pBattleBase.getIsGaming = function(self)
	return self.isStarted
end

pBattleBase.getHostName = function(self)
	return "battle"
end

pBattleBase.getCurTurnNum = function(self)
	return self.curTurnNum
end

pBattleBase.setCurTurnNum = function(self, turn)
	self.curTurnNum = turn
	self.battleUI:updateRoomInfo()
end

pBattleBase.getTotalTurnNum = function(self)
	return self.totalTurnNum
end

pBattleBase.getTurnDesc = function(self)
	return sf("%d/%d局", self.curTurnNum, self.totalTurnNum)
end

pBattleBase.isLastTurn = function(self)
	log("error", "pBattleBase.isLastTurn ", self.curTurnNum, self.totalTurnNum)
	return self.curTurnNum >= self.totalTurnNum
end

pBattleBase.setStartFlag = function(self, flag)
	self.isStarted = flag
	if self.isStarted then
		self.battleUI:onGameStart()
	end
	modEvent.fireEvent(EV_BATTLE_BEGIN)
end

pBattleBase.initFromData = function(self, userInfos, userFakeInfos, observeInfos, gameState)
	self.pokerType = gameState.poker_type
	self:initPlayers(userInfos, userFakeInfos, observeInfos)
	self:initSeats()
	self.curTurnNum = gameState.time_count
	self.totalTurnNum = gameState.max_time_count
	log("warn", "============= isStarted: ", self.isStarted)
	self:initBattleUI()
	self:initCardPools(gameState.player_states)
	self:initBattleState(gameState.table_state)
	self:initPlayerStates(gameState.player_states)
	self:setStartFlag(gameState.is_started)
	modChatMgr.pChatMgr:instance():setBattle(self)
	for _, player in pairs(self.players) do
		player:onBattleInitDone()
	end
	if self.executorMgr then
		--self.executorMgr:reset()
		self.executorMgr:run()
	end
end

pBattleBase.initPlayers = function(self, userInfos, userFakeInfos, observeInfos)
	local fakeInfos = {}
	for _, fakeInfo in ipairs(userFakeInfos) do
		fakeInfos[fakeInfo.user_id] = fakeInfo.is_fake
	end
	logv("error", "******* ", fakeInfos)
	for _, userInfo in ipairs(userInfos) do
		local player = nil
		if fakeInfos[userInfo.user_id] then
			player = self:newFakePlayer(userInfo.user_id, userInfo.player_id, self)
		else
			player = self:newPlayer(userInfo.user_id, userInfo.player_id, self)
		end
		player:setOnlineFlag(userInfo.is_online)
		self.players[player:getUserId()] = player
		if player:isMyself() then
			self.myself = player
		end
	end

	for _, obInfo in ipairs(observeInfos or {}) do
		local observer = self:addObserver(obInfo.user_id, obInfo.ob_user_id)
		if observer:isMyself() then
			self.myself = observer
			self.followeeUid = observer:getFollowee():getUserId()
		end
	end
end

pBattleBase.initSeats = function(self)
	local selfPlayerId = nil
	if self.myself:isObserver() then
		selfPlayerId = self.myself:getFollowee():getPlayerId()
	else
		selfPlayerId = self.myself:getPlayerId()
	end
	self.playerIdToSeat[selfPlayerId] = 0
	local num = self:getMaxPlayerCnt()
	for i = 0, num - 1 do
		if i > selfPlayerId then
			self.playerIdToSeat[i] = i - selfPlayerId
		elseif i < selfPlayerId then
			self.playerIdToSeat[i] = num - selfPlayerId + i
		end
	end
	for _, player in pairs(self.players) do
		local playerId = player:getPlayerId()
		local seatId = self.playerIdToSeat[playerId]
		player:sitDown(seatId)
	end
end

pBattleBase.initBattleUI = function(self)
	if self.battleUI then
		self.battleUI:destroy()
	end
	self.battleUI = modBattlePanel.pBattlePanel:new(self)
end

pBattleBase.getBattleUI = function(self)
	return self.battleUI
end

pBattleBase.getTableWnd = function(self)
	if self.battleUI then
		return self.battleUI:getTableWnd()
	else
		return nil
	end
end

pBattleBase.getMenuParent = function(self)
	return self:getTableWnd()
end

pBattleBase.setBankerUserId = function(self, bankerUserId)
	self.bankerUserId = bankerUserId
	local player = self:getPlayer(self.bankerUserId)
	if player then
		player:setBanker(true)
	end
end

pBattleBase.setRandomBanker = function(self, bankerUserId, flag)
	local player = self:getPlayer(bankerUserId)
	if player then
		player:setRandomBanker(flag)
	end
end

pBattleBase.getBankerUserId = function(self)
	return self.bankerUserId
end

pBattleBase.getGameVoiceName = function(self)
	return
end

pBattleBase.setPlayerBets = function(self, userIds, bets)
	for idx, userId in ipairs(userIds) do
		local player = self:getPlayer(userId)
		if player then
			player:setBet(bets[idx])
		end
	end
end

pBattleBase.playerOnline = function(self, userId)
	local player = self:getPlayer(userId)
	if player then
		player:setOnlineFlag(true)
		player:stopOfflineCountdown()
	end
end

pBattleBase.playerOffline = function(self, userId)
	local player = self:getPlayer(userId)
	if player then
		player:setOnlineFlag(false)
		player:startOfflineCountdown()
	end
end

pBattleBase.playerReady = function(self, userId, isReady)
	local player = self:getPlayer(userId)
	if player then
		player:ready(isReady)
	end
end

pBattleBase.playerBankrupt = function(self, userId)
	local player = self:getPlayer(userId)
	if player then
		player:bankrupt()
		--player:setBankruptHint()
	else
		log("error", sf("[pBattleBase.playerBankrupt] can't find player %d", userId))
	end
end

pBattleBase.onNotifyPlayerFinishState = function(self, userId, stateInfo)
	local player = self:getPlayer(userId)
	if player then
		player:onServerNotifyExecutorFinish(stateInfo)
	else
		log("error", sf("[pBattleBase.playerFinishState] can't find player %d", userId))
	end
end

pBattleBase.onNotifyPlayerBankrupt = function(self, userId)
	self:playerBankrupt(userId)
end

pBattleBase.onNotifyCardChange = function(self, info)
	log("error", "[pBattleBase.onNotifyCardChange] not implemented")
end

pBattleBase.initBattleState = function(self, battleState)
	self:setBankerUserId(battleState.banker_user_id)
	if battleState.state_info then
		self:enterState(battleState.state_info)
	end
end

pBattleBase.initPlayerStates = function(self, playerStates)
	for _, state in ipairs(playerStates) do
		local userId = state.user_id
		local player = self:getPlayer(userId)
		if player then
			player:initState(state)
			player:initData(state)
		end
	end
end

pBattleBase.initCardPools = function(self, playerStates)
	for _, state in ipairs(playerStates) do
		local userId = state.user_id
		local player = self:getPlayer(userId)
		if player then
			player:initCardPools(state)
		end
	end
end

pBattleBase.newExecutorMgr = function(self)
	log("error", "[pBattleBase.newExecutorMgr] not implemented!")
end

pBattleBase.pausePlayer = function(self)
	--[[
	for _, player in pairs(self.players) do
		player:pause()
	end
	]]--
	self.executorMgr:pausePlayer()
end

pBattleBase.resumePlayer = function(self)
	--[[
	for _,player in pairs(self.players) do
		player:resume()
	end
	]]--
	self.executorMgr:resumePlayer()
end

pBattleBase.newPlayer = function(self, userId, playerId, battle)
	log("error", "[pBattleBase.newPlayer] not implemented!")
end

pBattleBase.newFakePlayer = function(self, userId, playerId, battle)
	return modPlayerBase.pFakePlayer:new(userId, playerId, battle)
end

pBattleBase.newObserver = function(self, userId, playerId, battle)
	return modPlayerBase.pObserver:new(userId, playerId, battle)
end

pBattleBase.getPlayer = function(self, userId)
	return self.players[userId]
end

pBattleBase.getObserver = function(self, userId)
	return self.observers[userId]
end

pBattleBase.getObserverByFollowee = function(self, userId)
	return self.reverseObservers[userId]
end

pBattleBase.getAllPlayers = function(self)
	return self.players
end

pBattleBase.getPlayerCnt = function(self, excludeFake)
	local cnt = 0
	for _, player in pairs(self.players) do
		if not excludeFake or not player:isFake() then
			cnt = cnt + 1
		end
	end
	return cnt
end

pBattleBase.getPlayerBySeat = function(self, seat)
	for userId, player in pairs(self.players) do
		if player:getSeat() == seat then
			return player
		end
	end
	return nil
end

pBattleBase.addPlayer = function(self, userId, playerId, isFake, isReady, score)
	log("error", sf("===== addPlayer %d, isFake: %s", userId, isFake))
	local player = nil
	if isFake then
		player = self:newFakePlayer(userId, playerId, self)
	else
		player = self:newPlayer(userId, playerId, self)
	end
	local seatId = self.playerIdToSeat[playerId]
	player:sitDown(seatId)
	self.players[userId] = player
	player:initCardPools()
	player:ready(isReady)
	player:setScore(score)
	self:onAddPlayer(player)
end

pBattleBase.onAddPlayer = function(self, player)
	self:getTableWnd():addPlayer(player)
end

pBattleBase.delPlayer = function(self, userId)
	self:onDelPlayer(self.players[userId])
	self.players[userId] = nil
end

pBattleBase.onDelPlayer = function(self, player)
	self:getTableWnd():delPlayer(player)
	-- OB 处理
	for _, ob in pairs(self.reverseObservers[player:getUserId()] or {}) do
		ob:destroy()
	end
	self.reverseObservers[player:getUserId()] = nil
	if self:getMyself():isObserver() then
		local followeeUid = self:getMyself():getFollowee():getUserId()
		if followeeUid == player:getUserId() then
			setTimeout(1, function()
				infoMessage(sf(TEXT("您观看的玩家%s已经退出房间"), player:getName()))
				local modCardBattleMain = import("logic/card_battle/main.lua")
				modCardBattleMain.pBattleMgr:instance():battleDestroy()
			end)
		end
	end
end

pBattleBase.addObserver = function(self, userId, followeeUid)
	local observer = self:newObserver(userId, -1, self)
	observer:setFollowee(followeeUid)
	self.observers[userId] = observer
	if not self.reverseObservers[followeeUid] then
		self.reverseObservers[followeeUid] = {}
	end
	self.reverseObservers[followeeUid][userId] = observer
	local followee = self:getPlayer(followeeUid)
	observer:setFollowee(followee)
	return observer
end

pBattleBase.delObserver = function(self, userId)
	local observer = self:getObserver(userId)
	if observer then
		self.observers[userId] = nil
		local followee = observer:getFollowee()
		self.reverseObservers[followee:getUserId()] = nil
	end
end

pBattleBase.playerEnterState = function(self, userId, stateInfo)
	local player = self:getPlayer(userId)
	if player then
		player:enterState(stateInfo)
	else
		log("error", sf("[pBattleBase.playerEnterState] can't find player %d", userId))
	end
end

pBattleBase.enterState = function(self, stateInfo)
	self.executorMgr:addExecutor(stateInfo)
end

pBattleBase.newTableWnd = function(self)
	log("error", "[pBattleBase.newTableWnd] not implemented!")
end

pBattleBase.shouldResetBankerOnReset = function(self)
	return true
end

pBattleBase.reset = function(self)
	if self.executorMgr then
		self.executorMgr:reset()
	end
	for _, player in pairs(self.players) do
		player:reset()
	end
	if self.battleUI then
		self.battleUI:reset()
	end
end

pBattleBase.prepareCancel = function(self)
	if self.executorMgr then
		self.executorMgr:prepareCancel()
	end
	for _, player in pairs(self.players) do
		player:prepareCancel()
	end
end

pBattleBase.startLocationDetect = function(self)
	if not modChannelMgr.getCurChannel():isNeedGeoFunc() then
		return
	end
	if modUtil.isAppstoreExamineVersion() then return end
	if not self.__location_hdr then
		self.__location_hdr = setInterval(modUtil.s2f(60 * 5), function()
			if puppy.location and puppy.location.pLocationMgr then
				puppy.location.pLocationMgr:instance():getLocation(function(longitude, latitude)
					modBattleRpc.commitGeoLocation(longitude, latitude, function(success, reason)
						if not success then
							--infoMessage(reason)
						end
					end)
				end)
			end
		end):update()
	end
end

pBattleBase.stopLocationDetect = function(self)
	if self.__location_hdr then
		self.__location_hdr:stop()
		self.__location_hdr = nil
	end
end

pBattleBase.getGoldImg = function(self)
	if self:isClubRoom() then
		return "ui:icon_dou.png"
	else
		return "ui:main_shop_icon.png"
	end
end

pBattleBase.destroy = function(self)
	if self.executorMgr then
		self.executorMgr:destroy()
		self.executorMgr = nil
	end
	for _, player in pairs(self.players) do
		player:destroy()
	end
	self.players = {}
	if self.battleUI then
		self.battleUI:destroy()
		self.battleUI = nil
	end
	self:stopLocationDetect()
	modChatMgr.pChatMgr:instance():cleanBattle(self)
	modEvent.fireEvent(EV_BATTLE_END)
	log("warn", "battle destroyed", self)
end

