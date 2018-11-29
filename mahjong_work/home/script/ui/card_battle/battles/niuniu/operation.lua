

pRobBankerWnd = pRobBankerWnd or class(pWindow)

pRobBankerWnd.init = function(self)
	self:load("data/ui/card/rob_banker.lua")

	self.btn_rob:addListener("ec_mouse_click", function()
		self:doRob(true)
	end)

	self.btn_not_rob:addListener("ec_mouse_click", function()
		self:doRob(false)
	end)
end

pRobBankerWnd.doRob = function(self, rob)
	if self.onRob then self:onRob(rob) end
	self:show(false)
end

pBetWnd = pBetWnd or class(pWindow)

pBetWnd.init = function(self)
	self:load("data/ui/card/bet.lua")
	self.btn_bet1:addListener("ec_mouse_click", function()
		self:doBet(1)
	end)

	self.btn_bet2:addListener("ec_mouse_click", function()
		self:doBet(2)
	end)

	self.btn_bet3:addListener("ec_mouse_click", function()
		self:doBet(3)
	end)
end

pBetWnd.doBet = function(self, fold)
	if self.onBet then
		self:onBet(fold)
	end
	self:show(false)
end