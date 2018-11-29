
preload = function()
	-- DON'T change order
	math.randomseed(os.time())

	--[[
	local modMsgIDProto = import("data/proto/msgid_pb.lua")
	for k, v in pairs(modMsgIDProto) do
		if not string.match(k, "__.*__") then
			_G[k] = v
		end
	end
	]]--

	import("logic/macros.lua")
	import("logic/card_battle/macros.lua")
	import("net/macros.lua")
	--import("logic/hint/macros.lua")


	--- rpc ---
	import("net/rpc/battle.lua")
	import("net/rpc/poker.lua")
	import("net/rpc/chat.lua")
	--import("net/rpc/resource.lua")
	-- add more
	-- rpc end --

end
