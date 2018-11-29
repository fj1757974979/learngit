tree_list = class(puppy.gui.pList)

tree_list.init = function(self)
	self:init_list(self)
end

tree_list.init_list = function(self, wnd)
	self.item_wnd = item_wnd{
		btn_text = nil,
		parent_wnd = wnd,
		is_dir = true,
		is_top = true,
	}
end

--arg = {
--	btn_text = ,
--	parent_wnd = ,
--	is_dir = ,
--  is_top = ,
--}

tree_list.add_node = function(self, arg)
	local item_wnd = item_wnd(arg)
	local r = arg.parent_wnd.lst_file:insert_row(-1)
	arg.parent_wnd.lst_file:set_item_wnd(r, 0, item_wnd)
	return item_wnd
end

--每个item_wnd都是一个check_button、一个pButton、一个pList组成的pWindow，pList中的item再嵌套子item_wnd
---------------- ------------------------------------------------
--check_button-- ---------------------pButton---------------------
---------------- ------------------------------------------------

                 ------------------------------------------------
                 -------------------pList(row 1)------------------
				 ------------------------------------------------

                 ------------------------------------------------
                 -------------------pList(row 2)------------------
				 ------------------------------------------------

                 ------------------------------------------------
                 -------------------pList(row 3)------------------
				 ------------------------------------------------

                 ------------------------------------------------
                 -------------------pList(row n)------------------
				 ------------------------------------------------

item_wnd = class(puppy.gui.pWindow)

item_wnd.init = function(self, arg)
	icon_length = 15
	self.is_expand = false
	self.is_top = arg.is_top
	self.parent_list = {}
	self:get_image_list(puppy.gui.ip_normal):clear_image()
	self:set_height(icon_length)

	if arg.is_top then
		self.lst_file = arg.parent_wnd
		self.lst_file:set_column_count(1)
		self.lst_file:show_header(false)
	else
		table.insert(self.parent_list, arg.parent_wnd)
		if arg.parent_wnd.parent_list then
			for _,v in ipairs(arg.parent_wnd.parent_list) do
				table.insert(self.parent_list, v)
			end
		end

		self.chk_icon = puppy.gui.check_button()
		self.chk_icon:set_parent(self)
		self.chk_icon:init_style("~pList适用C")
		self.chk_icon:set_width(icon_length)
		self.chk_icon:set_height(icon_length)
		self.chk_icon:set_pos(0, 0)
		self.chk_icon:show(arg.is_dir)

		self.btn_file = puppy.gui.pButton()
		self.btn_file:set_parent(self)
		self.btn_file:set_height(icon_length)
		self.btn_file:set_pos(icon_length + 3, 0)
		self.btn_file:set_text(arg.btn_text)
		self.btn_file:get_image_list(puppy.gui.ip_window):clear_image()
		self.btn_file:get_image_list(puppy.gui.ip_mouseover):clear_image()
		self.btn_file:get_image_list(puppy.gui.ip_clickdown):clear_image()
		self.btn_file:set_text_color(puppy.gui.ip_window, 0xff000000, 0)
		self.btn_file:set_text_color(puppy.gui.ip_mouseover, 0xff999999, 0)
		self.btn_file:set_text_color(puppy.gui.ip_clickdown, 0xff000000, 0)

		self.lst_file = puppy.gui.pList()
		self.lst_file:set_parent(self)
		self.lst_file:set_pos(icon_length + 3, icon_length)
		self.lst_file:set_column_count(1)
		self.lst_file:show_header(false)
		self.lst_file:set_height(0)
		self.lst_file:show(false)
		self.lst_file:get_image_list(puppy.gui.ip_normal):clear_image()

		self.chk_icon:add_listener("ec_mouse_left_up", function(e) self:mouseclick() end)
		self.btn_file:add_listener("ec_mouse_left_up", function(e) self:mouseclick();self.chk_icon:set_check(self.is_expand) end)
		self.btn_file:add_listener("ec_mouse_left_doubleclick", function(e) self:doubleclick() end)

		self.mouseclick = function()
			self.is_expand = not self.is_expand
			if self.is_expand then
				self.lst_file:set_height(self.lst_file:get_content_height())
				self.lst_file:show(true)
			else
				self.lst_file:set_height(0)
				self.lst_file:show(false)
			end
			self:set_height(self.lst_file:get_height() + self.btn_file:get_height())

			if #self.parent_list > 0 then
				set_timeout(1, function()
					for _, v in ipairs(self.parent_list) do
						if v.lst_file then
							v.lst_file:dirty()
							if not v.is_top then
								v.lst_file:set_height(v.lst_file:get_content_height())
								v:set_height(v.lst_file:get_height() + icon_length)
							end
						end
					end
				end)
			end
		end
	end
end

to_tree_list = function(lst_instance)
	class_cast(tree_list, lst_instance)
	tree_list.init(lst_instance)
end
