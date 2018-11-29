local modMenuBase = import("ui/card_battle/menu.lua")

pChooseNiuMenu = pChooseNiuMenu or class(modMenuBase.pMenuWndBase)

pChooseNiuMenu.getTemplate = function(self)
	return "data/ui/card/niuniu_choose_niu_menu.lua"
end

pChooseNiuMenu.regEvent = function(self)
	self.btn_has:addListener("ec_mouse_click", function()
		local player = self:getExecutor():getHost()
		local tableWnd = player:getBattle():getBattleUI():getTableWnd()
		local cardIds = tableWnd:getUIChooseNiuCardIds(player)
		self:getExecutor():finish(true, cardIds)
	end)

	self.btn_hasnt:addListener("ec_mouse_click", function()
		self:getExecutor():finish(false, {})
	end)
end
