local modMenuBase = import("ui/card_battle/battles/paijiu/menus/base.lua")

pContBankerScoreWnd = pContBankerScoreWnd or class(modMenuBase.pPaijiuMenuBase)

pContBankerScoreWnd.init = function(self, executor)
	self.scores = executor:getContBankerScores()
	modMenuBase.pPaijiuMenuBase.init(self, executor)
end

pContBankerScoreWnd.initUI = function(self)
	self:setColor(0)
end

pContBankerScoreWnd.regEvent = function(self)
	self.btn_cont_score0:addListener("ec_mouse_click", function()
		self.callback(0)
	end)

	self.btn_cont_score1:addListener("ec_mouse_click", function()
		self.callback(self.scores[1])
	end)

	self.btn_cont_score2:addListener("ec_mouse_click", function()
		self.callback(self.scores[2])
	end)

	self.btn_cont_score3:addListener("ec_mouse_click", function()
		self.callback(self.scores[3])
	end)
end

pContBankerScoreWnd.getTemplate = function(self)
	return "data/ui/card/paijiu_cont_banker_score_menu.lua"
end

pContBankerScoreWnd.open = function(self, callback)
	self.callback = callback
end

-----------------------------------------------

pContBankerMenu = pContBankerMenu or class(modMenuBase.pPaijiuMenuBase)

pContBankerMenu.getTemplate = function(self)
	return "data/ui/card/paijiu_cont_banker_menu.lua"
end

pContBankerMenu.initUI = function(self)
	self:setColor(0)
end

pContBankerMenu.regEvent = function(self)
	self.btn_cont_banker:addListener("ec_mouse_click", function()
		self:show(false)
		self.menu = pContBankerScoreWnd:new(self:getExecutor())
		self.menu:open(function(score)
			self:getExecutor():finish(score)
		end)
	end)

	self.btn_not_cont_banker:addListener("ec_mouse_click", function()
		self:getExecutor():finish(0)
	end)
end

pContBankerMenu.destroy = function(self)
	if self.menu then
		self.menu:setParent(nil)
		self.menu = nil
	end
	self:setParent(nil)
end

