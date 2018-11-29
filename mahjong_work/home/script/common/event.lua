EventSource = EventSource or class()

EventSource.id = 0

EventSource.init = function(self)
	self.listenerList = self.listenerList or {}
	setmetatable(self.listenerList, {__mode = "v"})

	self.callbackList = self.callbackList or {}
end

EventSource.addListener = function(self, eventName, handleFunc)
	self.callbackList[eventName] = self.callbackList[eventName] or {}
	
	EventSource.id = EventSource.id + 16
	self.listenerList[EventSource.id] = handleFunc

	table.insert(self.callbackList[eventName], EventSource.id)
	return handleFunc
end

EventSource.add_listener = EventSource.addListener

EventSource.delListener = function(self, handleFunc)
	local t = filterp( function( v ) 
		return v == handleFunc 
	end , self.listenerList)	
	
	map(function(id) 
		self.listenerList[id] = nil 
	end, table.keys(t))
end

EventSource.del_listener = EventSource.delListener

EventSource.hasListener = function(self, eventName)
	return self.callbackList[eventName] and #self.callbackList[eventName] > 0
end

EventSource.has_listener = EventSource.hasListener

EventSource.fireEvent = function(self, eventName, ...)
	if not self.callbackList[eventName] then return end
	for i = #self.callbackList[eventName], 1, -1 do
		local id = self.callbackList[eventName][i]
		local func = self.listenerList[id]
		
		if func then
			local success
			local result
			local arg = {...}
			
			try { function()
				func(unpack(arg))
			end } catch {function(e)
				log("error",  string.format("---fire_event failed [%s]---\n%s\n%s", 
							    eventName,
							    e,
							    debug.traceback()))
			end } finally { function()

			end }
		else
			table.remove(self.callbackList[eventName], i)
		end
	end
end

EventSource.destroy = function(self)
	self.listenerList = nil
	self.callbackList = nil
end

globalEvent = globalEvent or EventSource()

function fireEvent(name, ...)
	return globalEvent:fireEvent(name, ...)
end

function removeListener(func)
	globalEvent:delListener(func)
end

function handleEvent(name, func)
	return globalEvent:addListener(name, func)
end
