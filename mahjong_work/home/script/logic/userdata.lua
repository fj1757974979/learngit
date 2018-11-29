local modMathProperty = import("logic/mathproperty.lua")
local modUIUtil = import("ui/common/util.lua")
local modPropMgr = import("common/propmgr.lua")
local modUtil = import("util/util.lua")
local modEasing = import("common/easing.lua")
local modJson = import("common/json4lua.lua")
local modEvent = import("common/event.lua")
local modResource = import("logic/resource.lua")
local modUserPropCache = import("logic/userpropcache.lua")

getClientVersion = function()
	local agent = puppy.pUpdateAgent:instance()
	if not agent then
		return "UNKNOWN" 
	else
		return agent:getClientVersion()
	end
end

pUserData = pUserData or class(modPropMgr.propmgr, pSingleton)

pUserData.init = function(self)
	modPropMgr.propmgr.init(self)
	self.uid = nil
	self.gender = nil
	self.score = nil
	self.goldCount = nil
	self.token = nil
end

pUserData.getUID = function(self)
	return self.uid
end

pUserData.setUID = function(self, uid)
	self.uid = uid
end

pUserData.setGender = function(self, gender) 
	self.gender = gender
end

pUserData.getGender = function(self)
	return self.gender
end

pUserData.getGoldCount = function(self)
	return self.goldCount
end

pUserData.setGoldCount = function(self, goldCount)
	self.goldCount = goldCount
end

pUserData.getScroe = function(self)
	return self.score
end

pUserData.setScore = function(self,score)
	self.score = score
end

pUserData.setToken = function(self, token)
	self.token = token
end

pUserData.getToken = function(self)
	return self.token
end

pUserData.getUserName = function(self)
	return self:getProp("userName")
end

pUserData.setUserName = function(self, name)
	self:setProp("userName", name)
end


pUserData.getNeedTeachBattleFlag = function(self)
	return self:getProp("needTeachBattle")
end

pUserData.setNeedTeachBattleFlag = function(self, flag)
	self:setProp("needTeachBattle", flag)
end

pUserData.setShareTime = function(self, time)
	self:setProp("shareTime", time)	
end

pUserData.setRedpacketTime = function(self, time)
	self:setProp("redpacketTime", time)	
end

pUserData.updateUserProps = function(self, callback, noBlock)
	local modSessionMgr = import("net/mgr.lua")
	local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
	local message = modLobbyProto.GetUserPropsRequest()
	message.user_id = self.uid
	message.all_require = true
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.GET_USER_PROPS, message, OPT_NONE, function(success, reason, ret)
		if success then
			local reply = modLobbyProto.GetUserPropsReply()
			reply:ParseFromString(ret)
			self:setProp("roomCards", reply.room_card_count)
			local name = reply.nickname
			if modUIUtil.utf8len(name) > 6 then
				name = modUIUtil.getMaxLenString(name, 6)
			end
			self:setProp("userName", name)
			self:setProp("gender", reply.gender)
			self:setProp("goldCount", reply.gold_coin_count)
			if reply.avatar_url == nil or reply.avatar_url == "" then
				local image = "ui:image_default_female.png"
				if reply.gender == T_GENDER_MALE then
					image = "ui:image_default_male.png"
				end
				reply.avatar_url = image
			end
			self:setProp("avatarUrl", reply.avatar_url)
			self:setProp("ip", reply.ip_address)
			self:setProp("inviteCode", reply.invite_code)
			self:setProp("realName", reply.real_name)
			self:setProp("phoneNo", reply.phone_no)
		end
		callback(success, reason)
	end, noBlock)
end

pUserData.destory = function(self)
	self.uid = nil
	self.gender = nil
	self.score = nil
	self.goldCount = nil
	self.token = nil
	pUserData:cleanInstance()
end

---------------------------------------------------

getUserName = function()
	return pUserData:instance():getUserName()
end

getUserAvatarUrl = function()
	return pUserData:instance():getProp("avatarUrl")
end

getCreateResult = function()
	return pUserData:instance():getProp("result")
end

getGender = function()
	return pUserData:instance():getGender()
end

getSoundPercent = function()
	return pUserData:instance():getProp("soundPercent")
end

getMusicPercent = function()
	return pUserData:instance():getProp("musicPercent")
end

getGoldCount = function()
	return pUserData:instance():getProp("goldCount")
end

getRoomCardCount = function()
	return pUserData:instance():getProp("roomCards")
end

getBtnPos = function()
	return pUserData:instance():getProp("btnPos")
end


getJinNiao = function()
	return pUserData:instance():getProp("jinNiao")
end

getFeiNiao = function()
	return pUserData:instance():getProp("feiNiao")
end

getJinNiaoPos = function()
	return pUserData:instance():getProp("jinNiaoPos")
end

getJinZeroPos = function()
	return pUserData:instance():getProp("jinZeroPos")
end

getGoldCount = function(self)
	pUserData:instance():getGoldCount()
end

getUID = function()
	return pUserData:instance():getUID()
end

getInviteCode = function()
	return pUserData:instance():getProp("inviteCode")
end

getRealName = function()
	return pUserData:instance():getProp("realName")
end

getPhoneNo = function()
	return pUserData:instance():getProp("phoneNo")
end

getShareTime = function()
	return pUserData:instance():getProp("shareTime")
end

getRedpacketTime = function()
	return pUserData:instance():getProp("redpacketTime")
end

getScore = function()
	return pUserData:instance():getScore()
end
instance = function()
	return pUserData:instance()
end

bind = function(key, func, defVal)
	return pUserData:instance():bind(key, func, defVal) 
end

unbind = function(key, hdr)
	pUserData:instance():unbind(key, hdr)
end

setProp = function(key, val)
	pUserData:instance():setProp(key, val)
	if modUserPropCache.pUserPropCache:getInstance() then
		if not getUID() then return end
		modUserPropCache.getCurPropCache():setProp(getUID(), key, val)
	end
end

