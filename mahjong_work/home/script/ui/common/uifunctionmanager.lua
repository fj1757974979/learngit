pUIFunctionManager = pUIFunctionManager or class(pSingleton)

pUIFunctionManager.init = function(self)
	self.priorFunctionArray = {}
	self.functionArray = {}
	self.functionIsRunning = false
end


pUIFunctionManager.destroy = function(self)
	self.priorFunctionArray = {}
	self.functionArray = {}
	self.functionIsRunning = false
end

pUIFunctionManager.startPriorFunction = function(self,f)
	table.insert(self.priorFunctionArray,f)
	if table.getn(self.priorFunctionArray) == 1 then
		f()
	end
end

pUIFunctionManager.stopPriorFunction = function(self)
	table.remove(self.priorFunctionArray,1)
	if table.getn(self.priorFunctionArray) > 0 then
		self.priorFunctionArray[1]()
	else
		if not self.functionIsRunning and table.getn(self.functionArray) > 0 then
			self.functionIsRunning = true
			self.functionArray[1]()
		end
	end
end

pUIFunctionManager.startFunction = function(self, f)
	table.insert(self.functionArray,f)
	if table.getn(self.priorFunctionArray) == 0 and table.getn(self.functionArray) == 1 then
		self.functionIsRunning = true
		f()
	end
end

pUIFunctionManager.stopFunction = function(self)
	table.remove(self.functionArray,1)
	if table.getn(self.priorFunctionArray) == 0 and table.getn(self.functionArray) > 0 then
		self.functionArray[1]()
	else
		self.functionIsRunning = false
	end
end

pUIFunctionManager.getPriorFunctionCount = function(self)
	return table.getn(self.priorFunctionArray)
end	

pUIFunctionManager.getFunctionCount = function(self)
	return table.getn(self.functionArray)
end	
