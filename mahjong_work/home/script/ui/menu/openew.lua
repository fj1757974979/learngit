local modMenuMain = import("ui/menu/main.lua")
local menuMain = modMenuMain.pMainMenu 

pMainOpenew = pMainOpenew or class(menuMain)

pMainOpenew.init = function(self)
	menuMain.init(self)
end

pMainOpenew.templateInitWnd = function(self)
	menuMain.templateInitWnd(self)
	menuMain.floatupIcon(self)
end

pMainOpenew.close = function(self)
	menuMain.close(self)
	pMainOpenew:cleanInstance()
end

