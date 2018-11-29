import("common/post_init.lua")

local modEvent = import("common/event.lua")
local modTrigger = import("logic/trigger/mgr.lua")

local initFont = function()
	local app = puppy.world.app.instance()
	local font_mgr = app:getFontmanager()
	font_mgr:addImgFont("join_number", "font:join_number.png", 40, 51)
	font_mgr:addImgFont("end_lose_number", "font:end_calculate_lose_number.png", 40/2, 45/2)
	font_mgr:addImgFont("end_win_number", "font:end_calculate_win_number.png", 40/2, 45/2)
	font_mgr:addImgFont("end_number", "font:end_calculate_number.png", 35/2, 46/2)
	font_mgr:addImgFont("join_number2", "font:join_number2.png", 48, 55)
	font_mgr:addImgFont("card_count_down", "font:card_count_down.png", 50, 58)
end

local beforeInit = function()
	initFont()
end

local registerAppStubFunc = function()
	app.onAfterRender = function(self)
		modTrigger.trigger(EV_AFTER_DRAW)
	end

	app.onBatteryLevelChanged = function(self, level)
		-- 电池电量改变
		modEvent.fireEvent(EV_BATTERY_LEVEL_CHANGED, level)
	end

	app.onBatteryStatusChanged = function(self, status)
		-- 电池状态改变
		modEvent.fireEvent(EV_BATTERY_STATUS_CHANGED, status)
	end

	app.onSendMessageToWeChat = function(self, isSuccess)
		-- 向微信发送消息的结果
		modEvent.fireEvent(EV_SHARE_TIME_LINE, isSuccess)
	end

	app.isInBackground = function(self)
		return app.__is_background
	end
end

local initDone = function()
	registerAppStubFunc()

	app:setRenderInterval(166)

	modEvent.fireEvent("INIT_DONE")
	--[[
	-- 获取当前位置
	if puppy.location and puppy.location.pLocationMgr then 
		puppy.location.pLocationMgr:instance():getLocation()
	end
	]]--
end

init = function(loginMgr)
	beforeInit()
	local modLogicMain = import("logic/main.lua")
	modLogicMain.startGame()
	initDone()
end

gIsDestroying = gIsDestroying or false

isDestroying = function()
	return gIsDestroying
end

setDestroyFlag = function(flg)
	gIsDestroying = flg
end

destroy_net = function()
end

-- 退出逻辑
destroy = function(callback)
end

__init__ = function(module)
end

__update__ = function(module)
end
