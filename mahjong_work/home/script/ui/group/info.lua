local modUtil = import("util/util.lua")
local modConfirm = import("ui/common/confirm.lua")
local modGroupRpc = import("logic/group/rpc.lua")

pGroupInfoPanel = pGroupInfoPanel or class(pSingleton, pWindow)

pGroupInfoPanel.init = function(self)
	self:load("data/ui/group_info.lua")
	self:setParent(gWorld:getUIRoot())
	modUtil.makeModelWindow(self)
	self:regEvent()
end

pGroupInfoPanel.regEvent = function(self)
	self.btn_leave_club:addListener("ec_mouse_click", function()
		modConfirm.pConfirmDilog:instance():open(TEXT("退出俱乐部"), TEXT("确定要退出该俱乐部吗？"), function()
			modGroupRpc.leaveGroup(self.group:getGrpId(), function(success, reason)
				if success then
					self.group:onLeave()
					self:close()
				else
					infoMessage(reason)
				end
			end)

		end)
	end)

	self.btn_exit:addListener("ec_mouse_click", function()
		modConfirm.pConfirmDilog:instance():open(TEXT("解散俱乐部"), TEXT("确定要解散该俱乐部吗？"), function()
			modGroupRpc.destroyGroup(self.group:getGrpId(), function(success, reason)
				if success then
					self.group:onDismiss()
					self:close()
				else
					infoMessage(reason)
				end
			end)
		end)
	end)

	self.btn_update:addListener("ec_mouse_click", function()
		local name = self.edit_name:getText()
		local desc = self.edit_desc:getText()
		if name == self.group:getProp("name") and
			desc == self.group:getProp("desc") then
			infoMessage(TEXT("似乎什么也没改哦"))
		elseif not name or name == "" then
			infoMessage(TEXT("俱乐部名称不能不写哦"))
		else
			self.group:setProp("name", name)
			if desc then
				self.group:setProp("desc", desc)
			end
			self.group:saveInfoToSvr(function(success, reason)
				if success then
					infoMessage(TEXT("修改成功"))
				else
					infoMessage(reason)
				end
			end)
		end
	end)

	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.edit_desc:addListener("ec_focus", function()
		if app:getPlatform() == "macos" then
			self.edit_desc:setText("")
		end
	end)
end

pGroupInfoPanel.open = function(self, group)
	self.group = group
	if group:isMyselfCreator() then
		self.btn_leave_club:show(false)
	else
		self.btn_exit:show(false)
		self.btn_update:show(false)
		self.edit_name:enableEvent(false)
		self.edit_desc:enableEvent(false)
	end
	self.edit_name:setText(self.group:getProp("name"))
	self.edit_desc:setText(self.group:getProp("desc"))
	self.wnd_image:setImage(self.group:getProp("avatar"))
	self.wnd_member:setText(sf("%d/%d", self.group:getProp("memberCnt"), self.group:getProp("maxMemberCnt")))
	self.wnd_id:setText("ID:" .. self.group:getGrpId())
end

pGroupInfoPanel.close = function(self)
	pGroupInfoPanel:cleanInstance()
end
