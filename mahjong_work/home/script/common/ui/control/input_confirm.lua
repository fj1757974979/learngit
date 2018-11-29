local input_confirm_list = {}

input_confirm = class(puppy.gui.pWindow)

input_confirm.init = function(self, parent, title, on_ok, on_cancel)
	self:set_parent(parent)
	self:load_template{"script/data", "uitemplate/control/confirm_dlg.lua"}
	self:set_movable(true)

	self:bring_top()
	self:center()
	self:capture_mouse(true)

	self.wnd_title:set_text(title)
	self.edit_input:set_text("")
	self.edit_input:handle_keyboard()

	-- 随机刷验证码
	self.wnd_num:set_text(string.format("%04d", math.random(0, 9999)))

	self.btn_enter:add_listener("ec_mouse_left_up", function()
		local confirm_text = self.wnd_num:get_text()
		local input_text = self.edit_input:get_text()

		if input_text == confirm_text then
			on_ok()
			self:unit()
		else
			ui.control.message_box.new_message(self:getWorld().ui, "验证码错误")
			-- 输错了
			self.wnd_num:set_text(string.format("%04d", math.random(0, 9999)))
			self.edit_input:set_text("")
		end
	end)

	self.btn_cancel:add_listener("ec_mouse_left_up", function()
		self:unit()
	end)

	input_confirm_list[self] = 1
end

input_confirm.unit = function(self)
	self:capture_mouse(false)
	self:detach()
	input_confirm_list[self] = nil
end
