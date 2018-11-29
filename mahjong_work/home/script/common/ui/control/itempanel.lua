local m_base = import("feditor_base.lua")

itempanel = class(puppy.gui.pWindow, m_base.feditor_base)
itempanel:__set_name("物品框")
itempanel:__set_default_size(250,180)

function itempanel:init(parent)
	self:set_parent(parent)
	self:get_image_list(puppy.gui.ip_window):clear_image()

	-- 列数
	self._column = 6
	-- 行数
	self._row = 4
	-- 间距
	self._space = 5

	self._itemwnds = {}

end
