local modUIUtil = import("ui/common/util.lua")
local modRoomProto = import("data/proto/rpc_pb2/room_pb.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modUserData = import("logic/userdata.lua")

pPresonalVideoInfo = pPresonalVideoInfo or class(pWindow)

pPresonalVideoInfo.init = function(self, info, playerInfos)
	self:load("data/ui/club_desk_list_record_personal_report_card.lua")
	self:setParent(gWorld:getUIRoot())
	self.info = info
	self.playerInfos = playerInfos
	self.roomInfo = modLobbyProto.CreateRoomRequest()
	self.roomInfo:ParseFromString(self.info.room_creation_info)
	self.endCalculateInfo = modRoomProto.ShowClosureReportRequest()
	self.endCalculateInfo:ParseFromString(self.info.room_closure_info)
	self:initUI()
	self:regEvent()
end


pPresonalVideoInfo.initUI = function(self)
	self.btn_save:show(false)
	self.btn_video:setText("录像回放")
	self.btn_save:setText("保存录像")
	self:setRoomId()
	self:initWnds()
	self:setNameScore()
end

pPresonalVideoInfo.setRoomId = function(self)
	local str = "房号：" .. sf("%06d", self.info.room_id)
	local timeStr = os.date("  %m-%d  %H:%M", self.info.room_created_date)
	local ruleStr = modUIUtil.getRuleStringByType(self.roomInfo.rule_type)
	str = str .. timeStr .. "          "  .. ruleStr
	self.wnd_room_id:setText(str)
end

pPresonalVideoInfo.initWnds = function(self)
	for i = 1, 4 do
		local nameWnd = self[sf("wnd_name_%d", i)]
		local imageBGWnd= self[sf("wnd_image_%d_bg", i)]
		local scoreWnd = self[sf("wnd_score_%d", i)]
		nameWnd:show(false)
		imageBGWnd:show(false)
		scoreWnd:show(false)
	end
end

pPresonalVideoInfo.findBaseScore = function(self, pid, scores)
	if not pid or not scores then return end
	for p, score in ipairs(scores) do
		if p - 1 == pid then return score end 
	end
	return
end

pPresonalVideoInfo.findScore = function(self, pid, scores)
	if not pid then return end
	for p, score in pairs(scores) do
		if pid == p then 
			return score
		end
	end
	return 
end

pPresonalVideoInfo.getScoreFromState = function(self, playerId, state)
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

pPresonalVideoInfo.setNameScore = function(self)
	local pidToUids = self.info.user_ids
	local pidToScores = {} 
	for pid, playerStatistics in ipairs(self.endCalculateInfo.player_total_statistics) do
--		local scoreBase = self:findBaseScore(pid - 1, self.info.player_score_bases) 
		pidToScores[pid - 1] = self:getScoreFromState(pid - 1, playerStatistics) --+ scoreBase
	end
	local index = 1
	for pid, uid in ipairs(pidToUids) do
		local nameWnd = self[sf("wnd_name_%d", index)]
		local imageWnd = self[sf("wnd_image_%d", index)]
		local imageBGWnd = self[sf("wnd_image_%d_bg", index)]
		local scoreWnd = self[sf("wnd_score_%d", index)]
		local prop = self:findProp(uid)
		local name = prop.nickname
		if modUIUtil.utf8len(name) > 6 then
			name = modUIUtil.getMaxLenString(name, 6)
		end
		local img = prop.avatar_url

		if not img or img == "" then
			img = "ui:image_default_female.png"
			if prop.gender == T_GENDER_MALE then
				img = "ui:image_default_male.png"
			end
		end
		if uid == modUserData.getUID() then
			nameWnd:getTextControl():setColor(0xFF800000)
			scoreWnd:getTextControl():setColor(0xFF800000)
		end
		nameWnd:setText(name)
		imageWnd:setImage(img)
		imageWnd:setColor(0xFFFFFFFF)
		scoreWnd:setText(self:findScore(pid - 1, pidToScores))
		nameWnd:show(true)
		imageBGWnd:show(true)
		scoreWnd:show(true)
		index = index + 1
	end
end

pPresonalVideoInfo.findProp = function(self, uid)
	if not uid or not self.playerInfos then return end
	for _, prop in ipairs(self.playerInfos) do
		if prop.user_id == uid then
			return prop
		end
	end
	return
end

pPresonalVideoInfo.regEvent = function(self)
	self.btn_video:addListener("ec_mouse_click", function() 
		local modVideoInfo = import("ui/menu/video_info.lua")	
		modVideoInfo.pVideoInfo:instance():open(self.info, self.playerInfos)
	end)
end


