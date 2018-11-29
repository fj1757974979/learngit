local modUtil = import("util/util.lua")
local modEvent = import("common/event.lua")
local modHttp = import("common/net/http.lua")

local modLoginMainPanel = import("ui/login/login_main.lua")
local modSessionMgr = import("net/mgr.lua")
local modUserLoginData = import("logic/login/data.lua")
local modUserData = import("logic/userdata.lua")
local modResource = import("logic/resource.lua")
local modPreload = import("init/preload.lua")
local modBattleMain = import("logic/battle/main.lua")
local modPokerBattleMgr = import("logic/card_battle/main.lua")
local modChatMgr = import("logic/chat/mgr.lua")
local modClipBoardMgr = import("logic/clipboard/mgr.lua")

local modLoginProto = import("data/proto/rpc_pb2/login_pb.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")

local modMain = import("init/main.lua")
local modMenuMain = import("logic/menu/main.lua")

local modJson = import("common/json4lua.lua")
local modConfirm = import("ui/common/confirm.lua")

-----------------------------------------------------------------------------------------

pLoginMgr = pLoginMgr or class(pSingleton)

pLoginMgr.init = function(self)
	self.userLoginData = modUserLoginData.pUserLoginData:new()
	self.userLoginData:loadData()
	self.isLogining = false
end

pLoginMgr.clearLoginData = function(self)
	self.userLoginData:setSDKClientToken("")
	self.userLoginData:saveToFile()
end

pLoginMgr.initLogin = function(self)
	modPreload.preload()
	self:getLoginInstance():showDialog()
	if modUtil.isAppstoreExamineVersion() then
		self:touristAuth()
	else
		if puppy.sys.hasWeChatInstalled() then
			self:wechatAuth()
		end
	end
end

pLoginMgr.getCurLoginPanel = function(self)
	return self.loginPanel
end
 
pLoginMgr.getLoginInstance = function(self)
	local channelId = modUtil.getOpChannel()	
	local modLogin = import("ui/login/" .. channelId .. ".lua")
	if not modLogin  then log("error", "login error channelId:", channelId)	return end
	local channelToName = {
		["openew"] = modLogin.pOpenewPanel,
		["ds_queyue"] = modLogin.pDsqueyuePanel,
		["tj_lexian"] = modLogin.pTjlexianPanel,
		["ly_youwen"] = modLogin.pLyyouwenPanel,
		["jz_laiba"] = modLogin.pJzlaibaPanel,
		["rc_xianle"] = modLogin.pRcxianlePanel,		
		["test"] = modLogin.pTestPanel,
		["xy_hanshui"] = modLogin.pXyhanshuiPanel,
		["yy_doudou"] = modLogin.pYydoudouPanel,
		["nc_tianjiuwang"] = modLogin.pNctianjiuwangPanel,
		["za_queyue"] = modLogin.pZaqueyuePanel,
		["qs_pinghe"] = modLogin.pQspinghePanel,
	}
	log("info", "channelId: ", channelId)
    self.loginPanel = channelToName[channelId]:instance()
	return self.loginPanel
end

pLoginMgr._initDeviceInfo = function(self, proto)
	proto.platform = app:getPlatform()
	proto.phone_model = modUtil.getDeviceModel()
	proto.phone_os_sdk = modUtil.getDeviceOsName()
	proto.phone_os_ver = modUtil.getDeviceOsVersion()
end

local getMyIp = function()
	local res = modHttp.curlGet("http://www.taobao.com/help/getip.php")
	if not res then return nil end
	local myIp = nil
	for val in string.gmatch(res, "\"(%d+%.%d+%.%d+%.%d+)\"") do
		myIp = val
		break
	end
	return myIp
end

pLoginMgr._initClientInfo = function(self, proto)
	proto.version = modUtil.getCurrentVersion() or ""
	proto.channel = modUtil.getOpChannel()
	local myIp = getMyIp()
	if myIp then
		proto.ip = modUtil.ipToInt(myIp)
	else
		proto.ip = 0
	end
end

