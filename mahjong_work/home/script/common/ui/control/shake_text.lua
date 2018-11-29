local m_image_text = import("common/ui/control/image_text.lua")
shake_text = shake_text or class(puppy.gui.pWindow)

local get_alpha_list = function(out_alpha, out_count)
	local alpha_list = {}
	local portion_value = (0xff-out_alpha)/out_count
	for i = 1, out_count, 1 do
		table.insert(alpha_list, 0xff-(i-1)*portion_value)
	end
	return alpha_list
end

local out_count = 4
local alpha_list = get_alpha_list(0x44, out_count)

shake_text.init = function(self, parent)
	self:set_parent(parent)
	self:disable_event()
	self:get_image_list(puppy.gui.ip_window):clear_image()
	self._wnd_list = {}
end

shake_text.set_text = function(self, text, color, char_x, width, height, scale)
	char_x = char_x or 23
	scale = scale or 1
	self._wnd_count = 0
	local char_list = string.get_char_list(text)
	self._width = #char_list*char_x
	self._height = 35
	self:set_size(self._width, self._height)
--	self.bg_wnd = self:add_background()
--	self.bg_wnd:show(false)
	self:show(false)
	for i, char in ipairs(char_list) do
		local wnd = m_image_text.image_text:new(self)
		wnd:set_text(char, color, char_x, width, height, scale)
		wnd:set_pos(char_x*scale*(i-1)-self:get_width()/2-char_x/2, 0)
		table.insert(self._wnd_list, wnd)
	end
	local scale_list = {[1]=0.50113378684807,[2]=0.51020408163265,[3]=0.54081632653061,[4]=0.61337868480726,[5]=0.75510204081633,[6]=1, }
	run_process(1, function()
		self:show(true)
		self:set_scale_center(0, self:get_height()/2)
		-- 文字：由小变大
		for _, scale in ipairs(scale_list) do
			self:set_scale(0.8, scale)
			yield()
		end
		-- 文字：震动
		for _, wnd in ipairs(self._wnd_list) do
			run_process(2, function()
				for i = 1, 14, 1 do
					wnd:set_pos(wnd:get_x()+math.random(-1, 1), wnd:get_y()+math.random(-1, 1))
					yield()
				end
				self:destroy()
			end)
		end
--		-- 背景：缩放
--		self.bg_wnd:show(true)
--		self.bg_wnd:set_scale_center(150, 150)
--		local scale_list =
--		{
--			0.8, 0.9, 0.8, 0.9, 0.9, 0.8, 0.8, 0.8, 0.9, 0.9, 1, 0.9,
--			0.8, 0.9, 0.8, 0.9, 0.9, 0.8, 0.8, 0.9, 0.8, 0.9, 0.9, 1,
--		}
--		run_process(1, function()
--			for _, scale in ipairs(scale_list) do
--				self.bg_wnd:set_scale(scale, scale)
--				yield()
--			end
--		end)
	end)
end

--shake_text.add_background = function(self)
--	local bg_wnd = puppy.gui.pWindow(self)
--	bg_wnd:set_size(self:get_width(), self:get_height())
--	bg_wnd:set_pos(-178, -134)
--	local image_list = bg_wnd:get_image_list(puppy.gui.ip_window)
--	image_list:clear_image()
--	image_list:add_image({"ui", "fight/number/baoji.fsi"}, "clear x=0 y=0 w=300 h=300", 0, 0, -1, -1, 0xFFFFFFFF)
--	bg_wnd:image_dirty()
--	return bg_wnd
--end

shake_text.get_width = function(self)
	return self._width
end

shake_text.get_height = function(self)
	return self._height
end

shake_text.destroy = function(self)
	run_process(1, function()
		for _, alpha in ipairs(alpha_list) do
			self:set_alpha(alpha)
			yield()
		end
		puppy.gui.pWindow.destroy(self)
	end)
end

__update__ = function(self)
	shake_text:updateObject()
end
