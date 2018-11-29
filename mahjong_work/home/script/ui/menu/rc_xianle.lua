
local modMenuMain = import("ui/menu/main.lua")
local menuMain = modMenuMain.pMainMenu 

pMainRcxianle = pMainRcxianle or class(menuMain)

pMainRcxianle.init = function(self)
	menuMain.init(self)
end

pMainRcxianle.close = function(self)
	menuMain.close(self)	
end