pLoginMgr.login = function(self, uid, callback)
	local wnd = modUtil.loadingMessage(TEXT("正在登录服务器"))
	self:initProxyNet(function(timeout, err)
		wnd:setParent(nil)
		if timeout or err then
			modSessionMgr.instance():closeSession(T_SESSION_PROXY)
			callback(false, TEXT("登录失败"))
		else
			local message = modLobbyProto.EnterSessionRequest()
			message.session_id = self.sessionId
			wnd = modUtil.loadingMessage(TEXT("正在验证登录"))
			modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.ENTER_SESSION, message, OPT_NONE, function(success, reason, ret)
				wnd:setParent(nil)
				if not success then
					modSessionMgr.instance():closeSession(T_SESSION_PROXY)
					callback(false, reason)
				else
					local reply = modLobbyProto.EnterSessionReply()
					reply:ParseFromString(ret)
					if reply.error_code == modLobbyProto.EnterSessionReply.SUCCESS then
						-- check verison
						local version = reply.client_config
						if version and version ~= "" then
							try { function()
								local ver_data = modJson.decode(version)
								if not modUtil.compareVersion(ver_data["version"]) then
									-- 版本号落后
									modConfirm.pForceConfirmDialog:instance():open(TEXT("检测到游戏更新，请重启游戏"), function()
										puppy.sys.closeGame()
									end)
								end
							end} catch { function()
								infoMessage("error parse version")
							end} finally { function()
							end}
						end
						-- LOGIN
						wnd = modUtil.loadingMessage(TEXT("正在获取玩家数据"))
						modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.LOGIN_USER, modLobbyProto.LoginUserRequest(), OPT_NONE, function(success, reason, ret)
							wnd:setParent(nil)
							if success then
								local reply = modLobbyProto.LoginUserReply()
								reply:ParseFromString(ret)
								local code = reply.error_code
								modUserData.pUserData:instance():setShareTime(reply.daily_sharing_timeout)
								modUserData.pUserData:instance():setRedpacketTime(reply.red_envelope_timeout)
								if code == modLobbyProto.LoginUserReply.SUCCESS then
									-- 玩家数据
									if not modSessionMgr.instance():hasSession(T_SESSION_BATTLE) and not modSessionMgr.instance():hasSession(T_SESSION_POKER) then
										-- 加入房间
										local roomId = reply.current_room.id
										local roomHost = reply.current_room.host
										local roomPort = reply.current_room.port
										local gameType = reply.current_room.game_type

										if 	modBattleMain.getCurBattle() then
											if not modBattleMain.getCurBattle():getIsVideoState() then
												modBattleMain.pBattleMgr:instance():battleDestroy()
											end
										end
										if modPokerBattleMgr.getCurBattle() then
											modPokerBattleMgr.pBattleMgr:instance():battleDestroy()
										end
										if roomId > 0 then
											setTimeout(1, function()
												if gameType == T_MAHJONG_ROOM then
													-- 进入房间开始牌局
													modBattleMain.pBattleMgr:instance():enterBattle(roomId, roomHost, roomPort)
												elseif gameType == T_POKER_ROOM then
													modPokerBattleMgr.pBattleMgr:instance():reenterBattle(roomId, roomHost, roomPort)
												end
											end)
										else
											modClipBoardMgr.pClipBoardMgr:instance():loginCheck()
										end
										log("info", "login success: ","cards:", roomId, roomHost, roomPort)
									end
									callback(true, "")
								elseif code == modLobbyProto.LoginUserReply.CONFLICT then
									modSessionMgr.instance():closeSession(T_SESSION_PROXY)
									callback(false, TEXT("账号已经在线"))
								else
									callback(false, TEXT("获取玩家数据失败"))
								end
							else
								callback(false, reason)
							end
						end, true)
					elseif reply.error_code == modLobbyProto.EnterSessionReply.BAD_SESSION then
						-- 返回登录界面
						if modBattleMain.getCurBattle() then
							modBattleMain.pBattleMgr:instance():battleDestroy()
						end
						if modMenuMain.pMenuMgr:instance():getInstance() then
							modMenuMain.pMenuMgr:instance():close()
						end
						self:getLoginInstance():show(true)
						modSessionMgr.instance():closeSession(T_SESSION_BATTLE)
						modSessionMgr.instance():closeSession(T_SESSION_PROXY)
						callback(false, TEXT("登录会话已过期，请重新登录"))
					else
						modSessionMgr.instance():closeSession(T_SESSION_PROXY)
						callback(false, TEXT("登录失败"))
					end
				end
			end, true)
		end
	end)
