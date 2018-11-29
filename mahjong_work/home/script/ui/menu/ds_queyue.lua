local modMenuMain = import("ui/menu/main.lua")
local menuMain = modMenuMain.pMainMenu 

pMainDsqueyue = pMainDsqueyue or class(menuMain)

pMainDsqueyue.init = function(self)
	menuMain.init(self)
end

pMainDsqueyue.isShowAuth = function(self)
	self.btn_auth:show(false)
end

pMainDsqueyue.isHideInviteWnd = function(self)
	return true
end

pMainDsqueyue.close = function(self)
	menuMain.close(self)	
end

