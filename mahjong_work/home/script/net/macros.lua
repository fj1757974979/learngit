local modMessage = import("data/proto/rpc_pb2/message_pb.lua")

T_SESSION_AUTH = 1
T_SESSION_PROXY = 2
T_SESSION_BATTLE = 3
T_SESSION_POKER = 4

__init__ = function(module)
	loadglobally(module)
	export("Request", modMessage.Request)
	export("Reply", modMessage.Reply)

	export("OPT_NONE", 0)
	export("OPT_NO_REPLY", modMessage.Request.NO_REPLY)

	export("ST_NO_CONNECT", -2)
	export("ST_TIMEOUT", -1)
	export("ST_OK", modMessage.Reply.OK)
	export("ST_ERROR", modMessage.Reply.ERROR)
	export("ST_DUPLICATE", modMessage.Reply.DUPLICATE)

	export("T_REQUEST", 0)
	export("T_REPLY", 1)
end

