playAction = function(self, name, times, pause, onStop, onFinish)
	times = times or -1
	local action = puppy.world.pNormalAction()
	action:setup(self, name, times, pause)
	action.onStop = function()
		if is_function(onStop) then
			onStop()
		end
		self.action = nil
	end
	action.onFinish = function()
		if is_function(onFinish) then
			onFinish()
		end
		self.action = nil
	end
	self.action = action
	self:doAction(action)
end

pCharacter.playAction = playAction

chase = function(self, dester, distance, onStop)
	local speed = self:getRunSpeed()
	local actionName = "walk"
	distance = distance or 0
	
	local action = pMoveAction()
	action:setup(self, 0, 0, speed, actionName)
	action:set_distance(distance)
	action:set_dest_object(dester)

	self[action] = 1
	action.onStop = function()
		if is_function(onStop) then onStop() end
		self[action] = nil
	end

	self:doAction(action)
end

pCharacter.chase = chase

chase2 = function(self, dester, distance, onStop)
	local speed = self:getRunSpeed()
	distance = distance or 0
	
	local action = pRunAreaFreeAction()
	action:setup(self)
	action:setDestObj(dester, distance);

	self[action] = 1
	action.onStop = function()
		if is_function(onStop) then onStop() end
		self[action] = nil
	end

	self:doAction(action)
end

pCharacter.chase2 = chase2

runTo = function(self, x, y, distance, onStop)
	local speed = self:getRunSpeed()
	local actionName = "walk"
	distance = distance or 0
	
	local action = pMoveAction()
	action:setup(self, x, y, speed, actionName)
	action:set_distance(distance)

	self[action] = 1
	action.onStop = function()
		if is_function(onStop) then
			onStop()
		end
		self[action] = nil
	end

	self:doAction(action)
end

runTo2 = function(self, x, y, defaultSpeed, distance, onStop)
	local speed = defaultSpeed or self:getRunSpeed()
	local actionName = "walk"
	distance = distance or 0
	
	local action = pMoveAction()
	action:setup(self, x, y, speed, actionName)
	action:set_distance(distance)

	self[action] = 1
	action.onStop = function()
		if is_function(onStop) then
			onStop()
		end
		self[action] = nil
	end

	self:doAction(action)
end

follow = function(self, obj, distance, onStop)
	local action = pFollowAction()
	action:setup(self, obj)
	action:set_distance(distance)
	self[action] = 1
	action.onStop = function()
		if is_function(onStop) then
			onStop()
		end
		self[action] = nil
	end

	self:doAction(action)
end

pCharacter.follow = follow

pCharacter.stand = function(self)
	playAction(self, "stand", -1)
end


pCharacter.runTo = runTo
pCharacter.runTo2 = runTo2

addEffect = function(self, path, times)
	local eff = pSprite()
	eff:setTexture(path, 0)
	eff:play(times)
	eff:setParent(self)
	return eff
end

pCharacter.addEffect = addEffect

oldGetAnimationNames = oldGetAnimationNames or pCharacter.getAnimationNames
pCharacter.getAnimationNames = function(self)
	local names = oldGetAnimationNames(self)
	return string.split(names, ",")
end
