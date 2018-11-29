local modVideoParser = import("logic/card_battle/videos/parser.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modUserData = import("logic/userdata.lua")

pGroupWnd = pGroupWnd or class(pWindow)

pGroupWnd.init = function(self, groupInfo, t, host)
	self:load("data/ui/card/video_group.lua")
	self.parser = modVideoParser.newGroupParser(groupInfo)
	self.parser:initPlayers(function()
		self:updatePlayerInfo()
		self:updatePlayerScore()
	end)
	self.t = t
	self.host = host
	self.userIdToScoreWnd = {}
	self:initUI()
	self:regEvent()
end

pGroupWnd.initUI = function(self)
	if self.t == modLobbyProto.GRGC_GENERAL then
		self.wnd_save:setImage("ui:standings_baocun_text.png")
	else
		self.wnd_save:setImage("ui:standings_del.png")
	end
	self.wnd_room_id:setText(sf("房号：%06d %s %s", self.parser:getRoomId(), self.parser:getRoomCreateDateStr(), self.parser:getName()))
	for i = 1, 5 do
		self[sf("wnd_image_%d_bg", i)]:show(false)
	end
	self.btn_save:show(false)
	self.btn_video:show(false)
end

pGroupWnd.regEvent = function(self)
	self.btn_video:addListener("ec_mouse_click", function()
		local modVideoInfo = import("ui/menu/video_info.lua")
		modVideoInfo.pVideoInfo:instance():open(self.parser:getGroupInfo(), self.playerInfos, nil, self.parser:getGroupParam())
	end)

	self.btn_save:addListener("ec_mouse_click", function()
		local moveTo = modLobbyProto.GRGC_FAVORITE
		if self.t == moveTo then
			moveTo = modLobbyProto.GRGC_GENERAL
		end
		modBattleRpc.moveVideo(self.parser:getGroupId(), moveTo, nil, function(success, reason)
			if success then
				if self.t == modLobbyProto.GRGC_FAVORITE then
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
end

pGroupWnd.updatePlayerInfo = function(self)
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
	self.btn_save:show(true)
	self.btn_video:show(true)
end

pGroupWnd.updatePlayerScore = function(self)
	local infos = self.parser:getEndCalcData()
	for userId, score in pairs(infos) do
		local wnd = self.userIdToScoreWnd[userId]
		wnd:setText(tostring(score))
		if userId == modUserData.getUID() then
			wnd:getTextControl():setColor(0xFF800000)
		end
	end
end
