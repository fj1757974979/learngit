local modUtil = import("util/util.lua")
local modGroupConfig = import("logic/group/config.lua")
local modGroupCreateWnd = import("ui/group/create.lua")
local modGroupJoin = import("ui/group/join.lua")

pGroupEntryPanel = pGroupEntryPanel or class(pWindow, pSingleton)

pGroupEntryPanel.init = function(self)
	self:load("data/ui/group_enter.lua")
	self:setParent(gWorld:getUIRoot())
	modUtil.makeModelWindow(self)
	self:initUI()
	self:regEvent()
end

pGroupEntryPanel.initUI = function(self)
	self.wnd_text:setText("您还没有俱乐部" .. "\n" .. "现在就去创建或者加入一个俱乐部吧！")
	self.txt_cost:setText(TEXT("消耗："))
	self.wnd_cost:setText(modGroupConfig.getCreateCost())
end

pGroupEntryPanel.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)
	self.btn_create:addListener("ec_mouse_click", function()
		modGroupCreateWnd.pGroupCreatePanel:instance():open(self)
	end)
	self.btn_join:addListener("ec_mouse_click", function()
		modGroupJoin.pGroupSearchWnd:instance():open()
		self:close()
	end)
end

pGroupEntryPanel.open = function(self)
end

pGroupEntryPanel.close = function(self)
	pGroupEntryPanel:cleanInstance()
end
