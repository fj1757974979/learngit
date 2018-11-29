local modBattleMgr = import("logic/battle/main.lua")
local modUtil = import("util/util.lua")
local modEvent = import("common/event.lua")
local modUIUtil = import("ui/common/util.lua")

local pauseImage = {
	[false] = "ui:video_play.png",
	[true] = "ui:video_pause.png"
}

local speedImage = {
	[0] = "ui:video_speed_m_1.png",
	[1] = "ui:video_speed_1.png",
	[2] = "ui:video_speed_2.png",
	[3] = "ui:video_speed_3.png",
	[4] = "ui:video_speed_4.png",
}

pVideoPlayer = pVideoPlayer or class(pWindow, pSingleton)

pVideoPlayer.init = function(self)
	self:load("data/ui/videoplayer.lua")
	self:setParent(modBattleMgr.getCurBattle():getBattleUI())
	self:setAlignX(ALIGN_CENTER)
	self:setAlignY(ALIGN_CENTER)
	self.currNumber = 1
--	self:setOffsetY(-gGameHeight / 2)
	self:setZ(C_BATTLE_UI_Z)
	self.host = nil
	self.isPause = false
	self:regEvent()
	self:initUI()
end

pVideoPlayer.initUI = function(self)
	self.btn_play:setImage(pauseImage[not self.isPause])
end

pVideoPlayer.open = function(self, host)
	if host then
		self.host = host
	end

end

pVideoPlayer.close = function(self)
	self.currNumber = 1
	pVideoPlayer:cleanInstance()
end

pVideoPlayer.regEvent = function(self)
	self.btn_back:addListener("ec_mouse_click", function()
		if self.host then
			self.host:setTime(self.host:getTime() + 10)
			self.currNumber = self.currNumber - 1
			if self.currNumber < 0 then
				self.currNumber = 0
			end
			self.wnd_speed:setImage(speedImage[self.currNumber])
		end
	end)
	
	self.btn_quick:addListener("ec_mouse_click", function()
		if self.host then
			self.host:setTime(self.host:getTime() - 10)
			self.currNumber = self.currNumber + 1
			if self.currNumber > 4 then
				self.currNumber = 4
			end
			self.wnd_speed:setImage(speedImage[self.currNumber])
		end
	end)

	self.btn_return:addListener("ec_mouse_click", function()
		if self.host then
			self.host:setReturn(true)
		end
		if modBattleMgr.getCurBattle() then
			modBattleMgr.pBattleMgr:instance():battleDestroy()
		end
	end)

	self.btn_play:addListener("ec_mouse_click", function() 
		self.isPause = not self.isPause
		self.btn_play:setImage(pauseImage[not self.isPause])
		if self.host then
			self.host:setPause(self.isPause)	
		end
	end)

	self.btn_share:addListener("ec_mouse_click", function()
		if not self.host then return end
		local channelId = modUtil.getOpChannel()
		local titleStr = modUIUtil.getDownloadTitle() .. "录像"
		titleStr = titleStr .. sf("【%08d】", self.host:getVideoId())
		local text = sf("时间：" .. self.host:getStartTime() .. "\n")
		local nameScoces = "对局玩家："
		local playerInfos = self.host:getPlayerInfos()
		local playerScores = self.host:getPlayerScores()
		local uidToPid = self.host:getUidToPid()
		-- 名字和分数
		for idx, prop in ipairs(playerInfos) do
			local uid = prop.user_id
			local pid = uidToPid[uid]
			local score = playerScores[pid]
			local name = prop.nickname
			if score >= 0 then
				score = "+" .. score 
			end
			nameScoces = nameScoces .. name .. score
			if idx < table.getn(playerInfos) then
				nameScoces = nameScoces .. "、"
			end
		end
		text = text .. nameScoces
		-- 链接
		local downLoadLink = modUIUtil.getDownloadLink()
		log("info", titleStr, text, downLoadLink)
		-- 分享到好友
		puppy.sys.shareWeChat(2, TEXT(titleStr), TEXT(text), downLoadLink)
	end)
end


pVideoPlayer.close = function(self)
	self.host = nil
	pVideoPlayer:cleanInstance()
end
