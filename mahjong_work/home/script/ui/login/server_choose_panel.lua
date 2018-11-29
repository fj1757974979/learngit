local modUtil = import("util/util.lua")
local modLoginMainPanel = import("ui/login/login_main.lua")
local modLoginMgr = import("logic/login/main.lua")

pServerChoosePanel = pServerChoosePanel or class(pWindow, pSingleton)

pServerChoosePanel.init = function(self)
	-- self:load("data/ui/nsg_login_choose.lua")
	self:load("data/ui/gj_login_choose_server.lua")

	self:setParent(gWorld:getUIRoot())
	self:show(false)
	self:setZ(-101)

	modUtil.makeModelWindow(self)

	self.__modelBgWnd:addListener("ec_mouse_click", function(e)
		self:doClose()
	end)

	self.txt_recently:setText(TEXT(100))
	self.txtRecentY = self.txt_recently:getY()
	self.txtAllY = self.txt_all:getY()
	
	self.width = self.wnd_recently:getWidth()
	
	self.wndRecentHeight = self.wnd_recently:getHeight()
	self.wndAllHeight = self.wnd_all:getHeight()

	self.wndRecentY = self.wnd_recently:getY()
	self.wndAllY = self.wnd_all:getY()

	self.loginmainPanel = modLoginMainPanel.pLoginMainPanel:instance()
	self.loginMgr = modLoginMgr.pLoginMgr:instance()
	local servers = self.loginMgr:getServerList()
	local recentServers = self.loginMgr:getUserLoginData():getRecentServers()

	if table.size(recentServers) > 0 then
		self:initDragWnd(self.wnd_recently, recentServers)
	else
		self.txt_recently:show(false)
		self.wnd_recently:show(false)
		self.txt_all:setPosition(0, 20)
		self.wnd_all:setSize(self.width, self.wndRecentHeight + self.wndAllHeight + 60)
	end

	-- 服务器分组
	local serverGroups = {}
	local idx = 1
	local group = {}
	local groupSize = 10
	for i, sinfo in ipairs(servers) do
		table.insert(group, {i, sinfo})
		if idx >= groupSize then
			table.insert(serverGroups, 1, group)
			group = {}
			idx = 1
		else
			idx = idx + 1
		end
	end
	if not table.isEmpty(group) then
		table.insert(serverGroups, 1, group)
	end

	self.serverGroups = serverGroups

	self:genAreaList()
end

pServerChoosePanel.genAreaList = function(self)
	-- 生成左边列表
	local areaListWnds = {}
	for _, group in ipairs(self.serverGroups) do
		local wnd = pWindow()
		-- wnd:load("data/ui/nsg_login_choose_area_list.lua")
		wnd:load("data/ui/gj_login_choose_server_card2.lua")
		local i = group[1][1]
		local j = group[table.size(group)][1]
		if i ~= j then
			wnd.wnd_name:setText(sf(TEXT(55), i, j))
		else
			wnd.wnd_name:setText(sf(TEXT(22), i))
		end
		wnd.group = group
		wnd:addListener("ec_mouse_click", function()
			local group = wnd.group
			self:initServerList(group)
			wnd:onChoose(true)
			if self.__choosing_wnd then
				if self.__choosing_wnd ~= wnd then
					self.__choosing_wnd:onChoose(false)
				end
			end
			self.__choosing_wnd = wnd
		end)

		wnd.onChoose = function(wnd, flag)
			if flag then
				wnd.wnd_name:getTextControl():setColor(0xfff9ffc4)
				wnd.bottom:setImage("ui:gj_login_tu9.png")
			else
				wnd.wnd_name:getTextControl():setColor(0xffffc973)
				wnd.bottom:setImage("ui:gj_login_tu8.png")
			end
		end

		wnd:onChoose(false)

		table.insert(areaListWnds, wnd)
	end

	self.areaListWnds = areaListWnds

	self.list_wnd.dragWnd = pWindow()
	self.list_wnd.dragWnd:showSelf(false)
	self.list_wnd.dragWnd:setParent(self.list_wnd)
	self.list_wnd:setClipDraw(true)
	-- modUtil.buildMultiColDragWindow(self.list_wnd.dragWnd, self.areaListWnds, 1, 0, 0, self.list_wnd:getWidth())
	modUtil.buildDragWindowVertical(self.list_wnd.dragWnd, self.areaListWnds, 5)

	self.areaListWnds[1]:fireEvent("ec_mouse_click")
end

