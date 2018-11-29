local m_base = import("feditor_base.lua")
import("common/locale.lua")
local item_tips_wnd = import("game/module/item/ui/item_tips_wnd.lua")
local m_const = import("common/const.lua")
------------------------------------------------------------

item_wnd = item_wnd or class(puppy.gui.pWindow, m_base.feditor_base)

item_wnd.destroy = function(self)

end

__update__ = function(self)
	item_wnd:updateObject()
end 


item_wnd:__set_name("物品按钮")
item_wnd:__set_default_size(40,40)

------------------------------------------------------------
-- 初始化为显示物品框

local image_background = 0	  --无物品时的背景
local image_mouse_over = 1
local image_select = 2
local image_icon = 3

local grow_to_bg = 
{
	[0] = "ui:skin/slhx/pButton/button_29_4.TGA",
	[1] = "ui:skin/slhx/pButton/button_29_9.TGA",
	[2] = "ui:skin/slhx/pButton/button_29_8.TGA",
	[3] = "ui:skin/slhx/pButton/button_29_7.TGA",
	[4] = "ui:skin/slhx/pButton/button_29_6.TGA",
}

item_wnd._get_image = function(self, id)
	return self:get_image_list(puppy.gui.ip_normal):get_image(id)
end

item_wnd.init = function(self, parent)
	self:set_parent(parent)
	self:get_image_list(puppy.gui.ip_normal):clear_image()

	self:get_image_list(puppy.gui.ip_normal):add_image("ui:skin/slhx/pButton/button_29_1.TGA", "", 0,0,-1,-1, 0xFFFFFFFF)	--bg
	self:get_image_list(puppy.gui.ip_normal):add_image("ui:skin/slhx/pButton/button_29_2.TGA", "", 0,0,-1,-1, 0xFFFFFFFF)  --over
	self:get_image_list(puppy.gui.ip_normal):add_image("ui:skin/slhx/pButton/button_29_2.TGA", "", 0,0,-1,-1, 0xFFFFFFFF)	--select
	self:get_image_list(puppy.gui.ip_normal):add_image("", "", 0,0,-1,-1, 0xFFFFFFFF)
	self._need_background = true 
	
	--self:_get_image(image_background):_show(false)
	self:_get_image(image_mouse_over):_show(false)
	self:_get_image(image_select):_show(false)
	self:_get_image(image_icon):_show(false)

	self:set_text_layout_info("clear x=3 y=3")
	self:set_text_color(puppy.gui.ip_window, 0xff000000, 0xffffffff)
	
	-- 发送装备信息
	self:add_listener("ec_mouse_left_up",function(e)
		local context = self:getWorld()
		local item_data_mgr = context:get_element("item_data_mgr")
		if e:ck_status() == 4 then	-- shift
			local info = self._info
			if info and info.id then
				local item_info = item_data_mgr:get_by_itype(info.type)
	
				local msg = string.format("#c%s#c(i%s%s)[%s]#c()#n", m_const.GROW_TO_COLOR_S[item_info.grow] or "ff808080", "", info.id, item_info and item_info.name or TEXT("神秘物品"))
	
				local kb_handler = context:get_keyboard_hanlder()
				if kb_handler then
					if puppy.is_editwnd(kb_handler) then
						local win = class_cast(puppy.gui.edit_wnd,kb_handler)
						win:input_text(msg)
					end
				end
	--			self:getWorld():get_panel("chat_input_panel"):insert_text(msg)
			end
	
			e:bubble(false)
			return
		end
	end)
	
	self._tips_wnd_class_list = 
	{
		["装备"] = item_tips_wnd.equip_tips_wnd,
		["翅膀"] = item_tips_wnd.wing_tips_wnd,
		["幸运星"] = item_tips_wnd.luckystar_tips_wnd,
	}
	setmetatable(self._tips_wnd_class_list, {__index = function() return item_tips_wnd.item_tips_wnd end})

	-- ec_mouse_in事件，mouse_in_self_wnd_event极少被重写，mouse_in_tips_wnd_event在装备预览的时候会被重写
	self.mouse_in_self_wnd_event = function(e)
		if not self._info then
			return
		end
		self:_get_image(image_mouse_over):_show(true)
	end
	self.mouse_in_tips_wnd_event = function(e)
		if not self._info then
			return
		end
		-- init时没有parent，找不到context
		local context = self:getWorld()
		
		if self._info and self._info.id then
			-- 0.5秒判断是否请求动态tips
			item_wnd._item_id = self._info.id
			set_timeout(17, function()
				-- 请求耐久度\强化\宝石\洗练
				if self._info and self._info.id == item_wnd._item_id then
					rpc_server_item_tips_req(context, item_wnd._item_id)
				end
			end)
		end
		
		if self._info and not self._info.id and self._info.type then
			-- 0.5秒判断是否请求动态tips
			item_wnd._item_type = self._info.type
			set_timeout(17, function()
				if self._info and self._info.type == item_wnd._item_type then
					rpc_server_equip_type_info_req(context, self._info.type)
				end
			end)
		end

		local type_name = context:get_element("item_data_mgr"):get_type(self._info.type)
		local tips_wnd_class = self._tips_wnd_class_list[type_name]
		self._tips_wnd_name = tips_wnd_class.element_name
		local tips_wnd = context:get_create_element(self._tips_wnd_name, tips_wnd_class, context.ui )
		local tips_info = self:get_tips_info()
		if tips_info then
			tips_wnd:set_info(tips_info)
			tips_wnd:set_target_rect{x = self:get_x(true), y = self:get_y(true), w = self:get_width(), h = self:get_height()}
			tips_wnd:show(true)
		end
	end
	self:add_listener("ec_mouse_in", function(e) self.mouse_in_self_wnd_event(e) end)
	self:add_listener("ec_mouse_in", function(e) self.mouse_in_tips_wnd_event(e) end)

	-- ec_mouse_out事件，mouse_out_self_wnd_event极少被重写，mouse_out_tips_wnd_event在装备预览的时候会被重写
	self.mouse_out_self_wnd_event = function(e)
		self:_get_image(image_mouse_over):_show(false)
	end
	self.mouse_out_tips_wnd_event = function(e)
		-- init时没有parent，找不到context
		local context = self:getWorld()
		self:_get_image(image_mouse_over):_show(false)
		local element_name = self._tips_wnd_name
		if context:get_element(element_name) then
			context:get_element(element_name):show(false)
		end
	end
	self:add_listener("ec_mouse_out", function(e) self.mouse_out_self_wnd_event(e) end)
	self:add_listener("ec_mouse_out", function(e) self.mouse_out_tips_wnd_event(e) end)

	self:add_listener("ec_mouse_left_up", function(e)
		if self.on_item_click then
			self:on_item_click(self._info)
		end
	end)

	self:add_listener("ec_mouse_right_up", function(e)
		if self.on_item_use then
			self:on_item_use(self._info)
		end
	end)
	self:needUpdate(true)
