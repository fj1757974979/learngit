local modBattleRpc = import("logic/battle/rpc.lua")

leaveRoom = function(callback)
	modBattleRpc.leaveRoom(function(success,reason)
		if success then
			infoMessage(TEXT("已经离开此房间。"))
			if callback then
				callback()
			end
		else
			infoMessage(TEXT(reason))
		end
	end)
end
