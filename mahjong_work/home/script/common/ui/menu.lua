local m_const = import("common/const.lua")
local menu_separate_style = "panel_5"
local menu_text_button_style = "blue_button_1"
local menu_sub_menu_style = "blue_button_2"


local top_space = 12
local line_space = 5
local left_space = 12
local bottom_space = 12

menu = menu or class(puppy.gui.pWindow)

function menu:init(parent)
   self:set_parent(parent)
   self:load_template("data/uitemplate/common/menu.lua")

   self:show(false)
   self.current_pos = top_space

   self._scale_center = {x = 0, y = 0}
   self.__btns = {}
end

function menu:clear()
	self:load_template("data/uitemplate/common/menu.lua")
	self.current_pos = top_space
	for _, btn in ipairs(self.__btns) do
		btn:detach()
	end
	self.__btns = {}
end

function menu:open(x, y)
	self:show(true)
	self:set_z(-100)
	self:set_scale(1,1)
	self._scale_center = {x = 0, y = 0}

	
	local context = self:getWorld()
	-- move to the cursor
	local cursor = context:get_cursor()
	x = x or cursor:get_x()
	y = y or cursor:get_y() + 1

	local h = self:get_height()
	local w = self:get_width()

	local px,py = 0,0
	local pw, ph = 0,0
	if self.__parent_menu then
		ph,pw = self.__parent_menu:get_height(), self.__parent_menu:get_width()
		px, py = self.__parent_menu:get_x(),self.__parent_menu:get_y()
	end
	if x + w + px > context.syswnd:get_width() then
		x = x - w - 1 - pw
		self._scale_center.x = w
		print("show_sub_x ", x, w, pw,px)
	else 
		x = x + 1
		self._scale_center.x = 0
	end

	if y + py + h > context.syswnd:get_height() then
		y = y - h - 1 - ph
		self._scale_center.y = h
		print("show_sub_y ", y, h, ph,py)
	else
		y = y - 1
		self._scale_center.y = 0
	end

	self:set_pos(x, y)
	self:set_scale_center(self._scale_center.x, self._scale_center.y)
	self:bring_top()
	self:set_scale(1,1)

	-- add event hook
	if self.event_hook then
		context:del_hook(self.event_hook)
		self.event_hook = nil
	end

	local ui_hook = puppy.event_hook:new()
	ui_hook.on_event_hook = function(_, e)
		local event = { x = e:ax(), y=e:ay() }

		set_timeout(1, function()
			local x,y = self:get_x(), self:get_y()
			local w,h = self:get_width(), self:get_height()

			if event.x < x or event.x > x + w or event.y < y or event.y > y + h then
				self:close()
			end
		end)
	end
	ui_hook:add_hook_event(puppy.object_event.ec_mouse_left_down)
	ui_hook:add_hook_event(puppy.object_event.ec_mouse_right_down)
	context:add_hook( ui_hook )
	self.event_hook = ui_hook
	
	--if not main_ctx:get_setting("ui_animation") then return end

	self:set_scale(0,0)

	if self.process then
		stop_process(self.process)
	end
--	self:use_self_target(true)
	self.process = run_process(1, function()
		for i=0, 1, 0.2 do
			self:set_scale(i, i)
			yield()
		end
		self:set_scale(1, 1)
--		self:use_self_target(false)
	end)
end

function menu:close()
	local context = self:getWorld()
	if self.event_hook then
		context:del_hook(self.event_hook)
		self.event_hook = nil
	end

	self:set_scale_center(self._scale_center.x, self._scale_center.y)
	self:set_scale(1, 1)

	if true then
		if self.process then
			stop_process(self.process)
		end
		--	self:use_self_target(true)
		self.process = run_process(1, function()
			for i=1,0,-0.125 do
				self:set_scale(i, i)
				yield()
			end
			self:set_scale(1,1)
			self:show(false)
			--		self:use_self_target(false)
		end)
	else
		self:show(false)
	end

	if self.on_closed then
		self:on_closed()
	end
end

function menu:add_item(win)
   local height = win:get_height()
   win:set_parent(self)
   win:set_pos(left_space, self.current_pos)
   self.current_pos = self.current_pos + height + line_space
   self:set_height(self.current_pos + bottom_space - line_space)
   table.insert(self.__btns, win)
   return win
end

function menu:add_text_item(text, onEvent)
   local btn = puppy.gui.pButton()
   btn:set_text(text)
   btn:init_style(menu_text_button_style)
   btn:set_width(100)

   btn:add_listener("ec_mouse_left_down", function(e)
					     onEvent(e)
					     self:close()
				  end)
   btn:add_listener("ec_mouse_in", function(e)
				      if self.opened_submenu then
					 self.opened_submenu:close()
					 self.opened_submenu = nil
				      end
				   end)
   return self:add_item(btn)
end

function menu:add_separate()
   local line = puppy.gui.pWindow()
   line:init_style(menu_separate_style)
   line:set_width(100)
   return self:add_item(line)
end

function menu:add_sub_menu(text, menu)
   local btn = puppy.gui.pButton()
   btn:set_text(text)
   btn:init_style(menu_sub_menu_style)
   menu.__parent_menu = self
   btn:add_listener("ec_mouse_in", function(e)
				      if self.opened_submenu ~= memu then
					 self.opened_submenu:close()
				      end
				      menu:set_parent(self)
				      self.opened_submenu = menu
				      menu:open(self:get_width(), btn:get_y())
				   end)
   return self:add_item(btn)
end

__update__ = function(new_module)
	menu:updateObject()
end
