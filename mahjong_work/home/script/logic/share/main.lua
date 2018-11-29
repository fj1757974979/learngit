local modUtil = import("util/util.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modMenuMain = import("logic/menu/main.lua")
local modEvent = import("common/event.lua")
local modUIUtil = import("ui/common/util.lua")
local modChannelMgr = import("logic/channels/main.lua")

pShareMgr = pShareMgr or class(pSingleton)

pShareMgr.init = function(self)
	self.isShareTimeline = false
	self:regEvent()
end

pShareMgr.setIsShareTimeline = function(self, isShare)
	self.isShareTimeline = isShare
end

pShareMgr.getIsShareTimeline = function(self)
	return self.isShareTimeline
end

pShareMgr.regEvent = function(self)
	self.__share_time_line_hdr = modEvent.handleEvent(EV_SHARE_TIME_LINE, function(success)
		if not self:getIsShareTimeline() then
			return
		end
		if success then
			-- 分享成功 回复服务器 隐藏分享提示
			if self:isShareGetRoomcard() then
				modBattleRpc.shareSuccess(function(success, reason)
					if success then
						modMenuMain.pMenuMgr:instance():getCurMenuPanel():hideShareDian()
					else
						infoMessage(reason)
					end
				end)
			end
			if self:isShareGetRedpacket() then
				self:shareRedpacketWork()
			end
			infoMessage("分享成功!")
		else
			infoMessage("分享失败!")
		end
		self:setIsShareTimeline(false)
	end)
end

pShareMgr.shareRedpacketWork = function(self)
	modBattleRpc.shareRedpacketSuccess(function(success, reason, reply)
		if success then
			local count = nil
			if reply then
				count = reply.amount / 100
			end
			modMenuMain.pMenuMgr:instance():getCurMenuPanel():hideRedpacket()
			self:getRedpacket(count)
		else
			infoMessage(reason)
		end
	end)
end

pShareMgr.getRedpacket = function(self, count)
	local modMenuMain = import("logic/menu/main.lua")
	modMenuMain.pMenuMgr:instance():getCurMenuPanel():showRedpacket(count)
end

pShareMgr.isShareGetSomething = function(self)
	local channel = modChannelMgr.getCurChannel()
	return self:isShareGetRoomcard() or self:isShareGetRedpacket()
end

pShareMgr.isShareGetRoomcard = function(self)
	local channel = modChannelMgr.getCurChannel()
	return channel:isShareGetRoomcard()
end

pShareMgr.isShareGetRedpacket = function(self)
	local channel = modChannelMgr.getCurChannel()
	return channel:isShareGetRedpacket()
end

pShareMgr.typeIsTimeline = function(self, t)
	return t == 1
end

pShareMgr.shareGameToWeChat = function(self, shareType, title, desc, link)
	if self:typeIsTimeline(shareType) then
		self:setIsShareTimeline(true)
	else
		self:setIsShareTimeline(false)
	end
	if self:isShareGetSomething() and self:typeIsTimeline(shareType) then
		local imagePath = modUIUtil.getChannelRes("wechat_share.png")
		if puppy.sys.shareWeChatWithImagePath and modUIUtil.hasFileByPath(imagePath) then
			puppy.sys.shareWeChatWithImagePath(shareType, imagePath)
		else
			puppy.sys.shareWeChat(shareType, title, desc, link)
		end
	else
		puppy.sys.shareWeChat(shareType, title, desc, link)
	end
end

pShareMgr.close = function(self)
	if self.__share_time_line_hdr then
		modEvent.removeListener(self.__share_time_line_hdr)
		self.__share_time_line_hdr = nil
	end
	pShareMgr:cleanInstance()
end
