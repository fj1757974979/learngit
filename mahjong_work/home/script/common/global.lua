-- rename name space
gLocalTest = true
gIsDebug = true

puppy.world.app = puppy.world.pApp
app = puppy.world.pApp.instance()
app.is_debug = function() return true end
gameconfig = app:getConfig()
iomanager = app:getIOServer()

getCurrentTime = function()
	local sec = get_current_sec()
	local usec = get_current_usec()
	return sec * 10000 + usec / 100
end

getTimeStamp = function()
	local t = get_current_sec()
	return t
end

--[[
#define KNRM  "\x1B[0m"
#define KRED  "\x1B[31m"
#define KGRN  "\x1B[32m"
#define KYEL  "\x1B[33m"
#define KBLU  "\x1B[34m"
#define KMAG  "\x1B[35m"
#define KCYN  "\x1B[36m"
#define KWHT  "\x1B[37m"
--]]

local color_string = {
	white = "\x1B[37m",
	green = "\x1B[32m",
	blue = "\x1B[34m",
	yellow = "\x1B[33m",
	red = "\x1B[31m",
}

console = {
	set_text_color = function(_, color)
		if app:getPlatform() == "win32" then return end
		if color_string[color] then
			io.write(color_string[color])
		end
	end,
}

getClass = function(name)
	return _G[name]
end


puppy.debug = puppy.debug or {}
puppy.debug.toggleDebug = puppy.debug.toggleDebug or function() end
puppy.debug.getDebugFlag = puppy.debug.getDebugFlag or function() return false end

function __init__(module)
	loadglobally(puppy.world)
	loadglobally(puppy.gui)
	--loadglobally(puppy)
	loadglobally(module)
end
