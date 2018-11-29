local modUIUtil = import("ui/common/util.lua")
local modUIAllFunction = import("ui/common/uiallfunction.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modUtil = import("util/util.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modUserData = import("logic/userdata.lua")
local modRoomProto = import("data/proto/rpc_pb2/room_pb.lua")
local modVideoPlayer = import("ui/menu/videoplayer.lua")
local modProtoFucntion = import("net/rpc/proto_to_function.lua")

pPlayRoom = pPlayRoom or class(pWindow)

pPlayRoom.init = function(self, videoGroup, info, userIds, playerInfos, playerUids, uidToPid, x, y, width, height, round, code)

	self:load("data/ui/videoinforoom.lua")
	self:setPosition(x, y)
	self:setAlignX(ALIGN_LEFT)
	self:setAlignY(ALIGN_TOP)
	self:setSize(width, height)

	-- 初始化
	self:initUIData(videoGroup, info, userIds, playerInfos, playerUids, uidToPid, round, code)

	-- 初始化UI
	self:showInfoWnd()
	self.wnd_code:setText(sf("回放码：%08d", self.videoId))
--	self.wnd_start_time:setText(os.date("  %m-%d  %H:%M", self.startTime))

	-- 描画第几局
	if not self.code then
		local roundStr = "局"
		if self.roomInfo.rule_type == modLobbyProto.CreateRoomRequest.TIANJIN or self.roomInfo.rule_type == modLobbyProto.CreateRoomRequest.PINGHE then
			roundStr = "圈"
		end
		self.wnd_round:setText(sf("第%d" .. roundStr, self.currRound))
	end

	local timeStr = os.date("  %m-%d  %H:%M", self.startTime)
	self.wnd_time:setText("录像时间：" .. timeStr)


	-- 播放按钮
	self.btn_play:addListener("ec_mouse_click", function() 
		self:createRoom(self.roomId, self.roomInfo, self.playerUids, self.videoId) 
	end)	

end

pPlayRoom.initUIData = function(self, videoGroup, info, userIds, playerInfos, playerUids, uidToPid, round, code)
	self.videoGroup = videoGroup
	self.videoId = info.id
	self.startTime = info.started_date
	self.gameOverInfo = info
	self.currRound = round
	self.playerInfos = playerInfos
	self.playerUids = playerUids
	self.uidToPid = uidToPid
	self.userIds = userIds
	self.code = code
	self.scoreBases = videoGroup.player_score_bases
	self:getScoresFromGameOverInfo()

	self.roomId = videoGroup.room_id
	self.roomInfo = modLobbyProto.CreateRoomRequest()
	self.roomInfo:ParseFromString(videoGroup.room_creation_info)
	self.roomCreateTime = videoGroup.room_created_date

	self:initData()
end

pPlayRoom.getScoresFromGameOverInfo = function(self)
	if not self.gameOverInfo then return end
	self.playerScores = {} 
	local tmpInfo = modGameProto.AskCheckGameOverRequest()
	tmpInfo:ParseFromString(self.gameOverInfo.game_over_info)
	local states = tmpInfo.player_statistics
	for pid, uid in pairs(self.playerUids) do
		local state = self:findStateByPid(pid, states)
		local scoreBase = self:getScoreBase(pid)
		self.playerScores[pid] = self:getScoreFromState(pid, state) --+ scoreBase
	end
end

pPlayRoom.getScoreBase = function(self, playerId)
	if not self.scoreBases or not playerId then return 0 end
	for pid, score in ipairs(self.scoreBases) do
		if playerId == pid - 1 then
			return score
		end
	end
	return 0
end

pPlayRoom.findStateByPid = function(self, playerId, states)
	if not playerId or not states then return end
	for pid, state in ipairs(states) do
		if playerId == pid - 1 then
			return state
		end
	end
	return
end

pPlayRoom.getScoreFromState = function(self, playerId, state)
	if not state or not playerId then return end
	local tmpScore = 0
	for pid, score in ipairs(state.scores_from_players) do
		if playerId == pid - 1 then
			tmpScore = score
			return tmpScore
		end
	end
	return 0 
end

pPlayRoom.getPropByUid = function(self, uid)
	if not uid or not self.playerInfos then return end
	for _, prop in ipairs(self.playerInfos) do
		if prop.user_id == uid then
			return prop
		end
	end
	return nil
end

pPlayRoom.showInfoWnd = function(self)
	for i = 1, 4 do
		if not self.userIds[i] then 
			self[sf("wnd_image_%d_bg", i)]:show(false)
			self[sf("wnd_name_%d", i)]:show(false)
			self[sf("wnd_score_%d", i)]:show(false)
		else
			if self.userIds[i] == modUserData.getUID() then
				self[sf("wnd_name_%d", i)]:getTextControl():setColor(0xFF800000)
				self[sf("wnd_score_%d", i)]:getTextControl():setColor(0xFF800000)
				self[sf("wnd_score_%d", i)]:setText(self.playerScores[self.uidToPid[self.userIds[i]]])
			end
			local reply = self:getPropByUid(self.userIds[i])
			local avatarUrl = reply.avatar_url
			if not avatarUrl or avatarUrl == "" then
				avatarUrl = modUIUtil.getDefaultImage(reply.gender)
			end
			self[sf("wnd_image_%d", i)]:setImage(avatarUrl)
			self[sf("wnd_image_%d", i)]:setColor(0xFFFFFFFF)

			local name = reply.nickname 
			if modUIUtil.utf8len(name) > 5 then
				name = modUIUtil.getMaxLenString(name, 5)
			end
			self[sf("wnd_name_%d", i)]:setText(name)
			self[sf("wnd_score_%d", i)]:setText(self.playerScores[self.uidToPid[self.userIds[i]]])
			--		self[sf("wnd_image_%d_front", i)]:addListener("ec_mouse_click", function() 
	--			local modPlayerInfo = import("ui/menu/player_info.lua")
	--			modPlayerInfo.pPlayerInfo:instance():open(self.userIds[i])
	--		end)
		end

	end
end


-- 创建录像房间初始化
pPlayRoom.createRoom = function(self, roomId, roomInfo, playerUids, videoId)
	if modBattleMgr.getCurBattle() then
		infoMessage(TEXT("已经在房间当中，观看录像请先退出房间。"))
		return
	end
	local roomId = roomId
	local roomInfo = roomInfo
	local playerUids = playerUids

	local createInfo = {}
	createInfo.user_infos = {}
	for pid, uid in pairs(playerUids) do
		createInfo.user_infos[pid + 1] ={}
		createInfo.user_infos[pid + 1].user_id = uid
		createInfo.user_infos[pid + 1].player_id = pid
		createInfo.user_infos[pid + 1].is_online = true
		createInfo.user_infos[pid + 1].player_score_base = self:getScoreBase(pid)
	end
	createInfo.is_gaming = false
	createInfo.game_state = {}
	createInfo.game_state.options = {}
	createInfo.game_state.options.max_number_of_cards_per_player = 0
	createInfo.player_states = {}
	createInfo.room_creation_info = roomInfo

	createInfo = modUIAllFunction.enterRoomConvert( roomId, createInfo, true)
	modBattleMgr.pBattleMgr:instance():initBattleInfo(createInfo, true)
	modBattleMgr.getCurBattle():setVideoTime(self.startTime)
	-- 播放录像
	self:playVideo(videoId)
	-- 播放器
	modVideoPlayer.pVideoPlayer:instance():open(self)
end

pPlayRoom.playVideo = function(self, recordId)
	local videoId = recordId
	modBattleRpc.getGameVideo(videoId, function(success, reason, ret)
		if success then
			-- 取得录像协议组
			local data = modGameProto.GameRecord()
			data:ParseFromString(ret.data)
			self.frames = data.frames
			-- 设置录像各个玩家地理位置
			modBattleMgr.getCurBattle():setVideoLocations(data.user_geo_locations)
			self.frameIndex = 1
			self:playFrames() 
		end
	end)		
end

pPlayRoom.overFunction = function(self)
	self:playCalculate()
	self:videoStop()
	self:initData()
end

pPlayRoom.playCalculate = function(self)
	-- 手动添加小结算协议
	local calculateAction = {} 
	calculateAction.id = modGameProto.ASK_CHECK_GAME_OVER
	calculateAction.data = self.gameOverInfo.game_over_info
	self:playProto( calculateAction )
end

pPlayRoom.playFrames = function(self)
	local frame = self.frames[self.frameIndex]
	self:playAction(frame.actions)
	local isOver = self.frameIndex == table.getn(self.frames)

	if isOver then
		self:overFunction()
	else
		self.frameIndex = self.frameIndex + 1
		self.timeOutEvent = modUIUtil.timeOutDo(self.time, nil, function()
			self:playFrames()
		end)
	end
end

pPlayRoom.playAction = function(self, actions)
	for _, action in ipairs(actions) do
		self:playProto(action)
	end
end

pPlayRoom.playProto = function(self, action)
	local id = action.id
	modProtoFucntion.getProtoFunction(id)(action.data)
end

pPlayRoom.setTime = function(self, t)
	if t > 40 then
		t = 40
	elseif t < 5 then
		t = 5
	end
	self.time = t
end

pPlayRoom.getTime = function(self)
	return self.time
end

pPlayRoom.videoStop = function(self)
	if modVideoPlayer.pVideoPlayer:getInstance() then
		modVideoPlayer.pVideoPlayer:instance():close()
	end
end

pPlayRoom.setPause = function(self, isBreak)
	if isBreak then
		if self.timeOutEvent ~= nil then
			self.timeOutEvent:stop()
			self.timeOutEvent = nil
		end
	else
		self:playFrames()
	end
end

pPlayRoom.setReturn = function(self, isReturn)
	if self.timeOutEvent ~= nil then
		self.timeOutEvent:stop()
		self.timeOutEvent = nil
	end
	self:overFunction()
end

pPlayRoom.initData = function(self)
	self.controls = {}
	self.time = 60
	self.frames = nil
	self.frameIndex = nil
	self.timeOutEvent = nil
end

pPlayRoom.getPlayerInfos = function(self)
	return self.playerInfos
end

pPlayRoom.getPlayerScores = function(self)
	return self.playerScores
end

pPlayRoom.getUidToPid = function(self)
	return self.uidToPid
end

pPlayRoom.getVideoId = function(self)
	return self.videoId
end

pPlayRoom.getStartTime = function(self)
	return  os.date("%y-%m-%d  %H:%M", self.startTime)
end
