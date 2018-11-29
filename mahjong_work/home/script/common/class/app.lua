
puppy.world.app.get_config_var = function(self,key,value)
	if type(value)=="number" then
		return gameconfig:get_config_int("settings", key, value)
	elseif type(value)=="boolean" then
		return gameconfig:get_config_int("settings", key, value and 1 or 0) == 1
	else
		return gameconfig:get_config_str("settings", key, value)
	end
end

puppy.world.app.get_config_var_by_id = function(self,id,key,value)
	
	if type(value)=="number" then
		return gameconfig:get_config_int("id"..tostring(id), key, value)
	elseif type(value)=="boolean" then
		return gameconfig:get_config_int("id"..tostring(id), key, value and 1 or 0) == 1
	else
		return gameconfig:get_config_str("id"..tostring(id), key, value)
	end
end

puppy.world.app.set_config_var = function(self,key,value)
	if type(value)=="number" then
		return gameconfig:set_config_int("settings", key, value)
	elseif type(value)=="boolean" then
		return gameconfig:set_config_int("settings", key, value and 1 or 0)
	else
		return gameconfig:set_config_str("settings", key, value)
	end
end

puppy.world.app.set_config_var_by_id = function(self,id,key,value)
	if type(value)=="number" then
		return gameconfig:set_config_int("id"..tostring(id), key, value)
	elseif type(value)=="boolean" then
		return gameconfig:set_config_int("id"..tostring(id), key, value and 1 or 0)
	else
		return gameconfig:set_config_str("id"..tostring(id), key, value)
	end
end


if puppy.location then
	puppy.location.pLocationMgr.old_getLocation = puppy.location.pLocationMgr.old_getLocation or puppy.location.pLocationMgr.getLocation

	puppy.location.pLocationMgr.getLocation = function(self, callback)
		if not self.old_getLocation then
			local modUtil = import("util/util.lua")	
			modUtil.consolePrint("========= no interface named getLocation")
			return
		end
		self:fetchLocation()
		if not self.__callbacks then
			self.__callbacks = {}
		end
		if callback then
			table.insert(self.__callbacks, callback)
		end
		local commitResult = function(location)
			local lng = tonumber(location.longitude)
			local lat = tonumber(location.latitude)
			for _, cb in ipairs(self.__callbacks) do
				cb(lng/1000000.0, lat/1000000.0)
			end
			self.__callbacks = {}
		end
		local location = self:old_getLocation()
		if location then
			commitResult(location)
		else
			if not self.__fetch_hdr then
				self.cnt = 0
				self.__fetch_hdr = setInterval(10, function()
					local location = self:old_getLocation()
					if location then
						commitResult(location)
						self.cnt = 0
						self.__fetch_hdr = nil
						return C_INTERVAL_RET
					else
						self.cnt = self.cnt + 1
						if self.cnt >= 20 then
							self:fetchLocation()
						end
					end
				end)
			end
		end
	end
end
