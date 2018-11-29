local modMenuBase = import("ui/card_battle/battles/paijiu/menus/base.lua")

pViewHandMenu = pViewHandMenu or class(modMenuBase.pPaijiuMenuBase)


pViewHandMenu.getTemplate = function(self)
	return "data/ui/card/paijiu_view_hand.lua"
end


pViewHandMenu.regEvent = function(self)
	self.btn_finish:addListener("ec_mouse_click", function()
		self:getExecutor():finish()
	end)

	self.btn_view:addListener("ec_mouse_click", function()
		if not self.handcard then return end

		self.handcard:startCuoPai(function()
			self:getExecutor():finish()
		end)
	end)
end

pViewHandMenu.setHandCardWnd = function(self, handcard)
	self.handcard = handcard
end


