image_text = image_text or class(puppy.gui.pWindow)

local color_to_path =
{
	["blue"] = "fight/number/1/",
	["green"] = "fight/number/2/",
	["orange"] = "fight/number/3/",
	["red"] = "fight/number/4/",
}

image_text.init = function(self, parent, color)
	self:set_parent(parent)
	self:disable_event()
	self.color = color or 1
end

image_text.set_text = function(self, text, color, in_width, width, height, scale)
	color = color or self.color
	self:get_image_list(puppy.gui.ip_window):clear_image()
	local char_width = width or 35
	local char_height = height or 35
	local char_x = in_width or 23
	local char_list = string.get_char_list(text)
	self._width = #char_list*char_x
	for i, char in pairs(char_list) do
		local path = string.format("fight/number/%d/%s.fsi", color, char)
		local layout = string.format("clear x=%d y=0 w=%d h=%d", char_x*(i-1), char_width, char_height)
		self:get_image_list(puppy.gui.ip_window):add_image({"ui", path}, layout, 0,0,-1,-1, 0xFFFFFFFF)
	end
	self:image_dirty()
	if scale then
		self:set_scale(scale, scale)
	end
end

image_text.get_width = function(self)
	return self._width
end

image_text.destroy = function(self)
	puppy.gui.pWindow.destroy(self)
end

__update__ = function(self)
	image_text:updateObject()
end
