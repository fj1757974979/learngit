date_picker = class(puppy.gui.pWindow)

date_picker.init = function(self, parent, widget)
	self:set_parent(parent)
	self:load_template{"script/data", "uitemplate/uieditor/date_picker.lua"}
	self.widget = widget
	local init_x = self.widget:get_x(true)
	local init_y = self.widget:get_y(true) + self.widget:get_height()
	self:set_pos(init_x, init_y)
	
	-- 判断鼠标是否在edit和pWindow的范围内，为hook提供数据
	self.widget:add_listener("ec_mouse_in", function(e)
		self.is_widget_mouse_in = true
	end)
	self.widget:add_listener("ec_mouse_out", function(e)
		self.is_widget_mouse_in = false
	end)
	self:add_listener("ec_mouse_in", function(e)
		self.is_mouse_in = true
	end)
	self:add_listener("ec_mouse_out", function(e)
		self.is_mouse_in = false
	end)
	
	-- hook鼠标操作，并重写on_close，删除hook
	local ui_hook = puppy.event_hook:new()
	ui_hook.on_event_hook = function(_, e)
--		logv("info", "self.is_mouse_in", self.is_mouse_in)
--		logv("info", "self.is_widget_mouse_in", self.is_widget_mouse_in)
		-- is_mouse_in和is_widget_mouse_in为nil时，表示初始状态，请注意not和==false的影响
		if not self.is_mouse_in and self.is_widget_mouse_in == false then
--			logv("info", "self:on_close()")
			self:on_close()
		end		
	end
	ui_hook:add_hook_event(puppy.object_event.ec_mouse_left_down)
	ui_hook:add_hook_event(puppy.object_event.ec_mouse_right_down)
	self.__ui_hook = ui_hook
	self.widget:getWorld():add_hook(ui_hook)
	self.on_close = function()
		set_timeout(1, function()
			self.__ui_hook = nil
			self.widget:getWorld():del_hook(ui_hook)
		end)
		self:close()
	end
	
	-- 解决本pWindow被覆盖的问题
	self.widget:add_listener("ec_mouse_left_down", function(e)
		set_timeout(1, function()
			self:bring_top()
		end)
	end)	
	set_timeout(1, function()
		self:bring_top()
	end)
	
	local widget_date = self.widget:get_text()
	local _, _, widget_year, widget_month, widget_day = string.find(widget_date, "(%d+)-(%d+)-(%d+)")
	
	self.widget_year = widget_year and tonumber(widget_year)
	self.widget_month = widget_month and tonumber(widget_month)
	self.widget_day = widget_day and tonumber(widget_day)	
	
	self.year = self.widget_year or tonumber(os.date("%Y"))
	self.month = self.widget_month or tonumber(os.date("%m"))
--	self.day = widget_day and tonumber(widget_day) or tonumber(os.date("%d"))
	for year = self.year - 4, self.year + 5 do
		self.sel_year:insert_row(-1, year .. "年")
	end
	for month = 1, 12 do
		self.sel_month:insert_row(-1, month .. "月")
	end
	self.sel_year:set_select_text(self.year .. "年")
	self.sel_month:set_select_text(self.month .. "月")
	self:update_day_sheet()
	
	self.btn_prevmonth:add_listener("ec_mouse_left_up", function(e)
		if self.month == 1 then
			self.year = self.year - 1
			self.month = 12
		else
			self.month = self.month - 1
		end		
		self.sel_year:set_select_text(self.year .. "年")
		self.sel_month:set_select_text(self.month .. "月")
	end)
	
	self.btn_nextmonth:add_listener("ec_mouse_left_up", function(e)
		if self.month == 12 then
			self.year = self.year + 1
			self.month = 1
		else
			self.month = self.month + 1
		end
		self.sel_year:set_select_text(self.year .. "年")
		self.sel_month:set_select_text(self.month .. "月")
	end)
	
	self.sel_year:add_listener("ec_select_change", function(e)
		local year = self.sel_year:get_select_text()
		if year == "" then
			return
		end
		year = string.gsub(year, "年", "")
		self.year = tonumber(year)
		self:update_day_sheet()
	end)
	
	self.sel_month:add_listener("ec_select_change", function(e)
		local month = self.sel_month:get_select_text()
		if month == "" then
			return
		end
		month = string.gsub(month, "月", "")
		self.month = tonumber(month)
		self:update_day_sheet()
	end)
	
	self.btn_today:add_listener("ec_mouse_left_up", function(e)
		local new_year = os.date("%Y")
		local new_month = date_picker.get_full_date(os.date("%m"))
		local new_day = date_picker.get_full_date(os.date("%d"))
		local new_date = string.format("%s-%s-%s", new_year, new_month, new_day)
		self.widget:set_text(new_date)
		self:on_close()		
	end)
end

date_picker.update_day_sheet = function(self)
	for i = 1, 39 do
		self["btn_day_" .. i]:show(false)
	end

	local firstday = os.date("%w", os.time{year=self.year, month=self.month, day=1, hour=0, min=0, sec=0}) + 1
	day_num = 1
	for i = firstday,firstday + date_picker.get_last_day(self.year, self.month) - 1 do
		local btn_day = self["btn_day_" .. i]
		btn_day:show(true)		
		if self.widget_year == self.year and self.widget_month == self.month and self.widget_day == day_num then			
			btn_day:set_font_bold(1000)
			btn_day:set_text_color(puppy.gui.ip_window, 0xff0000ff, 0)
		else
			btn_day:set_font_bold(500)
			btn_day:set_text_color(puppy.gui.ip_window, 0xff000000, 0)
		end
		btn_day:set_text(tostring(day_num))
		btn_day:add_listener("ec_mouse_left_up", function(e)
			local new_year = tostring(self.year)
			local new_month = date_picker.get_full_date(tostring(self.month))
			local new_day = date_picker.get_full_date(btn_day:get_text())
			local new_date = string.format("%s-%s-%s", new_year, new_month, new_day)
			self.widget:set_text(new_date)
			self:on_close()
		end)
		day_num = day_num + 1
	end
end

date_picker.last_day_every_month = 
{
	[1] = 31,
	[2] = 28,
	[3] = 31,
	[4] = 30,
	[5] = 31,
	[6] = 30,
	[7] = 31,
	[8] = 31,
	[9] = 30,
	[10] = 31,
	[11] = 30,
	[12] = 31
}

date_picker.get_last_day = function(year, month)
	local last_day = date_picker.last_day_every_month[month]
	if date_picker.is_leap_year(year) and month == 2 then
		last_day = last_day + 1
	end
	return last_day
end

date_picker.is_leap_year = function(year)
	if (0 == year%4 and ((year%100 ~= 0) or (year%400 == 0))) then
		return true
	else
		return false
	end
end

date_picker.get_full_date = function(str)
	if #str == 1 then
		str = "0" .. str
	end
	return str
end
