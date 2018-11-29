local modRpc = import("net/rpc.lua")
local modNetUtil = import("net/util.lua")
local modRC4 = import("common/net/rc4.lua")

puppy.pRpcProtocolHandler.handleProtocolBuff = function(self, buff)
	local data = buff:asBufferString()
	modRpc.getServiceMgr():handleRawData(data)
end

puppy.pRpcProtocolHandler.onRecvKey = function(self, key)
	self.rc4Key = bit.bxor(key, 0xFA381194)
	log("info", "receive rc4 key: ", self.rc4Key);
	self.rc4Context = modRC4.RC4_CreateContext {
		InitSeed = self.rc4Key,
		DisturbFunc = 2,
	}

	self.cryptCnt = 0
end

puppy.pRpcProtocolHandler.onVerifyFailed = function(self)
	modNetUtil.notifyVerifyFail()
end

puppy.pRpcProtocolHandler.rc4PackData = function(self, arr)
	if not self.rc4Key then
		return arr
	end

	self.cryptCnt = self.cryptCnt + 1

	log("error", "[pack data] count: ", self.cryptCnt)

	return modRC4.RC4_Transform(self.rc4Context, arr)
end

