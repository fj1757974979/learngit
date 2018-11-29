bar = class( puppy.gui.pWindow )

bar.init = function(self, parent, vertical, x, y)
	if parent then
		self:set_parent(parent)
	end
	self:show_self(false)

	self._wnd_list={}
	self:add_listener("ec_size_change",function(e)
		if e:target()==self or e:target():get_parent()==self then
			--println("bar update")
			self:update()
		end
	end)
	
	self._vertical = vertical
	self._start_x = x or 0
	self._start_y = y or 0
end

bar.get_control = function(self, i)
	return self._wnd_list[i]
end

bar.add_control = function(self, control)
	control:set_parent(self)
	table.insert(self._wnd_list,control)
	self:update()
	return control
end

bar.add_button = function(self, btn, text)
	if type(btn)=="table" then
		btn:set_parent(self)
		table.insert(self._wnd_list,btn)
	elseif type(btn)=="string" then
		local text=text or btn
		btn = puppy.gui.pButton:new()
		btn:set_parent(self)
		btn:init_style("blue_button_2")
		
		btn:set_line_wrap(false)
		--btn:auto_set_width(true)
		--btn:auto_set_height(true)
		--btn:set_layout_info("w=")
		btn:set_size(100, 25)
		btn:set_text(text)
		table.insert(self._wnd_list,btn)
	end
	
	self:update()
	return btn
end

bar.add_label = function(self, lab)
	if type(lab)=="table" then
		lab:set_parent(self)
		table.insert(self._wnd_list,lab)
	elseif type(lab)=="string" then
		local text=lab
		lab = puppy.gui.pWindow:new()
		lab:set_parent(self)
		
		lab:set_line_wrap(false)
		lab:auto_set_width(true)
		lab:auto_set_height(true)
		lab:set_text(text)
		table.insert(self._wnd_list,lab)
	end
	
	self:update()
	return lab
end

bar.update = function(self)
	if self._vertical then
		local y = self._start_y
		local x = self._start_x
		for k, wnd in ipairs(self._wnd_list) do
			if y > self:get_height() - 10 then
				y = self._start_y
				x = x + wnd:get_width() + 3
			end
			wnd:set_pos(x,y)
			y = y+wnd:get_height()
		end
	else
		local x = self._start_x
		for k, wnd in ipairs(self._wnd_list) do
			wnd:set_pos(x,self._start_y)
			x = x+wnd:get_width()+2
		end
	end
end
