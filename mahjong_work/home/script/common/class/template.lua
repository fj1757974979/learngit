import("common/ui/control/init.lua")
g_cur_ui_style_lib = {}
g_cur_ui_style_lib_auto = dofile("data/uistyle/stylelib.lua") or {}

for k,v in pairs(g_cur_ui_style_lib_auto) do
	g_cur_ui_style_lib[k] = g_cur_ui_style_lib[k] or {}
	setmetatable(g_cur_ui_style_lib[k],{__index=v})
end

get_stylelib = function(class_name)
	if class_name then
		return g_cur_ui_style_lib_auto[class_name]
	else
		return g_cur_ui_style_lib_auto
	end
end

save_auto_style_lib = function()
	table.save( g_cur_ui_style_lib_auto, "script/data/uistyle/stylelib.lua")
end

set_base_style = function(style,base)
	
	if base then
		if base==style then return end
		
		local subpart = rawget(style,"subpart")
		local base_subpart = rawget(base,"subpart")
		if subpart and base_subpart then
			setmetatable(subpart,{__index=base_subpart})
			for n,s in pairs(subpart) do
				local bs = base_subpart[n]
				if bs then
					set_base_style(s,bs)
				end
			end
		end
		
		setmetatable(style,{__index=base})
	else
	
		setmetatable(style,nil)
		
		local subpart = rawget(style,"subpart")
		if subpart then
			setmetatable(subpart,nil)
			for n,s in pairs(subpart) do
				set_base_style(s,nil)
			end
		end
	end
	
end

puppy.gui.pWindow.init_style = function(self,style,onlyself)

	if not style then return end
	local class_name = self:get_class_name()
	if type(style)=="string" then
		self:setName(style)
		g_cur_ui_style_lib[class_name] = g_cur_ui_style_lib[class_name] or {}
		style = g_cur_ui_style_lib[class_name][style]
		if not style then return end
	else
		local base_style_name = rawget(style,"base_style_name")
		if base_style_name then
			local base_style = g_cur_ui_style_lib[class_name] and g_cur_ui_style_lib[class_name][base_style_name]
			set_base_style(style,base_style)
			--log("info", class_name, base_style)
			self:setName(base_style_name)
		end
	end
	
	self.style = style
	if style.layout then
		self:setLocateInfo(style.layout)
	end
	
	if style.client_layout then
		self:set_client_region_layout(style.client_layout)
	end
	
	if style.fill_layout then
		self:set_fill_region_layout(style.fill_layout)
	end
	
	if style.width_adjust then
		self:set_width_adjust(style.width_adjust)
	end
	
	if style.line_wrap ~= nil then
		self:set_line_wrap( style.line_wrap )
	end
	
	if style.text_align_x then
		self:set_text_align_x( style.text_align_x )
	end
	
	if style.text_align_y then
		self:set_text_align_y( style.text_align_y )
	end
	
	if style.text_layout then
		self:set_text_layout_info( style.text_layout )
	end
	
	if style.multi_font_size then
		self:set_multi_font_size(style.multi_font_size)
	end

	if style.font_name then
		self:set_font_name( style.font_name )
	end

	if style.font_size then
		self:set_font_size( style.font_size )
	end

	if style.font_bold then
		self:set_font_bold( style.font_bold )
	end
				
	if style.vertical_show_type then
		self:set_vertical_show_type( style.vertical_show_type )
	end
	
	if style.horizon_show_type then
		self:set_horizon_show_type(style.horizon_show_type)
	end
	
	if style.auto_set_width then
		self:auto_set_width(style.auto_set_width)
	end
	
	if style.auto_set_height then
		self:auto_set_height(style.auto_set_height)
	end
	
	if style.password_input ~= nil then
		self:password_input(style.password_input)
	end
	
	if style.enable_ime ~= nil then
		self:enable_ime(style.enable_ime)
	end
	
	if style.hscroll ~= nil then
		self:set_hscroll(style.hscroll)
	end
	
	if style.slice_mode ~= nil then
		self:set_slice_mode(style.slice_mode)
	end
	
	if style.read_only ~= nil then
		self:read_only(style.read_only)
	end
	
	if style.mutex_group then
		self:set_group(style.mutex_group)
	end	
	
	if style.input_len_limit then
		self:set_input_len_limit(style.input_len_limit)
	end
	
	if style.mouse_down_sound then
		self:set_mouse_down_sound(style.mouse_down_sound)
	end
	
	if style.mouse_up_sound then
		self:set_mouse_up_sound(style.mouse_up_sound)
	end
	
	if style.mouse_in_sound then
		self:set_mouse_in_sound(style.mouse_in_sound)
	end
	
	if style.show_sound then
		self:set_show_sound(style.show_sound)
	end
	
	if style.hide_sound then
		self:set_hide_sound(style.hide_sound)
	end

	if style.clip_draw then
		-- to-do:
		-- self:clip_draw(style.clip_draw)
	end
	
	if style.number_mode ~= nil then
		self:set_number_mode(style.number_mode)
	end
	
	if type(style.text_color)=="table" then		
		self:set_text_color_info(style.text_color)
	end
	
	if style.texture2 then
		--logv("info", style.texture2)
		self:set_texture_info(style.texture2)
	end

	if style.subpart and (not onlyself) then
		for i=1, self:get_subpart_count() do
			local obj = self:get_subpart(i) 
			local name = self:get_subpart_name(i)
			local style = style.subpart[name]

	
			if style then
				obj:init_style(style)
			else
				log("error","style for unknow part",i,name, class_name )
			end
		end
	end
