local m_handler = import("handler.lua")
local m_rc4 = import("rc4.lua")

fsocket = class(puppy.socket)

RPC_CFG_FILE = "script:game/net/rpc.cfg"
PID_CLIENT_UPDATE_PROTOCOL = 1
PID_SERVER_CHECK_VERSION = 2
PID_CLIENT_VERSION_RETURN = 3
PID_SERVER_MOVE = 37
PID_SERVER_UPDATE_PLAYER = 80

HOST_NAME = "auth.puppy.175game.com"
IP_MAPPING = {
	["121.10.246.7"] = "dx",
	["119.38.128.199"] = "wt",
	["119.38.128.200"] = "wt",
}

fpacket = class()

function fpacket:init(pid)
	self.data = {}
	self:push_int32(pid)
end

function fpacket:push_int32(val)
	for i=1,4 do
		table.insert(self.data, bit.band(0xFF, val))
		val = bit.rshift(val, 8)
	end
end

function fpacket:push_string(str)
	if fpacket.codepage==puppy.code_page_gbk then
		str = string.utf8_to_gb2312(str)
	end
	if not is_string(str) then
		str = tostring(str)
	end
	self:push_buffer(str, #str)
end

function fpacket:push_buffer(buff, len)
	self:push_int32(len)
	for i=1,len do
		table.insert(self.data, string.byte(buff, i))
	end
end

function fpacket:get_data()
	return self.data
end

function fsocket:setup(context, client_prikey, server_pubkey)
	self.context = context
	self.handler = m_handler.handler:new(context,self)
	self.protocol_handler = puppy.fsg_protocol_handler()
	self.send_rc4_context = nil

	self.protocol_handler:set_client_prikey(client_prikey)
	self.protocol_handler:set_server_pubkey(server_pubkey)
	self.protocol_handler.on_recv_key = function(_, key)
		-- 发送rpc.cfg的md5码
		self.send_rc4_context = m_rc4.RC4_CreateContext{
			-- key 需要解密
			InitSeed = bit.bxor(key,0xFA381194),
			DisturbFunc = 2,
		}		
		
		local buffer = iomanager:get_file_content(RPC_CFG_FILE)

		--log("onlyu", buffer)
		local protocolMD5 = getMD5Str(buffer)
		local pak = fpacket(PID_SERVER_CHECK_VERSION)
		pak:push_string(string.format("%d", 10))
		pak:push_string("script version")
		pak:push_string(protocolMD5)
		self:send_packet(pak)

		self:init_protocol(buffer)
		log("net|info|onlyu", "send rpc.cfg", protocolMD5)
	end

	self:set_content_handler( self.handler )
	self:set_protocol_handler(self.protocol_handler)

	try{ 
		function()
			local buff = iomanager:get_file_content(RPC_CFG_FILE)
			self:init_protocol(buff)
		end
	}catch{
		function()
			log("net|error|onlyu", "加载网络配置文件出错", RPC_CFG_FILE)
		end
	}finally{
		function()

		end
	}
end

function fsocket:init_protocol(content)
	local lines = string.split(content, "\n" )
	if not is_table(lines) or #lines == 0 then return end
	-- protocolMD5 = getMD5Str(content)
	self.handler:load_config(lines)
end

function fsocket:send_packet(pkt)
	local data = pkt:get_data()
	-- rc4加密
	if self.send_rc4_context then
		data = m_rc4.RC4_Transform( self.send_rc4_context, data )
	end

	data = map(string.char, data, ipairs)

	local packet = self.protocol_handler:create_packet()
	packet:init_from_buffer(table.concat(data), #data, true)
	self.protocol_handler:send_packet(packet)
end
