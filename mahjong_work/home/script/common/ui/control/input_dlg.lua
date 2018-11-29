local input_dlg_list = {}

input_dlg = class(puppy.gui.pWindow)

input_dlg.init = function(self, parent, title, tips, on_ok, on_check)
	self:set_parent(parent)
	self:load_template{"script/data", "uitemplate/control/input_dlg.lua"}
	self:set_movable(true)

	self:bring_top()
	self:center()
	self:capture_mouse(true)

	self.wnd_title:set_text(title)
	self.wnd_tips:set_text(tips)
	self.wnd_fail_reason:set_text("")

	self.edit_input:set_text("")
	self.edit_input:handle_keyboard()
	
	if on_check then
		self.edit_input:add_listener("ec_text_change", function()
			local input_text = self.edit_input:get_text()

			local ok, reason = on_check(input_text)

			if not ok then
				self.wnd_fail_reason:set_text(reason or "输入内容不符合要求")
			else
				self.wnd_fail_reason:set_text("")
			end
		end)
	end

	self.btn_enter:add_listener("ec_mouse_left_up", function()
		local input_text = self.edit_input:get_text()
		if input_text ~= "" then
			on_ok(input_text)
			self:unit()
		end
	end)

	self.btn_cancel:add_listener("ec_mouse_left_up", function()
		self:unit()
	end)

	input_dlg_list[self] = 1
end

input_dlg.unit = function(self)
	self:capture_mouse(false)
	self:detach()
	input_dlg_list[self] = nil
end