end

puppy.gui.pWindow.reload_template = function(self, path, options)
	self:clear_child()
	self:load_template(path, options)
end

puppy.gui.pWindow.load_template = function(self,path,options)
	options = options or {}
	--local time = app:get_current_time()
	local template = dofile(path)
	if not template then 
		log("error", "load template failed:", path)
		return
	end

	-- 加载了配置的面包默认是可浮动的
	if options and options["none_float"] then
	else
		self:set_floatable()
	end

	local load_control = function(control_info,control)
		local class_info = string.split(control_info["class"],":")
		local style = control_info["style"] or {}
		local base_style_name = style["base_style_name"] or control_info["base_style"]
		local ex_style_info = control_info["ex_style_info"]
		if control then
			
		else
			local class_type = class_info[1]
			if class_type == "base" then
				local class_name = class_info[2]
				control = puppy.gui[class_name]:new(self)
			elseif class_type == "ext" then
				local class_name = class_info[2]
				log("onlyu", class_name)
				control = uicontrol[class_name][class_name]:new(self)
			elseif class_type == "com" then
				local path = class_info[2]
				control = puppy.gui.pWindow:new(self)
				ret = control:load_template(path,{none_float=true, is_editor = options.is_editor})
			end
		end
		
		control._load_from_template = true
		control._name = control_info["name"]
		control._class_type = class_info[1]
		control._class_name = class_info[2]
		control._class_desc = control_info["class"]

		-- control:setName(control_info["name"])
		control:set_text(control_info["text"] or "")
		--control:set_tip_text( control_info["tip"] or "" )
		
		if control_info["show"] ~= nil then
			control:show_self( control_info["show"] )
		end
		if control_info["enable"] ~= nil then
			control:enable( control_info["enable"] )
		end

		if control_info["is_disable_event"] then
			if options and options["is_editor"] then
				control._is_disable_event = true
			else
				control:disable_event()
			end
		end

		if class_info[1] == "base" then
			style["base_style_name"] = base_style_name
			--log("info", "base_style_name", base_style_name)
			control:init_style( style )
		end

		if options and options["ignore_main_panel_layout"] and control==self then
		else
			control:setLocateInfo(control_info["layout"])
		end
		control:enable_emote()
		if ex_style_info then
			control._ex_style_desc = ex_style_info
			control:load_ex_style_info(ex_style_info)
		end
		return control
	end
	
	
	load_control(template["main_panel"],self)
	self:setName(path)

	self._childs = {}
	for i=1,#template["controls"] do
		local control_info = template["controls"][i]
		if control_info then
			local control = load_control(control_info)
			control:set_parent(self)
			self[control._name] = control
			table.insert(self._childs,control)
		end
	end

	if self.btn_close then
		self.btn_close:add_listener("ec_mouse_left_up", function(e)
			if e:target() == self.btn_close then
				self:on_close()
			end
		end)
	end
	
	if self.btn_enter then
		self:add_listener("ec_key_down", function(e)
			if e:key() == 13 then
				e:code(puppy.ec_mouse_left_up)
				self.btn_enter:onEvent(e)
				e:bubble(false)
			end
		end)
		
		-- to-do:
		-- self:set_take_over_keyborad(true)
	end

	if gameconfig:get_config_int("settings", "console", 0) == 1 and not (options and options.is_editor) and not (options and options.no_edit_button)then
		install_edit_button(self, path)
	end

	return template
end

install_edit_button = function(self, path)
	local const = import("common/const.lua")
	local btn = puppy.gui.pButton()
	btn:init_style("blue_button_2")
	btn:set_text("编辑")
	btn:setLocateInfo("x=0 y=0 w=40 h=20")
	btn:set_parent(self)
	btn:set_layer(const.LAYER_TYPE.LT_EDIT_BUTTON)
	btn:add_listener("ec_mouse_left_up", function(e)
		local context = self:getWorld()
		local m_ui_main = import("tool/uieditor/main.lua")
		local uieditor = context:get_create_element("ui_editor_main", m_ui_main.main_panel, context.ui)
		uieditor:_load_main_panel(path)
		uieditor.on_save = function(_)
			log("onlyu", "on_save")
			local p = self
			while p do
				if p.updateObject then
					p:updateObject()
					uieditor:bring_top()
					return
				else
					p = p:get_parent()
				end
			end
		end
		uieditor:open()
	end)
	
	self.__edit_button = btn
end

