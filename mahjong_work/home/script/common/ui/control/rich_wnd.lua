
-- rich_wnd，只读，带滚动条，用于显示长文字的窗口，比如聊天框
-- 相对于现有的edit控件，rich_wnd以效率为最高追求，舍弃了一些复杂的功能
local event = import("common/event.lua")

rich_wnd = class(puppy.gui.pWindow)

rich_wnd.init = function(self, parent, arg)
	self.event_source = event.event_source()
	self:set_parent(parent)
	self:get_image_list(puppy.gui.ip_window):clear_image()
	-- self:clip_draw(true)

	self.create_arg = arg

	self._content_list = {}
	self._content_info = {
		["range"] = 0,
		["pos"] = 0,
		["max_pos"] = 0,
	}
	
	self.client_offset_x = 0
	self._wnd_in_use = {}
	self._wnd_unused = {}
	self._wnd_cache = {}

	self.scroll_bar = puppy.gui.scrollbar:new()
	self.scroll_bar:set_parent(self)
	--self.scroll_bar:set_width( 10 )
	self.scroll_bar:init_style("blue_scrollbar_1")
	
	self:add_listener("ec_mouse_wheel", function(e)
		local delta_pos = (e:z() < 0 and 1 or -1)*20
		self:scroll_pos(delta_pos)

		--self.event_source:fire_event("pos_change_by_player", self._content_info.pos, self._content_info.max_pos)
		if self._content_info.pos >= self._content_info.max_pos then
			self:pos_lock( false )
		else
			self:pos_lock( true )
		end
	end)

	self.scroll_bar:add_listener("ec_scrollbar_pos_change", function(e)
		if self._on_update_pos then
			return
		end

		local pos = self.scroll_bar:get_pos()
		self:pos_to(pos, true)
		
		--self.event_source:fire_event("pos_change_by_player", self._content_info.pos, self._content_info.max_pos)
		if self._content_info.pos >= self._content_info.max_pos then
			self:pos_lock( false )
		else
			self:pos_lock( true )
		end
	end)

	self:add_listener("ec_size_change", function(e)
		if e:target() ~= self then return end

		local page_size = self:get_height()
		local max_pos = self._content_info.range - page_size

		self:set_content_info{
			["max_pos"] = max_pos,
			["page_size"] = page_size,
		}

		self:pos_to(self._content_info.pos)
	end)
end

rich_wnd.set_text = function(self, text)
	if text == "" then
		self._content_list = {}
		self:add_text("")
	end
end

rich_wnd.clear_wnd_inuse = function(self)
	-- 在重新筛选窗口之前调用
	-- 先把上次in_use的放到cache列表内，这是因为在滚动小范围的时候，大多数窗口都是重复显示的
	-- 这样大多数这样的窗口都能优先在cache里找到，提高效率
	self._wnd_cache = self._wnd_in_use
	self._wnd_in_use = {}
end

rich_wnd.clear_wnd_cache = function(self)
	-- 在筛选完窗口之后调用
	-- 这时候还在cache里面的窗口，已经是不需要显示的了，所以把它们都放回unused列表中
	for _, wnd in pairs(self._wnd_cache) do
		wnd:show(false)
		table.insert(self._wnd_unused, wnd)
	end

	self._wnd_cache = {}
end

rich_wnd.get_wnd_to_use = function(self, index)
	-- 先在cache列表里面找
	if self._wnd_cache[index] then
		local wnd = self._wnd_cache[index]
		self._wnd_cache[index] = nil
		return wnd
	end

	-- 然后再在unused列表里找
	if #self._wnd_unused <= 0 then
		local wnd = self:create_sub_wnd()
		table.insert(self._wnd_unused, wnd)
	end
	
	return table.remove(self._wnd_unused)
end

-- 获取客户区域宽度，因为还需要放一个滑动条
rich_wnd.get_client_width = function(self)
	return self:get_width() - self.scroll_bar:get_width()
end

-- 创建用于显示文字的子窗口
rich_wnd.create_sub_wnd = function(self)
	local wnd = puppy.gui.pWindow:new(self)
	wnd:get_image_list(puppy.gui.ip_window):clear_image()
	wnd:auto_set_height(true)
	wnd:set_line_wrap(true)
	wnd:set_width(self:get_client_width())
	
	if self.create_arg.on_create_sub_wnd then
		self.create_arg.on_create_sub_wnd(wnd)
	end

	return wnd
end

-- 在content信息改变的时候，滑动条需要更新一次，这个时候仅是改变滑动条位置，不需要再触发滑动条的事件
rich_wnd.on_content_info_change = function(self, change_info)
	self._on_update_pos = 1
	self.scroll_bar:set_range(self._content_info.range)
	self.scroll_bar:scroll_to(self._content_info.pos)
	self.scroll_bar:set_page_size(self._content_info.page_size)
	self._on_update_pos = nil
end

rich_wnd.set_content_info = function(self, change_info, no_fire_change)
	for k, v in pairs(change_info) do
		self._content_info[k] = v
	end
	
	if not no_fire_change then
		self:on_content_info_change(change_info)
	end
end

rich_wnd.get_content_info = function(self)
	return self._content_info
end

rich_wnd.is_pos_end = function(self)
	return self._content_info.pos >= self._content_info.max_pos
end

