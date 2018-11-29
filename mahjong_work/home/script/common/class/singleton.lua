objects = objects or {}

pSingleton = pSingleton or class()

pSingleton.init = function(self)
end

pSingleton.instance = function(cls, ...)
	if cls.instance_ then
		return cls.instance_
	end
	cls.instance_ = cls:new(...)
	if gIsDebug then
		--local line = debug.traceback()
		objects[cls] = objects[cls] or weak_table("v")
		table.push_back(objects[cls], cls.instance_)
	end
	return cls.instance_
end

pSingleton.getInstance = function(cls)
	return cls.instance_
end

pSingleton.clean = function(cls)
	cls.instance_ = nil
	gc()
end

pSingleton.cleanInstance = function(cls)
	local obj = cls.instance_
	if obj and obj.setParent then
		obj:setParent(nil)
		--[[
		setTimeout(10, function()
			for k,v in pairs(obj) do
				obj[k] = nil
			end
			obj.isDestroy = true
		end)
		--]]
	end
	cls.instance_ = nil

	setTimeout(2, function()
		collectgarbage("collect")
	end)
end

dumpInstance = function()
	gc()
	for k,v in pairs(objects) do
		log("info", #v, k.__class_name)
	end
end

__init__ = function()
	export("pSingleton", pSingleton)
	export("dumpInstance", dumpInstance)
end

