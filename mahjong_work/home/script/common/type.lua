function new_weak_table()
	local t = {}
	setmetatable(t, {__mode="kv"})
	return t
end

is_type_of = function( obj, class)
	if not is_table(obj) then return false end
	if not obj.__class then return false end
	return obj[class]
end

isA = is_type_of

function is_function(obj)
	return type(obj) == "function"
end

function is_table(obj)
	return type(obj) == "table"
end

function is_string(obj)
	return type(obj) == "string" and type(obj) ~= "number"
end

function is_number(obj)
	return type(obj) == "number"
end

function is_boolean(obj)
	return type(obj) == "boolean"
end

define_class = function(class_name, ...)
	local cls = class(...)
	cls._name = class_name
	getfenv(2)[class_name]=cls
end

function do_nothing() end

__init__ = function(self)
	loadglobally(self)
end
