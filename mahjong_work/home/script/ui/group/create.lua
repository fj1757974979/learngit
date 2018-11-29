local modUtil = import("util/util.lua")
local modGroupConfig = import("logic/group/config.lua")
local modGroupMgr = import("logic/group/mgr.lua")
local modGroupMainPanel = import("ui/group/main.lua")

pGroupCreatePanel = pGroupCreatePanel or class(pWindow, pSingleton)

pGroupCreatePanel.init = function(self)
	self:load("data/ui/group_create.lua")
	self:setParent(gWorld:getUIRoot())
	modUtil.makeModelWindow(self)
	self:initUI()
	self:regEvent()
end

pGroupCreatePanel.initUI = function(self)
	self.txt_name:setText(TEXT("点击输入俱乐部名称"))
	self.txt_desc:setText(TEXT("点击输入俱乐部介绍"))
	self.wnd_cost:setText(modGroupConfig.getCreateCost())
end

pGroupCreatePanel.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.edit_name:addListener("ec_focus", function()
		self.txt_name:setText("")
	end)

	self.edit_name:addListener("ec_unfocus", function()
		local text = self.edit_name:getText()
		if not text or text == "" then
			self.txt_name:setText(TEXT("点击输入俱乐部名称"))
		end
	end)

	self.edit_desc:addListener("ec_focus", function()
		self.txt_desc:setText("")
	end)

	self.edit_desc:addListener("ec_unfocus", function()
		local text = self.edit_desc:getText()
		if not text or text == "" then
			self.txt_desc:setText(TEXT("点击输入俱乐部介绍"))
		end
	end)

	self.btn_ok:addListener("ec_mouse_click", function()
		local name = self.edit_name:getText()
		if not name or name == "" then
			infoMessage(TEXT("请输入俱乐部名称"))
			return
		end
		local desc = self.edit_desc:getText()
		if not desc or desc == "" then
			desc = TEXT("这家伙很懒，什么都没留下。")
		end
		modGroupMgr.pGroupMgr:instance():createGroup(name, desc, function(success, reason)
			if success then
				if self.fromWnd then
					self.fromWnd:close()
					self.fromWnd = nil
				end
				self:close()
				modGroupMainPanel.pGroupMainPanel:instance():open()
			else
				infoMessage(reason)
			end
		end)
	end)
end

pGroupCreatePanel.open = function(self, fromWnd)
	if fromWnd then
		self.fromWnd = fromWnd
		fromWnd:show(false)
	end
end

pGroupCreatePanel.close = function(self)
	if self.fromWnd then
		self.fromWnd:show(true)
		self.fromWnd = nil
	end
	pGroupCreatePanel:cleanInstance()
end
