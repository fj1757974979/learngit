local modUtil = import("util/util.lua")
local modGroupRpc = import("logic/group/rpc.lua")
local modUserPropCache = import("logic/userpropcache.lua")

pGroupApplyPanel = pGroupApplyPanel or class(pSingleton, pWindow)

pGroupApplyPanel.init = function(self)
	self:load("data/ui/group_join_apply.lua")
	modUtil.makeModelWindow(self)
	self:setParent(gWorld:getUIRoot())
	self:initUI()
	self:regEvent()
end

pGroupApplyPanel.initUI = function(self)
	self.wnd_title:setText(TEXT("请输入留言并确认是否加入俱乐部"))
	self.wnd_text:setText(TEXT("点击输入留言"))
end

pGroupApplyPanel.regEvent = function(self)
	self.edit_text:addListener("ec_focus", function()
		self.wnd_text:setText("")
	end)

	self.edit_text:addListener("ec_unfocus", function()
		local text = self.edit_text:getText()
		if not text or text == "" then
			self.wnd_text:setText(TEXT("点击输入留言"))
		end
	end)

	self.btn_ok:addListener("ec_mouse_click", function()
		local leftWords = self.edit_text:getText() or ""
		modGroupRpc.joinGroup(self.grpId, leftWords, function(success, reason)
			if success then
				infoMessage(TEXT("申请已发送，请等待俱乐部管理员通过验证"))
				self:close()
			else
				infoMessage(reason)
			end
		end)
	end)

	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)
end

pGroupApplyPanel.open = function(self, grpId)
	self.grpId = grpId
end

pGroupApplyPanel.close = function(self)
	pGroupApplyPanel:cleanInstance()
end

--------------------------------------------------------

pGroupInfoPanel = pGroupInfoPanel or class(pSingleton, pWindow)

pGroupInfoPanel.init = function(self)
	self:load("data/ui/group_join_info.lua")
	modUtil.makeModelWindow(self)
	self:setParent(gWorld:getUIRoot())
	self:initUI()
	self:regEvent()
end

pGroupInfoPanel.initUI = function(self)
end

pGroupInfoPanel.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_join:addListener("ec_mouse_click", function()
		if self.grpId then
			pGroupApplyPanel:instance():open(self.grpId)
			self:close()
		end
	end)
end

pGroupInfoPanel.open = function(self, groupInfo)
	self.grpId = groupInfo.id
	self.wnd_desc:setText(groupInfo.brief_intro)
	self.wnd_name:setText(groupInfo.name)
	self.wnd_id:setText(sf(TEXT("ID：%d"), groupInfo.id))
	local cnt = 0
	for _, uid in ipairs(groupInfo.member_uids) do
		cnt = cnt + 1
	end
	self.wnd_member:setText(sf("%d/%d", cnt, groupInfo.max_member_count))
	self.wnd_image:setImage(groupInfo.avatar)
	self.wnd_time:setText(sf("创建时间：%s", modUtil.timeToStr(groupInfo.created_date)))
	local creatorUserId = groupInfo.creator_uid
	modUserPropCache.pUserPropCache:instance():getPropAsync(creatorUserId, {"name"}, function(success, propData)
		if success then
			self.wnd_creater:setText("创建者：" .. propData["name"])
		end
	end)
end

pGroupInfoPanel.close = function(self)
	pGroupInfoPanel:cleanInstance()
end

--------------------------------------------------------

pGroupSearchWnd = pGroupSearchWnd or class(pSingleton, pWindow)

pGroupSearchWnd.init = function(self)
	self:load("data/ui/group_join_search.lua")
	self:setParent(gWorld:getUIRoot())
	modUtil.makeModelWindow(self)
	self:initUI()
	self:regEvent()
end

pGroupSearchWnd.initUI = function(self)
	self.wnd_title:setText(TEXT("请输入俱乐部的ID"))
end

pGroupSearchWnd.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_ok:addListener("ec_mouse_click", function()
		local txt = self.edit_text:getText()
		if not txt or txt == "" then
			infoMessage(TEXT("请输入俱乐部ID"))
			return
		end
		local grpId = tonumber(txt)
		if not grpId then
			infoMessage(TEXT("请输入正确的俱乐部ID"))
			self.edit_text:setText()
			return
		end
		modGroupRpc.getGroupsDetail({grpId}, function(success, reason, groupInfos)
			if success then
				if groupInfos[1] then
					pGroupInfoPanel:instance():open(groupInfos[1])
					self:close()
				else
					infoMessage(TEXT("找不到该俱乐部，请核对俱乐部ID是否正确"))
					self.edit_text:setText()
				end
			else
				infoMessage(TEXT("找不到该俱乐部，请核对俱乐部ID是否正确"))
				self.edit_text:setText()
			end
		end)
	end)

	for i = 0, 9 do
		self["btn_"..i]:isScale(true)
		self["btn_"..i]:addListener("ec_mouse_left_down", function() 
			self:touchNumber(i)
		end)
	end

	self.btn_del:addListener("ec_mouse_left_down", function() 
		self:delNumber()
	end)

	self.btn_reinput:addListener("ec_mouse_left_down", function() 
		self:reinput()
	end)

end

pGroupSearchWnd.setIdText = function(self, number)
	if not number or not tonumber(number) then return end
	number = tonumber(number)
	self.edit_text:setText(number)
	self.curNumber = number
end

pGroupSearchWnd.touchNumber = function(self, n)
	local code = self.edit_text:getText()
	if not code or tonumber(code) == 0 then
		self.edit_text:setText(n)
	end
	if code then
		if self:checkNumberIsMax(code .. n) then
			self.edit_text:setText(code)
			return
		end
		self.edit_text:setText(code .. n)
	end
end

pGroupSearchWnd.checkNumberIsMax = function(self, n)
	if string.len(tostring(n)) > 6 then
		return true
	end
end

pGroupSearchWnd.delNumber = function(self)
	local code = self.edit_text:getText()
	if not code or code == "" then return end
	local len = string.len(self.edit_text:getText())
	if len <= 1 then 
		self:reinput()
		return 
	end

	code = string.sub(code, 1, -2) 
	self.edit_text:setText(code)
end

pGroupSearchWnd.reinput = function(self)
	self.edit_text:setText("")
end

pGroupSearchWnd.open = function(self)
	self:show(true)
end

pGroupSearchWnd.close = function(self)
	pGroupSearchWnd:cleanInstance()
end
