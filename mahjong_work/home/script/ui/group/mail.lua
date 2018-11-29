local modWndList = import("ui/common/list.lua")
local modUtil = import("util/util.lua")
local modMailMgr = import("logic/post/mgr.lua")

pGroupMailCard = pGroupMailCard or class(pWindow)

pGroupMailCard.init = function(self, mail, list, group)
	self:load("data/ui/group_mail_card.lua")
	self.mail = mail
	self.list = list
	self.group = group
	self:initUI()
	self:regEvent()
end

pGroupMailCard.initUI = function(self)
	if not self.mail:needOperate() then
		self.btn_refuse:show(false)
		self.btn_ok:show(false)
	end
	self.wnd_txt:setText(self.mail:getText())
end

pGroupMailCard.regEvent = function(self)
	self.btn_ok:addListener("ec_mouse_click", function()
		self.mail:operate(true, function(success, reason)
			if success then
				self.list:delWnd(self)
				if self.group then
					self.group:fetchDetail(function() end)
				end
				infoMessage(TEXT("已通过申请"))
			else
				infoMessage(reason)
			end
		end)
	end)

	self.btn_refuse:addListener("ec_mouse_click", function()
		self.mail:operate(false, function(success, reason)
			if success then
				self.list:delWnd(self)
				infoMessage(TEXT("已拒绝申请"))
			else
				infoMessage(reason)
			end
		end)
	end)
end

--------------------------------------------------------

pGroupMailPanel = pGroupMailPanel or class(pSingleton, pWindow)

pGroupMailPanel.init = function(self)
	self:load("data/ui/group_mail.lua")
	modUtil.makeModelWindow(self)
	self:setParent(gWorld:getUIRoot())
	self:initUI()
	self:regEvent()
end

pGroupMailPanel.initUI = function(self)
end

pGroupMailPanel.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.chk_all:addListener("ec_mouse_click", function()
		if self.applyList then
			self.applyList:show(false)
		end
		self:showMails("all")
	end)

	self.chk_join:addListener("ec_mouse_click", function()
		if self.allList then
			self.allList:show(false)
		end
		self:showMails("apply")
	end)
end

pGroupMailPanel.newWndList = function(self)
	local parent = self.wnd_list
	local w, h = parent:getWidth(), parent:getHeight()
	local list = modWndList.pWndList:new(w, h, 1, 0, 1, T_DRAG_LIST_VERTICAL)
	list:setParent(parent)
	return list
end

pGroupMailPanel.showMails = function(self, t)
	modMailMgr.pMailMgr:instance():getMails(nil, function(success, reason)
		if success then
			local list = nil
			if t == "all" then
				if self.allList then
					self.allList:destroy()
				end
				self.allList = self:newWndList()
				list = self.allList
			else
				if self.applyList then
					self.applyList:destroy()
				end
				self.applyList = self:newWndList()
				list = self.applyList
			end
			local allMails = table.values(modMailMgr.pMailMgr:instance():getAllMails())
			table.sort(allMails, function(mail1, mail2)
				return mail1:getCreatedDate() > mail2:getCreatedDate()
			end)
			for _, mail in ipairs(allMails) do
				if mail:needDisplay(t) then
					local wnd = pGroupMailCard:new(mail, list, self.group)
					list:addWnd(wnd)
				end
			end
			if list:getWndCnt() <= 0 then
				self.wnd_list:setText(TEXT("没有需要处理的邮件"))
			else
				self.wnd_list:setText("")
			end
		else
			infoMessage(reason)
		end
	end)
end

pGroupMailPanel.open = function(self, group)
	self.group = group
	if self.group then
		if not self.group:isMyselfCreator() then
			self.chk_join:show(false)
		end
	end
	self.chk_all:fireEvent("ec_mouse_click")
	self.chk_all:setCheck(true)
end

pGroupMailPanel.close = function(self)
	if self.allList then
		self.allList:destroy()
		self.allList = nil
	end
	if self.applyList then
		self.applyList:destroy()
		self.applyList = nil
	end
	self.group = nil
	pGroupMailPanel:cleanInstance()
end
