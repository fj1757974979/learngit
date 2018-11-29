local modClubRpc = import("logic/club/rpc.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modWndList = import("ui/common/list.lua")
local modUIUtil = import("ui/common/util.lua")
local modClubMgr = import("logic/club/main.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modPresonalVideo = import("ui/club/presonal_video_info.lua")
local modPresonalVideoPoker = import("ui/club/presonal_video_info_poker.lua")

pPersonalReport = pPersonalReport or class(pWindow)

pPersonalReport.init = function(self, clubInfo, memberInfo, host, parentWnd)
	self:setParent(gWorld:getUIRoot())
	self.clubInfo = clubInfo
	self:setSize(parentWnd:getWidth(), parentWnd:getHeight())
	self:setColor(0)
	self.host = host
	self.controls = {}
	self:initUI()
	self:regEvent()
end


pPersonalReport.clearControls = function(self)
	if not self.controls then return end
	for _, wnd in pairs(self.controls) do
		wnd:setParent(nil)
	end
	self.controls = {}
end

pPersonalReport.initUI = function(self)
	self:getVideoGroups()
end

pPersonalReport.getVideoGroups = function(self)
	modClubMgr.getCurClub():getClubRecords(self.clubInfo:getClubId(), function(groups) 
		local uids = {}
		if table.getn(groups) <= 0 then
			self:setText("目前没有战报\n参与过的牌局战报会在此显示")
			self:getTextControl():setFontSize(40)
			self:getTextControl():setColor(0xFF930000)
		else
			self:setText("")
		end
		for _, group in ipairs(groups) do
			for _, uid in ipairs(group.user_ids) do
				if not self:findIdIsInList(uid, uids) then
					table.insert(uids, uid)
				end
			end
		end
		modBattleRpc.getMultiUserProps(uids, { "name", "avatarurl", "gender" }, function(success, reason, reply) 
			if success then
				local playerInfos = reply.multi_user_props
				self:showVideoGroups(groups, playerInfos)	
			end
		end)
	end)
end

pPersonalReport.findIdIsInList = function(self, id, list)
	if not id or not list then return end
	for _, i in pairs(list) do
		if i == id then
			return i
		end
	end
	return false
end

pPersonalReport.showVideoGroups = function(self, groups, playerInfos)
	if not groups then return end
	-- 先清理
	self:clearControls()
	self:clearDragWnd()
	self:clearWindowList()
	-- 滑动窗口
	self.dragWnd = self:newListWnd()
	self.windowList = modWndList.pWndList:new(self:getWidth(), self:getHeight() * 0.98, 1, 0, 0, T_DRAG_LIST_VERTICAL)

	local distaceX = (self:getWidth() - self:getInt(self:getWidth() / 760) * 760) / (self:getInt(self:getWidth() / 760) + 1)
	local maxCount = self:getInt(self:getWidth() / 760) 
	local x, y = 0, 10
	maxCount = self:getInt(maxCount)
	for index, group in ipairs(groups) do
		local wnd = self:newPanel(group, playerInfos) 
		wnd:setParent(self.dragWnd)
		wnd:setPosition(x, y)
		x = x + wnd:getWidth() + distaceX
		if index % maxCount == 0 then
			x = distaceX
			y = y + wnd:getHeight() + 10
		end
		table.insert(self.controls, wnd)
	end

	self.dragWnd:setSize(self:getWidth(),  y + 100)
	self.windowList:addWnd(self.dragWnd)
	self.windowList:setParent(self)
end

pPersonalReport.getInt = function(self,x)
    if x <= 0 then
        return math.ceil(x)
    end

    if math.ceil(x) == x then
        x = math.ceil(x)
    else
        x = math.ceil(x) - 1;
    end
    return x
end

pPersonalReport.childClick = function(self)
end

pPersonalReport.newPanel = function(self, group, playerInfos)
	local wnd = nil
	if self:isMahjongVideo(group) then
		wnd = modPresonalVideo.pPresonalVideoInfo:new(group, playerInfos, self) 
	elseif self:isPokerVideo(group) then
		wnd = modPresonalVideoPoker.pPresonalVideoPoker:new(group)
	end
	if not wnd then return end
	wnd:setParent(self.dragWnd)
	wnd:setAlignX(ALIGN_LEFT)
	wnd:setAlignY(ALIGN_TOP)
	table.insert(self.controls, wnd)
	return wnd
end

pPersonalReport.regEvent = function(self)
end


pPersonalReport.isPokerVideo = function(self, info)
	if not info then return end
	return info.game_type == modLobbyProto.POKER
end

pPersonalReport.isMahjongVideo = function(self, info)
	if not info then return end
	return info.game_type == modLobbyProto.MAHJONG
end


pPersonalReport.newListWnd = function(self)
	local pWnd = pWindow:new()
	pWnd:setSize(0, 0)
	pWnd:setParent(self)
	pWnd:setPosition(0,0)
	pWnd:setColor(0)
	return pWnd 
end

pPersonalReport.clearDragWnd = function(self)
	if self.dragWnd then
		self.dragWnd:setParent(nil)
		self.dragWnd = nil
	end
end

pPersonalReport.clearWindowList = function(self)
	if self.windowList then
		self.windowList:destroy()
	end
	self.windowList = nil
end

pPersonalReport.close = function(self)
	self:clearControls()
	self:clearDragWnd()
	self:clearWindowList()
end
