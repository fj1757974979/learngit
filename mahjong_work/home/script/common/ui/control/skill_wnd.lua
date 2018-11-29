--使用方法：
--skill_wnd:set_info({
--	["skill_id"] = "2010002",
--	["skill_grade"] = 3,
--})

--[[
local m_base = import("feditor_base.lua")
local m_skill_tips_wnd = import("game/module/skill/ui/skill_tips_wnd.lua")
local m_skill_mgr = import("game/module/skill/skill_mgr.lua")
local m_skill_data = import("game/module/skill/skill_data.lua")
import("common/locale.lua")

------------------------------------------------------------

skill_wnd = skill_wnd or class(puppy.gui.pWindow, m_base.feditor_base)

skill_wnd.destroy = function(self)

end

__update__ = function(self)
	skill_wnd:updateObject()
end 


skill_wnd:__set_name("技能按钮")
skill_wnd:__set_default_size(40,40)

------------------------------------------------------------
-- 初始化为显示物品框

local image_background = 0
local image_mouse_over = 1
local image_select = 2
local image_icon = 3
local image_icon_status = 4
skill_wnd._get_image = function(self, id)
	return self:get_image_list(puppy.gui.ip_normal):get_image(id)
end

skill_wnd.init = function(self, parent)
	self:set_size(30,30)
	self:set_parent(parent)
	self:set_cursor(puppy.CURSOR_HAND)
	self:get_image_list(puppy.gui.ip_normal):clear_image()
	self._need_background = true 

	self:get_image_list(puppy.gui.ip_normal):add_image({"ui", "skin/slhx/pButton/button_29_1.TGA"}, "", 0,0,-1,-1, 0xFFFFFFFF)	--bg
	self:get_image_list(puppy.gui.ip_normal):add_image({"ui", "skin/slhx/pButton/button_29_2.TGA"}, "", 0,0,-1,-1, 0xFFFFFFFF)	--
	self:get_image_list(puppy.gui.ip_normal):add_image({"ui", "skin/slhx/pButton/button_29_2.TGA"}, "", 0,0,-1,-1, 0xFFFFFFFF)
	self:get_image_list(puppy.gui.ip_normal):add_image({"", ""}, "", 0,0,-1,-1, 0xFFFFFFFF)
	self:get_image_list(puppy.gui.ip_normal):add_image({"", ""}, "", 0,0,-1,-1, 0xFFFFFFFF)

	--self:_get_image(image_background):_show(false)
	self:_get_image(image_mouse_over):_show(false)
	self:_get_image(image_select):_show(false)
	self:_get_image(image_icon):_show(false)
	self:_get_image(image_icon_status):_show(false)
	self:image_dirty()

	self:set_text_color(puppy.gui.ip_window, 0xff3d0000, 0xffffffff)
	self:set_text_layout_info("clear x=0 rx=0 ry=0 h=20")
	self:set_text_align_x(puppy.gui.pWindow.align_right)
	self:set_text_align_y(puppy.gui.pWindow.align_bottom)

	self:add_listener("ec_mouse_in", function(e)
		self:_get_image(image_mouse_over):_show(true)
		local tips_wnd = self:getWorld():get_create_element( "skill_tips_wnd", m_skill_tips_wnd.skill_tips_wnd, self:getWorld().ui )
		local tips_info = self:get_tips_info()
		if tips_info then
			tips_wnd:set_info( tips_info )
			tips_wnd:set_target_rect{x = self:get_x(true), y = self:get_y(true), w = self:get_width(), h = self:get_height()}
			tips_wnd:show( true )
		end
	end)

	self:add_listener("ec_mouse_out", function(e)
		self:_get_image(image_mouse_over):_show(false)
		if self:getWorld():get_element( "skill_tips_wnd" ) then
			self:getWorld():get_element( "skill_tips_wnd" ):show( false )
		end
	end)

	self:add_listener("ec_mouse_left_up", function(e)
		if self.on_skill_click then
			self:on_skill_click(self._info.skill_id)
		end
	end)

	self:add_listener("ec_mouse_right_up", function(e)
		if self.on_skill_use then
			self:on_skill_use(self._info.skill_id)
		end
	end)
end

skill_wnd.set_select = function(self, flag)
	self:_get_image(image_select):_show(flag)
	self._is_select = flag
end

skill_wnd.set_icon_status = function(self, icon_status)
	local status_list =
	{
		["lock"] = {{"ui", "skin/slhx/image/image_92_1.TGA"}, "clear w=17 h=15 rx=0 ry=0"},
		["unlock"] = {{"ui", "skin/slhx/image/image_92_2.TGA"}, "clear w=17 h=15 rx=0 ry=0"},
		["unknown"] = {{"ui", "skin/slhx/image/image_93.TGA"}, "clear w=10 h=14"},
	}
	if status_list[icon_status] then
		local path, layout = unpack(status_list[icon_status])
		self:_get_image(image_icon_status):reset(path, layout, 0, 0, -1, -1, 0xFFFFFFFF)
		self:_get_image(image_icon_status):_show(true)
		self:image_dirty()
	else
		self:_get_image(image_icon_status):_show(false)
	end
end

skill_wnd.show_lock = function(self, flag)
	if flag then
		self:_get_image(image_background):reset({"ui", "skin/slhx/pButton/button_29_5.TGA"}, "", 0,0,-1,-1, 0xFFFFFFFF)
	else
		self:_get_image(image_background):reset({"ui", "skin/slhx/pButton/button_29_4.TGA"}, "", 0,0,-1,-1, 0xFFFFFFFF)
	end
	
	self:image_dirty()
end

skill_wnd.set_back_ground = function( self, back_ground_path )
	self:_get_image(image_background):reset( back_ground_path, "", 0,0,-1,-1, 0xFFFFFFFF)
	if not self._need_background then
		self:_get_image(image_background):_show( false )
	else
		self:_get_image(image_background):_show( true )
	end
end

skill_wnd.set_gray = function(self, flag)
	if flag then
		self:get_image_list(puppy.gui.ip_window):set_color(0x77777777)	
	else
		self:get_image_list(puppy.gui.ip_window):set_color(0xffffffff)
	end
end

skill_wnd.is_select = function(self)
	return self._is_select
end

skill_wnd.is_empty = function(self)
	return self._info == nil
end

skill_wnd.set_info = function(self, skill_info)
	self._info = skill_info
	if skill_info then
		self:set_skill_image(skill_info.skill_id, skill_info.lock)
		self:set_text(skill_info.skill_grade ~= 0 and skill_info.skill_grade or "")
	else
		self:set_skill_image(nil)
		self:set_text("")
	end
end

skill_wnd.get_info = function(self)
	return self._info
end

skill_wnd.set_skill_image = function(self, skill_id, lock)
	self._skill_id = skill_id
	self:_get_image(image_icon):_show(false)
	self:set_back_ground( {"ui", "skin/slhx/pButton/button_29_1.TGA"} )
	
	if skill_id then
		local info = m_skill_data.get_static_data_by_id(skill_id)
		if not info then return end 
		self._info.icon_path = self:get_icon_path(info.icon)
		if self._info.icon_path then
			self:_get_image(image_icon):reset(self._info.icon_path, "", 0,0,-1,-1, lock and 0x55ffffff or 0xFFFFFFFF)
			self:_get_image(image_icon):_show(true)
		else
			self:_get_image(image_icon):_show(false)
		end
	end
	self:image_dirty()
end

-- 获取技能的icon资源路径
skill_wnd.get_icon_path = function(self, icon_id)
	local icon_path = {"icon", string.format("skill/%s.fsi", icon_id)}
	if iomanager:file_exist(icon_path) then
		return icon_path
	end
	return {"icon", "skill/wuxiao.fsi"}
end

skill_wnd.get_tips_info = function(self)
	return self._info
end

skill_wnd.set_pos_index = function(self, pos)
	self._pos_index = pos
end
	
skill_wnd.get_pos_index = function(self)
	return self._pos_index
end

__update__ = function(self)
	skill_wnd:updateObject()
end
--]]
