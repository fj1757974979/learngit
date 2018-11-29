local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")
local modShareMgr = import("logic/share/main.lua")
local modBattleRpc = import("logic/battle/rpc.lua")

pSharePanel = pSharePanel or class(pWindow, pSingleton)

pSharePanel.init = function(self)
	self:load("data/ui/share.lua")
	local channelId = modUtil.getOpChannel()
	local title = modUIUtil.getDownloadTitle()
	if not title or title == "" then
		title = "开新棋牌"
	end
	local link = modUIUtil.getDownloadLink()
	self:setParent(gWorld:getUIRoot())
	self.wnd_text_2:setText("分享到好友或群")
	self.wnd_text_1:setText("分享到朋友圈")
	self.titleStr = title .. "-防作弊、放心玩"
	self.dealStr = "同IP提醒、游戏回放、GPS定位系统三重保险防作弊，足不出户畅玩游戏！"
	self.downLoadLink = link
	self:initUI()
	self:initTipWnd()
	self:regEvent()
	log("info", self.titleStr, self.dealStr, self.downLoadLink)
	modUIUtil.makeModelWindow(self, false, true)
end


pSharePanel.initUI = function(self)
	local channel = modUtil.getOpChannel() 
	if channel == "jz_laiba" or modUtil.isDebugVersion() then
		self.btn_share_friend:show(false)
		self.wnd_text_2:show(false)
		self.btn_share_timeline:setOffsetX(0)
		--self.wnd_text_1:setPosition(self.wnd_text_1:getX() + 150, self.wnd_text_1:getY())
		self.wnd_text_1:setOffsetX(0)

	end
end

pSharePanel.getRoomcardText = function(self)
	local modChannelMgr = import("logic/channels/main.lua")	
	return modChannelMgr.getCurChannel():getRoomcardText()
end

pSharePanel.initTipWnd = function(self)
	self.wnd_tip_text:show(false)
	modBattleRpc.getShareDaily(function(success, reason, ret)
		if success then
			local roomcardMin = ret.min_room_card_count_of_award
			local roomcardMax = ret.max_room_card_count_of_award
			if roomcardMin ~= 0 and roomcardMax ~= 0 then
				local roomStr = roomcardMin .. "~" .. roomcardMax
				if roomcardMin == roomcardMax then
					roomStr = roomcardMin
				end
				self.wnd_tip_text:setText("分享到朋友圈奖励" .. "#cr" .. roomStr  .. "#n" ..  self:getRoomcardText() .. "\n")	
			end
			local goldMin = ret.min_gold_coin_count_of_award
			local goldMax = ret.max_gold_coin_count_of_award
			local goldStr = goldMin .. "~" .. goldMax
			if goldMin == goldMax then
				goldStr = goldMin 
			end
			if goldMin ~= 0 and goldMax ~= 0 then
				self.wnd_tip_text:setText(self.wnd_tip_text:getText() .. "并获得" .. "#cr"  .. goldStr .. "#n" ..  "金币" )
			end
			local interval = ret.interval
			if interval ~= 0 then
				self.wnd_tip_text:setText(self.wnd_tip_text:getText() .. "(每" .. interval .. "天可奖励一次)")
				self.wnd_tip_text:show(true)
			else
				self.wnd_tip_text:show(false)
			end
		else
			infoMessage(reason)
		end
	end)
end

pSharePanel.open = function(self)
end

pSharePanel.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_share_timeline:addListener("ec_mouse_click", function()
		-- 分享到朋友圈
		modShareMgr.pShareMgr:instance():shareGameToWeChat(1, TEXT(self.titleStr), TEXT(self.dealStr), self.downLoadLink)
		self:close()
	end)

	self.btn_share_friend:addListener("ec_mouse_click", function()
		-- 分享给好友
		modShareMgr.pShareMgr:instance():shareGameToWeChat(2, TEXT(self.titleStr), TEXT(self.dealStr), self.downLoadLink)
		self:close()
	end)
end

pSharePanel.close = function(self)
	self.dailyData = nil
--local modEvent = import("common/event.lua")
--modEvent.fireEvent(EV_SHARE_TIME_LINE, true)

	pSharePanel:cleanInstance()
end
