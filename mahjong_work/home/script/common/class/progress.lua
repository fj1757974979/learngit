pProgress.start_process = function(self, total_second, is_converse)
	self._is_processing = true
	self._is_converse = is_converse
	self._total_process_frame = total_second*FRAMES_PER_SECOND
	self:set_range(self._total_process_frame)
	if self._is_converse then
		self:pos_to(self._total_process_frame)
	else
		self:pos_to(0)
	end
	self._process_timer = set_interval(1, function() self:on_process() end)
end

pProgress.on_process = function(self)
	if not self._is_processing then return end
	local cur_frame = self:get_pos()
	if self._is_converse then
		cur_frame = cur_frame - 1
		if cur_frame <= 0 then
			self:pos_to(0)
			self:stop_process()
			return
		end
		self:pos_to(cur_frame)
		
	else
		cur_frame = cur_frame+1
		
		if cur_frame >= self._total_process_frame then
			self:pos_to(self._total_process_frame)
			self:stop_process()
			return
		end
		self:pos_to(cur_frame)
	end
end

pProgress.stop_process = function(self)
	if not self._process_timer then return end
	self._process_timer:stop()
	self._process_timer = nil
end

pProgress.set_cur_process = function(self, cur_second)	
	if not self._total_process_frame then return end
	local cur_frame = cur_second*FRAMES_PER_SECOND
	if cur_frame >= self._total_process_frame then
		self:stop_process()
		cur_frame = self._total_process_frame
	end
	if self._is_converse then
		self:pos_to(self._total_process_frame - cur_frame)
	else
		self:pos_to(cur_frame)
	end
end

pProgress.getTexturePath = function(self)
	return self:getSelfPicture():getTexturePath()
end

pProgress.setImage = function(self, image)
	self:getSelfPicture():setTexturePath(image)
end

pProgress.setColor = function(self, color)
	pWindow.setColor(self, color)
	self:setFillColor(color)
end

pProgress.setXSplit = function(self, flag)
	self:getPictureControl():setXSplit(flag)
	self:getSelfPicture():setXSplit(flag)
	--self:getFillPicture():setXSplit(flag)
end

pProgress.setYSplit = function(self, flag)
	self:getPictureControl():setYSplit(flag)
	self:getSelfPicture():setYSplit(flag)
	--self:getFillPicture():setYSplit(flag)
end

pProgress.setSplitSize = function(self, size)
	self:getPictureControl():setSplitSize(size)
	self:getSelfPicture():setSplitSize(size)
	--self:getFillPicture():setSplitSize(size)
end

pProgress.fromTable = function(self, conf, root)
	pWindow.fromTable(self, conf, root)
	if conf.fillImage ~= nil then
		self:getFillPicture():setTexturePath(conf.fillImage)
		self:getVirPicture():setTexturePath(conf.fillImage)
	end

	if conf.overImage ~= nil then
		self:getOverPicture():setTexturePath(conf.overImage)
	end
end

pProgress.toTable = function(self)
	local t = pWindow.toTable(self)
	if not t then return end
	t.fillImage = self:getFillPicture():getTexturePath()
	t.overImage = self:getOverPicture():getTexturePath()
	return t
end

__init__ = function(module)
end