end

pLoginMgr.loginToProxy = function(self, uid, sessionId, host, port, callback)
	modUserData.instance():setUID(uid)
	self.sessionId = sessionId
	self.host = host
	self.port = port
	self.uid = uid
	log("info", "======= loginToProxy:", uid, sessionId, host, port)
	self:login(uid, function(success, reason)
		if success then
			modUserData.instance():updateUserProps(function(success, reason)
				if success then
					-- talkingdata
					puppy.sys.submitRoleInfo(sf("%s.%d", modUtil.getOpChannel(), modUserData.getUID()), modUserData.getUserName(), 1, 1, modUtil.getOpChannel())
					modMain.init(self)  --跳转
				else
					infoMessage(reason)
					modSessionMgr.instance():closeSession(T_SESSION_PROXY)
				end
				modUtil.safeCallBack(callback, success, reason)
			end, true)
		else
			infoMessage(reason)
			modUtil.safeCallBack(callback, success, reason)
		end
	end)
end

pLoginMgr.relogin = function(self, callback)
	logv("warn","relogin")
	self:loginToProxy(self.uid, self.sessionId, self.host, self.port, callback)
end

pLoginMgr.onAuthSuccess = function(self, t, ret, noHint)
	local reply = modLoginProto.AuthReply()
	reply:ParseFromString(ret)
	if reply.code == modLoginProto.AuthReply.SUCCESS then
		if t == T_LOGIN_TOUR then
			if reply.account and
				reply.account ~= "" then
				self.userLoginData:setTouristAccount(reply.account)
				self.userLoginData:saveToFile()
			end
		elseif t == T_LOGIN_WX then
			modUserData.instance():setToken(reply.token)
			self.userLoginData:setSDKClientToken(reply.token)
			self.userLoginData:saveToFile()
		end
		modChatMgr.pChatMgr:instance():initEnv()
		modChatMgr.pChatMgr:instance():login(reply.uid, reply.im_token)
		self:loginToProxy(reply.uid, reply.session_id, reply.host, reply.port)
		return true
	elseif reply.code == modLoginProto.AuthReply.VERSION_ERR then
		infoMessage(TEXT("您的客户端版本已过期，请重启更新"))
		return false
	elseif reply.code == modLoginProto.AuthReply.BAD_CHANNEL then
		infoMessage(TEXT("错误的渠道ID"))
		return false
	else
		if not noHint then
			infoMessage(TEXT("验证失败"))
		end
		return false
	end
end

pLoginMgr.touristAuth = function(self, account)
	local wnd = modUtil.loadingMessage(TEXT("正在连接服务器..."))
	self:initAuthNet(function(timeout, err)
		wnd:setParent(nil)
		if timeout or err then
			infoMessage(TEXT("连接服务器失败"))
			modSessionMgr.instance():closeSession(T_SESSION_AUTH)
		else
			local message = modLoginProto.TouAuthRequest()
			--[[
			if modUtil.isDebugVersion() then
				message.account = account or "oyy1"
			else
			]]--
				message.account = account or self.userLoginData:getTouristAccount()
			--end
			self:_initClientInfo(message.client)
			self:_initDeviceInfo(message.device)
			wnd = modUtil.loadingMessage(TEXT("正在验证账号"))
			modSessionMgr.instance():callRpc(T_SESSION_AUTH, modLoginProto.TOU_LOGIN, message, OPT_NONE, function(success, reason, ret)
				wnd:setParent(nil)
				if not success then
					infoMessage(reason)
				else
					self:onAuthSuccess(T_LOGIN_TOUR, ret)
				end
				modSessionMgr.instance():closeSession(T_SESSION_AUTH)
			end, true)
		end
	end)
end

