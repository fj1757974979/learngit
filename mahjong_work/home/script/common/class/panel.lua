
pPanel = pPanel or class(pWindow)

pPanel.className = function() 
	return "pPanel" 
end

pPanel.init = function(self)
	self.path = ""
end

pPanel.getPath = function(self)
	return self.path or ""
end

pPanel.load = function(self, path)
	self.path = path
	self:clearNamedChild()
	try { function()
		pObject.load(self, self.path)
	end} catch { function()

	end} finally { function()
		log("info", "pPanel load path failed:", self.path)
	end}
end

pPanel.children = function(self)
	return {}
end

pPanel.fromTable =function(self, conf, root)
	if conf.path then self:load(conf.path) end
	pWindow.fromTable(self, conf, root)
end

pPanel.toTable = function(self)
	local t = pWindow.toTable(self)
	if not t then return end
	t.path = self:getPath()
	return t
end

__init__ = function()
	export("pPanel", pPanel)
end
