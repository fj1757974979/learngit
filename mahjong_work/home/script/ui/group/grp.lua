local modDeskWnd = import("ui/group/desk.lua")
local modWndList = import("ui/common/list.lua")
local modGroup = import("logic/group/grp.lua")
local modGroupMail = import("ui/group/mail.lua")
local modGroupInfo = import("ui/group/info.lua")
local modGroupShare = import("ui/group/share.lua")
local modGroupMemb = import("ui/group/members.lua")
local modMailMgr = import("logic/post/mgr.lua")
local modEvent = import("common/event.lua")

pGroupPanel = pGroupPanel or class(pWindow, modGroup.pGroupObserver, pSingleton)

pGroupPanel.init = function(self)
	self:load("data/ui/group_desk.lua")
	self:setParent(gWorld:getUIRoot())
	self:initUI()
	self:regEvent()
	self.deskWnds = {}
end

pGroupPanel.initUI = function(self)
	self.wnd_dian:show(modMailMgr.pMailMgr:instance():hasMailToProcess())
end

pGroupPanel.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)
	self.chk_mail:addListener("ec_mouse_click", function()
		modGroupMail.pGroupMailPanel:instance():open(self.group)
	end)
	self.chk_info:addListener("ec_mouse_click", function()
		modGroupInfo.pGroupInfoPanel:instance():open(self.group)
	end)
	self.chk_member:addListener("ec_mouse_click", function()
		modGroupMemb.pGroupMemberPanel:instance():open(self.group)
	end)
	self.chk_share:addListener("ec_mouse_click", function()
		modGroupShare.pGroupSharePanel:instance():open(self.group)
	end)
	self.__leave_grp_hdr = modEvent.handleEvent(EV_LEAVE_GROUP, function(grpId)
		if self.group:getGrpId() == grpId then
			self:close()
		end
	end)
	self.__dismiss_grp_hdr = modEvent.handleEvent(EV_DISMISS_GROUP, function(grpId)
		if self.group:getGrpId() == grpId then
			self:close()
		end
	end)
	self.__battle_begin_hdr = modEvent.handleEvent(EV_BATTLE_BEGIN, function()
		self:show(false)
	end)
	self.__battle_end_hdr = modEvent.handleEvent(EV_BATTLE_END, function()
		self:show(true)
	end)
	self.__post_mail_hdr = modEvent.handleEvent(EV_PROCESS_POST, function(isShow)
		self.wnd_dian:show(isShow)
	end)
	self.__reconnect_done = modEvent.handleEvent(EV_RECONNECT_DONE, function()
		if self.group then
			self.group:subscribe(function(success, reason)
				if success then
					self:open(self.group, self.fromWnd)
				else
					infoMessage(reason)
				end
			end)
		end
	end)
end

pGroupPanel.open = function(self, group, fromWnd)
	if fromWnd then
		fromWnd:show(false)
		self.fromWnd = fromWnd
	end
	self.group = group
	if self.list then
		self.list:destroy()
	end
	if self.deskWnd then
		for _, wnd in pairs(self.deskWnd) do
			wnd:destroy()
		end
	end
	self.deskWnd = {}
	local listWnd = self.wnd_list
	local listw, listh = listWnd:getWidth(), listWnd:getHeight()
	local deskw, _ = modDeskWnd.getDeskSize()
	local lineCnt = math.floor(listw / deskw)
	gap = (listw - lineCnt * deskw) / (lineCnt - 1)
	self.list = modWndList.pWndList:new(listw, listh, lineCnt, gap, 0, T_DRAG_LIST_VERTICAL)
	self.list:setParent(listWnd)
	self.list:addWnd(modDeskWnd.pDeskCreateWnd:new(self))
	local desks = table.values(self.group:getAllDesks())
	table.sort(desks, function(desk1, desk2)
		return desk1:getIdx() < desk2:getIdx()
	end)
	for _, desk in ipairs(desks) do
		self:addDeskWnd(desk)
	end

	self:initGroupInfo()

	self.group:addObserver(self)
end

pGroupPanel.getGroup = function(self)
	return self.group
end

pGroupPanel.initGroupInfo = function(self)
	self.__desk_hdr = self.group:bind("deskCnt", function(cnt)
		self.txt_desk:setText(sf(TEXT("牌局数：%d"), cnt))
	end)
	self.wnd_member:setText(sf("%d/%d", self.group:getProp("memberCnt"), self.group:getProp("maxMemberCnt")))
	self.__name_hdr = self.group:bind("name", function(name)
		self.wnd_name:setText(name)
	end)
	self.wnd_id:setText(sf(TEXT("ID：%d"), self.group:getGrpId()))
end

pGroupPanel.addDeskWnd = function(self, desk)
	local wnd = modDeskWnd.pDeskWnd:new(desk, self)
	self.deskWnds[desk:getRoomId()] = wnd
	self.list:addWnd(wnd)
end

pGroupPanel.delDeskWnd = function(self, roomId)
	local wnd = self.deskWnds[roomId]
	log("info", roomId, wnd)
	if wnd then
		self.list:delWnd(wnd)
	end
end

pGroupPanel.onAddDesk = function(self, desk)
	self:addDeskWnd(desk)
end

pGroupPanel.onDelDesk = function(self, roomId)
	self:delDeskWnd(roomId)
end

pGroupPanel.close = function(self)
	if self.fromWnd then
		self.fromWnd:show(true)
		self.fromWnd = nil
	end
	if self.__desk_hdr then
		self.group:unbind("deskCnt", self.__desk_hdr)
		self.__desk_hdr = nil
	end
	if self.__name_hdr then
		self.group:unbind("name", self.__name_hdr)
		self.__name_hdr = nil
	end
	if self.group then
		self.group:unsubscribe(function()
		end)
		self.group:delObserver(self)
		self.group = nil
	end
	self.deskWnds = {}
	pGroupPanel:cleanInstance()
end
