
local try_func = nil
local catch_func = nil
local finally_func = nil

function try( func_t )
	func_t = func_t or { function() end }
	try_func = func_t[1]
end

function catch( func_t )
	func_t = func_t or { function() end }
	catch_func = func_t[1]
end

function finally( func_t )
	func_t = func_t or { function() end }
	finally_func = func_t[1]
	xpcall( try_func, catch_func )
	finally_func()
end

__init__ = function(self)
	loadglobally(self)
end