rich_wnd.insert_text = function(self, pos, text)
	self:add_text(text)
end

rich_wnd._calc_text_height = function(self, text)
	if not self.refer_wnd then
		-- 参照窗口，用来获取每条信息占的区域的宽高
		-- 需要注意的是：参照窗口在第一次创建的时候，宽度已经定死了
		self.refer_wnd = self:create_sub_wnd()
		self.refer_wnd:show(false)
	end

	self._wnd_height_cache = self._wnd_height_cache or {}

	local h = self._wnd_height_cache[text]
	if not h then
		self.refer_wnd:set_text(text)
		h = self.refer_wnd:get_height()
		self._wnd_height_cache[text] = h
	end

	return h
end

-- 只往最后一行输入
rich_wnd.add_text = function(self, text)
	local h = self:_calc_text_height(text)
	-- off表示新加内容的插入y值
	local off = 0

	if #self._content_list > 0 then
		local last_content = self._content_list[#self._content_list]
		off = last_content.offset + last_content.height
	end

	-- 记下这段内容的信息
	table.insert(self._content_list, {
		["text"] = text,
		["width"] = self.refer_wnd:get_width(),
		["height"] = h,
		["offset"] = off,
	})

	-- 更新一下相关的信息
	local range = off + h - self._content_list[1].offset
	
	local page_size = self:get_height()
	local max_pos = math.max(0, range - page_size)
	
--	log("error", range, page_size, max_pos)

	self:set_content_info{
		["range"] = range,
		["max_pos"] = max_pos,
		["page_size"] = page_size,
	}
	
	if not self._pos_lock then
		self:pos_end()
	end
end

rich_wnd.add_text_list = function(self, text_list)
	if #text_list <= 0 then return end

	local w, h
	local off = 0

	for i = 1, #text_list - 1 do
		local text = text_list[i]
		h = self:_calc_text_height(text)
		w = w or self.refer_wnd:get_width()

		table.insert(self._content_list, {
			["text"] = text,
			["width"] = self.refer_wnd:get_width(),
			["height"] = h,
			["offset"] = off,
		})

		off = off + h
	end

	self:add_text(text_list[#text_list])
end

-- 位置滚动到最底
rich_wnd.pos_end = function(self)
	self:pos_to(self._content_info.max_pos)
end

-- 滚动，传入相对位移
rich_wnd.scroll_pos = function(self, inc)
	self:pos_to(self._content_info.pos + inc)
end

rich_wnd.pos_lock = function(self, is_lock)
	self._pos_lock = is_lock
end

-- 在改变当前显示位置的时候，重新刷新当前可见的窗口，并显示之
-- no_fire_change的意义：由调用pos_to函数驱动滑动条位置改变，所以如果pos_to是从滑动条发起的，则设置no_fire_change标记
rich_wnd.pos_to = function(self, pos, no_fire_change)
	if #self._content_list <= 0 then
		return
	end

	pos = math.max(0, pos)
	pos = math.min(pos, self._content_info.max_pos)
	
	local bgn_index = 1
	local bgn_offset = 0

	-- 因为self._content_list[1].offset并不一定为0（在content条目太多的时候，会从头删掉一些），所以要加上base_pos得到的real_pos
	-- 用这个real_pos作为显示的起点来筛选窗口
	local base_pos = self._content_list[1].offset
	local real_pos = base_pos + pos

	-- 通过二分法，查找到开始显示的内容
	local find = false

	local s, e = 1, #self._content_list

	while s <= e do
		local m = math.floor((s+e)/2)
		local content = self._content_list[m]

		if content.offset <= real_pos and content.offset + content.height >= real_pos then
			bgn_index = m
			bgn_offset = real_pos - content.offset
			break
		end

		if content.offset > real_pos then
			e = m - 1
		elseif content.offset + content.height < real_pos then
			s = m + 1
		end
	end

	self:set_content_info({
		["pos"] = pos,
	}, no_fire_change)

	-- bgn_index表示从第n个content开始显示
	-- bgn_offset表示从这个窗口的bgn_offset像素的位置开始显示
	self:update_content_wnd(bgn_index, bgn_offset)
end

rich_wnd.update_content_wnd = function(self, begin_index, pos_offset)
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
			
			self:_update_content_wnd(info[1], info[2])
		end)
	end
end

-- 从第begin_index个窗口的偏移pos_offset的位置开始显示
rich_wnd._update_content_wnd = function(self, begin_index, pos_offset)
	if not self._content_list[begin_index] then return end
		
	self:clear_wnd_inuse()
	
	local index = begin_index
	local offset = pos_offset
	local y = 0

	while index <= #self._content_list do
		local content = self._content_list[index]
		local wnd = self:get_wnd_to_use(index)
		wnd:set_width(self:get_client_width())

		wnd:set_text(content.text)
		wnd:show(true)

		local h = wnd:get_height()
		y = y - h*offset/content.height

		wnd:set_pos(0+self.client_offset_x, y)
		self._wnd_in_use[index] = wnd

		y = y + h
		offset = 0
		index = index + 1
		
		if y > self:get_height() then
			break
		end
	end
	
	self:clear_wnd_cache()
end

rich_wnd.set_scroll_bar_style = function(self, style )
	self.scroll_bar:init_style(style)
end

rich_wnd.set_client_offset_x = function( self, x )
	self.client_offset_x = x
end
