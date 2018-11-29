pEvent = puppy.world.pEvent

pEvent.isControlDown = function(self)
	return bit.band(self:ck_status(), puppy.ecks_ctrl) ~= 0
end
