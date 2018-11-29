local modMenuMain = import("ui/menu/main.lua")
local menuMain = modMenuMain.pMainMenu 

pMainLyyouwen = pMainLyyouwen or class(menuMain)

pMainLyyouwen.init = function(self)
	menuMain.init(self)
end

pMainLyyouwen.isHideInviteWnd = function(self)
	return true
end

pMainLyyouwen.templateInitWnd = function(self)
	menuMain.templateInitWnd(self)
	menuMain.floatupIcon(self)
end

pMainLyyouwen.close = function(self)
	menuMain.close(self)	
end

