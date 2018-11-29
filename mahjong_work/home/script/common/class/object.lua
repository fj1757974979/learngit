
pObject.__update__ = function(self)
	local parent = self:getParent()
	self:destroy()
	self:clearChild()
	self:init(parent)
end

pObject.destroy = function(self)
	self:clearChild()
	self:setParent(nil)
end

pObject.__oldAddListener = pObject.__oldAddListener or pObject.addListener

-- 重新加载
pObject.addListener = function(self,code,listenerFunc, this)
	if puppy[code]==nil then
		log("error", "addListener时使用了未知事件名"..code..debug.traceback())
		return
	end

	local listener = puppy.world.pEventListener:new()
	listener.onEvent=function(_,e)
		-- log("info", "on event", m_statistics.get_obj_name(self), listener)
		-- m_statistics.push_action(self:getWorld(), self, code)
		if this then
			listenerFunc(this, e)
		else
			listenerFunc(e)
		end
	end

	self:__oldAddListener(puppy[code], listener)
	self.listenerObject = self.listenerObject or {}
	self.listenerObject[code] = self.listenerObject[code] or {}
	self.listenerObject[code][listenerFunc] = listener

	self.listenerCode = self.listenerCode or new_weak_table()
	self.listenerCode[listenerFunc] = code
	return listenerFunc, listener
end

pObject.addClickListener = function(self, callback)
	self:addListener("ec_mouse_click", function(e)
		callback(e)
	end)
end

-- to-do
pObject.setLayer = function(self, layer) end

if not pObject.__oldRemoveListener then
pObject.__oldGetLocalCoord = pObject.__oldGetLocalCoord or pObject.getLocalCoord
pObject.__oldGetWorldCoord = pObject.__oldGetWorldCoord or pObject.getWorldCoord
pObject.getLocalCoord = compose(puppy.pValue.toLua, pObject.__oldGetLocalCoord)
pObject.getWorldCoord = compose(puppy.pValue.toLua, pObject.__oldGetWorldCoord)
end

pObject.fireEvent = function(self, code, e)
	local listeners = self.listenerObject and self.listenerObject[code] or {}
	map(function(listener) listener:onEvent(e) end, listeners, pairs)
end

pObject.setListener = function( self, code, listener, this )
	if self.listenerObject then
		local listeners = self.listenerObject[code] or {}
		for listenerFunc, _ in pairs(listeners) do
			self:removeListener( code, listenerFunc )
		end
	end
	self:addListener( code, listener, this )
end

pObject.__oldRemoveListener = pObject.__oldRemoveListener or pObject.removeListener
pObject.removeListener = function(self, listener)
	local code = self.listenerCode[listener]
	if not self.listenerObject[code] then return end
	local listenerObject = self.listenerObject[code][listener]
	self.listenerObject[code][listener] = nil
	pObject.__oldRemoveListener(self,puppy[code],listenerObject)
end

pObject.clearListener = function(self)
	for k,v in pairs(self.listenerCode or {}) do
		self:removeListener(k)
		if self.listenerCode then
			self.listenerCode[k] = nil
		end
	end
end

--[[
pObject.bind = function(self, propMgr, propName, objFunc, defaultValue, noImmediate)
	self.bindList = self.bindList or {}
	if self.bindList[propName] then
		--绑定不同的propMgr，要清除上次绑定的propMgr所绑定的propName
		self.bindList[propName].obj_prop:unbind( propName, self.bindList[propName].objFunc)

		--绑定相同的propMgr, 要清除propMgr上次所绑定的propName
		propMgr:unbind(propName, self.bindList[propName].objFunc)
	end

	propMgr:bind(propName, objFunc, defaultValue, noImmediate)
	self.bindList[propName] = {
		obj_prop = propMgr,
		objFunc = objFunc,
		defaultValue = defaultValue,
	}
end
]]--

pObject.toggleShow = function(self)
	local show = not self:isShow()
	self:show(show)
	if show then self:bringTop() end
