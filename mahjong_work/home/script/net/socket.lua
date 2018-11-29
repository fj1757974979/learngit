local clientPrivateKey = [[
-----BEGIN RSA PRIVATE KEY-----
MIICXgIBAAKBgQC+MHtmtJak8c3Gi33xHnBkpDjhe+V7pQpRduhg+lW7JzKhgNAf
jcyK6o8uZwfjrYt/Oxkrsc3ccQvkSm9F268+B+RVxkFIdzoWdZv9jG/meJIYrQKp
BEx54nhFMJGG0HNGUuPjLYNSX32RGLF+465IlRffjtKjfVFAqUa7XKeJswIDAQAB
AoGAZ16qc3QLvLLACP2gAgFtTQYE9GkGnWFibkyWmL73AbWYSzdb5wqG9anvEGVn
YFPe0dQpJhqJrRq0P+xE9k8kuzyoAkXkGByw1UjXQA4dsPyD8v4ET7FGJu7CWTdR
A5o690zJd9kLLXmVy9dlIlYTxlysRTvarCI2cFOa6K72VwECQQD5D4u5uOaQk/Nh
edEq9ycZDb6GDA1qYGzyQ+/0rhaS5xsoQN6smxXovxLY/hAkIXdnw0Gr+xXK33Ag
KOwZe7UTAkEAw30HlaSn7NoKoYMEwZ7uY4j0kl7V3KH3OiKCaeXVEJE++cKFTgfI
hKJ0JlaX3Qe9bI6WaScgtRmC9Ye+WF2M4QJBALqm7uUp8AksB/rmS16yyOdayI03
HRq61wsc5QjvKtW/QzgAnaCnvVynTd23UatyNUVbLK1Rx7w5hZNkd8SFVGcCQQCg
wkLodn15s10msN3Kc+5KgCfP7pkkVTU/430npM9wTmFhduu03YWyPP4TQQalx2Wo
ziE22+xzwUUGsNiBRn1BAkEAhvPLaDBa3QZh/OAB8sqzz373zsxmMimoQzAlTEI6
W8vIxUdxbvBTLc3ZhX56nv5dtNRzgQsIypfvRb5BvXSpMQ==
-----END RSA PRIVATE KEY-----]]

local serverPublicKey = [[
-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAK5LfvurVkE1wkCiC61jFfRkWq4IOHW5A8UyozAdAdaEp7WcjI4qLStp
1z47DbIkfvYhGTrNFs1rgCCH9eMHxdaUxfWq9DSHduZpvb8IZcaspndQySXccoJN
g2daRMcKjrDsNKcKklI5yGaRpoEhdrNtSSqrHA8pCU3fE60FsrIDAgMBAAE=
-----END RSA PUBLIC KEY-----]]

local getSocketCls = function()
	local netType = gameconfig:getConfigStr("global", "net", "libevent")
	if netType == "libevent" then
		return puppy.pClientSocket
	else  -- raw
		return puppy.net.pClientLink
	end
end

pSocket = pSocket or class(getSocketCls())

pSocket.init = function(self, session)
	self.session = session
	self.connecting = false
	self.available = false
	self:setupRSAEnv(serverPublicKey, clientPrivateKey)
end

pSocket.setTimeoutLimit = function(self, microsecond)
	if self.setTimeoutThrehold then
		--self:setTimeoutThrehold(8000)
		self:setTimeoutThrehold(microsecond or C_NET_TIMEOUT_LIMIT)
	end
end

pSocket.isAvailable = function(self)
	return self.available
end

pSocket.connectRemote = function(self, ip, port, callback)
	log("info", sf("connecting remote %s:%d", ip, port))
	self.connectCallback = callback
	if not self:connectTo(ip, port) then
		-- isTimeout isError 
		self:callConnectCb(false, true)
	else
		self.connecting = true
	end
end

pSocket.callConnectCb = function(self, ...)
	if self.connectCallback then
		self.connectCallback(...)
		self.connectCallback = nil
	end
end

pSocket.onAvailable = function(self)
	log("info", "traffic available!")
	self.connecting = false
	self.available = true
	self:callConnectCb(false, false)
	self.session:networkAvailable()
end

pSocket.onConnected = function(self)
	log("info", "connected, wait verify")
end

pSocket.onError = function(self, code, msg)
	log("error", sf("socket onError, code=%d, msg=%s", code, msg))
	self:close()
	if self.connecting then
		self.connecting = false
		self:callConnectCb(false, true)
	else
		self.session:networkError(code, msg)
	end
end

pSocket.onTimeout = function(self, code, msg)
	self:close()
	if self.connecting then
		self.connecting = false
		self:callConnectCb(true, false)
	else
		self.session:networkTimeout(code, msg)
	end
end

pSocket.onVerifyFailed = function(self)
	self:close()
	if self.connecting then
		self.connecting = false
		self:callConnectCb(false, true)
	end
	log("error", sf("verify server failed"))
end

pSocket.onTraffic = function(self, msgType, buff)
	local raw = buff:asBufferString()
	--log("info", sf("traffic, msgType=%d, buff=%s", msgType, raw))	
	if msgType == T_REQUEST then		
		self.session:callFromRemote(raw)
	else		
		self.session:replyFromRemote(raw)
	end
end

pSocket.__close = pSocket.__close or pSocket.close

pSocket.close = function(self)
	--[[
	if self.connecting then
		self:callConnectCb(false, true)
	end
	]]--
	self.available = false
	self:__close()
end


