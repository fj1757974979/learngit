
feditor_base = class()

feditor_base._design_time_support = true
feditor_base.__control_name = "扩展控件"
feditor_base.__default_width = 100
feditor_base.__default_height = 100

function feditor_base:init()

end

function feditor_base:__set_name(name)
	self.__control_name = name
end

function feditor_base:__set_default_size(w,h)
	self.__default_width = w
	self.__default_height = h
end