end

pObject.getPos = function(self)
	return self:getX(), self:getY()
end

pObject.getRect = function(self)
	local x = self:getX(true)
	local y = self:getY(true)
	local w = self:getWidth()
	local h = self:getHeight()

	return {{x, y}, {x + w, y + h}}
end

pObject.children = function(self)
	local child = self:firstChild()
	local children = {}
	while child do
		table.insert(children, child)
		child = self:nextChild(child)
	end
	return children
end

pObject.clearNamedChild = function(self)
	for _,child in ipairs(self:children()) do
		if child:getName() then
			child:setParent(nil)
		end
	end
end

pObject.needSave = function(self, flag)
	self.__dontSave = not flag
end

pObject.getParam = function(self, paramName)
	return self.paramMap and self.paramMap[paramName] or nil
end

pObject.setParam = function(self, paramName, value)
	self.paramMap = self.paramMap or {}
	self.paramMap[paramName] = value
end

pObject.toTable = function(self)
	if not self:getName() then return nil end
	if self.__dontSave then return nil end
	local parentName = nil
	if self:getParent() then
		parentName = self:getParent():getName()
	end
	local children = {}
	for _, child in ipairs(self:children()) do
		local data = child:toTable()
		if data then table.insert(children, data) end
	end
	local obj = pObject()
	local defaultTable = {
		position = {obj:getX(), obj:getY()},
		alignX = obj:getAlignX(),
		alignY = obj:getAlignY(),
		rx = obj:getRX(),
		ry = obj:getRY(),
		offsetX = obj:getOffsetX(),
		offsetY = obj:getOffsetY(),
		z = obj:getZ(),
		size = {obj:getWidth(), obj:getHeight()},
		name = obj:getName(),
		color = obj:getColor(),
		enableDrag = obj:canDrag(),
		isEnableEvent = obj:isEnableEvent(),
		isSelfShow = obj:isSelfShow(),
		isChildShow = obj:isChildShow(),
		scale = {obj:getSX(), obj:getSY()},
	}
	local newTable = {
		className = self:className(),
		position = {self:getX(), self:getY()},
		alignX = self:getAlignX(),
		alignY = self:getAlignY(),
		rx = self:getRX(),
		ry = self:getRY(),
		offsetX = self:getOffsetX(),
		offsetY = self:getOffsetY(),
		z = self:getZ(),
		size = {self:getWidth(), self:getHeight()},
		name = self:getName(),
		parent = self:getParent():getName(),
		color = self:getColor(),
		children = children,
		enableDrag = self:canDrag(),
		eventMap = self.eventMap or {},
		paramMap = self.paramMap or {},
		stylePath = self.stylePath_,
		isEnableEvent = self:isEnableEvent(),
		isSelfShow = self:isSelfShow(),
		isChildShow = self:isChildShow(),
		scale = {self:getSX(), self:getSY()},
	}
	local retTable = {}
	for k,v in pairs(newTable) do
		if v ~= defaultTable[k] then
			if type(v) == "table" and type(defaultTable[k]) == "table" then
				local same = true
				for k1,v1 in pairs(v) do
					if v1 ~= defaultTable[k][k1] then
						same = false
					end
				end
				if not same then
					retTable[k] = v
				end
			else
				retTable[k] = v
			end
		end
	end
	return retTable
end

local defaultConfig = {
	className = "pWindow",
	position = {0, 0},
	size = {400, 300},
	name = "testName",
	text = "",
	color = 0xFFFFFFFF,
	enableDrag = false,
	enableEvent = true,
}

