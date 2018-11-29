local m_base = import("feditor_base.lua")

ui_sprite = class(puppy.gui.pWindow, m_base.feditor_base)
ui_sprite._design_time_support = true
ui_sprite:__set_name("ui_sprite")
ui_sprite:__set_default_size(30,20)

function ui_sprite:init(parent)
	self:set_parent(parent)
	self:show_self(false)
	
	self._sprite = puppy.sprite:new()
	self._sprite:set_parent(self)
	self._sprite.on_load = function(spt)
		self:update_size()
	end
	self:add_listener("ec_size_change",function(e)
		if e:target() == self then
			self:update_size()
		end
	end)
	self:disable_event()
end

function ui_sprite:is_show_self()
	return self._sprite and self._sprite:is_show()
end

function ui_sprite:show_self(flag)
	puppy.gui.pWindow.show_self(self, false)

	if self._sprite then
		self._sprite:show(flag)
	end
end

function ui_sprite:show(flag)
	puppy.gui.pWindow.show_self(self, false)

	if self._sprite then
		self._sprite:show(flag)
	end
end

function ui_sprite:get_path()
	local texture = self._sprite:get_texture()
	if not texture then return "" end
	return texture:get_path()[3]
end

function ui_sprite:sprite_size_change()
	--local box = self._sprite:get_bound_box()
	--local x,y,w,h = box[1],box[2], box[3],box[4]
	--self:set_size(w,h)
end

function ui_sprite:disable_event()
	self._sprite:disable_event()
end

function ui_sprite:enable_event()
	self._sprite:enable_event()
end

function ui_sprite:set_path(path)
	do return end
	self._sprite:set_picture{"ui", path}
	self:sprite_size_change()
end

--function ui_sprite:set_x(x)
--	local _,y = self:get_pos()
--	self:set_pos(x,y)
--end
--
--function ui_sprite:get_x()
--	local x, y = self:get_pos()
--	return x
--end
--
--function ui_sprite:get_y()
--	local x,y = self:get_pos()
--	return y
--end
--
--function ui_sprite:set_y(y)
--	local x,_ = self:get_pos()
--	self:set_pos(x,y)
--end

function ui_sprite:set_color(color)
	if not color then return end
	self._sprite:set_color(color)
end

function ui_sprite:get_color()
	return self._sprite:get_color()
end

function ui_sprite:set_alpha(alpha)
	if not alpha then return end
	self.__alpha = alpha
	self._sprite:set_alpha(alpha)
end

function ui_sprite:get_alpha()
	return self._sprite:get_alpha()
end

function ui_sprite:set_speed(speed)
	do return end
	if not speed then return end
	self._sprite:set_speed(speed)
end

function ui_sprite:get_speed()
	if self._sprite:get_speed() <=0 then
		return self._sprite:get_res_speed()
	end
	return self._sprite:get_speed()
end

function ui_sprite:play(time, need_hide, end_callback, args)
	do return end
	self:on_play_end()
	self._sprite:show(true)
	
	self._sprite:play(time,false)
	self._sprite:start()
	
	if type(end_callback) == "function" or need_hide then
		self._end_callback_set = {func = end_callback, args = args}
		local time = self._sprite:get_num_frame()*time*self:get_speed()
		self._play_timer = set_interval(time, function() self:on_play_end(need_hide) end)
	end
end

function ui_sprite:stop_timer()
	if self._play_timer then
		self._play_timer:stop()
		self._play_timer = nil
	end
end

function ui_sprite:on_play_end(need_hide)
	self:stop_timer()
	if self._end_callback_set then
		local func = self._end_callback_set.func
		local args = self._end_callback_set.args or {}
		pcall(func, unpack(args))
		self._end_callback_set = nil
	end
	if need_hide then self._sprite:show(false) end
end

function ui_sprite:start()
	self._sprite:start()
end

function ui_sprite:stop()
	self._sprite:stop()
end

function ui_sprite:stop_play(need_hide)
	self._sprite:stop()
	self:on_play_end(need_hide)
end

function ui_sprite:get_dir()
	return self._sprite:get_dir()
end

function ui_sprite:set_dir(dir)
	self._sprite:set_dir(dir)
end

function ui_sprite:set_size(w,h)
	puppy.gui.pWindow.set_size(self, w, h)
	self:update_size()
end

function ui_sprite:get_a_color()
	local color = self._sprite:get_color()
	local a = bit.dword_rshift(bit.dword_and(color, 0xFF000000), 24)
	return a
end

function ui_sprite:get_r_color()
	local color = self._sprite:get_color()
	local r = bit.dword_rshift(bit.dword_and(color, 0x00FF0000), 16)
	return r
end

function ui_sprite:get_g_color()
	local color = self._sprite:get_color()
	local g = bit.dword_rshift(bit.dword_and(color, 0x0000FF00), 8)
	return g
end

