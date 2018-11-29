local modUIUtil = import("ui/common/util.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modUtil = import("util/util.lua")
local modUserData = import("logic/userdata.lua")
local modRoomProto = import("data/proto/rpc_pb2/room_pb.lua")

local T_VIDEO_GENERAL = modLobbyProto.GRGC_GENERAL

pVideoGroup = pVideoGroup or class(pWindow)

pVideoGroup.init = function(self, videoGroup, moveTo, host, x, y, width, height, isDel)
	self:load("data/ui/videoroom.lua")
	self:setParent(host.wnd_drag)
	self:setSize(width, height)
	self:setAlignX(ALIGN_LEFT)
	self:setAlignY(ALIGN_TOP)
	self:setPosition(x, y)
	self:setZ(-1)
	self.isDel = isDel
	self.host = host
	-- 测试大结算按钮
	self.btn_end_calculate:show(false)

	-- 初始化
	self:initData(videoGroup, moveTo)


	-- 没有信息的窗体不显示
	self:showWnd()
	for pid, uid in ipairs(self.userIds) do
		self.playerUids[pid - 1] = uid
	end
	for pid, uid in pairs(self.playerUids) do
		self.uidToPid[uid] = pid
	end
	for pid, playerStatistics in ipairs(self.endCalculateInfo.player_total_statistics) do
	--	local scoreBase = self:getScoreBase(pid - 1)
		self.playerScores[pid] = self:getScoreFromState(pid - 1, playerStatistics)-- + scoreBase
	end
	if self.isDel then
		self.wnd_save:setImage("ui:standings_del.png")
		self.moveTo = T_VIDEO_GENERAL
	end

	-- 设置玩家头像和昵称
	self:setUserPropWnd(videoGroup)

	self.btn_end_calculate:addListener("ec_mouse_click", function()
			local modEndCalculte = import("ui/battle/endcalculate.lua")
			modEndCalculte.pEndCalculate:instance():open(self.endCalculateInfo, true, self.playerUids, self.roomInfo, self.roomCreateTime, self.roomId)
		end)
end

pVideoGroup.getScoreBase = function(self, playerId)
	if not self.scoreBases or not playerId then return 0 end
	for pid, score in ipairs(self.scoreBases) do
		if playerId == pid - 1 then
			return score
		end
	end
	return 0
end

pVideoGroup.getScoreFromState = function(self, playerId, state)
	if not playerId or not state then return end
	local tmpScore = 0
	for pid, score in ipairs(state.scores_from_players) do
		if playerId == pid - 1 then
			tmpScore = score
			return tmpScore
		end
	end
	return 0
end

pVideoGroup.initData = function(self, videoGroup, moveTo)
	self.moveTo = moveTo
	self.roomId = videoGroup.room_id
	self.roomInfo = modLobbyProto.CreateRoomRequest()
	self.roomInfo:ParseFromString(videoGroup.room_creation_info)
	self.roomCreateTime = videoGroup.room_created_date
	self.groupId = videoGroup.id
	self.userIds = videoGroup.user_ids  -- pid to uid
	self.scoreBases = videoGroup.player_score_bases
	self.playerUids = {}
	self.endCalculateInfo = modRoomProto.ShowClosureReportRequest()
	self.endCalculateInfo:ParseFromString(videoGroup.room_closure_info)
	self.videoIds = videoGroup.record_ids
	self.uidToPid = {}
	self.playerScores = {}

end

pVideoGroup.showWnd = function(self)
	for i = 1, 4 do
		if not self.userIds[i] then
			self[sf("wnd_image_%d_bg", i)]:show(false)
			self[sf("wnd_name_%d", i)]:show(false)
			self[sf("wnd_score_%d", i)]:show(false)
		else
			if self.userIds[i] == modUserData.getUID() then
				self[sf("wnd_name_%d", i)]:getTextControl():setColor(0xFF800000)
				self[sf("wnd_score_%d", i)]:getTextControl():setColor(0xFF800000)
			end
--			self[sf("wnd_image_%d_front", i)]:addListener("ec_mouse_click", function()
--				local modPlayerInfo = import("ui/menu/player_info.lua")
--				modPlayerInfo.pPlayerInfo:instance():open(self.userIds[i])end)
			end
	end
end

pVideoGroup.setRoomId = function(self)
	local str = "房号：" .. sf("%06d", self.roomId)
	local timeStr = os.date("  %m-%d  %H:%M", self.roomCreateTime)
	local ruleStr = modUIUtil.getRuleStringByType(self.roomInfo.rule_type)
	str = str .. timeStr .. "  "  .. ruleStr
	self.wnd_room_id:setText(str)
end

pVideoGroup.setScore = function(self)
	for pid, score in ipairs(self.playerScores) do
		local wnd = self[sf("wnd_score_%d", pid)]
		if not wnd then return end
		wnd:setText(score)
	end
end

pVideoGroup.setUserPropWnd = function(self, videoGroup)

	-- 请求玩家属性
	local namelist = {
		"gender", "avatarurl", "name",
	}
	local us = {}
	for _, u in ipairs(self.userIds) do
		table.insert(us, u)
	end
	modBattleRpc.getMultiUserProps (us, namelist, function(success, reason, ret)
		if not success then return end

		for id, prop in ipairs(ret.multi_user_props) do
			local uid = prop.user_id
			local pid = self.uidToPid[uid] + 1
			local gender = prop.gender
			local avatarUrl = prop.avatar_url
			if not avatarUrl or avatarUrl == "" then
				avatarUrl = modUIUtil.getDefaultImage(gender)
			end
			prop.avatar_url = avatarUrl
			self[sf("wnd_image_%d", pid)]:setImage(avatarUrl)
			self[sf("wnd_image_%d", pid)]:setColor(0xFFFFFFFF)
			local name = prop.nickname
			if modUIUtil.utf8len(name) > 6 then
				name = modUIUtil.getMaxLenString(name, 6)
			end
			self[sf("wnd_name_%d", pid)]:setText(name)
		end

		-- 录像按钮
		self.btn_video:addListener("ec_mouse_click", function()
			local modVideoInfo = import("ui/menu/video_info.lua")
			modVideoInfo.pVideoInfo:instance():open(videoGroup, ret.multi_user_props)

		end)

		-- 设置房间号和时间,麻将类型
		self:setRoomId()

		-- 设置分数
		self:setScore()

		-- 收藏战绩
		self.btn_save:addListener("ec_mouse_click", function()
			modBattleRpc.moveVideo(self.groupId, self.moveTo, nil, function(success, reason)
				if success then
					if self.isDel then
						infoMessage(TEXT("取消收藏!"))
					else
						infoMessage(TEXT("收藏成功!"))
					end
					self.host:clearVideoData()
					self.host:refash()
				else
					infoMessage(TEXT(reason))
				end
			end)
		end)
	end)
end