pObject.fromTable = function(self, conf, root)
	root = root or self
	setmetatable(conf, {__index = defaultConfig})
	if conf.stylePath ~= nil then
		self:setStyle(conf.stylePath)
	end
	if conf.alignX ~= nil then self:setAlignX(conf.alignX or ALIGN_LEFT) end
	if conf.alignY ~= nil then self:setAlignY(conf.alignY or ALIGN_TOP) end
	if conf.position ~= nil then
		self:setPosition(conf.position[1], conf.position[2])
	end
	self:setRX(conf.rx or self:getRX())
	self:setRY(conf.ry or self:getRY())
	self:setOffsetX(conf.offsetX or self:getOffsetX())
	self:setOffsetY(conf.offsetY or self:getOffsetY())
	if conf.size ~= nil then
		self:setSize(conf.size[1], conf.size[2])
	end

	if conf.scale then
		self:setScale(conf.scale[1] or 1, conf.scale[2] or 1)
	end

	if conf.isEnableEvent == false then
		self:enableEvent(false)
	else
		self:enableEvent(true)
	end

	if conf.isSelfShow ~= nil then
		self:showSelf(conf.isSelfShow)
	end

	if conf.isChildShow ~= nil then
		self:showChild(conf.isChildShow)
	end

	if conf.z then self:setZ(conf.z) end

	if conf.name ~= nil then
		self:setName(conf.name)
	end

	if conf.color ~= nil then
		self:setColor(conf.color)
	end

	if conf.enableDrag ~= nil then
		self:enableDrag(conf.enableDrag)
	end

	self.paramMap = conf.paramMap or {}
	self.eventMap = conf.eventMap or {}
	for k,v in pairs(self.eventMap) do
		if root.eventTable_ and root.eventTable_[v] then
			self:addListener(k, function()
				root.eventTable_[v](root, self)
			end)
		else
			log("error", string.format("install event error:%s.%s=>%s", conf.name, k,v))
		end
	end

	for _, childConf in ipairs(conf.children or {}) do
		local child = getClass(childConf.className)()
		child.loadForStyle = root.loadForStyle
		child:setParent(self)
		child:fromTable(childConf, root)
		if not root.loadForStyle then
			root[child:getName()] = child
		end
	end
end

pObject.load = function(self, path, eventTable)
	self.templatePath_ = path
	local data = import(path)
	self.eventTable_ = eventTable or self
	self:fromTable(data.data)
end

pObject.preLoad = function(self, path)
	local data = import(path)
	local conf = data.data
	if conf.size then
		local w, h = conf.size[1], conf.size[2]
		self:setSize(w, h)
	end
end

pObject.setStyle = function(self, stylePath)
	for _,child in ipairs(self:children()) do
		if not child:getName() then
			child:setParent(nil)
		end
	end

	if self.getTextControl and self:getTextControl() then
		self:getTextControl():setParent(self)
	end

	local names = {}

	self.stylePath_ = stylePath
	if not stylePath or stylePath == "" then return end

	local x,y = self:getX(), self:getY()
	local w,h = self:getWidth(), self:getHeight()
	local name = self:getName()

	self.loadForStyle = true
	try { function()
		local data = _import(stylePath)
		self:fromTable(data.data)
		self.loadForStyle = false

		self:setPosition(x,y)
		self:setSize(w,h)
		self:setName(name)

		for _,child in ipairs(self:children()) do
			if child.loadForStyle then
				child:setName(nil)
				child:enableEvent(false)
			end
		end
	end} catch {function()

	end} finally { function()

	end}
end

pObject.getStyle = function(self)
	return self.stylePath_ or ""
end

pObject.setCoverSize = function(self, coverW, coverH)
	local dx, dy = 0, 0
	if coverW then
		local w = self:getWidth()
		dx = (coverW - w) / 2
	end

	if coverH then
		local h = self:getHeight()
		dy = (coverH - h) / 2
	end

	self:setCoverBox(-dx, -dy, dx, dy)
end

pObject.setHighLight = function(self, flag)
	if flag then
		self:setHSVMutiply(1, 1, 1.2)
	else
		self:setHSVMutiply(1, 1, 1)
	end
end

pObject.setHSV = function(self, h, s, v)
	self:setHSVMutiply(0, 0, 0)
	self:setHSVAdd(h, s, v)
end

