local modUIUtil = import("ui/common/util.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modUtil = import("util/util.lua")
local modUserData = import("logic/userdata.lua")
local modRoomProto = import("data/proto/rpc_pb2/room_pb.lua")

pJiluWnd = pJiluWnd or class (pWindow)

pJiluWnd.init = function(self, srh, detail, x, y, pWnd, host)
	self:load("data/ui/videoroom.lua")
	self.userProps = {}
	self.uidToScores = {}
	self:setParent(pWnd)
	self:setPosition(x, y)
	self:setAlignX(ALIGN_LEFT)
	self:setAlignY(ALIGN_TOP)
	self:setZ(-1)
	self.btn_end_calculate:show(false)
	self:initUI(srh, detail, host)
end

pJiluWnd.initUI = function(self, srh, detail, host)
	if not srh then return end
	-- 图片
	self.wnd_save:setImage("ui:daikai_del_text.png")
	self.wnd_save:setSize(69, 34)
	self.btn_text:setImage("ui:daikai_share_text.png")
	self.btn_text:setSize(69, 34)

	-- 属性
	self.id = srh.id
	self.host = host
	self.roomId = srh.room_id
	self.time = srh.room_created_date
	self.ruleType = detail.rule_type
	self.uids = detail.user_ids  --> pid to uid
	self.scores = detail.player_scores -- > pid to score

	-- 取玩家属性
	local list = {
		"name", "avatarurl", "gender"
	}
	modBattleRpc.getMultiUserProps(self.uids, list, function(success, reason, reply)
		if success then
			self:setWndText(reply)
		else
			infoMessage(TEXT(reason))
		end
	end)
end

pJiluWnd.setWndText = function(self, reply)
	if not reply then return end
	local timeStr = os.date("  %m-%d  %H:%M", self.time)
	local ruleStr = "  " .. modUIUtil.getRuleStringByType(self.ruleType)
	self.wnd_room_id:setText("房号：" .. self.roomId .. timeStr .. ruleStr)

	-- 设置各个玩家信息
	local index = 0
	for pid, uid in ipairs(self.uids) do
		-- index++
		index = index + 1
		-- 信息
		local score = self.scores[pid]
		local prop = self:findInfoByUid(uid, reply)
		local imgWnd = self[sf("wnd_image_%d", index)]
		local nameWnd = self[sf("wnd_name_%d", index)]
		local scoreWnd = self[sf("wnd_score_%d", index)]
		-- 保存玩家属性
		self.userProps[uid] = prop
		self.uidToScores[uid] = score
		-- 设置头像
		if imgWnd and (prop.avatar_url or prop.avatar_url == "") then
			local img = prop.avatar_url
			if img == "" and prop.gender then
				img = modUIUtil.getDefaultImage(prop.gender)
			end
			imgWnd:setImage(img)
			imgWnd:setColor(0xFFFFFFFF)
		end
		-- 设置名字
		if nameWnd  and prop.nickname then
			nameWnd:setText(prop.nickname)
		end
		-- 设置分数
		if scoreWnd and score then
			scoreWnd:setText(score)
		end
	end

	-- 没有信息的隐藏
	for i = index + 1, 4 do
		local imgWnd = self[sf("wnd_image_%d_bg", i)]
		local nameWnd = self[sf("wnd_name_%d", i)]
		local scoreWnd = self[sf("wnd_score_%d", i)]
		if imgWnd then
			imgWnd:show(false)
		end
		if nameWnd then
			nameWnd:show(false)
		end
		if scoreWnd then
			scoreWnd:show(false)
		end
	end

	-- 添加点击事件
	self.btn_video:addListener("ec_mouse_click", function()
		self:share()
	end)
	self.btn_save:addListener("ec_mouse_click", function()
		self:delSharedRoom()
	end)
end

pJiluWnd.findInfoByUid = function(self, uid, reply)
	if not uid or not reply then return end
	for _, prop in ipairs(reply.multi_user_props) do
		if uid == prop.user_id then
			return prop
		end
	end
end

pJiluWnd.delSharedRoom = function(self)
	if not self.id then return end
	modBattleRpc.delSharedRoomHistories(self.id, nil, function(success, reason)
		if success then
			infoMessage(TEXT("删除成功"))
			if self.host then
				self.host:delRoom()
			end
		else
			infoMessage(TEXT(reason))
		end
	end)
end

pJiluWnd.share = function(self)
	-- 没取到属性
	if table.size(self.userProps) < 1 or table.size(self.uidToScores) < 1 then
		return
	end
	-- 分享
	local channelId = modUtil.getOpChannel()
	local titleStr = modUIUtil.getDownloadTitle() .. "记录"
	titleStr = titleStr .. sf("【%06d】", self.roomId)
	local timeStr = sf(os.date(" %m-%d %H:%M", self.time))
	titleStr = titleStr .. timeStr
	local text = ""
	local nameScoces = ""
	-- 玩家信息
	local max = 2
	local idx = 0
	for uid, prop in pairs(self.userProps) do
		idx = idx + 1
		local score = self.uidToScores[uid]
		local name = prop.nickname
		if modUIUtil.utf8len(name) > 5 then
			name = modUIUtil.getMaxLenString(name, 5)
		end
		nameScoces = nameScoces .. name .. "  " .. score .."\t"
		if idx % max == 0 or idx == table.size(self.userProps) then
			nameScoces = nameScoces .. "\n"
		end
	end
	-- 大赢家
	local winnerIds = self:findBigWinner()
	local winStr = "大赢家："
	local index = 0
	for _, uid in pairs(winnerIds) do
		index = index + 1
		local prop = self.userProps[uid]
		winStr = winStr .. prop.nickname
		if index < table.getn(winnerIds) then
			winStr = winStr .. "、"
		end
	end
	text = text .. nameScoces .. winStr

	-- 链接
	local downLoadLink = modUIUtil.getDownloadLink()
	log("info", titleStr, text, downLoadLink)
	-- 分享到好友
	puppy.sys.shareWeChat(2, TEXT(titleStr), TEXT(text), downLoadLink)

end

pJiluWnd.findBigWinner = function(self)
	if not self.uidToScores then return end
	local uids = {}
	-- 排序找出最高分
	table.sort(self.uidToScores, function(s1, s2)
		return s1 > s2
	end)
	local winScore = nil
	for _, score in pairs(self.uidToScores) do
		if not winScore then
			winScore = score
			break
		end
	end
	-- 找出最高分的uids
	for uid, score in pairs(self.uidToScores) do
		if score >= winScore then
			table.insert(uids, uid)
		end
	end
	return uids


end

