local modClubRpc = import("logic/club/rpc.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modWndList = import("ui/common/list.lua")
local modUIUtil = import("ui/common/util.lua")
local modClubMgr = import("logic/club/main.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modClubReportInfo = import("ui/club/club_report_info.lua")

pClubReport = pClubReport or class(pWindow)

pClubReport.init = function(self, clubInfo, memberInfo, host, parentWnd)
	self:setParent(gWorld:getUIRoot())
	self.clubInfo = clubInfo
	self:setSize(parentWnd:getWidth(), parentWnd:getHeight())
	self:setColor(0)
	self.host = host
	self.controls = {}
	self.delJiluIds = {}
	self:initUI()
	self:regEvent()
end


pClubReport.clearControls = function(self)
	if not self.controls then return end
	for _, wnd in pairs(self.controls) do
		wnd:setParent(nil)
	end
	self.controls = {}
end

pClubReport.initUI = function(self)
	self:getJilus()
	self:getTextControl():setFontSize(40)
	self:getTextControl():setColor(0xFFFFFFFF)
end

pClubReport.getJiluDetailData = function(self, jilu)
	if not jilu then return end
	local t = jilu.game_type
	local protoGame = nil

	if t == modLobbyProto.MAHJONG then
		protoGame = modLobbyProto.GetSharedRoomHistoriesReply.MahjongSharedRoomDetail() 
	elseif t == modLobbyProto.POKER then
		protoGame = modLobbyProto.GetSharedRoomHistoriesReply.PokerSharedRoomDetail()
	end
	if not protoGame then return end
	protoGame:ParseFromString(jilu.detail_data)
	return protoGame 
end

pClubReport.getJilus = function(self)
	modClubMgr.getCurClub():getClubJilu(self.clubInfo:getClubId(), function(jilus)
		local uids = {}
		for _, jilu in ipairs(jilus) do
			local detailData = self:getJiluDetailData(jilu)
			for _, uid in ipairs(detailData.user_ids) do
				if not self:findIdIsInList(uid, uids) then
					table.insert(uids, uid)
				end
			end
		end
		modBattleRpc.getMultiUserProps(uids, { "name", "avatarurl", "gender" }, function(success, reason, reply) 
			if success then
				local playerInfos = reply.multi_user_props
				self:showJilus(jilus, playerInfos)	
			end
		end)
	end)
end

pClubReport.findIdIsInList = function(self, id, list)
	if not id or not list then return end
	for _, i in pairs(list) do
		if i == id then
			return i
		end
	end
	return false
end

pClubReport.showJilus = function(self, jilus, playerInfos)
	if not jilus then return end
	if table.getn(jilus) <= 0 then
		self:setText("目前没有牌局记录\n俱乐部代开牌局记录会在此显示")
		self:getTextControl():setFontSize(40)
		self:getTextControl():setColor(0xFF930000)
	else
		self:setText("")
	end
	-- 先清理
	self:clearControls()
	self:clearDragWnd()
	self:clearWindowList()
	-- 滑动窗口
	self.dragWnd = self:newListWnd()
	self.windowList = modWndList.pWndList:new(self:getWidth(), self:getHeight() * 0.95, 1, 0, 0, T_DRAG_LIST_VERTICAL)

	local distaceX = (self:getWidth() - self:getInt(self:getWidth() / 760) * 760) / (self:getInt(self:getWidth() / 760) + 1)
	local maxCount = self:getInt(self:getWidth() / 760) 
	local x, y = 0, 10
	maxCount = self:getInt(maxCount)
	for index, jilu in ipairs(jilus) do
		local wnd = self:newPanel(jilu, playerInfos) 
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

pClubReport.getInt = function(self,x)
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

pClubReport.childClick = function(self, id, isDel)
	if not id then return end
	if isDel and not self.delJiluIds[id] then
		self.delJiluIds[id] = id
	elseif not isDel then
		self.delJiluIds[id] = nil
	end
end

pClubReport.delSignJilus = function(self)
	if not self.delJiluIds or table.size(self.delJiluIds) <= 0 then return end
	for _, id in pairs(self.delJiluIds) do
		self:delJiluRpc(id)	
	end
end

pClubReport.delJiluRpc = function(self, id)
	if not id then return end
	modBattleRpc.delSharedRoomHistories(id, self.clubInfo:getClubId(), function(success, reason)
		if not success then
			infoMessage(reason)
		end
	end)
end


pClubReport.newPanel = function(self, jilu, playerInfos)
	if not jilu or not playerInfos then return end
	local wnd = modClubReportInfo.pReportInfo:new(jilu, playerInfos, self)
	wnd:setParent(self.dragWnd)
	table.insert(self.controls, wnd)
	return wnd
end

pClubReport.regEvent = function(self)
end

pClubReport.newListWnd = function(self)
	local pWnd = pWindow:new()
	pWnd:setSize(0, 0)
	pWnd:setParent(self)
	pWnd:setPosition(0,0)
	pWnd:setColor(0)
	return pWnd 
end

pClubReport.clearDragWnd = function(self)
	if self.dragWnd then
		self.dragWnd:setParent(nil)
		self.dragWnd = nil
	end
end

pClubReport.clearWindowList = function(self)
	if self.windowList then
		self.windowList:destroy()
	end
	self.windowList = nil
end

pClubReport.close = function(self)
	self:delSignJilus()
end