pServerChoosePanel.initServerList = function(self, group)
	if self.wnd_all.dragWnd then
		self.wnd_all.dragWnd:setParent(nil)
		self.wnd_all.dragWnd = nil
	end
	if self.serverWnds then
		for _, wnd in ipairs(self.serverWnds) do
			wnd:setParent(nil)
		end
		self.serverWnds = nil
	end
	self.wnd_all.dragWnd = pWindow()
	self.wnd_all.dragWnd:setParent(self.wnd_all)
	self.wnd_all.dragWnd:showSelf(false)
	self.wnd_all:setClipDraw(true)
	local serverWnds = {}
	for _, info in ipairs(group) do
		local serverInfo = info[2]
		local wnd = self:genWnd(serverInfo, self)
		wnd.wnd_name:getTextControl():setColor(0xffc4cdff)
		table.insert(serverWnds, wnd)
	end
	self.serverWnds = serverWnds
	-- modUtil.buildMultiColDragWindow(self.wnd_all.dragWnd, self.serverWnds, 2, 30, nil, self.wnd_all:getWidth())
	modUtil.buildDragWindowVertical(self.wnd_all.dragWnd, self.serverWnds, 5)
	self.wnd_all.dragWnd:rollToBottom()

	local i = group[1][1]
	local j = group[table.size(group)][1]
	if i == j then
		self.txt_all:setText(sf(TEXT(54), i))
	else
		self.txt_all:setText(sf(TEXT(92), i, j))
	end
end

pServerChoosePanel.initDragList = function(self, father, list, dragWnd)
	local wnds = {}
	for name, value in ipairs(list) do
		local wnd = self:genWnd(value, self)
		table.insert(wnds, wnd)
	end
	father.wnds = wnds
	if table.size(father.wnds) > 0 then
		-- modUtil.buildMultiColDragWindow(dragWnd, wnds, 2, 30, nil, father:getWidth())
		modUtil.buildDragWindowVertical(dragWnd, wnds, 5)
	end

end

local statusToImg = {
	new = "ui:gj_login_new.png",
	hot = "ui:gj_login_hot.png",
	wei = "ui:gj_login_maintain.png",
}

pServerChoosePanel.genWnd = function(self, serverObj, father)
	local wnd = pWindow()
	wnd:load("data/ui/gj_login_choose_server_card.lua")
	wnd.wnd_name:setText(TEXT(serverObj.name))
	wnd.uid = serverObj.uid
	wnd.address = serverObj.address
	wnd.port = serverObj.port
	wnd.status = serverObj.status

	local st = ""
	if wnd.status ~= 0 then
		st = "wei"
	else
		if serverObj.isNew then
			st = "new"
		else
			st = "hot"
		end
	end
	local img = statusToImg[st]
	wnd.sign:setImage(img)
	local cb = function()
		self.loginmainPanel:setServerInfo(wnd.uid, wnd.wnd_name:getText(), wnd.address, wnd.port, wnd.status, serverObj.isNew)
		father:doClose()
		self.loginMgr:onChooseServerInfo(serverObj)
	end
	
	wnd:addListener("ec_mouse_click", cb)
	return wnd

end

pServerChoosePanel.initWndRecently = function(self)
	if self.wnd_recently.dragWnd then
		self.wnd_recently.dragWnd:setParent(nil)
	end

	self.wnd_recently.wnds = {}
	local wnd = pWindow()
	wnd:setParent(self.wnd_recently)
	wnd:showSelf(false)
	wnd:setPosition(0,0)
	self.wnd_recently.dragWnd = wnd

end

pServerChoosePanel.initDragWnd = function(self, pWnd, list)
	if pWnd.dragWnd then
		pWnd.dragWnd:setParent(nil)
	end

	pWnd.wnds = {}
	pWnd:setClipDraw(true)
	local wnd = pWindow()
	wnd:setParent(pWnd)
	wnd:showSelf(false)
	wnd:setColor(0)
	wnd:setPosition(0,0)
	pWnd.dragWnd = wnd

	pWnd:setClipDraw(true)
	self:initDragList(pWnd, list, wnd)	
end

pServerChoosePanel.showDialog = function(self)
	self:show(true)
end

pServerChoosePanel.doClose = function(self)
	if self.list_wnd.dragWnd then
		self.list_wnd.dragWnd:setParent(nil)
		self.list_wnd.dragWnd = nil
	end
	if self.areaListWnds then
		for _, wnd in ipairs(self.areaListWnds) do
			wnd:setParent(nil)
		end
		self.areaListWnds = nil
	end
	if self.serverWnds then
		for _, wnd in ipairs(self.serverWnds) do
			wnd:setParent(nil)
		end
		self.serverWnds = nil
	end
	if self.wnd_recently.dragWnd then
		self.wnd_recently.dragWnd:setParent(nil)
		self.wnd_recently = nil
	end
	pServerChoosePanel:cleanInstance()
end

