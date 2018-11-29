local m_image_text = import("common/ui/control/image_text.lua")
jump_text = jump_text or class(puppy.gui.pWindow)

local get_move_list = function(distance, move_count, stop_count)
	local single_count = move_count/2
	local move_list = {}
	-- 计算份额
	local total_portion = 0
	for i = 1, single_count do
		local portion = i^4
		total_portion = total_portion+portion
	end
	portion_value = distance/total_portion
	-- 上升时候，每n帧经过的像素
	for i = single_count, 1, -1 do
		local portion = i^4
		table.insert(move_list, -1*portion_value*portion)
	end
	-- 下降时候，每n帧经过的像素
	for i = 1, single_count, 1 do
		local portion = i^4
		table.insert(move_list, portion_value*portion)
	end
	-- 停留
	for i = 1, stop_count, 1 do
		table.insert(move_list, 0)
	end
	return move_list
end

local get_alpha_list = function(out_alpha, out_count)
	local alpha_list = {}
	local portion_value = (0xff-out_alpha)/out_count
	for i = 1, out_count, 1 do
		table.insert(alpha_list, 0xff-(i-1)*portion_value)
	end
	return alpha_list
end

local move_count = 8 -- 上升运动+下降运动的时间
local stop_count = 20 -- 停留时间
local total_count = move_count+stop_count -- 总体时间
local out_count = 4 -- 逐渐消失时间
local move_list = get_move_list(32, move_count, stop_count)
local alpha_list = get_alpha_list(0x44, out_count)

jump_text.init = function(self, parent)
	self:set_parent(parent)
	self:disable_event()
	self:get_image_list(puppy.gui.ip_window):clear_image()
end

jump_text.set_text = function(self, text, color, char_x, width, height, scale)
	char_x = char_x or 23
	scale = scale or 1
	self._wnd_count = 0
	local char_list = string.get_char_list(text)
	self._width = #char_list*char_x
	self._wnd_list = {}
	for i, char in ipairs(char_list) do
		local wnd = m_image_text.image_text:new(self)
		wnd:set_text(char, color, char_x, width, height, scale)
		wnd:set_pos(char_x*scale*(i-1), 0)
		wnd:show(false)
		set_timeout(2*(i-1), function()
			wnd:show(true)
			run_process(1, function()
				for i = 1, total_count do
					local move = move_list[i]					
					if move then						
						wnd:set_y(wnd:get_y()+move)
					end
					yield()
				end
				-- 所有子pWindow运动完毕，销毁self
				self._wnd_count = self._wnd_count+1
				if #char_list == self._wnd_count then
					self:destroy()
				end
			end)
		end)
	end
end

jump_text.get_width = function(self)
	return self._width
end

jump_text.destroy = function(self)
	run_process(1, function()
		for i = 1, out_count do
			local alpha = alpha_list[i]
			if alpha then
				self:set_alpha(alpha)
			end
			yield()
		end
		puppy.gui.pWindow.destroy(self)
	end)
	
end

__update__ = function(self)
	jump_text:updateObject()
end
