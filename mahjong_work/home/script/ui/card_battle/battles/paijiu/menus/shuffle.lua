local modMenuBase = import("ui/card_battle/battles/paijiu/menus/base.lua")

pShuffleMenu = pShuffleMenu or class(modMenuBase.pPaijiuMenuBase)

pShuffleMenu.getTemplate = function(self)
	return "data/ui/card/paijiu_shuffle_menu.lua"
end

pShuffleMenu.initUI = function(self)
	self:setColor(0)
	local opts = self:getExecutor():getOpts()
	logv("info", "(((((((((((((((((((((((((((((((((((( shuffle opts: ", opts)
	if opts[1] then
		self.btn_shuffle:show(true)
	else
		self.btn_shuffle:show(false)
	end
	if opts[2] then
		self.btn_continue:show(true)
	else
		self.btn_continue:show(false)
	end
	if opts[3] then
		self.btn_end:show(true)
	else
		self.btn_end:show(false)
	end
end

pShuffleMenu.regEvent = function(self)
	self.btn_shuffle:addListener("ec_mouse_click", function()
		self:getExecutor():finish(1)
	end)

	self.btn_continue:addListener("ec_mouse_click", function()
		self:getExecutor():finish(2)
	end)

	self.btn_end:addListener("ec_mouse_click", function()
		self:getExecutor():finish(3)
	end)
end

