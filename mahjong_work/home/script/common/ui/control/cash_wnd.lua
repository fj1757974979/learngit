-- 通用的显示金钱窗口，xxxxxx金xx银xx铜
local m_base = import("feditor_base.lua")

cash_wnd = class(puppy.gui.pWindow, m_base.feditor_base)

cash_wnd:__set_name("金钱窗口")
cash_wnd:__set_default_size(168, 24)

cash_wnd.init = function(self, parent)
	self:set_parent(parent)
	self:load_template{"script/data", "uitemplate/control/cash.lua"}

	local limit_input_len = function(edit_wnd, len)
		edit_wnd:add_listener("ec_text_change", function()
			local input_num = tonumber(edit_wnd:get_text()) or 0
			local limit_num = 10^len - 1

			--log("onlyu", "ec_text_change", len, input_num,limit_num, 10a^len -1, 10^4 - 1)				
			if input_num > 10^len - 1 then
				--log("onlyu", "ec_text_change", len, input_num,limit_num)				
				edit_wnd:set_text(10^len -1)
				--log("onlyu", "after set_text", edit_wnd:get_text())
			end
		end)
	end
	
	limit_input_len(self.edit_gold, 4)
	limit_input_len(self.edit_silver, 2)
	limit_input_len(self.edit_copper, 2)
	
	self.edit_gold:add_listener("ec_text_change", function()
		self:check_money_limit()
	end)
	
	self.edit_silver:add_listener("ec_text_change", function()
		self:check_money_limit()
	end)
	
	self.edit_copper:add_listener("ec_text_change", function()
		self:check_money_limit()
	end)

	self:set_cash(0, 0, 0)
end

cash_wnd.read_only = function(self, set)
	self.edit_gold:read_only(set)
	self.edit_silver:read_only(set)
	self.edit_copper:read_only(set)
end

cash_wnd.check_money_limit = function(self)
	if self._in_setcash then return end
	if self._limit_func then
		local self_cash = self:get_cash_by_copper()
		local new_cash = self._limit_func(self_cash)
		
		log("info", "check_money_limit", self_cash, new_cash)
		if self_cash ~= new_cash then
			self:set_cash(0, 0, new_cash)
		end
	end
end

cash_wnd.set_money_limit = function(self, limit_value)
	if type(limit_value) == "number" then
		self._limit_func = function(cash) 
			if cash > limit_value then 
				return limit_value  
			else 
				return cash
			end
		end
	elseif type(limit_value) == "function" then
		self._limit_func = limit_value
	end
end

cash_wnd.set_cash = function(self, gold, silver, copper)
	silver = silver + math.floor(copper/100)
	copper = math.mod(copper, 100)
	
	gold = gold + math.floor(silver/100)
	silver = math.mod(silver, 100)

	-- 注意，在这3个set_text的时候，是不能够触发检查上下限逻辑的
	-- 这是因为没有调完3个set_text之前，界面上的cash并不是真正的最终值
	-- 如果触发了检查逻辑，会导致死循环
	self._in_setcash = 1
	self.edit_gold:set_text(gold)
	self.edit_silver:set_text(silver)
	self.edit_copper:set_text(copper)
	self._in_setcash = nil
	self:check_money_limit()
end

cash_wnd.get_cash = function(self)
	return tonumber(self.edit_gold:get_text()) or 0, tonumber(self.edit_silver:get_text()) or 0, tonumber(self.edit_copper:get_text()) or 0
end

cash_wnd.get_cash_by_copper = function(self)
	local g, s, c = self:get_cash()
	return 10000*g + 100*s + c
end

cash_wnd.add_cash = function(self, gold, silver, copper)
	local g, s, c = self:get_cash()

	self:set_cash(g + gold, s + silver, c + copper)
end

cash_wnd.multi_cash = function(self, pow)
	local g, s, c = self:get_cash()
	
	self:set_cash(g*pow, s*pow, c*pow)
end

to_cash_wnd = function(self)
	class_cast(cash_wnd, self)
end
