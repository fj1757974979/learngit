local modMenuBase = import("ui/card_battle/menu.lua")

pBetMenu = pBetMenu or class(modMenuBase.pMenuWndBase)

pBetMenu.init = function(self, executor, opts)
	self.opts = opts
	modMenuBase.pMenuWndBase.init(self, executor)
end

pBetMenu.getTemplate = function(self)
	return "data/ui/card/niuniu_bet_menu.lua"
end

pBetMenu.initUI = function(self)
	for idx, opt in ipairs(self.opts) do
		local btn = self[sf("btn_bet%d", idx)]
		local img = self[sf("img_bet%d", idx)]
		if btn and img then
			btn.__bet = tonumber(opt)
			img:setImage(sf("ui:card_game/fold_%d.png", opt))
		end
		index = idx
	end
	if #self.opts == 1 then
		self.btn_bet1:setAlignX(ALIGN_CENTER)
		self.btn_bet2:show(false)
		self.btn_bet3:show(false)
	elseif #self.opts == 2 then
		self.btn_bet2:setAlignX(ALIGN_RIGHT)
		self.btn_bet3:show(false)
		self:setSize(self:getWidth() - self.btn_bet3:getWidth(), self:getHeight())
	end
end

pBetMenu.regEvent = function(self)
	self.btn_bet1:addListener("ec_mouse_click", function()
		self:getExecutor():finish(self.btn_bet1.__bet)
	end)
	self.btn_bet2:addListener("ec_mouse_click", function()
		self:getExecutor():finish(self.btn_bet2.__bet)
	end)
	self.btn_bet3:addListener("ec_mouse_click", function()
		self:getExecutor():finish(self.btn_bet3.__bet)
	end)
end

