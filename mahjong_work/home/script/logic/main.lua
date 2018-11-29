local modMenuMain = import("logic/menu/main.lua")
local modSound = import("logic/sound/main.lua")
local modPerLoadMgr = import("logic/perload/mgr.lua")
local modResLoadingPanel = import("ui/login/resource_loading.lua")
local modUtil = import("util/util.lua")

startGame = function()
	local callback = function()
		modSound.getCurSound():playBgm()
		modMenuMain.pMenuMgr:instance():getCurMenuPanel():open()   --打开游戏界面
	end
	if modPerLoadMgr.getCurLoadMgr():hasResourceLoaded() then
		callback()
	else
		modResLoadingPanel.pResourceLoadingPanel:instance():open(callback)
		local delay = 1
		if modUtil.isFastLoadingChannel() then
			delay = modUtil.s2f(1)
		end
		setTimeout(delay, function()
			modPerLoadMgr.getCurLoadMgr():loadAllRes()
		end)
	end
end
