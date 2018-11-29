
-- simple_list��û��ͷ�����⣬��֧��ˮƽ��������֧���Զ����ø߶ȣ���֧�ֵ�������ĳһЩ��
-- ֧�ֶ�����ʾ��֧��ÿ�й̶��߶ȣ����߸��ݸ�����ߴ�������Ӧ�߶ȣ�֧�ִ������������ѡ�й��ܣ�ʵ�����и���/ѡ��Ч����ֻ֧�ֵ���ѡ��
local MAX_ROW_NUM = 10000

simple_list = class(puppy.gui.pWindow)

simple_list.init = function(self, parent, arg)
	self:set_parent(parent)
	self:get_image_list(puppy.gui.ip_window):clear_image()
	-- self:clip_draw(true)

	self._row_list = {}				-- �����У��洢ÿ�е�����Ϣ���Լ�ÿ����Ҫ��ʾ������
	self._column_info_list = {}		-- ��������Ϣ�������洢ÿ�е���Ϣ

	self._wnd_in_use = {}
	self._wnd_unused = {}
	self._wnd_cache = {}
	
	self._content_info = {
		["range"] = 0,
		["pos"] = 0,
		["page_size"] = 5,
	}

	self._handle_item_mouse_event = false
--	self:insert_column(-1)

	self.scroll_bar = puppy.gui.scrollbar:new()
	self.scroll_bar:set_parent(self)
	self.scroll_bar:init_style("blue_scrollbar_1")
	self.scroll_bar:set_z(-1)

	self.scroll_bar:add_listener("ec_scrollbar_pos_change", function(e)
		if self._on_update_pos then
			return
		end

		local pos = self.scroll_bar:get_pos()
		local range = self.scroll_bar:get_range()
		local row_count = self._max_row_count or math.ceil(h/14)

		local row = math.floor((#self._row_list+row_count-1)*pos/range + 0.5) + 1

--		log("error", "ec_scrollbar_pos_change:", pos, range, #self._row_list, row)
		self:row_to(row)
	end)

	self:add_listener("ec_mouse_wheel", function(e)
		self:scroll_row(e:z() < 0 and 1 or -1)
	end)

	self:add_listener("ec_mouse_in", function(e)
		if not self._handle_item_mouse_event then return end

		self:for_each_visible_item_wnd(function(r, c, item_wnd)
			if e:target() == item_wnd then
				self:on_row_mouseover(r, c, true)
				return true
			end
		end)
	end)
	
	self:add_listener("ec_mouse_out", function(e)
		if not self._handle_item_mouse_event then return end

		self:for_each_visible_item_wnd(function(r, c, item_wnd)
			if e:target() == item_wnd then
				self:on_row_mouseover(r, c, false)
				return true
			end
		end)
	end)
	
	self:add_listener("ec_mouse_left_up", function(e)
--		log("error", "ec_mouse_left_up")
		if not self._handle_item_mouse_event then return end

		self:for_each_visible_item_wnd(function(r, c, item_wnd)
			if e:target() == item_wnd then
				if (not self._last_selected_row) or self._last_selected_row ~= r then
					if self._last_selected_row then
						self:on_row_selected(self._last_selected_row, c, false)
					end

					log("error", "select:", r)
					self._last_selected_row = r
					self:on_row_selected(r, c, true)
				end
				
				return true
			end
		end)
	end)
end

------------------------------------------------------------
-- �ӿ�
simple_list.set_row_interval = function(self, i)
	self._row_interval = i
end

simple_list.handle_item_mouse_event = function(self, set)
	self._handle_item_mouse_event = set
end

simple_list.clear_item = function(self)
	self._row_list = {}
	self:_update_row_wnd(1, 0)
end

simple_list.insert_column = function(self, column_width)
	table.insert(self._column_info_list, {
		width = column_width,
	})
end

simple_list.insert_row = function(self, insert_index)
	if insert_index < 0 then
		insert_index = math.max(1, #self._row_list + 2 + insert_index)
	end

	table.insert(self._row_list, insert_index, {
		item_list = {},			-- ÿ�е������б�
		auto_height = false,	-- �Զ����ø߶ȣ�Ĭ�Ϲ�
		auto_width = false,		-- �Զ����ÿ�ȣ���ָÿ�еĴ��ڶ����ó����п���ͬ
		height = 14,			-- ÿ�й̶��ĸ߶ȣ�Ĭ��14
	})

	return insert_index
end

-- ����ĳһ�е�����
simple_list.set_row_prop = function(self, row, prop)
	local row_info = self._row_list[row]
	if row_info then
		for k, v in pairs(prop) do
			row_info[k] = v
		end
		
		return true
	end
	
	return false
end

simple_list.get_top_row = function(self)
	return self._top_row or 1
end

simple_list.get_row_prop = function(self, row, key)
	local row_info = self._row_list[row]
	if row_info then
		return row_info[key]
	end
end

simple_list.get_row_count = function(self)
	return #self._row_list
end



-- ע�⣬����������һ����������ֱ�Ӵ�wnd�����Ǵ�һ��create wnd�ĺ�����������Ϊ��Ҫ��̬����wnd
simple_list.set_item_wnd = function(self, row, col, func_create_wnd, ... )
	local row_info = self._row_list[row]
	if row_info then
		row_info.item_list[col] = row_info.item_list[col] or {
			off_x = 0,	-- ֧������x/yƫ��
			off_y = 0,
		}
		
		local item_info = row_info.item_list[col]

		item_info.func_create = func_create_wnd
		item_info.create_arg = {...}
		
		return true
	end
	
	return false
end

simple_list.set_item_prop = function(self, row, col, prop)
	local row_info = self._row_list[row]
	if row_info then
		if row_info.item_list[col] then
			for k, v in pairs(prop) do
				row_info.item_list[col][k] = v
			end
		end
	end
end

simple_list.scroll_row = function(self, delta_row)
	if self._top_row then
		self:row_to(self._top_row + delta_row)
	end
end

-- ����ĳһ��
simple_list.row_to = function(self, row, immediately_to)
	row = math.min(#self._row_list, row)
	row = math.max(1, row)

	if immediately_to then
		self:_update_row_wnd(row, 0)
	else
		self:update_row_wnd(row, 0)
	end
end

simple_list.refresh_show = function(self)
	self:_update_row_wnd(self._top_row or 1, 0)
end

simple_list.on_content_info_change = function(self, change_info)
	local range = self.scroll_bar:get_range()
	local pos = self.scroll_bar:get_pos()
	local page_size = self.scroll_bar:get_page_size()
	local row_count = self._max_row_count or math.ceil(h/14)

	local old_row = math.floor((#self._row_list+row_count-1)*pos/range + 0.5) + 1
	local new_row = math.floor((#self._row_list+row_count-1)*self._content_info.pos/self._content_info.range + 0.5) + 1

--	logv("error", "on_content_info_change:", change_info, old_row, new_row, page_size)
	
	if old_row ~= new_row or self._content_info.page_size ~= page_size or self._content_info.range ~= range then
		self._on_update_pos = 1
		self.scroll_bar:set_range(self._content_info.range)
		self.scroll_bar:scroll_to(self._content_info.pos)
		self.scroll_bar:set_page_size(self._content_info.page_size)
		self._on_update_pos = nil
	end
end

simple_list.set_content_info = function(self, change_info, no_fire_change)
	for k, v in pairs(change_info) do
		self._content_info[k] = v
	end
	
	if not no_fire_change then
		self:on_content_info_change(change_info)
	end
end

simple_list.for_each_visible_item_wnd = function(self, func)
	for key, wnd in pairs(self._wnd_in_use) do
		local r = math.floor(key/MAX_ROW_NUM) + 1
		local c = math.mod(key, MAX_ROW_NUM)

		if func(r, c, wnd) then
			break
		end
	end
end

simple_list.is_row_visible = function(self, row)
	for key, wnd in pairs(self._wnd_in_use) do
		local r = math.floor(key/MAX_ROW_NUM) + 1
		
		if r == row then
			return true
		end
	end
	
	return false
end

simple_list.get_item_wnd = function(self, row, col)
	local key = (row-1)*MAX_ROW_NUM + col
	return self._wnd_in_use[key]
end

simple_list.get_selected_row = function(self)
	return self._last_selected_row
end

------------------------------------------------------------
-- �ڲ�����

simple_list.on_row_mouseover = function(self, row, col, is_mouseover)
--	log("error", "on_row_mouseover", row, col, is_mouseover)
	if self._last_selected_row and self._last_selected_row == row then
		return
	end

	self:for_each_visible_item_wnd(function(r, c, item_wnd)
		if r == row then
			item_wnd:set_cur_image_list(is_mouseover and puppy.gui.ip_mouseover or puppy.gui.ip_window)
		end
	end)
end

simple_list.on_row_selected = function(self, row, col, is_selected)
--	log("error", "on_row_selected", row, col, is_selected)
	self:for_each_visible_item_wnd(function(r, c, item_wnd)
		if r == row then
			item_wnd:set_cur_image_list(is_selected and puppy.gui.ip_selected or puppy.gui.ip_window)
		end
	end)
end

-- wnd:���ܿ����ظ����õ�wnd���������wnd�϶����ɺ���������������
simple_list.default_create_wnd = function(self, parent, wnd)
	if not wnd then
		wnd = puppy.gui.pWindow:new()
		wnd:set_parent(parent)
		wnd:get_image_list(puppy.gui.ip_window):clear_image()
	end

	return wnd
end

simple_list.clear_wnd_inuse = function(self)
	-- ������ɸѡ����֮ǰ����
	-- �Ȱ��ϴ�in_use�ķŵ�cache�б��ڣ�������Ϊ�ڹ���С��Χ��ʱ�򣬴�������ڶ����ظ���ʾ��
	-- ��������������Ĵ��ڶ���������cache���ҵ������Ч��
	self._wnd_cache = self._wnd_in_use
	self._wnd_in_use = {}
end

simple_list.clear_wnd_cache = function(self)
	-- ��ɸѡ�괰��֮�����
	-- ��ʱ����cache����Ĵ��ڣ��Ѿ��ǲ���Ҫ��ʾ���ˣ����԰����Ƕ��Ż�unused�б���
	for _, wnd in pairs(self._wnd_cache) do
		wnd:show(false)
		table.insert(self._wnd_unused, wnd)
	end

--	log("error", "clear_wnd_cache:", #self._wnd_unused)
	self._wnd_cache = {}
end

simple_list.get_wnd_to_use = function(self, index, func_create_wnd, create_arg )
	-- ����cache�б�������
	if self._wnd_cache[index] then
--		log("error", "find in cache:", index)
		local wnd = self._wnd_cache[index]
		self._wnd_cache[index] = nil
		return wnd
	end

	func_create_wnd = func_create_wnd or function(...) return self:default_create_wnd(...) end

	local wnd = nil
	-- Ȼ������unused�б�����
	if #self._wnd_unused <= 0 then
--		log("error", "create new:", index)
		wnd = func_create_wnd(self, nil, unpack(create_arg))
		wnd._create_func = func_create_wnd
	else
		wnd = table.remove(self._wnd_unused)
		wnd:show(true)
		
		local new_wnd = func_create_wnd(self, wnd._create_func == func_create_wnd and wnd or nil, unpack(create_arg))
		new_wnd._create_func = func_create_wnd


		if new_wnd ~= wnd then
--			log("error", "create new2222:", index)
			wnd:set_parent(nil)
			wnd = new_wnd
		end

--		log("error", "reset new:", index)
	end
	
	wnd.refresh_parent_list = wnd.refresh_parent_list or function(wnd)
		self:refresh_show()
	end

	return wnd
end

simple_list.update_content_info = function(self)
	local h = self:get_height()
	local row_count = self._max_row_count or math.ceil(h/14)
	local t_row = self._top_row or 1

	local i = 20

	self:set_content_info({
		range = (#self._row_list+row_count-1)*i,
		pos = (t_row-1)*i,
		page_size = row_count*i,
	})
end

simple_list.update_select_info = function(self)
	if self._last_selected_row then
		local found_row = false
		for key, _ in pairs(self._wnd_in_use) do
			local row = math.floor(key/MAX_ROW_NUM) + 1
			if self._last_selected_row == row then
				found_row = true
			end
		end

		if found_row then
--			self:on_row_selected(self._last_selected_row, 1, true)
		else
			self._last_selected_row = nil
		end
	end
end

simple_list.update_row_wnd = function(self, begin_index, pos_offset)
	self._update_queue = self._update_queue or {}
	table.insert(self._update_queue, {begin_index, pos_offset})

	if not self._timer_update_content_wnd then
		self._timer_update_content_wnd = set_interval(1, function()
			if #self._update_queue <= 0 then
				self._timer_update_content_wnd = nil
				return "release"
			end

			local info = self._update_queue[#self._update_queue]
			self._update_queue = {}
			
			self:_update_row_wnd(info[1], info[2])
		end)
	end
end

-- �ӵ�begin_row�е�����ƫ��pos_offset��ʼ��ʾ
simple_list._update_row_wnd = function(self, begin_row, pos_offset)
--	log("error", "_update_row_wnd:", begin_row, pos_offset, #self._row_list)

	-- �������ʾ��ʱ��û�м���һ�У���Ĭ��Ϊһ��
	if #self._column_info_list <= 0 then
		self:insert_column(-1)
	end
	
	self._top_row = begin_row

	self:clear_wnd_inuse()

	local row = begin_row
	local offset = pos_offset
	local cur_y = 0
	local cur_row_count = 0

	while row <= #self._row_list and row > 0 do
		local row_info = self._row_list[row]

		local max_h = 0
		local cur_x = 0
		for col, col_info in ipairs(self._column_info_list) do
			local item_info = row_info.item_list[col]
			if item_info then
				local key = (row-1)*MAX_ROW_NUM + col
				local wnd = self:get_wnd_to_use(key, item_info.func_create, item_info.create_arg)

				self._wnd_in_use[key] = wnd

				local off_x = item_info.off_x or 0
				local off_y = item_info.off_y or 0
				
				wnd:set_pos(cur_x + off_x, cur_y + off_y)
				
--				logv("error", "wnd:", col, wnd:get_text(), cur_x, cur_y, col_info)
				
				if row_info.auto_width then
					local wnd_width = col_info.width
					if wnd_width == -1 then
						wnd_width = self:get_width() - cur_x
					end

					wnd:set_width(wnd_width)
				end

				max_h = math.max(max_h, off_y + wnd:get_height())
			end

			if col_info.width == -1 then
				cur_x = self:get_width()
			else
				cur_x = cur_x + col_info.width
			end
		end

		cur_row_count = cur_row_count + 1
		
		local cur_height = row_info.auto_height and max_h or row_info.height
		cur_y = cur_y + cur_height
		
		if cur_y > self:get_height() then
			break
		end

		row = row + 1
	end

	self:clear_wnd_cache()
	
	self._max_row_count = self._max_row_count or 0
	self._max_row_count = math.max(self._max_row_count, cur_row_count)
	self._cur_row_count = cur_row_count

	self:update_content_info()
	self:update_select_info()
end
