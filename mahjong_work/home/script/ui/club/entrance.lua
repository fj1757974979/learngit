local modClubMgr = import("logic/club/main.lua")
local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")

pClubEntrance = pClubEntrance or class(pWindow, pSingleton)

pClubEntrance.init = function(self)
	self:load("data/ui/club_enter.lua")
	self:setParent(gWorld:getUIRoot())
	self:regEvent()
	self:setWndText()	
	modUIUtil.makeModelWindow(self, false, true)
end

pClubEntrance.setWndText = function(self)
	self.wnd_text:setText("您还没有俱乐部" .. "\n" .. "现在就去创建或者加入一个俱乐部吧！")
	self.txt_cost:setText(TEXT("消耗："))
	self.wnd_cost:setText(TEXT("x100"))
end

pClubEntrance.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_create:addListener("ec_mouse_click", function() 
		self:create()	
	end)

	self.btn_join:addListener("ec_mouse_click", function() 
		self:join()	
	end)

end

pClubEntrance.create = function(self)
	local modClubCreate = import("ui/club/create.lua")
	if modClubCreate.pClubCreate:getInstance() then
		modClubCreate.pClubCreate:instance():setParent(gWorld:getUIRoot())
	end
	modClubCreate.pClubCreate:instance():open()
	self:close()
end

pClubEntrance.join = function(self)
	local modClubJoin = import("ui/club/join.lua")
	modClubJoin.pClubJoin:instance():open()
	self:close()
end

pClubEntrance.open = function(self)

end

pClubEntrance.close = function(self)
	pClubEntrance:cleanInstance()
end
