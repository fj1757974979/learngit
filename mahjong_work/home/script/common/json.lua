
function from_jstr(str)
	local value = puppy.value.new_null()
	value:load(str)
	return json2lua(value)
end

function to_jstr(t)
	local value = lua2json(t)
	return value:save()
end

function is_array(t)
	local keys = 0
	for _, __ in pairs(t) do
		keys = keys + 1
	end

	return keys == #t
end

function lua2json(lua_value)
	local value 
	local type_string = type(lua_value)

	if type_string == "string" then
		value = puppy.value.new_str(lua_value)
	elseif type_string == "table" then
		if is_array(lua_value) then
			value = puppy.value.new_array()
			for i, v in ipairs(lua_value) do
				value:seti(i-1, lua2json(v))
			end
		else
			value = puppy.value.new_object()
			for k, v in pairs(lua_value) do
				if type(k) == "string" then
					value:setk(k, lua2json(v))
				end
			end
		end
		
	elseif type_string == "number" then
		value = puppy.value.new_double(lua_value)
	elseif type_string == "boolean" then
		value = puppy.value.new_bool(lua_value)
	elseif type_string == "nil" then
		value = puppy.value.new_null()
	end
	return value
end

function json2lua(json_value)

	if json_value:is_bool() then
		return json_value:as_bool()
	elseif json_value:is_str() then
		return json_value:as_str()
	elseif json_value:is_int() then
		return json_value:as_int()
	elseif json_value:is_double() then
		return json_value:as_double()
	elseif json_value:is_object() then
		local t = {}
		local mem_size = json_value:member_size()
		for i=0, mem_size -1 do
			local name = json_value:member_name(i)
			t[name] = json2lua(json_value:getk(name))
		end
		return t
	elseif json_value:is_array() then
		local t = {}
		local size = json_value:size()
		for i=0, size-1 do
			t[i+1] = json2lua(json_value:geti(i))
		end
		return t
	elseif json_value:is_null() then
		return nil
	end
end
