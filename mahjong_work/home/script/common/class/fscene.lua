
oldLoadCfg = oldLoadCfg or pScene.loadCfg

pScene.loadCfg = function(self, id, flag)
	oldLoadCfg(self, id, flag)
	for k,v in pairs(self) do
		if isA(v, pObject) and v:getName() then
			self[k] = nil
		end
	end
end

pScene.toTable = function(self)
	local children = {}
	for _, child in ipairs(self:children()) do
		local data = child:toTable()
		if data then table.insert(children, data) end
	end
	return {children = children,}
end

pScene.fromTable = function(self, conf, root)
	for _, childConf in ipairs(conf.children or {}) do
		local child = getClass(childConf.className)()
		child:fromTable(childConf, root)
		child:setParent(self)
		root[child:getName()] = child
	end
end

pScene.isPosBlock = function(self, x, y)
	return self:isBlock(x/16, y/16)
end

pScene.setHeroID = function(self, id)
	return
end

