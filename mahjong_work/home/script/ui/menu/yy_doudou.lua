local modMenuMain = import("ui/menu/main.lua")
local menuMain = modMenuMain.pMainMenu 

pMainYydoudou = pMainYydoudou or class(menuMain)

pMainYydoudou.init = function(self)
	menuMain.init(self)
end

pMainYydoudou.getRemoveDistance = function(self)
	return self.btn_join_room:getWidth()
end

pMainYydoudou.close = function(self)
	menuMain.close(self)	
end
