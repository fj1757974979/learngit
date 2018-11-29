local modConfirmDialog = import("ui/common/confirm.lua")
local modUtil = import("util/util.lua")

notifyReconnect = function(callback)
	local doOpFunc = function()
		setTimeout(1, function()
			callback()
		end)
	end
	local dialog = modConfirmDialog.pConfirmDilog:instance()
	dialog:open(nil, TEXT("您的网络状态不稳定，网络连接已断开，请尝试重新连接"), 
	function()
		doOpFunc()
	end,
	function()
		doOpFunc()
	end)

end
