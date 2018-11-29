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
local modVideoGropWnd = import("ui/menu/videogroup.lua")
local modCardGameVideoGroupWnd = import("ui/card_battle/videos/group.lua")

local time = 30
local T_VIDEO_GENERAL = modLobbyProto.GRGC_GENERAL
local T_VIDEO_FAVORITE = modLobbyProto.GRGC_FAVORITE

pVideo = pVideo or class(pWindow, pSingleton)

pVideo.init = function(self)
	self:load("data/ui/video.lua")
	self:setParent(gWorld:getUIRoot())
	self.playerInfos = {}
	self:regEvent()
	self.controls = {}
	self.videoData = nil
	self.saveVideo = nil
	self:initUI()
	modUIUtil.adjustSize(self, gGameWidth, gGameHeight)
	modUIUtil.makeModelWindow(self, false, false)
	self.wnd_list:setText("还没有战绩哟，快和小伙伴们一起玩游戏吧!")
end

pVideo.cbtnClick = function(self, cbtn, wnd, cbtnAn, wndAn)
	if  cbtn:isChecked() then
		cbtn:setColor(0xFFFFFFFF)
		cbtnAn:setColor(0)
		self.currData = cbtn.cbtnData
		self.moveTo = cbtnAn.cbtnData
	else
		cbtn:setColor(0)
		cbtnAn:setColor(0xFFFFFFFF)
	end
	wndAn:setImage(cbtnAn.clickTextImage[cbtnAn:isChecked()])
	wnd:setImage(cbtn.clickTextImage[cbtn:isChecked()])
	self:refash()
end

pVideo.initUI = function(self)
	self.currData = T_VIDEO_GENERAL
	self.cbtn_lishi:setCheck(true)
	self.moveTo = T_VIDEO_FAVORITE
	self.wnd_title:show(false)
	--self.wnd_list:setSize(gGameWidth * 0.97, gGameHeight * 0.82)
	--self.wnd_list:setOffsetY(gGameHeight * 0.04)
	self.btn_other:setPosition(gGameWidth * 0.02, gGameHeight * 0.023)
	self.cbtn_lishi.clickTextImage ={
		[true] = "ui:standings_lishi_selected.png",
		[false] = "ui:standings_lishi_dis.png",
	}
	self.cbtn_lishi.cbtnData = T_VIDEO_GENERAL
	self.cbtn_shoucang.clickTextImage = {
		[true] = "ui:standings_sc_selected.png",
		[false] = "ui:standings_sc_dis.png",
	}
	self.cbtn_shoucang.cbtnData = T_VIDEO_FAVORITE
	self.cbtn_lishi:addListener("ec_mouse_click", function()
		self:cbtnClick(self.cbtn_lishi, self.wnd_lishi, self.cbtn_shoucang, self.wnd_shoucang)
	end)

	self.cbtn_shoucang:addListener("ec_mouse_click", function()
		self:cbtnClick(self.cbtn_shoucang, self.wnd_shoucang, self.cbtn_lishi, self.wnd_lishi)
	end)
	modUIUtil.setClosePos(self.btn_close)
end


pVideo.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function() self:close() end)
	self.btn_other:addListener("ec_mouse_click", function()
		local modMainJoin = import("ui/menu/join.lua")
		modMainJoin.pMainJoin:instance():open(true)
	end)
end


pVideo.open = function(self)
	self:refash()
end

pVideo.refash = function(self)
	for _, wnd in ipairs(self.controls) do
		wnd:setParent(nil)
	end
	self.controls = {}
	if self.windowList then
		self.windowList:destroy()
	end

	-- 创建滑动窗口
	local dragHeight = 0
	self.wnd_drag = self:newListWnd()
	self.wnd_drag:setSize(self.wnd_list:getWidth(), dragHeight)
	self.windowList = modWndList.pWndList:new(self.wnd_list:getWidth(), self.wnd_list:getHeight(), 1, 0, 0, T_DRAG_LIST_VERTICAL)
	-- 请求录像组数据
	local videoData = nil
	if self.currData == T_VIDEO_GENERAL then
		videoData = self.videoData
	else
		videoData = self.saveVideo
	end

	if videoData == nil then
		modBattleRpc.getAllGameVideos(self.currData, 10, 1, nil, function(success, reason, reply)
			local videoGroups = reply.game_record_groups
			if self.currData == T_VIDEO_GENERAL then
				self.videoData = videoGroups
			else
				self.saveVideo = videoGroups
			end
			self:work(videoGroups, dragHeight)
		end)
	else
		self:work(videoData, dragHeight)
	end
end

pVideo.work = function(self, v, dragHeight)
	local videoGroups = v
	local selfUid = modUserData.getUID()
	local maxX = 2
	if table.getn(videoGroups) > 0 then
		self.wnd_list:setText("")
		local bgWidth, bgHeight = 591, 323
		local distanceX = (self.wnd_list:getWidth() - bgWidth * 2) / 3
		local distanceY = gGameHeight * 0.04
		local x, y = distanceX, 0
		dragHeight = math.ceil(table.getn(videoGroups) / 2) * (bgHeight + distanceY) - distanceY
		for idx, videoGroup in ipairs(videoGroups) do
			local wnd = nil
			if videoGroup.game_type == modLobbyProto.MAHJONG then
				wnd = modVideoGropWnd.pVideoGroup:new(videoGroup, self.moveTo, self, x, y, bgWidth, bgHeight, self.currData == T_VIDEO_FAVORITE)
			else
				wnd = modCardGameVideoGroupWnd.pGroupWnd:new(videoGroup, self.currData, self)
				wnd:setParent(self.wnd_drag)
				wnd:setPosition(x, y)
				wnd:setSize(bgWidth, bgHeight)
				log("info", "got poker video!")
			end
			if wnd then
				x = x + wnd:getWidth() + distanceX
				if idx % maxX == 0 then
					x = distanceX
					y = y + wnd:getHeight() + distanceY
				end
				table.insert(self.controls, wnd)
			end
		end
	else
		self.wnd_list:setText("还没有战绩哟，快和小伙伴们一起玩游戏吧!")
		log("error", "get video groups is nil")
	end
	-- 设置滑动窗口最终大小
	self.wnd_drag:setSize(self.wnd_drag:getWidth(), dragHeight)
	self.windowList:addWnd(self.wnd_drag)
	self.windowList:setParent(self.wnd_list)
end

pVideo.newListWnd = function(self)
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

pVideo.clearVideoData = function(self)
	self.videoData = nil
	self.saveVideo = nil
end

pVideo.close = function(self)
	for _, wnd in pairs(self.controls) do
		wnd:setParent(nil)
	end
	self.currData = nil
	self.moveTo = nil
	self.saveVideo = nil
	self.playerInfos = {}
	pVideo:cleanInstance()
end



