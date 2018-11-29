local modEvent = import("common/event.lua")
local modSimpleList = import("simple_list.lua")


rich_list = rich_list or class( modSimpleList.simple_list )

rich_list.destroy = function(self)

end

__update__ = function(self)
	rich_list:updateObject()
end 


rich_list.init = function(self, ...)
	self.EventSource = modEvent.EventSource()
	modSimpleList.simple_list.init(self, ...)

	self:handle_item_mouse_event(true)
	
	self._node_list = {
		["root"] = {},
	}

	self:set_row_interval(4)
	self:insert_column(20)
	self:insert_column(-1)
end

rich_list.clear_node = function(self)
	self._node_list = {
		["root"] = {},
	}

	self:_update_node_wnd()
end

rich_list.expand_all = function(self, expand)
	for node_id, node_info in pairs(self._node_list) do
		node_info.expand = expand
	end

	self:_update_node_wnd()
end

--arg = {
--	id = ,		id，一定要存在
--	text = ,	显示内容，没有则取id
--	p_id = ,	父id，默认为nil
--	index = ,	插入位置，默认-1
--	is_dir = ,	是否是文件夹（是否包含子列表），默认值nil
--	select = ,	是否默认选中，默认值nil
--	item_wnd = ,窗口对象
--}

rich_list.add_node = function(self, arg)
	assert(arg.id, "一定要传id")

	arg.p_id = arg.p_id or "root"
	local parent_node = self._node_list[arg.p_id]
	if not parent_node then return false end
	
	arg.index = arg.index or -1
	local insert_type = arg.index > 0 and "front" or "back"	-- insert位置这个，先不支持寻址insert了，因为实际应用中只有往最前或最后insert两种情况
	
	--已存在结点 就更新
	if self._node_list[arg.id] then
		local node_info = self._node_list[arg.id] 
		node_info.id = arg.id
		node_info.create_arg = arg
		node_info.parent_node = parent_node
	else
		--新结点就创建结点
		local node_info = {
			id = arg.id,
			create_arg = arg,
			parent_node = parent_node,
		}
		
		
		self._node_list[arg.id] = node_info
    	
		if not parent_node.last_child then
			parent_node.first_child = node_info
			parent_node.last_child = node_info
		else
			if insert_type == "front" then
				parent_node.first_child.prev_node = node_info
				node_info.next_node = parent_node.first_child
				parent_node.first_child = node_info
			else
				parent_node.last_child.next_node = node_info
				node_info.prev_node = parent_node.last_child
				parent_node.last_child = node_info
			end
		end
	end

	if not arg.no_update_show then
		self:_update_node_wnd()
	end
end

rich_list.del_node = function(self, id)
	local node_info = self._node_list[id]
	if not node_info then return end
	
	-- 从兄弟节点链摘下
	if node_info.prev_node then
		node_info.prev_node.next_node = node_info.next_node
	end
	
	if node_info.next_node then
		node_info.next_node.prev_node = node_info.prev_node
	end
	
	-- 从父节点摘下
	if node_info.parent_node then
		if node_info.parent_node.first_child == node_info then
			node_info.parent_node.first_child = node_info.next_node
		end

		if node_info.parent_node.last_child == node_info then
			node_info.parent_node.last_child = node_info.prev_node
		end
	end
	self._node_list[id] = nil
	
	if node_info.parent_node.last_node == nil then
		self:del_node( node_info.parent_node.id )
	end

	self:_update_node_wnd()
end

-- 子类可以重写此俩函数，实现各种显示效果
rich_list.create_icon_wnd = function(parent, wnd, self, node_info)
	if not wnd then
		wnd = puppy.gui.check_button:new()
		wnd:set_parent(parent)
		wnd:init_style("node_check_button_1")
		
		wnd:add_listener("ec_select_change", function(e)
			local node = wnd.node_info
			if node then
				node.expand = wnd:is_checked()
				self:_update_node_wnd()
			end
		end)
	end

	wnd.node_info = node_info
	wnd:only_check(node_info.expand)
	return wnd
end

rich_list.create_text_wnd = function(parent, wnd, self, node_info)
	if not wnd then
		wnd = puppy.gui.pWindow:new()
		wnd:set_parent(parent)
		wnd:get_image_list(puppy.gui.ip_window):clear_image()
		wnd:set_height(15)
		wnd:set_font_size( 12 )
		
		wnd:add_listener("ec_mouse_left_up", function()
			local node = wnd.node_info
			if node then
				self.EventSource:fire_event("select_node", node.id, node.create_arg)
			end
		end)
		
		local image_list = wnd:create_image_list(puppy.gui.ip_mouseover)
		image_list:add_image("", "clear w=100% h=100%", 0, 0, -1, -1, 0xccff0000)
		
		local image_list = wnd:create_image_list(puppy.gui.ip_selected)
		image_list:add_image("", "clear w=100% h=100%", 0, 0, -1, -1, 0x66ff0000)
		
		wnd:set_common_click_event()
	end

	wnd.node_info = node_info

	local arg = node_info.create_arg
	wnd:set_text(arg.text or arg.id)
	
	if arg.on_item_wnd_create then
		arg.on_item_wnd_create(wnd)
	end

	if arg.font_info then
		wnd:set_font(unpack(arg.font_info))
	end

	if arg.text_color then
		wnd:set_text_color(unpack(arg.text_color))
	end

	return wnd
end

rich_list.update_node_wnd = function(self)
	self:_update_node_wnd()
end

rich_list._update_node_wnd = function(self)
	local top_row = self:get_top_row()

	self:clear_item()
--	logv("error", "_update_node_wnd:", self._node_list["root"])

	local off_x = 0
	local add_node_wnd = nil
	add_node_wnd = function(node_id)
		local node_info = self._node_list[node_id]

		if not node_info then return end

		-- 先加node自己, root不算
		if node_id ~= "root" then
			local r = self:insert_row(-1)
        	
			if node_info.create_arg.is_dir then
--				self:set_item_wnd(r, 1, function(...) return self:create_icon_wnd(node_info, ...) end)
--				self:set_item_wnd(r, 2, function(...) return self:create_text_wnd(node_info, ...) end)
				self:set_item_wnd(r, 1, self.create_icon_wnd, self, node_info)
				self:set_item_wnd(r, 2, self.create_text_wnd, self, node_info)

				self:set_item_prop(r, 1, { off_x = off_x, no_select = true, })
				self:set_item_prop(r, 2, { off_x = off_x, })
			else
--				self:set_item_wnd(r, 1, function(...) return self:create_text_wnd(node_info, ...) end)
				self:set_item_wnd(r, 1, self.create_text_wnd, self, node_info)
				self:set_item_prop(r, 1, { off_x = off_x, })
			end
			
			-- 设置行属性
			self:set_row_prop(r, { auto_height = true, })
		end

		-- 再加node的所有child node
		if node_id == "root" or node_info.expand then
			local child = node_info.first_child

			if node_id ~= "root" then
				off_x = off_x + 20
			end
			
			while child do
				add_node_wnd(child.id)
				
				child = child.next_node
			end
			
			if node_id ~= "root" then
				off_x = off_x - 20
			end
		end
	end
	
	add_node_wnd("root")

	self:row_to(top_row, true)
--	self:refresh_show()
end
