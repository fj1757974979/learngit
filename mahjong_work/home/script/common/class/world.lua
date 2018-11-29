puppy.world.pWorld.addHook = function(self, eventType, func)
	local hook = puppy.world.pEventHook:new()
	hook.onEventHook = function(_, event)
		func(event)
	end

	hook:addHookEvent(puppy[eventType])
	puppy.world.pContext.addHook(self, hook)
	return hook
end

