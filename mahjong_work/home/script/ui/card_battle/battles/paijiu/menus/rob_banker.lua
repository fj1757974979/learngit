local modMenuBase = import("ui/card_battle/battles/paijiu/menus/base.lua")

pRobBankerMenu = pRobBankerMenu or class(modMenuBase.pPaijiuMenuBase)

pRobBankerMenu.getTemplate = function(self)
	return "data/ui/card/paijiu_grab_menu.lua"
end

pRobBankerMenu.initUI = function(self)
	local executor = self:getExecutor()
	local maxGrabRate = executor:getMaxGrabRate()
	local w = self.btn_no_grab:getWidth()
	local idx = 1
	for i = 1, maxGrabRate do
		idx = i
		self[sf("btn_grab%d", i)]:show(true)
	end
	for i = idx + 1, 3 do
		self[sf("btn_grab%d", i)]:show(false)
	end
	self:setSize((maxGrabRate + 1) * w, self:getHeight())
end

pRobBankerMenu.regEvent = function(self)
	self.btn_no_grab:addListener("ec_mouse_click", function()
		self:getExecutor():finish(0)
	end)

	self.btn_grab1:addListener("ec_mouse_click", function()
		self:getExecutor():finish(1)
	end)

	self.btn_grab2:addListener("ec_mouse_click", function()
		self:getExecutor():finish(2)
	end)

	self.btn_grab3:addListener("ec_mouse_click", function()
		self:getExecutor():finish(3)
	end)
end
