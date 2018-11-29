local modUIUtil = import("ui/common/util.lua")
local modShareMgr = import("logic/share/main.lua")
local modUtil = import("util/util.lua")

pRedpacketLock = pRedpacketLock or class(pWindow, pSingleton)

pRedpacketLock.init = function(self)
	self:load("data/ui/hongbao_lock.lua")
	self:setParent(gWorld:getUIRoot())
	self.btn_share:addListener("ec_mouse_click", function() 
		self:shareToWeixin()
		self:close()
	end)
	modUIUtil.makeModelWindow(self, false, false)
	modUtil.addFadeAnimation(self)
end

pRedpacketLock.shareToWeixin = function(self)
	local link = modUIUtil.getDownloadLink()
	local title = modUIUtil.getDownloadTitle()
	if not title or title == "" then
		title = "开新棋牌"
	end
	local titleStr = title .. "-防作弊、放心玩"
	local dealStr = "同IP提醒、游戏回放、GPS定位系统三重保险防作弊，足不出户畅玩游戏！"
	local downLoadLink = link
	modShareMgr.pShareMgr:instance():shareGameToWeChat(1, TEXT(titleStr), TEXT(dealStr), downLoadLink)
--local modEvent = import("common/event.lua")
--modEvent.fireEvent(EV_SHARE_TIME_LINE, true)
	
end

pRedpacketLock.open = function(self)
	self.txt:setText("分享领微信红包")
	self.btn_share:setText("分享到朋友圈")
end


pRedpacketLock.close = function(self)
	pRedpacketLock:cleanInstance()
end

