local modUtil = import("util/util.lua")
local modWndList = import("ui/common/list.lua")
local modConfirm = import("ui/common/confirm.lua")

pGroupMemebrEditor = pGroupMemebrEditor or class(pWindow, pSingleton)

pGroupMemebrEditor.init = function(self)
	self:load("data/ui/group_member_edit.lua")
	modUtil.makeModelWindow(self)
	self:setParent(gWorld:getUIRoot())
	self:regEvent()
end

pGroupMemebrEditor.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_ok:addListener("ec_mouse_click", function()
		local aka = self.edit_text:getText() or ""
		self.member:setProp("aka", aka)
		self.member:saveInfoToSvr(function(success, reason)
			if success then
				infoMessage(TEXT("备注成功"))
				self:close()
			else
				infoMessage(reason)
			end
		end)
	end)
end

pGroupMemebrEditor.open = function(self, member)
	self.member = member
	local aka = self.member:getAka()
	if aka and aka ~= "" then
		self.edit_text:setText(aka)
	end
	self.member:bind("name", function(name)
		self.wnd_title:setText(sf(TEXT("对玩家<%s>进行备注"), name))
	end)
end

pGroupMemebrEditor.close = function(self)
	pGroupMemebrEditor:cleanInstance()
end

----------------------------------------------------------

pGroupMemberCard = pGroupMemberCard or class(pWindow)

pGroupMemberCard.init = function(self, member, group, list, host)
	self:load("data/ui/group_member_card.lua")
	self.member = member
	self.group = group
	self.list = list
	self.host = host
	self:initUI()
	self:regEvent()
end

pGroupMemberCard.initUI = function(self)
	self.__name_hdr = self.member:bind("name", function(name)
		if self.group:isMyselfCreator() then
			local aka = self.member:getAka()
			if aka and aka ~= "" then
				self.txt_name:setText(sf("%s\n【%s】", name, aka))
			else
				self.txt_name:setText(name)
			end
		else
			self.txt_name:setText(name)
		end
	end)
	if self.group:isMyselfCreator() then
		self.__aka_hdr = self.member:bind("aka", function(aka)
			local name = self.member:getProp("name")
			if aka and aka ~= "" then
				self.txt_name:setText(sf("%s\n【%s】", name, aka))
			else
				self.txt_name:setText(name)
			end
		end)
	end
	self.txt_id:setText(self.member:getUserId())
	if self.member:isMyself() or
		not self.group:isMyselfCreator() then
		self.btn_kick:show(false)
		self.btn_edit:show(false)
	end
end

pGroupMemberCard.regEvent = function(self)
	self.btn_kick:addListener("ec_mouse_click", function()
		modConfirm.pConfirmDilog:instance():open(TEXT("移除成员"), sf(TEXT("确定要将玩家%s从俱乐部移除吗？"), self.member:getProp("name")), function()
			self.group:kickMember(self.member:getUserId(), function(success, reason)
				if success then
					self.host:open(self.group)
				else
					infoMessage(reason)
				end
			end)
		end)
	end)

	self.btn_edit:addListener("ec_mouse_click", function()
		pGroupMemebrEditor:instance():open(self.member)
	end)
end

pGroupMemberCard.destroy = function(self)
	if self.__name_hdr then
		self.member:unbind("name", self.__name_hdr)
		self.__name_hdr = nil
	end
	if self.__aka_hdr then
		self.member:unbind("aka", self.__aka_hdr)
		self.__aka_hdr = nil
	end
end

----------------------------------------------------------

pGroupMemberPanel = pGroupMemberPanel or class(pSingleton, pWindow)

pGroupMemberPanel.init = function(self)
	self:load("data/ui/group_member.lua")
	self:setParent(gWorld:getUIRoot())
	modUtil.makeModelWindow(self)
	self:initUI()
	self:regEvent()
end

pGroupMemberPanel.initUI = function(self)
	self.txt_search:setText(TEXT("点击输入玩家ID"))
end

pGroupMemberPanel.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.edit_search:addListener("ec_focus", function()
		self.txt_search:setText("")
	end)

	self.edit_search:addListener("ec_unfocus", function()
		local text = self.edit_search:getText()
		if not text or text == "" then
			self.txt_search:setText(TEXT("点击输入玩家ID"))
			self:showMembers()
		end
	end)

	self.btn_search:addListener("ec_mouse_click", function()
		local text = self.edit_search:getText()
		local userId = tonumber(text)
		if not userId then
			infoMessage(TEXT("请输入正确的玩家ID"))
		else
			local member = self.group:getMember(userId)
			if member then
				self:showMembers({member})
			else
				self:showMembers({})
			end
		end
	end)
end

pGroupMemberPanel.open = function(self, group)
	self.group = group
	self.group:fetchDetail(function(success, reason)
		if success then
			self:showMembers()
		else
			infoMessage(reason)
		end
	end)
end

pGroupMemberPanel.showMembers = function(self, members)
	if not members then
		members = table.values(self.group:getAllMembers())
		table.sort(members, function(m1, m2)
			return m1:getJoinDate() < m2:getJoinDate()
		end)
	end
	if self.list then
		self.list:destroy()
	end
	local parent = self.wnd_list
	local w, h = parent:getWidth(), parent:getHeight()
	self.list = modWndList.pWndList:new(w, h, 1, 0, 1, T_DRAG_LIST_VERTICAL)
	self.list:setParent(parent)
	for _, member in ipairs(members) do
		local wnd = pGroupMemberCard:new(member, self.group, self.list, self)
		self.list:addWnd(wnd)
	end
end

pGroupMemberPanel.close = function(self)
	if self.list then
		self.list:destroy()
		self.list = nil
	end
	pGroupMemberPanel:cleanInstance()
end
