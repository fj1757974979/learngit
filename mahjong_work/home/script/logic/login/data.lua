local modJson = import("common/json4lua.lua")
local modUtil = import("util/util.lua")
local modPreloadingPanel = import("ui/login/preloading_panel.lua")

pUserLoginData = pUserLoginData or class()

pUserLoginData.init = function(self)
    self.account = ""
end

pUserLoginData.copyFrom = function(self, copy)
	self.account = copy.account
end

pUserLoginData.saveToFile =function(self)
	local data =  {}
	data["account"] = self.account or ""
	data["t"] = self.token or ""
	data = modJson.encode(data)

	log("info", "save user regist info locally")
	local pApp = puppy.world.pApp.instance()
	local ioMgr = pApp:getIOServer()
	local buff = puppy.pBuffer:new()
	buff:initFromString(data,len(data))
	-- 保存起来
	self.buff = buff 
	local ret = ioMgr:save(self.buff, "tmp:userlogindata.dat",0)
	log("info", "save user regist data write file ret", ret)
end

pUserLoginData.checkUsername = function(self, uname)
	local account = uname or self.account

	if not account or account == "" then
		--提示用户输入账号
		return "请输入账号"
	end
	
	if string.len(account) > 18 then
		return "账号长度太长了"
	end
end

pUserLoginData.loadData = function(self)
	local pApp = puppy.world.pApp.instance()
	local ioMgr = pApp:getIOServer()
	if not ioMgr:fileExist("tmp:userlogindata.dat") then
		return false
	end

	local data = ioMgr:getFileContent("tmp:userlogindata.dat")
	if data and data ~= "" then
		local udata = modJson.decode(data)
		log("info", udata.account)
		self.account = udata.account or ""
		self.token = udata.t or ""
	else
		return false
	end
	
	return true
end

pUserLoginData.getTouristAccount = function(self)
	return self.account
end

pUserLoginData.setTouristAccount = function(self, account)
	self.account = account
end

pUserLoginData.getSDKClientToken = function(self)
	return self.token or ""
end

pUserLoginData.setSDKClientToken = function(self, token)
	self.token = token
end
