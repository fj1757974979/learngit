local modGroupMgr = import("logic/group/mgr.lua")
local modUtil = import("util/util.lua")
local modWndList = import("ui/common/list.lua")
local modGroupPanel = import("ui/group/grp.lua")
local modGroupCreateWnd = import("ui/group/create.lua")
local modGroupJoin = import("ui/group/join.lua")
local modEvent = import("common/event.lua")
local modGroupMail = import("ui/group/mail.lua")
local modMailMgr = import("logic/post/mgr.lua")

----------------------------------------------------------

pGroupDropDownWnd = pGroupDropDownWnd or class(pWindow, pSingleton)

pGroupDropDownWnd.init = function(self)
	self:load("data/ui/group_main_down.lua")
	self:setParent(gWorld:getUIRoot())
	modUtil.makeModelWindow(self, true, true)
	self:regEvent()
end

pGroupDropDownWnd.regEvent = function(self)
	self.btn_create:addListener("ec_mouse_click", function()
		modGroupCreateWnd.pGroupCreatePanel:instance():open()
		self:close()
	end)

	self.btn_join:addListener("ec_mouse_click", function()
		modGroupJoin.pGroupSearchWnd:instance():open()
		self:close()
	end)
end

pGroupDropDownWnd.open = function(self, x, y)
	self:setPosition(x - 50, y - 50)
end

pGroupDropDownWnd.close = function(self)
	pGroupDropDownWnd:cleanInstance()
end

------------------------------------------------------------

pGroupCard = pGroupCard or class(pWindow)

pGroupCard.init = function(self, group, w, host)
	self:load("data/ui/group_main_card.lua")
	self:setSize(w, self:getHeight())
	self.group = group
	self.host = host
	self:initUI()
	self:regEvent()
end

pGroupCard.initUI = function(self)
	self.wnd_image:setImage(self.group:getProp("avatar"))
	self.__name_hdr = self.group:bind("name", function(name)
		self.wnd_name:setText(name)
	end)
	self.__desc_hdr = self.group:bind("desc", function(desc)
		self.wnd_desc:setText(desc)
	end)
	self.__member_hdr = self.group:bind("memberCnt", function(cnt)
		self.wnd_member:setText(sf("%d/%d", cnt, self.group:getProp("maxMemberCnt")))
	end)
end

pGroupCard.regEvent = function(self)
	self.btn_club:enableEvent(false)
	self:addListener("ec_mouse_click", function()
		self.group:fetchDetail(function(success, reason)
			if success then
				self.group:subscribe(function(success, reason)
					if success then
						modGroupPanel.pGroupPanel:instance():open(self.group, self.host)
					else
						infoMessage(reason)
						self.host:open()
					end
				end)
			else
				infoMessage(reason)
				self.host:open()
			end
		end)
	end)
end

pGroupCard.destroy = function(self)
	if self.__name_hdr then
		self.group:unbind("name", self.__name_hdr)
		self.__name_hdr = nil
	end
	if self.__desc_hdr then
		self.group:unbind("desc", self.__desc_hdr)
		self.__desc_hdr = nil
	end
	if self.__member_hdr then
		self.group:unbind("memberCnt", self.__member_hdr)
		self.__member_hdr = nil
	end
	self.host = nil
	self.group = nil
	self:setParent(nil)
end

----------------------------------------------------------

pGroupMainPanel = pGroupMainPanel or class(pWindow, pSingleton)

pGroupMainPanel.init = function(self)
	self:load("data/ui/group_main.lua")
	self:setParent(gWorld:getUIRoot())
	self.grpIdToCards = {}
	self:initUI()
	self:regEvent()
end

pGroupMainPanel.initUI = function(self)
	self.wnd_dian:show(modMailMgr.pMailMgr:instance():hasMailToProcess())
end

pGroupMainPanel.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_down:addListener("ec_mouse_click", function()
		local w, h = self.btn_down:getWidth(), self.btn_down:getHeight()
		local x, y = self.btn_down:getX(true), self.btn_down:getY(true)
		pGroupDropDownWnd:instance():open(x + w, y + h)
	end)

	self.btn_mail:addListener("ec_mouse_click", function()
		modGroupMail.pGroupMailPanel:instance():open()
	end)

	self.__leave_grp_hdr = modEvent.handleEvent(EV_LEAVE_GROUP, function(grpId)
		local wnd = self.grpIdToCards[grpId]
		if wnd then
			self.list:delWnd(wnd)
		end
	end)
	self.__dismiss_grp_hdr = modEvent.handleEvent(EV_DISMISS_GROUP, function(grpId)
		local wnd = self.grpIdToCards[grpId]
		if wnd then
			self.list:delWnd(wnd)
		end
	end)
	self.__post_mail_hdr = modEvent.handleEvent(EV_PROCESS_POST, function(isShow)
		self.wnd_dian:show(isShow)
	end)
end

pGroupMainPanel.open = function(self)
	if self.list then
		self.list:destroy()
	end
	local listParent = self.club_list
	local gap = 10
	self.list = modWndList.pWndList:new(listParent:getWidth(), listParent:getHeight(), 2, gap, gap, T_DRAG_LIST_VERTICAL)
	self.list:setParent(listParent)
	local cardw = (listParent:getWidth() - gap) / 2
	local groups = table.values(modGroupMgr.pGroupMgr:instance():getAllGroups())
	table.sort(groups, function(g1, g2)
		return g1:getProp("createdDate") < g2:getProp("createdDate")
	end)
	for _, group in ipairs(groups) do
		local wnd = pGroupCard:new(group, cardw, self)
		self.grpIdToCards[group:getGrpId()] = wnd
		self.list:addWnd(wnd)
	end
end

pGroupMainPanel.close = function(self)
	if self.list then
		self.list:destroy()
		self.list = nil
	end
	pGroupMainPanel:cleanInstance()
end
