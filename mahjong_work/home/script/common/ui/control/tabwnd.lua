local m_base = import("feditor_base.lua")
define_class( "tabwnd", puppy.gui.pWindow, feditor_base)

tabwnd = class(puppy.gui.pWindow, m_base.feditor_base)
tabwnd:__set_name("tabwnd")
tabwnd:__set_default_size(320,240)
tabwnd._body_style = "panel_1"
tabwnd._tab_style = "blue_check_button_15"
tabwnd._container_style = "panel_5"

local G_TAB_X = 10
tabwnd.init = function(self, parent)
	self:set_parent(parent)
	self:show_self(false)
	
	self._tab_list={}
	self._wnd_list={}
	self._next_tab_x = G_TAB_X

	self._body_widget = puppy.gui.pWindow:new()
	self._body_widget:set_parent(self)
	self._body_widget:init_style(self._body_style)
	self._body_widget:set_layout_info("y=18 ry=0 x=0 rx=0")
	
	self._container = puppy.gui.pWindow:new()
	self._container:set_parent(self._body_widget)
	--self._container:init_style(self._container_style)
	self._container:set_layout_info("x=5 y=5 rx=5 ry=5")
	self._container:show_self(false)

	self._header_widget = puppy.gui.pWindow:new()
	self._header_widget:set_parent(self)
	self._header_widget:set_layout_info("y=0 h=14")
	self._header_widget:show_self(false)	

end

tabwnd.add_tab = function(self, text, wnd)

	assert(wnd)
	
	local tab_btn = puppy.gui.check_button:new()
	tab_btn:set_parent(self._header_widget)
	tab_btn:init_style(self._tab_style)
	tab_btn:set_text(text)
	tab_btn:set_group(1)
	tab_btn:set_line_wrap(false)
	tab_btn:set_size(50, 25)
	tab_btn:set_pos(self._next_tab_x,-4)
	tab_btn:set_z(-1)
	
	tab_btn:add_listener("ec_select_change",function()
		if self.updating then return end
		self:show_tab(text)
	end)
	
	self._tab_list[#self._tab_list+1] = tab_btn
	self._next_tab_x = self._next_tab_x+tab_btn:get_width()
	
	
	wnd:set_parent(self._container)
	wnd:show(false)
	self._wnd_list[#self._wnd_list+1]=wnd
	
	return wnd
	
end

tabwnd.get_window_list = function(self)
	return self._wnd_list
end
tabwnd.get_wnd = function(self, tab)
	local si
	if type(tab)=="number" then 
		si=tab
	else
		for i=1,#self._tab_list do
			if si == nil and tab == self._tab_list[i]:get_text() then
				si = i
				break
			end
		end
	end
	
	return self._wnd_list[si]
end

tabwnd.get_tab = function(self, tab)
	local si
	if type(tab)=="number" then 
		si=tab
	else
		for i=1,#self._tab_list do
			if si == nil and tab == self._tab_list[i]:get_text() then
				si = i
				break
			end
		end
	end
	
	return self._tab_list[si]
end

tabwnd.get_show_tab = function(self)
	for i=1,#self._tab_list do
		if self._wnd_list[i]:is_show() then
			return i
		end
	end
end

tabwnd.show_tab = function(self,tab)
	local si
	if type(tab)=="number" then si=tab end
	
	self.updating = true

	local last_window = nil
	if self._current_tab then
		last_window = self._wnd_list[self._current_tab]
	end

	for i=1,#self._tab_list do
		if si == nil and tab == self._tab_list[i]:get_text() then
			si = i
		end
	end

	local now_window = self._wnd_list[si]
	if last_window then
		last_window:show(false)
		now_window:show(true)
	else
		now_window:show(true)
	end

	self._tab_list[si]:set_check(true)
	self._current_tab = si
	
	self.updating = false
end

tabwnd.hide_all = function(self)
	self.updating = true
	
	for i=1,#self._tab_list do
		self._wnd_list[i]:show(false)
		--self._tab_list[i]:show(false)
	end
	
	self.updating = false
end

tabwnd.set_tab_count = function(self, count)
	self:clear_all_tab()
 
	for i = 1,count do
		wnd = puppy.gui.pWindow:new()
		text = string.format("%d", i)
		self:add_tab(text,wnd)
	end
end

tabwnd.clear_all_tab = function(self)
	self._next_tab_x = G_TAB_X
	for k, btn in pairs(self._tab_list) do
		btn:destroy ()
	end
	self._tab_list = {}
	for k, wnd in pairs(self._wnd_list) do
		wnd:destroy()
	end
	self._wnd_list = {}
end

tabwnd.get_tab_count = function(self)
	return #self._tab_list
end

tabwnd.set_tab_name = function(self, tab_name, idx)
	if idx > #self._tab_list then return end
	self._tab_list[idx]:set_text(tab_name)
end 

tabwnd.get_tab_name = function(self, idx)
	if idx > #self._tab_list then return end
	return self._tab_list[idx]:get_text()
end

tabwnd.set_tab_wnd = function(self, idx, wnd, text)
	assert(wnd)
	if idx > #self._wnd_list then return end
	old_wnd = self._wnd_list[idx]
	self._wnd_list[idx] = wnd
	old_wnd:destroy()
	if text then
		btn = self._tab_list[idx]
		btn:set_text(text)
	end
end

tabwnd.window_ex_style_desc = {
	{
		type = "edit",
		name = "tab count",
		vtype = "number",		
		style_name = "tab_count",		
		setter = "set_tab_count",
		getter = "get_tab_count",
		ext_prop_set = {
			type = "edit",
			name = "tab_name",
			vtype = "string",		
			style_name = "tab_name",		
			setter = "set_tab_name",
			getter = "get_tab_name",
		},
	},
}

tabwnd.load_ex_style_info = function(self, ex_style_info)
	local tab_count = ex_style_info["tab_count"]
	if tab_count then
		self:set_tab_count(tab_count)
		local tab_name_info = ex_style_info["tab_name"]
		if not tab_name_info then return end
		for idx, name in pairs(tab_name_info) do
			self:set_tab_name(name, idx)
		end
	end
end
