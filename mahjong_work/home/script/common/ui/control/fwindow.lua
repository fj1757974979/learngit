local m_base = import("feditor_base.lua")

fwindow = class(puppy.gui.pWindow, m_base.feditor_base)
fwindow:__set_name("窗口")
fwindow:__set_default_size(320,240)

function fwindow:init(parent)
	if parent then
		self:set_parent(parend)
	end
	self.is_maxsize = true
	self:load_template("data/uitemplate/control/fwindow.lua")
	self:set_movable(true)

	self.btn_close:set_listener("ec_mouse_left_up", function(e)
		self:on_close()
	end)
end

function fwindow:open()
	puppy.gui.pWindow.open(self)
end

function fwindow:close()
	puppy.gui.pWindow.close(self)
end

function fwindow:on_close()
	self:close()
	log("ui|info|onlyu", "on_close should rewrite in subclass")
end

function fwindow:max_size()
	if self.is_maxsize == true then
		self:set_layout_info("x=0 y=0 w=70% h=70%")
		self:center()
		self.is_maxsize = false
		self:set_movable(true)
	else
		self:set_layout_info("x=0 y=0 w=100% h=100%")
		self:center()
		self.is_maxsize = true
		self:set_movable(false)
	end
end

function fwindow:on_size_change()

end
