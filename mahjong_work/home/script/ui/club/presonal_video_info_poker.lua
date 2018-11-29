local modVideoParser = import("logic/card_battle/videos/parser.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modUserData = import("logic/userdata.lua")

pPresonalVideoPoker = pPresonalVideoPoker or class(pWindow)

pPresonalVideoPoker.init = function(self, groupInfo)
	self:load("data/ui/card/video_group_club.lua")
	self.parser = modVideoParser.newGroupParser(groupInfo)
	self.parser:initPlayers(function()
		self:updatePlayerInfo()
		self:updatePlayerScore()
	end)
	self.userIdToScoreWnd = {}
	self:initUI()
	self:regEvent()
end

pPresonalVideoPoker.initUI = function(self)
	self.wnd_room_id:setText(sf("房号：%06d %s            %s", self.parser:getRoomId(), self.parser:getRoomCreateDateStr(), self.parser:getName()))
	for i = 1, 5 do
		self[sf("wnd_image_%d_bg", i)]:show(false)
	end
	self.btn_save:show(false)
	self.btn_video:setText("查看详情")
end

pPresonalVideoPoker.regEvent = function(self)
	self.btn_video:addListener("ec_mouse_click", function()
		local modVideoInfo = import("ui/menu/video_info.lua")
		modVideoInfo.pVideoInfo:instance():open(self.parser:getGroupInfo(), self.playerInfos, nil, self.parser:getGroupParam())
	end)
end

pPresonalVideoPoker.updatePlayerInfo = function(self)
	local playerInfos = self.parser:getPlayerInfos()
	local idx = 1
	for _, info in ipairs(playerInfos) do
		self[sf("wnd_image_%d_bg", idx)]:show(true)
		local wndPhoto = self[sf("wnd_image_%d", idx)]
		wndPhoto:setImage(info.avatarUrl)
		local wndName = self[sf("wnd_name_%d", idx)]
		wndName:setText(info.name)
		if info.userId == modUserData.getUID() then
			wndName:getTextControl():setColor(0xFF800000)
		end
		self.userIdToScoreWnd[info.userId] = self[sf("wnd_score_%d", idx)]
		idx = idx + 1
	end
	for i = idx, 5 do
		self[sf("wnd_image_%d_bg", i)]:show(false)
	end
	self.playerInfos = playerInfos
end

pPresonalVideoPoker.updatePlayerScore = function(self)
	local infos = self.parser:getEndCalcData()
	for userId, score in pairs(infos) do
		local wnd = self.userIdToScoreWnd[userId]
		if wnd then
			wnd:setText(tostring(score))
			if userId == modUserData.getUID() then
				wnd:getTextControl():setColor(0xFF800000)
			end
		end
	end
end
