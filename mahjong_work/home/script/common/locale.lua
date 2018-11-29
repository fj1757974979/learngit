
--[[
TEXT = function(text, ...)
	if id_string then
		return id_string[text] or text
	else
		return text
	end
end

 
__init__ = function(self)
	export("TEXT", TEXT)
	local lang=gameconfig:getConfigStr("settings", "flang","cn")
	import(string.format("locale/%s.lua",lang))
end
]]--
