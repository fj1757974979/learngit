local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")
local modMenuMain = import("ui/menu/main.lua")
local menuMain = modMenuMain.pMainMenu 

pMainJzlaiba = pMainJzlaiba or class(menuMain)

pMainJzlaiba.init = function(self)
	menuMain.init(self)
	self:huodongClick()
end


pMainJzlaiba.huodongClick = function(self)
	if not self.btn_huodong then return end
	self.btn_huodong:addListener("ec_mouse_click", function()
		local modWeb = import("ui/menu/webwindow.lua")
		if modWeb.pWeb:getInstance() then 
			modWeb.pWeb:instance():close()
		end
		modWeb.pWeb:instance():open("http://www.laibaa.com/active/active1/")
	end)
end

pMainJzlaiba.open = function(self)
	menuMain.open(self)
end

pMainJzlaiba.close = function(self)
	menuMain.close(self)
end

pMainJzlaiba.hideGoldIcon = function(self)
	for i = 1, 3 do
		local wnd = self["wnd_icon_" .. i]
		if wnd then wnd:show(false) end
	end
end

pMainJzlaiba.templateInitWnd = function(self)
	menuMain.templateInitWnd(self)
	local time = modUtil.s2f(1)
	local vy = -20
	modUIUtil.floatUp(self.wnd_create_icon, time, vy)
	modUIUtil.floatUp(self.wnd_join_icon, time, -vy)
end

