local modClubMgr = import("logic/club/main.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modUIUtil = import("ui/common/util.lua")

pReportInfo = pReportInfo or class(pWindow)

pReportInfo.init = function(self, info, playerInfos, host)
	self:load("data/ui/club_desk_list_record_club_report_card.lua")
	self:setParent(gWorld:getUIRoot())
	self.info = info
	self.host = host
	self:getJiluDetailData()
	self.delText = {
		[true] = "ui:club/txt_cancel.png",
		[false] = "ui:club/txt_delete.png"
	}
	self.isDel = false
	self.playerInfos = playerInfos
	self:initUI()
	self:regEvent()
end

pReportInfo.getJiluDetailData = function(self)
	local jilu = self.info
	if not jilu then return end
	local t = jilu.game_type
	local data = nil
	local protoGame = nil
	if t == modLobbyProto.MAHJONG then
		protoGame = modLobbyProto.GetSharedRoomHistoriesReply.MahjongSharedRoomDetail() 
	elseif t == modLobbyProto.POKER then
		protoGame = modLobbyProto.GetSharedRoomHistoriesReply.PokerSharedRoomDetail()
	end
	if not protoGame then return end
	protoGame:ParseFromString(jilu.detail_data)
	self.detailData = protoGame
end

pReportInfo.initUI = function(self)
	self.wnd_mahjong:setText(modUIUtil.getRuleStringByType(self.detailData.rule_type))
	self.wnd_time:setText(os.date("%m-%d %H:%M", self.info.room_created_date))
	self.btn_share:setText("分享")
	self.btn_share:show(false)
	self:initWnds()
	self:setNameScore()
	self.wnd_del_txt:setImage(self.delText[self.isDel])
end

pReportInfo.updateDelState = function(self) 
	self.isDel = not self.isDel
	self.wnd_del_txt:setImage(self.delText[self.isDel])
	if self.host then
		self.host:childClick(self.info.id, self.isDel)
	end
end

pReportInfo.initWnds = function(self)
	for i = 1, 4 do
		local nameWnd = self[sf("wnd_name_%d", i)]
		local imageBGWnd= self[sf("wnd_image_%d_bg", i)]
		local scoreWnd = self[sf("wnd_score_%d", i)]
		nameWnd:show(false)
		imageBGWnd:show(false)
		scoreWnd:show(false)
	end
end

pReportInfo.setNameScore = function(self)
	local pidToUids = self.detailData.user_ids
	local pidToScores = self.detailData.player_scores
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
		nameWnd:setText(name)
		imageWnd:setImage(img)
		imageWnd:setColor(0xFFFFFFFF)
		scoreWnd:setText(self:findScore(pid))
		nameWnd:show(true)
		imageBGWnd:show(true)
		scoreWnd:show(true)
		index = index + 1
	end
end

pReportInfo.findScore = function(self, pid)
	if not pid then return end
	for p, score in ipairs(self.detailData.player_scores) do
		if p == pid then
			return score
		end
	end
	return 
end

pReportInfo.findProp = function(self, uid)
	if not uid or not self.playerInfos then return end
	for _, prop in ipairs(self.playerInfos) do
		if prop.user_id == uid then
			return prop
		end
	end
	return
end

pReportInfo.regEvent = function(self)
	self.btn_sign:addListener("ec_mouse_click", function() 
		self:updateDelState()	
	end)
end

