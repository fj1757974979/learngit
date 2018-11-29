-- 字库
local code_list = ""

-- 验证码窗口
verify_wnd = class(puppy.gui.pWindow)

verify_wnd.init = function(self, parent)
	self:set_parent(parent)
	self:set_size(80, 40)
	self:get_image_list(puppy.gui.ip_window):clear_image()

	self._text_wnd = puppy.gui.pWindow:new(self)
	self._text_wnd:set_pos(0, 0)
	self._text_wnd:set_size(40, 16)
	self._text_wnd:set_font("宋体", 14, 800)
	self._text_wnd:get_image_list(puppy.gui.ip_window):clear_image()
	self._text_wnd:auto_set_width(true)
	self._text_wnd:set_multi_font_size(true)
	
	self:refresh()
	
--	self:add_listener("ec_mouse_left_up", function()
--		self:refresh()
--	end)
end

verify_wnd.get_right_text = function(self)
	return self._text_wnd:get_text()
end

verify_wnd.stop = function(self)
	if self._timer_change then
		self._timer_change:stop()
		self._timer_change = nil
		self._text_wnd:set_text("")
	end
end

-- 刷新验证码
-- 验证码变化特征：大小变化(no_scale)、位置变化(no_pos)、旋转(no_rot)、颜色变化(no_color)
verify_wnd.refresh = function(self, arg)
	arg = arg or {}

	self:stop()
	
	local pos1 = math.random(1, string.len(code_list))
	pos1 = pos1 + math.mod(pos1, 2) - 1

	local pos2 = math.random(1, string.len(code_list))
	pos2 = pos2 + math.mod(pos2, 2) - 1

	local text = string.sub(code_list, pos1, pos1+1)
	text = text..string.sub(code_list, pos2, pos2+1)

	self._text_wnd:set_text(text)

	self._timer_change = set_interval(FRAMES_PER_SECOND, function()
		if not arg.no_scale then
			self._text_wnd:set_scale(math.random(8, 20)/10, math.random(8, 20)/10)
		end

		if not arg.no_pos then
			local sw, sh = self:get_width(), self:get_height()
			local tw, th = self._text_wnd:get_width(), self._text_wnd:get_height()

			self._text_wnd:set_pos(math.random(0, sw - tw), math.random(0, sh - th))
		end

		if not arg.no_rot then
			self._text_wnd:set_rot(math.random(-74, 74)/100)
		end

		if not arg.no_color then
			local new_color = math.random(0, 0xffffff)
			self._text_wnd:set_text_color(puppy.gui.ip_window, 0xff000000 + new_color, 0xffffffff - new_color)
		end
	end)
end
