
gAllNetTimers = gAllNetTimers or {}

NetTimer = class(puppy.nt_timer)

NetTimer.dispatch = function(self)
	puppy.nt_timer:dispatch()
end

NetTimer.reset = function(self)
	puppy.nt_timer:reset()
end

NetTimer.init = function(self, interval, func, ...)
	gAllNetTimers[self] = true
	self.func = func
	self.arg = {...}
	self.needRelease = true
	self.interval = interval
end

NetTimer.on_tick = function(self)
	--log("info", "on_tick")
	if self.func(unpack(self.arg or {})) == "release" then
		self.needRelease = true
	end

	if self.needRelease then
		self:stop()
		self:release_()
	else
		self:start()
	end
end

NetTimer.release_ = function(self)
	self:release()
	self.func = nil
	self.arg = nil
end

NetTimer.release = function(self)
	gAllNetTimers[self] = nil
end

NetTimer.stop = function(self)
	self.needRelease = true
	if self.onStopCallback then
		self.onStopCallback()
		self.onStopCallback = nil
	end
	self:deactivate()
	self:release()
end

NetTimer.onStop = function(self, callback)
	self.onStopCallback = callback
end

NetTimer.start = function(self)
	self.needRelease = not self.isInterval
	self:activate(self.interval)
end

NetTimer.pause = function(self, flag)
	if flag then
		self:deactivate()
	else
		self:activate(self.interval)
	end
end

NetTimer.update = function(self)
	self:on_tick()
	return self
end

setNetTimeout = function(interval, func, ...)
	assert(func)
	local t = NetTimer:new(interval, func, ...)
	t:start()
	t.needRelease = true
	return t
end

setNetInterval = function(interval, func, ...)
	assert(func)
	local t = NetTimer:new(interval, func, ...)
	t:start()
	t.needRelease = false
	t.isInterval = true
	return t
end

runNetProcess = function(interval, func)
	local co = coroutine.create(func)
	return setNetInterval(interval, function()
		if not coroutine.resume(co) then
			return "release"
		end
	end)
end

stopNetProcess = function(process)
	if is_type_of(process, NetTimer) then
		process:stop()
	end
end

netTimerDestroy = function()
	local allTimers = table.keys(gAllNetTimers)
	for _, t in pairs(allTimers) do
		t:stop()
	end
	gAllNetTimers = {}
end

__init__ = function(module)
	loadglobally(module)
end
