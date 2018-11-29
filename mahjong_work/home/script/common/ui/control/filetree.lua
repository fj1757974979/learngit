filetree = class(puppy.gui.pList)

filetree.init = function(self, full_path)
	self:init_list(full_path)
end

filetree.init_list = function(self, full_path)
	self:set_root_dir(full_path)
end

filetree.set_root_dir = function(self, full_path)
	self:clear_item()

	local arr_filelist = item_wnd.get_filelist(full_path)
	self:set_column_count(1)
	self:show_header(false)

	for k,v in ipairs(arr_filelist) do
		local r = self:insert_row(-1)
		local tempwnd = item_wnd{
			full_path = full_path .. "\\" .. v[1],
			parent_lst = self,
			parent_wnd = nil,
			btn_text = v[1],
			is_dir = v[2],
		}
		self:set_item_wnd(r, 0, tempwnd)
	end
end

--arg = {
--  full_path = ,
--  parent_lst = ,
--  parent_wnd = ,
--	btn_text = ,
--	is_dir = ,
--}

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
	local icon_length = 15
	self.top_lst = arg.parent_lst
	self.is_expand = false
	self.full_path = arg.full_path
	self.arr_parent = {}

	table.insert(self.arr_parent, {arg.parent_lst, arg.parent_wnd})
	if arg.parent_wnd then
		if arg.parent_wnd.arr_parent then
			for _,v in ipairs(arg.parent_wnd.arr_parent) do
				table.insert(self.arr_parent, v)
				self.top_lst = v[1]
			end
		end
	end

	self:load_template{"script/data", "uitemplate/sceneeditor/filetree.lua"}
	self.chk_icon:show(arg.is_dir)
	self.btn_file:set_text(arg.btn_text)
	self.lst_file:set_column_count(1)
	self.lst_file:show_header(false)
	self.lst_file:set_height(0)   --在脚本设置height，则在UI编辑器不用设置height，更方便可视化操作
	self:set_height(icon_length)  --在脚本设置height，则在UI编辑器不用设置height，更方便可视化操作

	self.chk_icon:add_listener("ec_mouse_left_up", function(e) self:mouseclick() end)
	self.btn_file:add_listener("ec_mouse_left_up", function(e) self:mouseclick();self.chk_icon:set_check(self.is_expand) end)
	self.btn_file:add_listener("ec_mouse_left_doubleclick", function(e) self.top_lst:double_click(self.full_path) end)

	self.mouseclick = function()
		self.is_expand = not self.is_expand
		if self.is_expand then
			self.lst_file:show(true)
			local arr_filelist = item_wnd.get_filelist(self.full_path)
			for _,v in ipairs(arr_filelist) do
				local r = self.lst_file:insert_row(-1)
				local tempwnd = item_wnd{
					full_path = self.full_path .. "\\" .. v[1],
					parent_lst = self.lst_file,
					parent_wnd = self,
					btn_text = v[1],
					is_dir = v[2],
				}
				self.lst_file:set_item_wnd(r, 0, tempwnd)
			end
			self.lst_file:set_height(self.lst_file:get_content_height())
		else
			self.lst_file:clear_item()
			self.lst_file:show(false)
			self.lst_file:set_height(0)
		end
		self:set_height(self.lst_file:get_height() + self.btn_file:get_height())

		if #self.arr_parent > 0 then
			set_timeout(1, function()
				for _, v in ipairs(self.arr_parent) do
					local parent_lst = v[1]
					local parent_wnd = v[2]
					if parent_lst then
						parent_lst:dirty()
						if parent_wnd then
							parent_lst:set_height(parent_lst:get_content_height())
							parent_wnd:set_height(parent_lst:get_height() + icon_length)
						end
					end
				end
			end)
		end
	end

end

item_wnd.get_filelist = function(full_path)
	local files = win32.GetAllFiles(full_path)
	local sorted_files = {}
	local type_priority = { directory=true,file=false }
	if files then
		for k,v in pairs(files) do
			if k ~= ".svn" and k ~= ".." then
				table.insert( sorted_files, {k,type_priority[v]} )
			end
		end

		table.sort(sorted_files,function(e1,e2)
			if e1[2] and not e2[2] then
				return true
			elseif e1[2] == e2[2] then
				return e1[1]<e2[1]
			else
				return false
			end
		end)
	end

	return sorted_files
end

to_filetree = function(lst_instance, full_path)
	class_cast(filetree, lst_instance)
	filetree.init(lst_instance, full_path)
end
