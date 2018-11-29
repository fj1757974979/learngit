local modMenuBase = import("ui/card_battle/menu.lua")

pRobBankerMenu = pRobBankerMenu or class(modMenuBase.pMenuWndBase)

pRobBankerMenu.getTemplate = function(self)
	return "data/ui/card/niuniu_rob_banker_menu.lua"
end

pRobBankerMenu.regEvent = function(self)
	self.btn_rob:addListener("ec_mouse_click", function()
		self:getExecutor():finish(true)
	end)
	self.btn_not_rob:addListener("ec_mouse_click", function()
		self:getExecutor():finish(false)
	end)
end
