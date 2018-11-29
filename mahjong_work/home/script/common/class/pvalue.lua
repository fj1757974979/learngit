pValue = puppy.pValue

asNull = function(json) return nil end
asArray = function(json)
	local size = pValue.size(json)
	local ret = {}
	for i = 1, size do
		ret[i] = toLua(pValue.geti(json, i-1))
	end
	return ret
end

asObject = function(json)
	local size = pValue.memberSize(json)
	local ret = {}
	for i=0,size-1 do
		local k = pValue.memberName(json, i)
		local v = pValue.getk(json, k)
		ret[k] = toLua(v)
	end
	return ret
end

toLua = function(json)
	local typeConvert = {
		[pValue.isInt] = pValue.asInt,
		[pValue.isFloat] = pValue.asFloat,
		[pValue.isString] = pValue.asCString,
		[pValue.isBool] = pValue.asBool,
		[pValue.isNull] = asNull,
		[pValue.isArray] = asArray,
		[pValue.isObject] = asObject,
	}

	for isType,toType in pairs(typeConvert) do
		if isType(json) then return toType(json) end
	end
end

pValue.toLua = toLua

newArray = function(lua)
	local json = pValue.newArray()
	for i,v in ipairs(lua) do
		pValue.seti(json, i, fromLua(v))
	end
	return json
end

newObject = function(lua)
	local json = pValue.newObject()
	for k,v in pairs(lua) do
		pValue.setk(json, k, fromLua(v))
	end
	return json
end

is_array = function(lua)
	if not is_table(lua) then return false end
	
	for k,v in pairs(lua) do
		if not is_number(k) then
			log("info", k, "is not number")
			return false 
		end
	end
	return true
end

is_object = is_table

fromLua = function(lua)
	local convert = {
		[is_number] = pValue.newFloat,
		[is_string] = pValue.newString,
		[is_boolean] = pValue.newBool,
		[is_array] = newArray,
		[is_object] = newObject,
	}

	for isType, toType in pairs(convert) do
		if isType(lua) then return toType(lua) end
	end
end

pValue.forLua = fromLua

-- very hacking, thinking carefull before chang it

pValue.__objmt = {
	__index = function(t,k)
		local val =  rawget(t,k) or pValue[k]
		if val then return val end
		
		if is_number(k) then
			return toLua(pValue.geti(t, k-1))
		elseif is_string(k) then
			return toLua(pValue.getk(t,k))
		end
		return nil
	end,
	__newindex = function (t, k, v)
		if is_number(k) then
			pValue.seti(t, k-1, fromLua(v))
		elseif is_string(k) and string.sub(k,1,2) ~= "__" then
			pValue.setk(t, k, fromLua(v))
		else
			rawset(t, k, v)
		end
	end,
}
