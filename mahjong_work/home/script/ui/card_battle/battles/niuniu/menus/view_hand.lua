local modMenuBase = import("ui/card_battle/menu.lua")

pViewHandMenu = pViewHandMenu or class(modMenuBase.pMenuWndBase)

pViewHandMenu.getTemplate = function(self)
	return "data/ui/card/niuniu_view_hand_menu.lua"
end

pViewHandMenu.regEvent = function(self)
	self.btn_cuo:addListener("ec_mouse_click", function()
		self:getExecutor():cuoPai()
	end)

	self.btn_show:addListener("ec_mouse_click", function()
		self:getExecutor():finish()
	end)
end
