propmgr = propmgr or class()

propmgr.init = function(self)
	self.propSet = table.protect({}, true, function(k, v)
		self.linkedPropSet[k] = v
	end)
	self.bindList = {}
	-- 外部关联的属性集，始终为propSet的子集
	self.linkedPropSet = {}
	self.linkedNotifier = nil
end

propmgr.linkPropSet = function(self, set, callback)
	self.linkedPropSet = set
	self.linkedNotifier = callback
	-- 同时设置propSet
	for k, v in pairs(set) do
		self:setProp(k, v)
	end
end

propmgr.getLinkedPropSet = function(self)
	return self.linkedPropSet
end

propmgr.setProp = function(self, propName, value)
	local old = self.propSet[propName]
	local _old = old
	if type(old) == "table" and type(value) == "table" and old ~= value then
		_old = {}
		for k, v in pairs(old) do
			_old[k] = v
			old[k] = nil
		end
		for k, v in pairs(value) do
			old[k] = v
		end
	else
		self.propSet[propName] = value
	end
	for bindFunc, defaultValue in pairs(self.bindList[propName] or {}) do
		if value == nil then
			bindFunc(defaultValue, _old)
		else
			bindFunc(value, _old)
		end
	end
end

-- 给外部依赖的属性集合添加／设置属性值
propmgr.setLinkedProp = function(self, propName, value)
	self.linkedPropSet[propName] = value
	if self.linkedNotifier then
		self.linkedNotifier(propName, value)
	end
	-- 同时修改内部管理的属性集
	self:setProp(propName, value)
end

propmgr.setPropQuietly = function(self, propName, value)
	self.propSet[propName] = value
end

propmgr.setLinkedPropQuietly = function(self, propName, value)
	self.linkedPropSet[propName] = value
	if self.linkedNotifier then
		self.linkedNotifier(propName, value)
	end
	self:setPropQuietly(propName, value)
end

propmgr.getLinkedProp = function(self, propName, defaultValue)
	return self.linkedPropSet[propName] or defaultValue
end

propmgr.getProp = function(self, propName, defaultValue)
	return self.propSet[propName] or defaultValue
end

propmgr.tryModifyLinkedProp = function(self, propName, newVal)
	local oldVal = self.linkedPropSet[propName]
	if oldVal ~= nil then
		-- 已经存在的才做修改
		self.linkedPropSet[propName] = newVal
		if self.linkedNotifier then
			self.linkedNotifier(propName, newVal)
		end
	end
end

propmgr.addProp = function(self, propName, val)
	local newVal = self:getProp(propName, 0) + val
	self:setProp(propName, newVal)
	self:tryModifyLinkedProp(propName, newVal)
	return newVal
end

propmgr.subProp = function(self, propName, val)
	local newVal = self:getProp(propName, 0) - val
	self:setProp(propName, newVal)
	self:tryModifyLinkedProp(propName, newVal)
	return newVal
end

propmgr.modifyProp = function(self, propName, val)
	local modify = math.abs(val)
	if val > 0 then
		self:addProp(propName, modify)
	else
		self:subProp(propName, modify)
	end
end

propmgr.bind = function(self, propName, bindFunc, defaultValue, noImmediate)
	defaultValue = defaultValue or 0
	self.bindList[propName] = self.bindList[propName] or new_weak_table()
	self.bindList[propName][bindFunc] = defaultValue
	if not noImmediate then
		if self.propSet[propName] == nil then
			bindFunc(defaultValue, defaultValue)
		else
			bindFunc(self.propSet[propName], self.propSet[propName])
		end
	end
	return bindFunc
end

propmgr.unbind = function(self, propName, bindFunc)
	if self.bindList[propName] then
		self.bindList[propName][bindFunc] = nil
	end
end

propmgr.clone = function(self)
	return deepCopy(self.propSet)
end

