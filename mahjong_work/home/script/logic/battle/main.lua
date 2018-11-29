---- battle从进入房间开始
-- 管理牌局中的所有流程和对象

------------------ 导入文件 --------------------
local modUtil = import("util/util.lua")
local modEvent = import("common/event.lua")
local modSessionMgr = import("net/mgr.lua")
local modSound = import("logic/sound/main.lua")
local modChatMgr = import("logic/chat/mgr.lua")
local modUserData = import("logic/userdata.lua")
local modPlayer = import("logic/battle/player.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modCalculate = import("ui/battle/calculate.lua")
local modUserPropCache = import("logic/userpropcache.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modFunctionManager = import("ui/common/uifunctionmanager.lua")
-------------------------------------------------

------------------ battle 战斗 --------------------

pBattle = pBattle or class()

pBattle.init = function(self, roomId)
	self.roomId = roomId
	-- playerId --> seatId
	self.seatMap = {}
	-- seatId --> playerId
	self.playerIdMap = {}
	-- uid --> seatId
	self.uidToSeat = {}
	-- seaetId --> uid
	self.seatToUid = {}
	-- seatId --> player
	self.players = {}
	-- playerId --> player
	self.pidToPlayers = {}
	-- uid --> isOnline
	self.playerOnlineInfo = {}
	-- seat --> dir
	self.seatToDir = {}
	-- 当前要出牌的玩家
	self.curTurnPlayer = nil
	-- 庄家
	self.bankerPlayer = nil
	-- 当前局数
	self.currentRound = 0
	-- 总局数
	self.totalRound = 0
	-- isGaming
	self.isGaming = nil
	-- roomInfo
	self.roomInfo = nil
	-- 是否为录像
	self.isVideoState = nil
	-- videoLocations
	self.videoLocations = nil
	-- 当局录像时间
	self.videoTime = nil
	self.robotCnt = 0
	self.playerCnt = 0
	-- 游戏阶段
	self.gamePhase = nil
	-- 默认解散时间
	self.timeOut = 60
	self.isReconnectFlag = false
	self.isReloginFlag = false
end

------------------ get set ------------------------
pBattle.getRoomId = function(self)
	return self.roomId
end

pBattle.getPlayerByPlayerId = function(self, playerId)
	return self.pidToPlayers[playerId]
end

pBattle.getAllPlayersByPid = function(self)
	return self.pidToPlayers
end

pBattle.getAllPlayers = function(self)
	return self.players
end

pBattle.getCurTurnPlayer = function(self)
	return self.curTurnPlayer
end

pBattle.getCurPlayer = function(self)
	return self:getPlayerByPlayerId(self:getMyPlayerId())
end

pBattle.setCurrMJTpe = function(self, t)
	self.currMJType = t
end

pBattle.getTimeOut = function (self)
	return self.timeOut
end

pBattle.getMyPlayerId = function(self)
	return self.myPlayerId
end

pBattle.getRoomInfo = function(self)
	return self.roomInfo
end

pBattle.getMySeatId = function(self)
	return self.seatMap[self.myPlayerId]
end

pBattle.getSeatIdByPlayerId = function(self, playerId)
	return self.seatMap[playerId]
end

pBattle.getSeatMap = function(self)
	return self.seatMap
end

pBattle.getPlayerIdMap = function(self)
	return self.playerIdMap
end
pBattle.getUidToSeat = function(self)
	return self.uidToSeat
end
pBattle.getSeatToUid = function(self)
	return self.seatToUid
end

pBattle.setPlayerIdMap = function(self,pidMap)
	self.playerIdMap = pidMap
end

pBattle.setUidToSeat = function(self,UTS)
	self.uidToSeat = UTS
end

pBattle.setSeatToUid = function(self,STU)
	self.seatToUid = STU
end

pBattle.setSeatMap = function(self,sm)
	self.seatMap = sm
end

pBattle.setPlayerCacheProp = function(self, player, prop)
	if not player or not prop then return end
	player:setPlayerCacheProp(prop)
end

pBattle.getSeatByPlayerId = function(self, playerId)
	return self.seatMap[playerId]
end

pBattle.getRobotCnt = function(self)
	return self.robotCnt
end

pBattle.getPlayerCnt = function(self, excludeRobot)
	if excludeRobot then
		return math.max(0, self.playerCnt - self.robotCnt)
	else
		return self.playerCnt
	end
end

pBattle.setPlayerOnlineInfo = function(self, uid, isOnline)
	self.playerOnlineInfo[uid] = isOnline
end

pBattle.getUidToSeat = function(self)
	return self.uidToSeat
end

pBattle.getPlayerIdBySeatId = function(self,curSeat)
	for pid,seatId in pairs(self.seatMap) do
		if seatId == curSeat then
			return pid
		end
	end
end

pBattle.getGamePhase = function(self)
	return self.gamePhase
end

pBattle.setGamePhase = function(self, phase)
	self.gamePhase = phase
end

pBattle.isPhaseHuanSanZhang = function(self)
	return self.gamePhase == modGameProto.EnterGamePhaseRequest.YUNYANG_HUANSANZHANG
end

pBattle.isPhaseRongchengHaidi = function(self)
	return self.gamePhase == modGameProto.EnterGamePhaseRequest.RONGCHENG_HAIDILAO
end

pBattle.isPhaseJieBao = function(self)
	return self.gamePhase == modGameProto.EnterGamePhaseRequest.RONGCHENG_JIEBAO
end

pBattle.isPhaseDingQue = function(self)
	return self.gamePhase == modGameProto.EnterGamePhaseRequest.YUNYANG_DINQUE
end

pBattle.isPhaseLa = function(self)
	return self.gamePhase == modGameProto.EnterGamePhaseRequest.TIANJIN_LA
end

pBattle.isPhaseChuai = function(self)
	return self.gamePhase == modGameProto.EnterGamePhaseRequest.TIANJIN_CHUAI
end

pBattle.isPhasePiao = function(self)
	return self.gamePhase == modGameProto.EnterGamePhaseRequest.PIAO
end

pBattle.isPhaseQianSi = function(self)
	return self.gamePhase == modGameProto.EnterGamePhaseRequest.YUNYANG_QIANSI
end

pBattle.isPhaseHouSi = function(self)
	return self.gamePhase == modGameProto.EnterGamePhaseRequest.YUNYANG_HOUSI
end

pBattle.isPhaseNormal = function(self)
	return self.gamePhase == modGameProto.EnterGamePhaseRequest.NORMAL
end

pBattle.isNormalDiscardPhase = function(self)
	return self:isPhaseNormal() or self:isPhaseQianSi() or self:isPhaseHouSi()
end

pBattle.isReconnect = function(self)
	return self.isReconnectFlag
end

pBattle.isRelogin = function ( self )
	return self.isReloginFlag
end

pBattle.getPlayerOnlineInfos = function(self)
	return self.playerOnlineInfo
end

pBattle.getIsJieBaoPhase = function(self)
	return self.gamePhase == modGameProto.EnterGamePhaseRequest.RONGCHENG_JIEBAO
end

pBattle.getVideoTime = function(self)
	return self.videoTime
end

pBattle.setVideoTime = function(self, t)
	self.videoTime = t
end

pBattle.getUidBySeatId = function(self,seatId)
	return self.seatToUid[seatId]
end

pBattle.getUidByPlayerId = function(self,pid)
	return self.seatToUid[self.seatMap[pid]]
end

pBattle.setIsGaming = function(self,isGaming)
	self.isGaming = isGaming
end

pBattle.getRoomInfo = function(self)
	return self.roomInfo
end

pBattle.getIsGaming = function(self)
	return self.isGaming
end

pBattle.getMyPlayer = function(self)
	return self:getPlayerByPlayerId(self:getMyPlayerId())
end

pBattle.getPlayers = function(self)
	return self.players
end

pBattle.getSeatToDir = function(self)
	return self.seatToDir
end

pBattle.setIsVideoState = function(self, isVideo)
	self.isVideoState = isVideo
end

pBattle.getIsVideoState = function(self)
	return self.isVideoState
end

pBattle.setVideoLocations = function(self, locations)
	self.videoLocations = locations
end

pBattle.getVideoLocations = function(self)
	return self.videoLocations
end

pBattle.setIsCalculate = function(self, isCalculate)
	self.isCalculate = isCalculate
end

pBattle.getIsCalculate = function(self)
	return self.isCalculate
end

pBattle.getBattleUI = function(self)
	return self.majiangGame:getBattleUI()
end

pBattle.isPhaseHuanSanZhang = function(self)
	return self.gamePhase == modGameProto.EnterGamePhaseRequest.YUNYANG_HUANSANZHANG
end

pBattle.getOwnerId = function(self)
	return self.ownerId
end

------------------- get set over -------------------

pBattle.initFromData = function(self, data)
	-- logv("warn",data)
	-- 设置房间属性
	self:setRoomParam(data)
	-- 初始化玩家
	self:initPlayers()
	-- 初始玩家信息(分数)
	self:initPlayerUserInfos(data)
	-- 游戏状态
	self.gameState = data[K_ROOM_STATE]
	-- 初始化game
	-- logv("info","data[K_ROOM_INFO].rule_type",data[K_ROOM_INFO].rule_type)
	self.majiangGame = self:initMajiangtGame(data[K_ROOM_INFO].rule_type):new(data)
	-- 在游戏中 重登
	if data[K_ROOM_IS_GAMING] then
		self.isReloginFlag = true
		self:parseGameState(data[K_ROOM_STATE])
		self:setIsCalculate(data[K_ROOM_STATE].is_over)
	end
	-- gameUI
	self.majiangGame:initBattleUI()
	-- 语音
	modChatMgr.pChatMgr:instance():setBattle(self)
end

pBattle.initPlayerUserInfos = function(self, data)
	local userInfos = data[K_USER_INFO]
	for _, info in ipairs(userInfos) do
		local player = self:getPlayerByPlayerId(info.player_id)
		player:setBaseScore(info.player_score_base)
	end
end


pBattle.initMajiangtGame = function(self, mjt)
	logv("info","pBattle.initMajiangtGame")
	if not mjt then return end	
	local crr = modLobbyProto.CreateRoomRequest
	local zhuanzhuangame = import("logic/battle/zhuanzhuangame.lua")
	local hongzhonggame = import("logic/battle/hongzhonggame.lua")
	local daodaogame = import("logic/battle/daodaogame.lua")
	local taojianggame = import("logic/battle/taojianggame.lua")
	local dongshangame = import("logic/battle/dongshangame.lua")
	local zhaoangame = import("logic/battle/zhaoangame.lua")
	local maominggame = import("logic/battle/maominggame.lua")
	local tianjingame = import("logic/battle/tianjingame.lua")
	local yunyanggame = import("logic/battle/yunyanggame.lua")
	local xiangyanggame = import("logic/battle/xiangyanggame.lua")
	local baihegame = import("logic/battle/baihexiangyang.lua")
	local rongchenggame = import("logic/battle/rongchenggame.lua")
	local chengdugame = import("logic/battle/chengdugame.lua")
	local jininggame = import("logic/battle/jininggame.lua")
	local pinghegame = import("logic/battle/pinghegame.lua")
	local mjts = {
		[crr.ZHUANZHUAN] = zhuanzhuangame.pZhuanzhuanGame,
		[crr.HONGZHONG] = hongzhonggame.pHongzhongGame,
		[crr.DAODAO] = daodaogame.pDaodaoGame,
		[crr.TAOJIANG] = taojianggame.pTaojiangGame,
		[crr.DONGSHAN] = dongshangame.pDongshanGame,		
		[crr.ZHAOAN]= zhaoangame.pZhaoanGame,
		[crr.MAOMING] = maominggame.pMaomingGame,
		[crr.TIANJIN] = tianjingame.pTianjinGame,
		[crr.YUNYANG] = yunyanggame.pYunyangGame,
		[crr.XIANGYANG] = xiangyanggame.pXiangyangGame,
		[crr.RONGCHENG] = rongchenggame.pRongchengGame,
		[crr.CHENGDU] = chengdugame.pChengduGame,
		[crr.XIANGYANG_BAIHE] = baihegame.pBaiheGame,
		[crr.JINING] = jininggame.pJiningGame,
		[crr.PINGHE] = pinghegame.pPingheGame,
	}
	logv("info","mjts[mjt]",mjts[mjt])
	return mjts[mjt]
end

-- 设置房间属性并生成座位
pBattle.setRoomParam = function(self, param)	
	self.param = param
	self.uids = param[K_ROOM_UIDS]
	self.gamePhase = param[K_ROOM_STATE].phase
	self.ownerId = param[K_ROOM_OWNER]
	if param[K_ROOM_ONLINE_INFO] then
		self.playerOnlineInfo = param[K_ROOM_ONLINE_INFO]
	end
--	self:setMagicCard(param[K_ROOM_STATE].options.magic_card_ids)
	self.roomInfo = param[K_ROOM_INFO]
	local playerIds = param[K_ROOM_PLAYER_IDS]
	self.myPlayerId = param[K_ROOM_MY_PLAYER_ID]
	self.myUserId = param[K_ROOM_UIDS][self.myPlayerId]
	self:setCurrMJTpe(self.roomInfo.rule_type)
	self:buildSeats(self.myPlayerId, self.myUserId, playerIds, self.roomInfo.max_number_of_users)
end


-- 更新玩家属性
pBattle.setPlayerInfo = function(self, uid, seatId)
	for uid, seatId in pairs(self.uidToSeat) do
		local player = 	self:getPlayerByPlayerId(self:getPlayerIdBySeatId(seatId))
		player:updateUserProps(uid, seatId)
	end
end

pBattle.sameIp = function(self)
	if not self.players or table.size(self.players) < 1 then return end
	local sameIPPlayers = {}
	local noipPlayers = {}
	-- 初始化samip 和 noip
	for _, player in pairs(self.players) do
		local ip = player:getIP()
		if not ip then
			table.insert(noipPlayers, player)
		else
			if not sameIPPlayers[ip] then
				sameIPPlayers[ip] = {}
			end
			table.insert(sameIPPlayers[ip], player)
		end
	end
	-- 移除没有相同的
	local removeidxs = {}
	for ip, list in pairs(sameIPPlayers) do
		if table.size(list) < 2 then
			table.insert(removeidxs, ip)
		end
	end
	for _, idx in pairs(removeidxs) do
		sameIPPlayers[idx] = nil
	end
	return {sameIPPlayers, noipPlayers}
end

pBattle.getCurGame = function(self)
	return self.majiangGame
end

-- 设置座位
pBattle.buildSeats = function(self, mine, uid, all, playerCount)
	--[[
	-- 自己的座位为0
	--		2
	--	3		1
	--		0
	--]]
	-- 建立映射
	logv("info","mine",mine,"uid",uid,"all",all,"playerCount",playerCount)
	local selfUid = self.myUserId
	self.seatMap[mine] = 0   -- pid to seat
	self.uidToSeat[selfUid] = 0
	self.seatToUid[0] = selfUid
	self.playerIdMap[0] = mine -- seat to pid

	if playerCount == 2 then
		for i = 0,playerCount - 1  do
			if i ~= mine then
				self.seatMap[i] = playerCount
				self.playerIdMap[playerCount] = i
				if all[i] then
					local _uid = all[i]
					self.uidToSeat[_uid] = playerCount
					self.seatToUid[playerCount] = _uid
				end
			end
		end
	elseif playerCount == 3 then
		for i = 0,playerCount - 1 do
			if i ~= mine then
				local distance = math.abs(i - mine)
				local seat = distance
				local pid = i
				if i > mine then
					if distance == 2 then
						seat = seat + 1
					end
				else
					if distance == 2 then
						seat = seat - 1
					elseif distance == 1 then
						seat = seat + 2
					end
				end
				if seat < 0 then
					seat = 3
				end
				if seat > 3 then
					seat = 3
				end
				self.seatMap[pid] = seat
				self.playerIdMap[seat] = pid
				if all[pid] then
					local _uid = all[pid]
					self.uidToSeat[_uid] = seat
					self.seatToUid[seat] = _uid
				end
			end
		end
	elseif playerCount == 4 then
		self:initSeat(mine,all)
	end

	logv("info", "buildSeats seatmap:", self.seatMap, "	  uidToSeat:", self.uidToSeat, "   playerIdMap:", self.playerIdMap,"seatToUid",self.seatToUid)
end

-- 初始化作为四人
pBattle.initSeat = function(self,mine,all)
	local selfUid = self.myUserId
	self.seatMap[mine] = 0   -- pid to seat
	self.uidToSeat[selfUid] = 0
	self.seatToUid[0] = selfUid
	self.playerIdMap[0] = mine -- seat to pid
	local num = 4
	for i = 0, num - 1 do
		if i ~= mine then
			if i > mine then
				self.seatMap[i] = i - mine
			else
				self.seatMap[i] = num - mine + i
			end
			self.playerIdMap[self.seatMap[i]] = i
			if all[i] then
				local _uid = all[i]
				local seatId = self.seatMap[i]
				self.uidToSeat[_uid] = seatId
				self.seatToUid[seatId] = _uid
			end
		end
	end
end

-- 初始化player
pBattle.initPlayers = function(self)
	for uid, seatId in pairs(self.uidToSeat) do
		local playerId = self.playerIdMap[seatId]
		local player = modPlayer.pPlayer:new(uid,playerId, seatId, self)
		local prop = modUserPropCache.getCurPropCache():getProp(uid)
		if prop then
			self:setPlayerCacheProp(player, prop)
		end
		self.players[seatId] = player
		self.pidToPlayers[playerId] = player
		player:updateUserProps(uid, seatId)
		self.playerCnt = self.playerCnt + 1
		if player:isRobot() then
			self.robotCnt = self.robotCnt + 1
		end
	end
end

pBattle.addPlayer = function(self, message)
	if not message then return end
	local uid = message.user_id
	local playerId = message.player_id
	local score = message.player_score_base
	if self.playerOnlineInfo[uid] then
		self.playerOnlineInfo[uid] = true
		return
	end
	self.playerOnlineInfo[uid] = true
	local seatId = self.seatMap[playerId]
	if not self.uidToSeat[uid] then
		self.uidToSeat[uid] = seatId
		logv("warn", self.seatToUid, seatId, score)
		self.seatToUid[seatId] = uid
		local player = modPlayer.pPlayer:new(uid, playerId, seatId, self)
		player:setBaseScore(score)
		self.players[seatId] = player
		self.pidToPlayers[playerId] = player
		self:setPlayerInfo(uid, seatId)
		modEvent.fireEvent(EV_ADD_USER, seatId, self.players)
		self.playerCnt = self.playerCnt + 1
		if player:isRobot() then
			self.robotCnt = self.robotCnt + 1
		end
	else
	end
end

--清除离开房间的人的信息
pBattle.leaveRoomCleanPlayerInfo = function(self,uid)
	local seatId = self.uidToSeat[uid]
	if seatId then
		self.uidToSeat[uid] = nil
	else
		return
	end
	self.seatToUid[seatId] = nil
	local player = self.players[seatId]
	if player then
		self.players[seatId] = nil
		self.playerCnt = math.max(0, self.playerCnt - 1)
		if player:isRobot() then
			self.robotCnt = math.max(0, self.robotCnt - 1)
		end
	end
	return self.players
end

-- 删除玩家
pBattle.delPlayer = function(self, uid, isLeave)
	local uid = uid
	local isLeave = isLeave
	self.playerOnlineInfo[uid] = false
	-- 并不离开座位
	if self.uidToSeat[uid] then
		local seatId = self.uidToSeat[uid]
		if self.players[seatId] then
			local player = self.players[seatId]
			self.seatToUid[seatId] = nil
			self.uidToSeat[uid] = nil
			self.pidToPlayers[player:getPlayerId()] = nil
			self.players[seatId] = nil
		end
	else
		log("error", "[battle delPlayer] can't find user", uid)
	end
end

pBattle.parseGameState = function(self, proto) -- ??
	logv("warn","pBattle.parseGameState","999")
	if not proto then
		return
	end
	for playerId, playState in ipairs(proto.player_states) do
		playerId = playerId - 1
		local seatId = self.seatMap[playerId]
		local player = self.players[seatId]
		-- comb 没有触发牌处理
		for idx, comb in ipairs(playState.showed_combs) do
			if table.getn(comb.trigger_card_ids) == 0 then
				local tId = nil
				for _, id in ipairs(comb.card_ids) do
					tId = id
				end
				comb.trigger_card_ids:append(tId)
			end
		end

		-- 添加
		player:addCardsToPool(T_POOL_SHOW, playState.showed_combs)
		player:addCardsToPool(T_POOL_HAND, playState.held_card_ids)
		player:addCardsToPool(T_POOL_DISCARD, playState.discarded_card_ids)
		player:addCardsToPool(T_POOL_FLOWER, playState.bonus_card_ids)
		-- flag
		player:clearFlags()
		for _, flag in ipairs(playState.flags) do
			player:setFlag(flag)
		end

		-- 发牌
		local cards = {}
		for _, id in ipairs(playState.dangling_held_card_ids) do
			table.insert(cards, id)
			if id < 0 then
				log("error", "error id ====", id)
			end
		end
		player:setCurrentDealCard(cards)

		-- 胡牌
		player:setCanHuCardIds(playState.winning_card_ids)

		-- 特殊弃牌
		player:setDiscardIndex(playState.special_discarding_position)

		-- 设置玩家分数
		self:updateScoreByPid(playerId, playState)

		-- 设置玩家附加信息
		player:setExtras(playState.extras)
	end
	self.curTurnPlayer = self.pidToPlayers[proto.current_player_id]
	self.bankerPlayer = self.pidToPlayers[proto.banker_id]
	self.majiangGame:afterSetParseGame()
end

pBattle.start = function(self)
	self.majiangGame:start()
end

pBattle.updateScoreByPid = function(self, playerId, state)
	if not playerId or not state then return end
	local player = self:getPlayerByPlayerId(playerId)
	for pid, score in ipairs(state.scores_from_players) do
		if  pid - 1 == playerId then
			self:getPlayerByPlayerId(playerId):resetScore()
			self:getPlayerByPlayerId(playerId):addScore(score)
			return
		end
	end
end

pBattle.seatConvertToDir = function(self, hostId)
	-- 东南西北
	local pidToDir = {}
	local dirs = {T_DIR_E, T_DIR_S, T_DIR_W, T_DIR_N}
	pidToDir[hostId] = T_DIR_E
	local nextId = hostId + 1
	for i = hostId + 1, hostId + table.size(self.players) - 1 do
		if nextId > table.size(self.players) - 1 then
			nextId = 0
		end
		pidToDir[nextId] = pidToDir[hostId] + (i - hostId)
		nextId = nextId + 1
	end

	for pid, dir in pairs(pidToDir) do
		self.seatToDir[self.seatMap[pid]] = dir
	end
end

pBattle.clearAllPlayerFlags = function(self)
	for _, player in pairs(self.players) do
		player:clearFlags()
	end
end


pBattle.stop = function(self)
	for _, player in pairs(self.players) do
		player:cleanAllCards()
	end
	self.curTurnPlayer = nil
	self:setIsGaming(false)
end

pBattle.startLocationDetect = function(self)
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

pBattle.destroy = function(self)
	self:stop()
	for _, player in pairs(self.players) do
		player:destroy()
	end
	if self.majiangGame then
		self.majiangGame:destroy()
	end
	self.seatToDir = {}
	self.players = {}
	self.seatMap = {}
	self.playerIdMap = {}
	self.uidToSeat = {}
	self.seatToUid = {}
	self.pidToPlayers = {}
	self.videoLocations = nil
	self.gamePhase = nil
	self.curTurnPlayer = nil
	self.bankerPlayer = nil
	self.isVideoState = nil
	self.isGaming = nil
	self.videoTime = nil
	self.btnValues = nil
	self.roomInfo = nil
	self:stopLocationDetect()
	self:clearUIFunctionMgr()
	modChatMgr.pChatMgr:instance():setBattle(nil)
end

pBattle.stopLocationDetect = function(self)
	if self.__location_hdr then
		self.__location_hdr:stop()
		self.__location_hdr = nil
	end
end

pBattle.clearUIFunctionMgr = function(self)
	if modFunctionManager.pUIFunctionManager:getInstance() then
		modFunctionManager.pUIFunctionManager:instance():destroy()
	end
end

pBattle.dismissRoomAndStopFunction = function(self)
	modFunctionManager.pUIFunctionManager:instance():startPriorFunction(function()
		local modDisMissList = import("ui/battle/dismisslist.lua")
		if modDisMissList.pDisMissList:getInstance() then
			modDisMissList.pDisMissList:instance():isShowOkAndNo(false)
			local disRoomTime = 120
			modDisMissList.pDisMissList:instance():timeOut(disRoomTime, nil, function()
				if modDisMissList.pDisMissList:getInstance() then
					modDisMissList.pDisMissList:instance():close()
				end
				modFunctionManager.pUIFunctionManager:instance():stopPriorFunction()
			end)
		end
	end)
end

pBattle.setPropCacheData = function(self, name, value)
	local modUserData = import("logic/userdata.lua")
	modUserPropCache.getCurPropCache():setProp(modUserData.getUID(), name, value)
end
--***************** 协议接口 ****************
pBattle.closeRoom = function(self, message)
	if not message then return end
	-- 关闭连接
	modSessionMgr.instance():closeSession(T_SESSION_BATTLE)
	-- 如果存在小结算界面关闭当前队列函数
	if modCalculate.pCalculatePanel:getInstance() then
		modFunctionManager.pUIFunctionManager:instance():stopFunction()
	end
	-- 摧毁战斗和界面
	modFunctionManager.pUIFunctionManager:instance():startFunction(function()
		local modBattleMgr = import("logic/battle/main.lua")
		modBattleMgr.pBattleMgr:instance():battleDestroy()
		modFunctionManager.pUIFunctionManager:instance():destroy()
	end)
end

pBattle.cancelCloseRoom = function(self, message)
	if not message then return end
	-- 清除关闭房间
	self:getBattleUI():clearCloseRoom()
	-- 延迟关闭
	self:dismissRoomAndStopFunction()
end

pBattle.answerCloseRoom = function(self, message)
	if not message then return end
	-- 回复结果
	modEvent.fireEvent(EV_UPDATE_DISSROOM_RESULT, message)
end

pBattle.askCloseRoom = function(self, message)
	if not message then return end
	self:getBattleUI():closeSet()
	self:getBattleUI():askCloseRoomWork(message)
end

pBattle.applyCloseRoom = function(self)
	self:dismissRoomAndStopFunction()
end

pBattle.updateUserProps = function(self, message)
	if not message then return end
end


pBattle.addUser = function(self, message)
	if not message then return end
	local userId = message.user_id
	local playerId = message.player_id
	self:addPlayer(message)
	self:getBattleUI():addUserStatus(userId, playerId)
end

pBattle.removeUser = function(self, message)
	if not message then return end
	local uid = message.user_id
	self:getBattleUI():removeUserStatus(uid)
	self:delPlayer(uid)
end

pBattle.updateOnline = function(self, message)
	if not message then return end
	local uid = message.user_id
	local isOnline = message.is_online
	if isOnline then
		self:getBattleUI():onlineStatus(uid)
	else
		self:getBattleUI():offlineIcon(uid)
	end
	self:setPlayerOnlineInfo(uid, isOnline)
	self:getBattleUI():updateIsShowBtnTellAll()
end

pBattle.askChooseCardToDiscard = function(self, message)
	if not message then return end
	self.majiangGame:askChooseCardToDiscard(message)
end

pBattle.askChoosePlayerFlag = function(self, message)
	if not message then return end
	self.majiangGame:askChoosePlayerFlag(message)
end

pBattle.updatePlayerFlags = function(self, message)
	if not message then return end
	self.majiangGame:updatePlayerFlags(message)
end

pBattle.startGame = function(self, message)
	if not message then return end
	-- 设置玩家分数
	local states = message.initial_state.player_states
	for playerId, state in ipairs(states) do
		self:updateScoreByPid(playerId - 1, state)
	end
	-- 其他逻辑
	self.majiangGame:startGame(message)
end

pBattle.askChooseCombination = function(self, message)	
	if not message then return end
	-- 加入combs	
	for idx, comb in ipairs(message.combs) do
		if table.getn(comb.trigger_card_ids) == 0 then
			local tId = nil			
			for _, id in ipairs(comb.card_ids) do				
				tId = id
			end
			comb.trigger_card_ids:append(tId)
		end
	end	
	modEvent.fireEvent(EV_CHOOSE_COMBS, message)
end

--请求玩家选择暗杠
pBattle.askChooseAngang = function ( self,message )
	logv("warn","pBattle.askChooseAngang")
	if not message then return end
	local PlayerToAngang = message.player_to_angang
	for _,v in ipairs (PlayerToAngang) do
		logv("warn","v",v.angang_id,v.player_id)
		for m,s in ipairs (v.angang_id) do
			logv("warn","m",m,"s",s)
		end		
	end
	modEvent.fireEvent(EV_CHOOSE_ANGANGS,message)	
end

pBattle.nextTurn = function(self, message)
	if not message then return end
	local playerId = message.player_id
	local seatId = self:getSeatMap()[playerId]
	self.curTurnPlayer = self:getPlayerByPlayerId(playerId)
	modEvent.fireEvent(EV_NEXT_TURN, seatId)
end

pBattle.askCheckGameOver = function(self, message)
	if not message then return end
	modEvent.fireEvent(EV_GAME_CALC, message)
	self.majiangGame:askCheckGameOver()
	self:clearAllPlayerFlags()
	local isTimeOut = false
	if  not self:getIsCalculate() then
		isTimeOut = true
		self:setIsCalculate(true)
		if table.getn(message.niao_card_ids) > 0  then
			isTimeOut = false
			self:getBattleUI():zhuanNiaoFunction(message)
		end
	end
	modFunctionManager.pUIFunctionManager:instance():startFunction(function()
		if isTimeOut then
			local modUIUtil = import("ui/common/util.lua")
			modUIUtil.timeOutDo(modUtil.s2f(1), nil, function()
				modFunctionManager.pUIFunctionManager:instance():stopFunction()
			end)
		else
			modFunctionManager.pUIFunctionManager:instance():stopFunction()
		end
	end)
	self:getBattleUI():calculateFunction(message)
end

pBattle.updatePlayerScore = function(self, message)
	if not message then return end
	self.majiangGame:updatePlayerScore(message)
end

pBattle.updateUndealtCardCount = function(self, message)
	if not message then return end
	self:getBattleUI():updateUndealtCard(message.undealt_card_count)
end

pBattle.updateReservedCardCount = function(self, message)
	if not message then return end
	self:getBattleUI():updatePlayerScore(message.score_delta, message.from_player_id, message.to_player_id)
end

pBattle.showClosureReport = function(self, message)
	if not message then return end
	self:getBattleUI():clearDiscardMark()
	local modEndCalculate = import("ui/battle/endcalculate.lua")
	modFunctionManager.pUIFunctionManager:instance():startFunction(function()
		if modCalculate.pCalculatePanel:getInstance() then
			modCalculate.pCalculatePanel:instance():close()
		end
		modEndCalculate.pEndCalculate:instance():open(message)
	end)
end

pBattle.rollDices = function(self, message)
	if not message then return end
	self:getBattleUI():rollDices(message)
end

pBattle.sendMessage = function(self, message)
	if not message then return end
	self:getBattleUI():showSendMessage(message)
end

pBattle.updateCardPoolUpdate = function(self, message)
	if not message then return end
	self.majiangGame:updateCardPoolUpdate(message)
end

pBattle.updateShowCombsUpdate = function(self, message)
	if not message then return end
	self.majiangGame:updateShowCombsUpdate(message)
end

pBattle.gamePhaseFunction = function(self, phase)
	if not phase then return end
	self.majiangGame:gamePhaseFunction(phase)
end

pBattle.askChooseCards = function(self, message)
	if not message then return end
	self.majiangGame:askChooseCards(message)
end

pBattle.askChooseAngangIds = function ( self, message )
	if not message then return end
	self.majiangGame:askChooseAngangIds(message)
end

pBattle.updateWinnerCards = function(self, message)
	if not message then return end
	self.majiangGame:updateWinnerCards(message)
end

pBattle.updateMagicCards = function(self, message)
	if not message then return end
	self.majiangGame:updateMagicCards(message)
end

pBattle.updateDiscardIndex = function(self, message)
	if not message then return end
	local player = self:getPlayerByPlayerId(message.player_id)
	player:setDiscardIndex(message.special_discarding_position)
	self:getBattleUI():updatePlayerDiscardCards(player)
end

pBattle.updatePlayerExtras = function(self, message)
	if not message then return end
	if message.player_id ~= self:getMyPlayerId() then
		return
	end
	local player = self:getPlayerByPlayerId(message.player_id)
	player:setExtras(message.player_extras)
	self.majiangGame:updatePlayerExtras(message, player)
end

-- **************** 接口over ***********

--------------------- battle mgr ----------------------

pBattleMgr = pBattleMgr or class(pSingleton)

pBattleMgr.init = function(self)
end

pBattleMgr.enterBattle = function(self,roomId, roomHost, roomPort, callback)
	logv("warn","pBattleMgr.enterBattle")
	local wnd = modUtil.loadingMessage(TEXT("正在连接到房间服务器..."))
	self:initRoomNet(roomHost, roomPort, function(success)
		wnd:setParent(nil)
		if success then
			self:enterRoom(roomId, callback)
		else
			infoMessage(TEXT("连接房间服务器失败"))
			modSessionMgr.instance():closeSession(T_SESSION_BATTLE)
		end
	end)
end

pBattleMgr.enterRoom = function(self, roomId, callback, isReconnect)
	logv("warn","pBattleMgr.enterRoom")	
	logv("warn",isReconnect)
	modBattleRpc.enterRoom(roomId, function(success, reason, ret, isRoomCardError)
		if success then
			if self.curBattle then
				self.curBattle:destroy()
			end			
			self:initBattleInfo(ret, false, roomId, isReconnect)
			if callback then callback(true) end
		else
			self:battleDestroy()
			if isRoomCardError then
				local modMenuMain = import("logic/menu/main.lua")
				modMenuMain.pMenuMgr:instance():getCurMenuPanel():buyCard()
				local modShopMgr = import("logic/shop/main.lua")
				local modInvite = import("ui/menu/invite.lua")
				local modJoin = import("ui/menu/join.lua")
				if modShopMgr.pShopMgr:instance():getShopPanel(true) then
					modShopMgr.pShopMgr:instance():getShopPanel():setParent(self)
					modShopMgr.pShopMgr:instance():getShopPanel():setZ(C_BATTLE_UI_Z)
				elseif modInvite.pInviteWindow:getInstance() then
					modInvite.pInviteWindow:instance():setParent(modJoin.pMainJoin:instance())
					modInvite.pInviteWindow:instance():setZ(C_BATTLE_UI_Z)
				end
			end
			infoMessage(reason)
			if callback then callback(false) end
		end
	end)
end

pBattleMgr.initRoomNet = function(self, roomHost, roomPort, callback)
	local session = modSessionMgr.instance():newSession(T_SESSION_BATTLE, roomHost, roomPort)
	session:connectRemote(function(timeout, err)
		if not timeout and not err then
			callback(true)
		else
			callback(false)
		end
	end)
end

getCurBattle = function()
	return pBattleMgr:instance().curBattle
end

pBattleMgr.battleDestroy = function(self)
	if self.curBattle then
		self.curBattle:destroy()
		self.curBattle = nil
		modSessionMgr.instance():closeSession(T_SESSION_BATTLE)
	end
--	pBattleMgr:cleanInstance()
end


pBattleMgr.initBattleInfo = function(self, ret, isVideo, roomId, isReconnect)	
	-- 初始化战斗
	self.curBattle = pBattle:new(roomId)
	self.curBattle:initFromData(ret)
	-- 设置录像
	if isVideo then
		self.curBattle:setIsVideoState(true)
	else
		self.curBattle:startLocationDetect()
	end
	-- 已经在战斗中，直接开始战斗
	if ret[K_ROOM_IS_GAMING] then		
		self.curBattle:start()
	end
	-- 测试
--	local message = modLobbyProto.UpdateUserPropsRequest()
--	message.room_card_count_delta = 14
--	self.curBattle:updateUserProps(message)
end