end

item_wnd.set_select = function(self, flag)
	self:_get_image(image_select):_show(flag)
	self._is_select = flag
end

item_wnd.show_lock = function(self, flag)
	if flag then
		self:set_back_ground( "ui:skin/slhx/pButton/button_29_5.TGA")
	else
		if self._info then
			self:set_back_ground( "ui:skin/slhx/pButton/button_29_4.TGA")
		else
			self:set_back_ground( "ui:skin/slhx/pButton/button_29_1.TGA")
		end
	end
end

item_wnd.set_gray = function(self, flag)
	if flag then
		self:get_image_list(puppy.gui.ip_window):set_color(0x77777777)	
	else
		self:get_image_list(puppy.gui.ip_window):set_color(0xffffffff)
	end
end

item_wnd.clear_background = function(self)
	self._need_background = false
end

item_wnd.set_back_ground = function( self, back_ground_path )
	self:_get_image(image_background):reset( back_ground_path, "", 0,0,-1,-1, 0xFFFFFFFF)
	if not self._need_background then
		self:_get_image(image_background):_show( false )
	else
		self:_get_image(image_background):_show( true )
	end
	self:needUpdate(true)
end

item_wnd.is_select = function(self)
	return self._is_select
end

item_wnd.is_empty = function(self)
	return self._info == nil
end

item_wnd.set_info = function(self, item_info)
	if item_info then
		if item_info.count and item_info.count ~= 1 then
			self:set_text("#R"..item_info.count.."#n")
		else
			self:set_text("")
		end
		self:set_item_image(item_info.type, item_info.lock)
	else
		self:set_item_image(nil)
		self:set_text("")
		local context = self:getWorld()
		local hero = context:get_hero()
		-- 删除监听器，被使用的模块例如装备冲星的装备、宝石镶嵌的装备
		if self._change_listener then
			hero:getProp("item_mgr"):del_listener(self._change_listener)
			self._change_listener = nil
		end
		-- 删除监听器，被使用的模块例如装备冲星的幸运符、宝石镶嵌的宝石
		if self._listener_item then
			hero:getProp("item_mgr"):del_listener(self._listener_item)
			self._listener_item = nil
		end
	end
	self._info = item_info
end

item_wnd.get_info = function(self)
	return self._info
end


