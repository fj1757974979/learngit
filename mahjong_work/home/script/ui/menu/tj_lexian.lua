
local modMenuMain = import("ui/menu/main.lua")
local menuMain = modMenuMain.pMainMenu 

pMainTjlexian = pMainTjlexian or class(menuMain)

pMainTjlexian.init = function(self)
	menuMain.init(self)
end

pMainTjlexian.close = function(self)
	menuMain.close(self)	
end

