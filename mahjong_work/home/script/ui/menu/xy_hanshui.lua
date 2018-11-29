local modMenuMain = import("ui/menu/main.lua")
local menuMain = modMenuMain.pMainMenu 

pMainXyhanshui = pMainXyhanshui or class(menuMain)

pMainXyhanshui.init = function(self)
	menuMain.init(self)
end

pMainXyhanshui.close = function(self)
	menuMain.close(self)	
end
