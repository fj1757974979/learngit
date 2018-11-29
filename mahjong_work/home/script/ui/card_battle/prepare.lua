local modMenuBase = import("ui/card_battle/menu.lua")

pPrepareMenu = pPrepareMenu or class(modMenuBase.pMenuWndBase)

pPrepareMenu.getTemplate = function(self)
	return "data/ui/card/niuniu_prepare_menu.lua"
end

pPrepareMenu.regEvent = function(self)
	self.btn_prepare:addListener("ec_mouse_click", function()
		self:getExecutor():finish()
	end)
end
