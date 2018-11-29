local modUIUtil = import("ui/common/util.lua")
local modUtil = import("util/util.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modUserData = import("logic/userdata.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modWndList = import("ui/common/list.lua")
local modVideoPlayer = import("ui/menu/videoplayer.lua")
local modEvent = import("common/event.lua")
local modProtoFucntion = import("net/rpc/proto_to_function.lua")
local modRoomProto = import("data/proto/rpc_pb2/room_pb.lua")
local modUIAllFunction = import("ui/common/uiallfunction.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modVideoPlayRoom = import("ui/menu/playroom.lua")
local modCardGameRecordWnd = import("ui/card_battle/videos/record.lua")

pVideoInfo = pVideoInfo or class(pWindow, pSingleton)

pVideoInfo.init = function(self)
	self:load("data/ui/video.lua")
	self:setParent(gWorld:getUIRoot())
	self.controls = {}
	self:regEvent()
	self:initUI()
	modUIUtil.adjustSize(self, gGameWidth, gGameHeight)
	modUIUtil.makeModelWindow(self, false, false)
end

pVideoInfo.initUI = function(self)
	--self.wnd_list:setSize(gGameWidth * 0.97, gGameHeight * 0.82)
	--self.wnd_list:setOffsetY(gGameHeight * 0.04)
	self.wnd_title:setPosition(0, -3)
	self.wnd_title:setImage("ui:video_title.png")
	self.wnd_select_bg:show(false)
	self.wnd_title:show(true)
	self.btn_other:show(false)
	modUIUtil.setClosePos(self.btn_close)
end

pVideoInfo.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function() self:close() end)
	self.__update_video_user_prop_hdr = modEvent.handleEvent(EV_UPDATE_VIDEO_USER_PROP, function(uid, nickName, avatarUrl)
		local index = 1
		for pid, userId in pairs(self.playerUids) do
			if userId == uid then
				break
			else
				index = index + 1
			end
		end

		local nameWnd = self[sf("wnd_video_info_name_%d%d", index, uid)]
		local imageWnd = self[sf("wnd_video_info_image_%d%d", index, uid)]

		if nameWnd then
			local name = nickName
			if modUIUtil.utf8len(name) > 6 then
				name = modUIUtil.getMaxLenString(name, 6)
			end
			nameWnd:setText(name)
		end
		if imageWnd then
			imageWnd:setImage(avatarUrl)
		end
	end)


end

pVideoInfo.open = function(self, videoGroup, playerInfos, code, param)
--	self:setParent(parentWnd)
	-- 创建滑动窗口
	local dragHeight = 0
	self.wnd_drag = self:newListWnd()
	self.wnd_drag:setSize(self.wnd_list:getWidth(), dragHeight)
	self.windowList = modWndList.pWndList:new(self.wnd_list:getWidth(), self.wnd_list:getHeight(), 1, 0, 0, T_DRAG_LIST_VERTICAL)
	-- 请求录像组数据
	local selfUid = modUserData.getUID()
	local maxX = 2
	local bgWidth, bgHeight = 591, 226
	if videoGroup.game_type == modLobbyProto.POKER then
		maxX = 1
		bgWidth = self.wnd_list:getWidth()
		bgHeight = 260
	end
	local distanceX = (self.wnd_list:getWidth() - bgWidth * maxX) / 3
	local distanceY = gGameHeight * 0.04
	local x, y = distanceX, 0
	local videoGroup = videoGroup
	-- 录像组数据
	--local roomId = videoGroup.room_id
	--local roomInfo = modLobbyProto.CreateRoomRequest()
	--roomInfo:ParseFromString(videoGroup.room_creation_info)
	local roomCreateTime = videoGroup.room_created_date
	local groupId = videoGroup.id
	local userIds = videoGroup.user_ids  -- pid to uid
	self.playerUids = {}
	--local endCalculateInfo = modRoomProto.ShowClosureReportRequest()
	--endCalculateInfo:ParseFromString(videoGroup.room_closure_info)
	local recordIds = videoGroup.record_ids
	local videoIds = {}
	for _, id in ipairs(recordIds) do
		table.insert(videoIds, id)
	end

	local uidToPid = {}

	for pid, uid in ipairs(userIds) do
		self.playerUids[pid - 1] = uid
	end
	for pid, uid in pairs(self.playerUids) do
		uidToPid[uid] = pid
	end

	-- 指定回访码
	if code then
		videoIds = { code }
	end
	modBattleRpc.getGameVideoInfosByKeys(videoIds, function(success, reason, reply)
		if success then
			local videoInfos = reply.game_record_infos
			for idx, info in ipairs(videoInfos) do
				local videoId = info.id
				local time = info.started_date
--				local playerScores = info.player_scores
				local wnd = nil
				if videoGroup.game_type == modLobbyProto.POKER then
					wnd = modCardGameRecordWnd.pRecordWnd:new(idx, info, playerInfos, param)
					wnd:setParent(self.wnd_drag)
					wnd:setPosition(x, y)
					wnd:setSize(bgWidth, bgHeight)
				else
					wnd = modVideoPlayRoom.pPlayRoom:new(videoGroup, info, userIds, playerInfos, self.playerUids, uidToPid, x, y, bgWidth, bgHeight, idx, code)
					wnd:setParent(self.wnd_drag)
				end
				if wnd then
					table.insert(self.controls, wnd)

					x = x + bgWidth + distanceX
					if idx % maxX == 0 then
						y = y + distanceY + bgHeight
						x = distanceX
					end
				end
			end
			dragHeight = math.ceil(table.getn(videoInfos) / maxX) * (bgHeight + distanceY) - distanceY
		end

		-- 设置滑动窗口最终大小
		self.wnd_drag:setSize(self.wnd_drag:getWidth(), dragHeight)
		self.windowList:addWnd(self.wnd_drag)
		self.windowList:setParent(self.wnd_list)
	end)
end

pVideoInfo.close = function(self)
	for _, wnd in pairs(self.controls) do
		wnd:setParent(nil)
	end
	if modVideoPlayer.pVideoPlayer:getInstance() then
		modVideoPlayer.pVideoPlayer:instance():close()
	end
	self.playerUids = {}
	pVideoInfo:cleanInstance()
end


pVideoInfo.newListWnd = function(self)
	local pWnd = pWindow:new()
	pWnd:setName("wnd_drag")
	pWnd:setSize(1000,1000)
	pWnd:setParent(self.wnd_list)
	pWnd:setPosition(0,0)
	pWnd:setColor(0)
	self[pWnd:getName()] = pWnd
	table.insert(self.controls, pWnd)
	return self[pWnd:getName()]
end