item_wnd.set_item_image = function( self, item_type, lock)
	self._item_type = item_type
	self:_get_image(image_icon):_show(false)
	self:set_back_ground( "ui:skin/slhx/pButton/button_29_1.TGA" )
	
	if item_type then
		local item_data_mgr = self:getWorld():get_element("item_data_mgr")
		local item_img = item_data_mgr:get_image( item_type )
		if item_img then
			local w, h = self:get_width(), self:get_height()
			--物品框40x40  物品图标36X36
			self:_get_image(image_icon):reset( item_img, string.format("clear x=%s y=%s rx=%s ry=%s", w/20, h/20, w/20, h/20), 0,0,-1,-1, lock and 0x55ffffff or 0xFFFFFFFF)
			self:_get_image(image_icon):_show(true)

			local item_info = item_data_mgr:get_by_itype(item_type)
			if item_info and item_info.grow then
				local bg_path = grow_to_bg[item_info.grow] or "ui:skin/slhx/pButton/button_29_4.TGA"
				self:set_back_ground(bg_path)
			else
				logv("info", "item_type no grow", item_type)
			end
		else
			self:_get_image(image_icon):_show(false)
		end
	end
	self:needUpdate(true)
end

item_wnd.get_tips_info = function( self )
	if self._info then
		local tips_info =
		{
			["item_id"] = self._info.id,
			["item_type"] = self._info.type,
			["frame"] = self._info.frame, -- frame动态数据，理论上应该传递。
		}
		-- 装备专用数据
		local context = self:getWorld()
		local hero = context:get_hero()
		local equip_info_list = hero:getProp("tEquipInfoList", {})
		if equip_info_list[self._info.id] then
			tips_info["chongxing_count"] = equip_info_list[self._info.id].chongxing_count
			tips_info["chongxing_max_count"] = equip_info_list[self._info.id].chongxing_max_count
			tips_info["naijiu"] = equip_info_list[self._info.id].naijiu
			tips_info["base_attr_list"] = equip_info_list[self._info.id].base_attr_list
			tips_info["jinglian_attr_list"] = equip_info_list[self._info.id].jinglian_attr_list
			tips_info["baoshi_attr_list"] = equip_info_list[self._info.id].baoshi_attr_list
			tips_info["taozhuang_attr_list"] = equip_info_list[self._info.id].taozhuang_attr_list
		end
		return tips_info
	end
end

item_wnd.set_pos_index = function(self, pos)
	self._pos_index = pos
end
	
item_wnd.get_pos_index = function(self)
	return self._pos_index
end

item_wnd.add_change_listener = function(self, del_func, add_func)
	local context = self:getWorld()
	local hero = context:get_hero()
	
	-- 删除监听器
	if self._change_listener then
		hero:getProp("item_mgr"):del_listener(self._change_listener)
		self._change_listener = nil
	end

	self._change_listener = hero:getProp("item_mgr"):add_listener("item_change", function(...)
	local _, _, change_str, _, change_item_info = ...
		if change_item_info.id ~= self._info.id then
			return
		end
		-- 删除物品
		if change_str == "Del" then
			del_func()
		end
		-- 增加物品
		if change_str == "Add" then
			add_func()
		end
	end)
end

item_wnd.map_item = function( self, item_type, sub_item_type_list, require_count,txt_wnd )
	self:set_info({type = item_type})
	
	local hero = self:getWorld():get_hero()
	sub_item_type_list = sub_item_type_list or {}
	local sub_item_type_set = {}
	for k, sub_type in ipairs(sub_item_type_list) do
		sub_item_type_set[sub_type] = true
	end
	
	local refresh_count = function()
		local item_list = hero:getProp("item_mgr"):get()
		
		local count = 0
		for _, item_info in pairs(item_list) do
			if item_info.type == item_type or sub_item_type_set[item_info.type] then
				count = count + item_info.count
			end
		end
		
		self.total_item_count = count
		self.require_count = require_count
		
		if require_count then
			local str = string.format("%d/%d", count, require_count)
			if count < require_count then
				str = string.format("#R%d/%d#n", count, require_count)
			end
			if txt_wnd then
				txt_wnd:set_text(str)
			else
				self:set_text(str)
			end
		else
			if txt_wnd then
				txt_wnd:set_text(item_type and count or "")
			else			
				self:set_text(item_type and count or "")
			end
		end
		self:set_item_image(item_type, count <= 0)
	end

	refresh_count()
	
	if self._listener_item then
		hero:getProp("item_mgr"):del_listener(self._listener_item)
		self._listener_item = nil
	end

	self._listener_item = hero:getProp("item_mgr"):add_listener("item_change", function(item_list, frames, type, frame, info)
		if info.type == item_type or sub_item_type_set[info.type] then
			refresh_count()
		end
	end)
	
	----------------------------------------------------------------------

	self.is_count_enough = function()
		return (not self.require_count) or (self.require_count <= (self.total_item_count or 0))
	end
	
	self.get_absent_count = function()
		if self.require_count and self.total_item_count and self.require_count > self.total_item_count then
			return self.require_count - self.total_item_count
		end
		return 0
	end

	self:set_clip_text(false)
end



__update__ = function(self)
	item_wnd:updateObject()
end
