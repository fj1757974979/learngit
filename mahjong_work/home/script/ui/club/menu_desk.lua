local modClubRpc = import("logic/club/rpc.lua")
local modWndList = import("ui/common/list.lua")
local modUIUtil = import("ui/common/util.lua")
local modClubMgr = import("logic/club/main.lua")
local modCreateGround = import("ui/club/menu_info_create.lua")
local modGamingGround = import("ui/club/menu_info_gaming.lua")
local modRulePanel = import("ui/common/rule_panel.lua")
local modUtil = import("util/util.lua")

pMenuDesk = pMenuDesk or class(pWindow, pSingleton)

pMenuDesk.init = function(self)
	self:load("data/ui/club_desk_list_desk.lua")
end

pMenuDesk.open = function(self, clubInfo, host, parentWnd)
	self:setParent(parentWnd)
	self.clubInfo = clubInfo
	self.host = host
	self.groundInfos = nil
	self.contorls = {}
	self:initUI()
	self:regEvent()
end

pMenuDesk.initUI = function(self)
	self:getClubGounds()
end

pMenuDesk.getClubGounds = function(self)
	if not self.clubInfo then return end
	self.groundIds = self.clubInfo:getGroundIds()
	self.clubInfo:getGroundInfos(function(groundInfos)
		self.groundInfos = groundInfos
		self:showGrounds(self.groundInfos)
		self:setDeskCount(table.size(self.groundInfos), self.clubInfo:getMaxGround())
	end)
end

pMenuDesk.setDeskCount = function(self, count, max)
	self.txt_desk:setText(sf("当前牌局：%d / %d ", count, max))
end

pMenuDesk.initValues = function(self)
	local scale = 1
	local width, height = 370 * scale, 320 * scale
	local bgWidth, bgHeight = self.wnd_list:getWidth(), self.wnd_list:getHeight()
	self.maxX = self:getInt((bgWidth / width))
	self.distanceX = (bgWidth - self.maxX * width) / (self.maxX+ 1)
	self.distanceY = (bgHeight - (bgHeight / height) * height) / ( (bgHeight / height) + 1) + 80
	self.x, self.y = self.distanceX, 0
end

pMenuDesk.showGrounds = function(self, groundInfos)
	-- 清除
	self:refreshClear()
	self.dragWnd = self:newListWnd()
	self.windowList = modWndList.pWndList:new(self.wnd_list:getWidth(), self.wnd_list:getHeight(), 1, 0, 0, T_DRAG_LIST_VERTICAL)
	-- show 创建
	if self:getIsCreator() then
		self:showCreate()
	end
	if not groundInfos or table.size(groundInfos) <= 0 then
		if not self:getIsCreator() then
			self.wnd_list:setText("目前没有牌局，快去联系管理员吧！")
		end
		return
	end

	-- 描画
	self:showGamingGrounds(groundInfos)

	-- 滑动窗口
	self.dragWnd:setSize(self.wnd_list:getWidth(), self.y + 300)
	self.windowList:addWnd(self.dragWnd)
	self.windowList:setParent(self.wnd_list)

	-- 取场地玩家信息
	modClubMgr.getCurClub():getGroundMemberCount(self.clubInfo:getClubId(), self.groundIds, function(reply)
		local memberCounts = reply.club_grounds
		self:setGroundMemberCount(memberCounts)
	end)
end

pMenuDesk.setGroundMemberCount = function(self, memberCounts)
	if not memberCounts then return end
	for _, wnd in pairs(self.contorls) do
		if wnd["gid"] then
			local data = self:findValuesInData(wnd["gid"], memberCounts)
			if data then
				wnd:setGroundText(data.number_of_players)
			end
		end
	end
end

pMenuDesk.findValuesInData = function(self, cid, datas)
	if not cid or not datas then return end
	for _, data in ipairs(datas) do
		if data.id == cid then
			return data
		end
	end
	return
end

pMenuDesk.showCreate = function(self)
	local wnd = self:newCreate(self.x, self.y)
	self.x = self.x + wnd:getWidth() + self.distanceX
end

pMenuDesk.getIsCreator = function(self)
	return self.clubInfo:getIsCreator(self.clubInfo)
end

pMenuDesk.showGamingGrounds = function(self, groundInfos)
	if not groundInfos then return end
	local idx = 0
	for _, info in modUtil.iterateNumKeyTable(groundInfos, true) do
		idx = idx + 1
		local wnd = self:newGaming(info)
		self.x = self.x + wnd:getWidth() + self.distanceX
		local index = idx
		if self:getIsCreator() then index = index + 1 end
		if index % self.maxX == 0 then
			self.x = self.distanceX
			self.y = self.y + wnd:getHeight() + self.distanceY - 70
		end
	end
end

pMenuDesk.newGaming = function(self, info)
	if not info then return end
	local wnd = modGamingGround.pMenuGaming:new(info, self.clubInfo)
	wnd:setParent(self.dragWnd)
	wnd:setPosition(self.x, self.y)
	wnd["gid"] = info.id
	table.insert(self.contorls, wnd)
	return wnd
end

pMenuDesk.newCreate = function(self)
	local wnd = modCreateGround.pMenuCreate:new(self.clubInfo, nil, self.host)
	wnd:setParent(self.dragWnd)
	wnd:setPosition(self.x, self.y)
	table.insert(self.contorls, wnd)
	return wnd
end

pMenuDesk.regEvent = function(self)
end

pMenuDesk.clearDragWnd = function(self)
	if self.dragWnd then
		self.dragWnd:setParent(nil)
		self.dragWnd = nil
	end
end

pMenuDesk.clearWindowList = function(self)
	if self.windowList then
		self.windowList:destroy()
	end
	self.windowList = nil
end

pMenuDesk.clearControls = function(self)
	for _, wnd in pairs(self.contorls) do
		wnd:setParent(nil)
	end
	self.contorls = {}
end

pMenuDesk.newListWnd = function(self)
	local pWnd = pWindow:new()
	pWnd:setSize(100, 100)
	pWnd:setParent(self.wnd_list)
	pWnd:setPosition(0,0)
	pWnd:setColor(0)
	return pWnd
end

pMenuDesk.refreshClear = function(self)
	self:clearControls()
	self:clearDragWnd()
	self:clearWindowList()
	self:initValues()
	self.wnd_list:setText("")
end

pMenuDesk.getInt = function(self,x)
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

pMenuDesk.close = function(self)
	self.clubInfo = nil
	self.groundInfos = nil
	self.groundIds = nil
	self:clearControls()
	self:clearDragWnd()
	self:clearWindowList()
	pMenuDesk:cleanInstance()
end
