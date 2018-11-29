import("tcf.lua")

gAllTimers = {}

local dump = function()
	import("util/util.lua")
	log("error", sf("not timer cnt: %d\n", table.size(gAllTimers)))
	for t, _ in pairs(gAllTimers) do
		log("error", t.debugInfo .. "\n-----------------\n")
	end
end

gGroupToTimers = {}

updateAllTimer=function()
	tms = {}
	for k,v in pairs(gAllTimers) do
		table.insert(tms,{k,v})
	end
	log("info","timers:",#tms)
end

timer = class(puppy.s_timer)

function timer:setGroup(group, canPauseNow)
	self.group = group
	if not gGroupToTimers[group] then
		gGroupToTimers[group] = {}
		gGroupToTimers[group]["timers"] = {}
		gGroupToTimers[group]["isPaused"] = false
	end
	gGroupToTimers[group]["timers"][self] = true
	if canPauseNow then
		local isPaused = gGroupToTimers[group]["isPaused"]
		self:pause(isPaused)
	end
end

function timer:init(interval, func, ...)
	local dt = debug.traceback()
	gAllTimers[self] = dt
	self.func = func
	self.arg = {...}
	self.needRelease = true
	self.interval = interval
	
	--self:set_name(dt)
	
	self.debugInfo = debug.traceback()
end

function timer:release()
	gAllTimers[self] = nil
	local group = self.group
	if group then
		if gGroupToTimers[group] and
			gGroupToTimers[group]["timers"][self] then
			gGroupToTimers[group]["timers"][self] = nil
		end
	end
end

function timer:release_()
	self:release()
	-- 清掉timer相关的变量，避免泄露
	self.func = nil
	self.arg = nil
	self.debugInfo = nil
end

function timer:stop()
	self.needRelease = true
	if self.onStopCallback then
		self.onStopCallback()
		self.onStopCallback = nil
	end
	self:deactivate()
	self:release()
	--log("error", "stop \n")
	--dump()
end

function timer:onStop(onStopCallback)
	self.onStopCallback = onStopCallback
end

function timer:start()
	self.needRelease = not self.isInterval
	self:activate(self.interval)
end

function timer:pause(flg)
	if flg then
		self:deactivate()
	else
		self:activate(self.interval)
	end
end

function timer:on_tick()
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

function timer:update()
	self:on_tick()
	return self
end

setTimeout = function( interval, func, ... )
	assert(func)
	local t = timer:new(interval, func, ...)
	t:start()
	t.needRelease = true
	return t
end

setInterval = function( interval, func, ... )
	--log("error", "setInterval \n")
	--dump()
	assert(func)
	local t = timer:new(interval, func, ...)
	t:start()
	t.needRelease = false
	t.isInterval = true
	return t
end

local oldcreateco=coroutine.create
coroutine.create = function(real_crt_func)
	return oldcreateco( apply(xpcall, real_crt_func, function(e)
		log( "error", string.format("---- coroutine resume error! ---- \n%s\n%s\n",
				e,
				debug.traceback()))
	
	end))
end

runProcess = function(interval, func)
	local co = coroutine.create(func)
	return setInterval(interval, function()
		if not coroutine.resume(co) then
			return "release"
		end
	end)
end

stopProcess = function( process )
	if is_type_of(process, timer) then
		process:stop()
	end
end

sleepProcess = function(val)
	for i=1,val do
		yield()
	end
end

local TIMEOUT_SCENE = 1
local TIMEOUT_UI = 2
local TIMEOUT_SCENE_PERSIST = 3

pauseTimerByGroup = function(group, flg)
	local groupTimers = gGroupToTimers[group]
	if groupTimers then
		for timer, _ in pairs(groupTimers["timers"]) do
			timer:pause(flg)
		end
	else
		gGroupToTimers[group] = {}
		gGroupToTimers[group]["timers"] = {}
		gGroupToTimers[group]["isPaused"] = flg
	end
end

runSceneProcess = function(interval, func)
	local co = coroutine.create(func)
	local t = setInterval(interval, function()
		if not coroutine.resume(co) then
			return "release"
		end
	end)

	t:setGroup(TIMEOUT_SCENE)
	return t
end

setSceneTimeout = function( interval, func, canPauseNow)
	assert(func)
	local t = timer:new(interval, func)
	t:start()
	t.needRelease = true
	t:setGroup(TIMEOUT_SCENE, canPauseNow)
	return t
end

setSceneInterval = function(interval, func, canPauseNow)
	assert(func)
	local t = timer:new(interval, func)
	t:start()
	t.needRelease = false
	t.isInterval = true
	t:setGroup(TIMEOUT_SCENE, canPauseNow)
	return t
end

setSceneIntervalPersist = function(interval, func, canPauseNow)
	assert(func)
	local t = timer:new(interval, func)
	t:start()
	t.needRelease = false
	t.isInterval = true
	t:setGroup(TIMEOUT_SCENE_PERSIST, canPauseNow)
	return t
end

stopSceneTimer = function()
	local groupTimers = gGroupToTimers[TIMEOUT_SCENE]
	if not groupTimers then return end
	for timer, _ in pairs(groupTimers["timers"]) do
		timer:stop()
		timer:release()
	end
end


pauseSceneTimer = function(flg)
	pauseTimerByGroup(TIMEOUT_SCENE, flg)
	pauseTimerByGroup(TIMEOUT_SCENE_PERSIST, flg)
end

yield = coroutine.yield
wait = function(ticket) for i=1,ticket do yield() end end
set_timeout = setTimeout
set_interval = setInterval
run_process = runProcess
stop_process = stopProcess

__init__ = function(self)
	loadglobally(self)
end
