local modMenuBase = import("ui/card_battle/battles/paijiu/menus/base.lua")

pRollDiceMenu = pRollDiceMenu or class(modMenuBase.pPaijiuMenuBase)

pRollDiceMenu.getTemplate = function(self)
	return "data/ui/card/paijiu_dice_menu.lua"
end

pRollDiceMenu.initUI = function(self)
end

pRollDiceMenu.regEvent = function(self)
	self.btn_dice:addListener("ec_mouse_click", function()
		self:getExecutor():finish()
	end)
end

