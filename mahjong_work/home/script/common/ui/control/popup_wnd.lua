local popup_wnd_list = {}

popup_wnd = class(puppy.gui.pWindow)

--type 1 为默认 2 为新的窗口
popup_wnd.init = function(self, parent, text, time, cant_close,type)
	type = type or 1
	self:set_parent(parent)
	
	if 1 == type then 
		self:load_template{"script/data", "uitemplate/tips/piaochuang.lua"}
	elseif 2 == type then
		self:load_template{"script/data", "uitemplate/tips/piaochuang2.lua"}
	end
	
	self:show(false)
	self:set_z(LOGIC_CONST.ZVALUE_POPUPWND)

	ui.init_common_click_event(self.edit_content)

	self.edit_content:set_text(text or "")
	self.btn_hide:show(not cant_close)

	self.btn_hide:add_listener("ec_mouse_left_up", function()
		self:unit()
	end)

	local w, h = self:get_width(), self:get_height()

	self:set_layout_info("clear rx=0 ry=%d w=%d h=%d", -h, w, h)

	local state = "弹出"
	local cur_ry = -h
	local inter = 1
	local float_time = (time or 60)*1000/30

	self._timer_popup = set_interval(inter, function()
		if state == "弹出" then
			cur_ry = min(102, cur_ry + 10)
			self:set_ry(cur_ry)
			if cur_ry >= 102 then
				state = "悬浮"
			end
		elseif state == "悬浮" then
			float_time = float_time - inter
			if float_time <= 0 then
				state = "收起"
			end
		elseif state == "收起" then
			cur_ry = cur_ry - 10
			self:set_ry(cur_ry)
			if cur_ry <= -h then
				self:unit()
				self._timer_popup = nil
				return "release"
			end
		end
	end):update()

	popup_wnd_list[self] = 1
	self:show(true)
	
end

popup_wnd.set_msg = function(self,msg)
	self.edit_content:set_text(msg)	
end

popup_wnd.unit = function(self)
	if self._timer_popup then
		self._timer_popup:stop()
		self._timer_popup = nil
	end

	self:show(false)
	self:set_parent(nil)
	popup_wnd_list[self] = nil
end