function ui_sprite:get_b_color()
	local color = self._sprite:get_color()
	local b = bit.dword_and(color, 0x000000FF)
	return b
end

function ui_sprite:set_a_color(a_color)
	local color = self._sprite:get_color()
    color = bit.dword_and(color, 0x00FFFFFF)
  	self._sprite:set_color(bit.dword_or(color, bit.dword_lshift(a_color, 24)))	
end

function ui_sprite:set_r_color(r_color)
	local color = self._sprite:get_color()
    color = bit.dword_and(color, 0xFF00FFFF)
  	self._sprite:set_color(bit.dword_or(color, bit.dword_lshift(r_color, 16)))	
end

function ui_sprite:set_g_color(g_color)
	local color = self._sprite:get_color()
    color = bit.dword_and(color, 0xFFFF00FF)
  	self._sprite:set_color(bit.dword_or(color, bit.dword_lshift(g_color, 8)))
end

function ui_sprite:set_b_color(b_color)
	local color = self._sprite:get_color()
    color = bit.dword_and(color, 0xFFFFFF00)
  	self._sprite:set_color(bit.dword_or(color, b_color))
end

function ui_sprite:update_size()
	do return end
	local w, h = self:get_width(), self:get_height()
	local box = self._sprite:get_bound_box()
	local x,y,bw, bh =box[1],box[2], box[3],box[4]
	if not x or not y or not bw or not bh then return end
	
	if bw ~= 0 and bh ~= 0 then
		local scale_w = w/bw
		local scale_h = h/bh
		self._sprite:set_scale(scale_w,scale_h)
		self._sprite:set_pos(-x*scale_w,-y*scale_h)
	end
end

function ui_sprite:set_layout_info(layout_info)
	puppy.gui.pWindow.set_layout_info(self,layout_info)
	self:update_size()
end

function ui_sprite:set_scale(sx,sy)
	puppy.gui.pWindow.set_scale(self, sx,sy)
	self:update_size()
end

function ui_sprite:set_width(w)
	puppy.gui.pWindow.set_width(self, w)
	self:update_size()
end

function ui_sprite:set_angle(angle)
	local rot = (angle*math.pi)/180
	self._sprite:set_rot(rot)
	--self:update_size()
end

function ui_sprite:set_rot(rot)
	self._sprite:set_rot(rot)
end

function ui_sprite:get_rot()
	return self._sprite:get_rot()
end

function ui_sprite:set_key_point(kx,ky)
	self._sprite:set_key_point(kx,ky)
end

function ui_sprite:get_angle()
	return (self._sprite:get_rot() * 180/math.pi)
end

function ui_sprite:set_height(h)
	puppy.gui.pWindow.set_height(self, h)
	self:update_size()
end

ui_sprite.window_ex_style_desc = {
	{
		type = "edit",
		name = "path",
		vtype = "string",		
		style_name = "path",		
		setter = "set_path",
		getter = "get_path",
	},
	{
		type = "scrollbar",
		name = "R",
		vtype = "number",		
		style_name = "r_color",		
		setter = "set_r_color",
		getter = "get_r_color",
		range = 255,
	},
	{
		type = "scrollbar",
		name = "G",
		vtype = "number",		
		style_name = "g_color",		
		setter = "set_g_color",
		getter = "get_g_color",
		range = 255,
	},		
	{
		type = "scrollbar",
		name = "B",
		vtype = "number",		
		style_name = "b_color",		
		setter = "set_b_color",
		getter = "get_b_color",
		range = 255,
	},		
	{
		type = "scrollbar",
		name = "A",
		vtype = "number",		
		style_name = "a_color",		
		setter = "set_a_color",
		getter = "get_a_color",
		range = 255,
	},		
	{
		type = "edit",
		name = "speed",
		vtype = "number",		
		style_name = "speed",		
		setter = "set_speed",
		getter = "get_speed",
	},
	
	{
		type = "scrollbar",
		name = "旋转",
		vtype = "number",		
		style_name = "angle",		
		setter = "set_angle",
		getter = "get_angle",
		range = 360,
	},	
}

ui_sprite.load_ex_style_info = function(self, ex_style_info)
	local w,h = self:get_width(), self:get_height()
	local path = ex_style_info["path"]
	if path then self:set_path(path) end
	local a_color = ex_style_info["a_color"]
	if a_color then self:set_a_color(a_color) end

	local r_color = ex_style_info["r_color"]
	if r_color then self:set_r_color(r_color) end
	
	local g_color = ex_style_info["g_color"]
	if g_color then self:set_g_color(g_color) end

	local b_color = ex_style_info["b_color"]
	if b_color then self:set_a_color(b_color) end		
	
	local speed = ex_style_info["speed"]
	if speed then self:set_speed(speed) end
	local angle = ex_style_info["angle"]
	if angle then self:set_angle(angle) end

	self:set_size(w,h)
end
