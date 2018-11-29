local modSessionMgr = import("net/mgr.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modUtil = import("util/util.lua")

pUserPropCache = pUserPropCache or class(pSingleton)

pUserPropCache.init = function(self)
	self.playerProps = {}
end

pUserPropCache.setProp = function(self, uid, name, value)
	if not uid or not name or not value then
		return 
	end
	if not self.playerProps[uid] then self.playerProps[uid] = {} end
	self.playerProps[uid][name] = value
end

pUserPropCache.getProp = function(self, uid)
	return self.playerProps[uid]
end

local nameToProto = {
	["all"] = "all_require",
	["roomcard"] = "room_card_count",
	["name"] = "nickname",
	["avatarurl"] = "avatar_url",
	["ip"] = "ip_address",
	["gender"] = "gender",
	["gold"] = "gold_coin_count",
	["invite"] = "invite_code",
	["realname"] = "real_name",
	["phone"] = "phone_no",
}

local protoToName = {}

pUserPropCache.getProtoKeyByPropKey = function(self, key)
	return nameToProto[key]
end

pUserPropCache.getPropKeyByProtoKey = function(self, key)
	if #protoToName <= 0 then
		for propKey, protoKey in pairs(nameToProto) do
			protoToName[protoKey] = propKey
		end
	end
	return protoToName[key]
end

pUserPropCache.getPropAsync = function(self, uid, keyList, callback)
	local reqKeyList = {}
	if not self.playerProps[uid] then
		reqKeyList = keyList
	else
		for _, key in ipairs(keyList) do
			if not self.playerProps[uid][key] then
				table.insert(reqKeyList, key)
			end
		end
	end
	local assembleValuesAndReturn = function(keys)
		local ret = {}
		for _, key in ipairs(keys) do
			ret[key] = self.playerProps[uid][key]
		end
		callback(true, ret)
	end
	if #reqKeyList <= 0 then
		assembleValuesAndReturn(keyList)
	else
		local request = modLobbyProto.GetUserPropsRequest()
		request.user_id = uid
		for _, key in ipairs(reqKeyList) do
			local protoKey = self:getProtoKeyByPropKey(key)
			if protoKey then
				request[protoKey] = true
			end
		end
		local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
		modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.GET_USER_PROPS, request, OPT_NONE, function(success, reason, ret)
			wnd:setParent(nil)
			if success then
				local reply = modLobbyProto.GetUserPropsReply()
				reply:ParseFromString(ret)
				local code = reply.error_code
				if code == modLobbyProto.GetUserPropsReply.SUCCESS then
					if not self.playerProps[uid] then
						self.playerProps[uid] = {}
					end
					for _, key in ipairs(reqKeyList) do
						local protoKey = self:getProtoKeyByPropKey(key)
						if reply[protoKey] then
							self.playerProps[uid][key] = reply[protoKey]
						end
					end
					assembleValuesAndReturn(reqKeyList)
				else
					infoMessage(TEXT("请求玩家数据失败"))
					callback(false)
				end
			else
				infoMessage(TEXT("请求玩家数据失败"))
				callback(false)
			end
		end)
	end
end

getCurPropCache = function()
	return pUserPropCache:instance()
end
