local modMenuBase = import("ui/card_battle/battles/paijiu/menus/base.lua")

pAntesMenu = pAntesMenu or class(modMenuBase.pPaijiuMenuBase)

pAntesMenu.getTemplate = function(self)
	local battle = self:getExecutor():getHost():getBattle()
	if battle:isKzwf() then
		return "data/ui/card/paijiu_bet_kzwf_menu.lua"
	else
		return "data/ui/card/paijiu_bet_menu.lua"
	end
end

pAntesMenu.initUI = function(self)
	local antesParam = self:getExecutor():getAntesParam()
	self.min = antesParam.min_antes
	self.max = antesParam.max_antes
	local battle = self:getExecutor():getHost():getBattle()
	if battle:isKzwf() then
		self.setAntes = function(self, antes1, antes2)
			self.antes1 = antes1
			self.antes2 = antes2
			self.wnd_antes1:setText(self.antes1)
			self.wnd_antes2:setText(self.antes2)
		end
		self.adjustAntes = function(self, antes, max)
			if antes ~= max then
				if antes % 10 <= 5 then
					antes = math.floor(antes / 10) * 10
				else
					antes = math.min(max, math.floor(antes / 10) * 10 + 10)
				end
			end
			return antes
		end
		self.calculateAntes = function(self)
			local x1 = self.wnd_cursor1:getX()
			local x2 = self.wnd_cursor2:getX()
			local antes1 = math.max(self.min, math.min(self.max, self.max * (x1 - self.__cursor1_min_x) / (self.__cursor2_max_x - self.__cursor_w - self.__cursor1_min_x)))
			antes1 = self:adjustAntes(antes1, self.max)
			local max2 = self.max - antes1
			local antes2 = 0
			if x1 ~= self.__cursor2_max_x - self.__cursor_w then
				antes2 = math.max(0, math.min(max2, max2 * (x2 - x1 - self.__cursor_w) / (self.__cursor2_max_x - x1 - self.__cursor_w)))
				antes2 = self:adjustAntes(antes2, max2)
			end
			self:setAntes(antes1, antes2)
		end
		self:setAntes(self.min, 0)
		self.__cursor1_min_x = 8
		self.__cursor2_max_x = 388
		self.__cursor_w = 10
		self.__cursor_min_gap = 0
		self.__fill_h = 40
		self.txt_min:setText(self.min)
		self.txt_max:setText(self.max)
		self:initKzwfUI()
	else
		local idx = 1
		for i = self.min, self.max, 1 do
			local wnd = self[sf("btn_bet%d", idx)]
			if wnd then
				wnd:setText(i)
				wnd.__bet = i
			end
			idx = idx + 1
		end
		self.tuiScore = antesParam.tui_score
		if self.tuiScore > 0 then
			self.btn_tui:show(true)
			self.btn_tui:setText(self.tuiScore)
		else
			self.btn_tui:show(false)
		end
	end
end

pAntesMenu.initKzwfUI = function(self)
	local data = self:getExecutor():getHost():getKzwfAntesUIData()
	if not data then
		return
	end
	local antes = data.antes
	if antes > self.max then
		return
	end
	local antes1 = data.antes1
	local x1 = 0
	if antes1 == self.min then
		x1 = self.__cursor1_min_x
	elseif antes1 == self.max then
		x1 = self.__cursor2_max_x - self.__cursor_w
	else
		x1 = (antes1 / self.max) * (self.__cursor2_max_x - self.__cursor_w - self.__cursor1_min_x) + self.__cursor1_min_x
	end
	local antes2 = data.antes2
	local x2 = 0
	if antes2 == 0 then
		x2 = x1 + self.__cursor_w
	elseif antes2 == self.max - antes1 then
		x2 = self.__cursor2_max_x
	else
		x2 = antes2 * (self.__cursor2_max_x - x1 - self.__cursor_w) / (self.max - antes1) + x1 + self.__cursor_w
	end
	self.wnd_cursor1:setPosition(x1, 0)
	self.wnd_cursor2:setPosition(x2, 0)
	local w1 = x1 - self.__cursor1_min_x + self.__cursor_w / 2
	self.wnd_fill1:setSize(w1, self.__fill_h)
	self.wnd_fill2:setPosition(self.__cursor1_min_x + w1, 0)
	local w2 = x2 - x1
	self.wnd_fill2:setSize(w2, self.__fill_h)
	self:calculateAntes()
end

pAntesMenu.regEvent = function(self)
	local battle = self:getExecutor():getHost():getBattle()
	if battle:isKzwf() then
		self.setCursorPosition = function(self, idx, dx)
			if idx == 1 then
				local x1 = self.wnd_cursor1:getX()
				x1 = math.min(math.max(x1 + dx, self.__cursor1_min_x), self.__cursor2_max_x - self.__cursor_w)
				self.wnd_cursor1:setPosition(x1, 0)

				local x2 = math.max(math.min(self.wnd_cursor2:getX() + dx, self.__cursor2_max_x), self.__cursor1_min_x + self.__cursor_w)
				self.wnd_cursor2:setPosition(x2, 0)

				local w1 = x1 - self.__cursor1_min_x + self.__cursor_w / 2
				self.wnd_fill1:setSize(w1, self.__fill_h)

				self.wnd_fill2:setPosition(self.__cursor1_min_x + w1, 0)
				local w2 = x2 - x1
				self.wnd_fill2:setSize(w2, self.__fill_h)
			elseif idx == 2 then
				local x1 = self.wnd_cursor1:getX()

				local x2 = self.wnd_cursor2:getX()
				x2 = math.min(math.max(x1 + self.__cursor_w, x2 + dx), self.__cursor2_max_x)
				self.wnd_cursor2:setPosition(x2, 0)

				local w2 = x2 - x1
				self.wnd_fill2:setSize(w2, self.__fill_h)
			end
			self:calculateAntes()
		end
		self.wnd_drag1:addListener("ec_mouse_drag", function(e)
			self:setCursorPosition(1, e:dx())
		end)
		self.wnd_drag2:addListener("ec_mouse_drag", function(e)
			self:setCursorPosition(2, e:dx())
		end)
		self.btn_confirm:addListener("ec_mouse_click", function(e)
			local data = {
				cursor1 = {
					x = self.wnd_cursor1:getX(),
				},
				cursor2 = {
					x = self.wnd_cursor2:getX(),
				},
				fill1 = {
					w = self.wnd_fill1:getWidth(),
				},
				fill2 = {
					x = self.wnd_fill2:getX(),
					w = self.wnd_fill2:getWidth(),
				},
				antes1 = self.antes1,
				antes2 = self.antes2,
				antes = self.antes1 + self.antes2,
			}
			self:getExecutor():getHost():saveKzwfAntesUIData(data)
			self:getExecutor():finish({self.antes1, self.antes2}, false)
		end)
	else
		self.btn_bet1:addListener("ec_mouse_click", function()
			self:getExecutor():finish(self.btn_bet1.__bet, false)
		end)
		self.btn_bet2:addListener("ec_mouse_click", function()
			self:getExecutor():finish(self.btn_bet2.__bet, false)
		end)
		self.btn_bet3:addListener("ec_mouse_click", function()
			self:getExecutor():finish(self.btn_bet3.__bet, false)
		end)
		self.btn_bet4:addListener("ec_mouse_click", function()
			self:getExecutor():finish(self.btn_bet4.__bet, false)
		end)
		self.btn_tui:addListener("ec_mouse_click", function()
			self:getExecutor():finish(self.tuiScore, true)
		end)
	end
end