pLoginMgr.authSDKLogin = function(self, account, token, clientToken, sdkUid, channelId, firstTry, callback)
	if self.isAuthing then
		return
	end
	self.isAuthing = true
	local message = modLoginProto.SdkAuthRequest()
	message.account = account
	message.token = token
	message.client_token = clientToken
	message.sdk_uid = sdkUid
	message.platform_id = channelId
	self:_initClientInfo(message.client)
	self:_initDeviceInfo(message.device)
	local wnd = modUtil.loadingMessage(TEXT("正在验证账号"))
	modSessionMgr.instance():callRpc(T_SESSION_AUTH, modLoginProto.SDK_LOGIN, message, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		self.isAuthing = false
		if success then
			if self:onAuthSuccess(T_LOGIN_WX, ret, firstTry) then
				success = true
			else
				success = false
			end
		end
		if callback then
			callback(success, reason)
		end
	end, true)
end

pLoginMgr.wechatAuth = function(self)
	if app:getPlatform() == "macos" then
		infoMessage(TEXT("mac不支持微信登陆！"))
	else
		local wnd = modUtil.loadingMessage(TEXT("正在连接服务器..."))
		self:initAuthNet(function(timeout, err)
			wnd:setParent(nil)
			if timeout or err then
				infoMessage(TEXT("连接服务器失败"))
				modSessionMgr.instance():closeSession(T_SESSION_AUTH)
			else
				self:authSDKLogin("", "", self.userLoginData:getSDKClientToken(), "", puppy.sys.getChannelId(), true, function(success, reason)
					if success then
						modSessionMgr.instance():setDeamonMode(false)
						modSessionMgr.instance():closeSession(T_SESSION_AUTH)
					else
						if self.__sdk_login_hdr then
							modEvent.removeListener(self.__sdk_login_hdr)
							self.__sdk_login_hdr = nil
						end
						modSessionMgr.instance():setDeamonMode(true)
						wnd = modUtil.loadingMessage(TEXT("请求登录中..."))
						self.__sdk_login_hdr = modEvent.handleEvent("SDK_LOGIN", function(success, _userid, sdkUserName, sdkUid, sdkToken, channelId, phoneInfo, productCode)
							wnd:setParent(nil)
							if success then
								self:authSDKLogin(sdkUserName, sdkToken, "", sdkUid, channelId, false, function(success, reason)
									if not success then
										infoMessage(reason)
									end
									modSessionMgr.instance():setDeamonMode(false)
									modSessionMgr.instance():closeSession(T_SESSION_AUTH)
								end)
							else
								modSessionMgr.instance():setDeamonMode(false)
								infoMessage(TEXT("微信登录失败"))
								modSessionMgr.instance():closeSession(T_SESSION_AUTH)
							end
						end)
						puppy.sys.showLoginWindow("")
					end
				end)
			end
		end)
	end
end

local getAuthHostAndPort = function()
	local debugType = gameconfig:getConfigInt("global", "debug", 0)
	if debugType == 1 then
		-- 外服测试服
		return "kxqp.test.openew.cn", 7888
		--return "kxqp-openew-cn.zealsafe.net", 7888
	elseif debugType == 2 then
		-- 私服
		return "192.168.1.242", 18888
		--return "192.168.1.180", 8888
	elseif debugType == 3 then
		-- 牛牛
		return "192.168.1.180", 18888
	else
	-- 外服
		--return "kxqp-openew-cn.zealsafe.net", 8888
		return "kxqp.openew.cn", 8888
	end
end

pLoginMgr.initAuthNet = function(self, callback)
	local host, port = getAuthHostAndPort()
	local session = modSessionMgr.instance():newSession(T_SESSION_AUTH, host, port)
	session:connectRemote(function(isTimeout, errCode)
		callback(isTimeout, errCode)
	end)
end

pLoginMgr.initProxyNet = function(self, callback)
	if modSessionMgr.instance():hasSessionAvailable(T_SESSION_PROXY) then
		callback(false, false)
	else
		local session = modSessionMgr.instance():newSession(T_SESSION_PROXY, self.host, self.port)
		session:connectRemote(function(isTimeout, errCode)
			callback(isTimeout, errCode)
		end)
	end
end




