local modUtil = import("util/util.lua")
local modVoiceDefault = import("data/info/info_voices_default.lua")
local modBeilvs = import("data/info/info_club_min_gold.lua")
local modChannelData = import("data/info/info_channel_option.lua")
local modSound = import("logic/sound/main.lua")

pMainChannel = pMainChannel or class()

pMainChannel.init = function(self)
	self.isResetFangYan = true
	self:initState()
end

pMainChannel.getConfig = function(self, key)
	local channelId = modUtil.getOpChannel()
	return modChannelData.data[channelId][key]
end

pMainChannel.getCostData = function(self)
	local path = self:getConfig("costData")
	return import(path).data
end

pMainChannel.initState = function(self)
	local big = true
	if modUtil.getOpChannel() == "za_queyue" then
		big = false
	end
	self.btnState = {
		["zhengdong"] = false,
		["fangyan"] = self:hasFangyan(),
		["click"] = false,
		["big"] = big,
	}
	self:loadData()
end

pMainChannel.getMJStrs = function(self)
	local games = self:getConfig("games")
	return string.split(games, ",")
end

pMainChannel.getVoiceData = function(self)
	local dataPath = self:getConfig("fangyanData")
	if dataPath and dataPath ~= "" then
		local data = import(dataPath)
		return data.data
	end
	if (not dataPath or dataPath == "") and self:getPokerBattle() then
		local gameVoiceName = self:getPokerVoiceName()
		dataPath = self:getPokerVoiceData(gameVoiceName)["fanyanData"]
		local data = import(dataPath)
		return data.data
	end
	return modVoiceDefault.data
end

pMainChannel.getPokerVoiceData = function(self, name)
	if not name then return end
	local modPokerData = import("data/info/info_channel_poker_voice.lua")
	return modPokerData.data[name]
end

pMainChannel.getPokerVoiceName = function(self)
	local battle = self:getPokerBattle()
	if not battle then return end
	return battle:getGameVoiceName()
end

pMainChannel.getPokerBattle = function(self)
	local modCardbattleMgr = import("logic/card_battle/main.lua")
	local battle = modCardbattleMgr.getCurBattle()
	return battle
end

pMainChannel.getFangYanPath = function(self)
	return self:getConfig("fanyanPath")
end

pMainChannel.getIsFangYanState = function(self)
	return self.btnState["fangyan"]
end

pMainChannel.getIsZhengdongState = function(self)
	return self.btnState["zhengdong"]
end

pMainChannel.getClickState = function(self)
	return self.btnState["click"]
end

pMainChannel.getBigState = function(self)
	return self.btnState["big"]
end

pMainChannel.getRoomcardText = function(self)
	return self:getConfig("cardName")
end

pMainChannel.setBtnState = function(self, name, state)
	if not name or self.btnState[name] == nil then return end
	self:setFangyangValueReset(name, state)
	self.btnState[name] = state
end

pMainChannel.setFangyangValueReset = function(self, name, state)
	if not name or name ~= "fangyan" then return end
	self:resetFangYan(self.btnState[name] ~= state)
end

pMainChannel.resetFangYan = function(self, isReset)
	self.isResetFangYan = isReset
end

pMainChannel.genUrlCall = function(self, method, p1, p2, p3, p4)
	local url = self:getConfig("mlinkURL")
	if url and url ~= ""  then
		return sf("%s?method=%s&p1=%s&p2=%s&p3=%s&p4=%s", url, tostring(method), tostring(p1), tostring(p2), tostring(p3), tostring(p4));
	end
	return nil
end

pMainChannel.getShareRoomUrl = function(self, roomID)
	local url = self:genUrlCall("enter_room", roomID)
	if not url then
		local modUIUtil = import("ui/common/util.lua")
		url = modUIUtil.getDownloadLink()
	end
	return url
end

pMainChannel.isShareGetRoomcard = function(self)
	local text = self:getConfig("shareRoomcard")
	if not text or text == "" then return false end
	return  text == "yes"
end

pMainChannel.isShareGetRedpacket = function(self)
	local text = self:getConfig("shareRedpacket")
	if not text or text == "" then return false end
	return  text == "yes"
end

pMainChannel.isSDKPay = function(self)
	local text = self:getConfig("isSDKPay")
	if not text or text == "" then return false end
	return text == "yes"
end

pMainChannel.getShareClubUrl = function(self, clubId)
	local url = self:genUrlCall("join_club", clubId)
	if not url then
		local modUIUtil = import("ui/common/util.lua")
		url = modUIUtil.getDownloadLink()
	end
	return url
end

pMainChannel.getShareGroupUrl = function(self, grpId)
	local url = self:genUrlCall("join_group", grpId)
	if not url then
		local modUIUtil = import("ui/common/util.lua")
		url = modUIUtil.getDownloadLink()
	end
	return url
end

pMainChannel.getIsResetFangYan = function(self)
	return self.isResetFangYan
end

pMainChannel.hasFangyan = function(self)
	local fangyanData = self:getConfig("fangyanData")
	return fangyanData and fangyanData ~= ""
end

pMainChannel.getControlNum = function(self)
	return self:getConfig("fanyanID")
end

pMainChannel.getFixedMessageId = function(self, fixedId)
	return fixedId - self:getControlNum()
end

pMainChannel.playSoundMessage = function(self, fixedId, gender, gameVoiceName)
	local messageId = self:getFixedMessageId(fixedId)
	local mjPath = self:getFangYanPath()
	if gameVoiceName then
		local modGameVoiceName = import("data/info/info_channel_poker_voice.lua")
		if modGameVoiceName.data[gameVoiceName] then
			mjPath = mjPath .. modGameVoiceName.data[gameVoiceName]["fanyanPath"]
		end
	end
	local sound = modSound.getCurSound()
	sound:playSound(sound:getVoicePath(messageId, gender, mjPath))
end

pMainChannel.getSoundMessageContent = function(self, fixedId)
	local messageId = self:getFixedMessageId(fixedId)
	local data = self:getVoiceData()
	return data[messageId]["_text_"]
end

pMainChannel.loadData = function(self)
	local modSound = import("logic/sound/main.lua")
	local setData = modSound.getCurSound():loadData()
	if not setData then return end
	if not setData.btnPos then return end
	for name, value in pairs(setData.btnPos) do
		self:setBtnState(name, value > 0)
	end
end

pMainChannel.getClubCost = function(self)
	local modClubCost = import("data/info/info_club_config.lua")
	local channelId = modUtil.getOpChannel()
	if not modClubCost.data[channelId] then return end
	return modClubCost.data[channelId]["room_card_cost1"]
end

pMainChannel.getClubData = function(self)
	local modClubCost = import("data/info/info_club_config.lua")
	local channelId = modUtil.getOpChannel()
	return modClubCost.data[channelId]
end

-- 是否需要代开功能
pMainChannel.isPokerNeedDaiKai = function(self)
	local disableChannel = {
		nc_tianjiuwang = true,
		test = true,
	}
	local channelId = modUtil.getOpChannel()
	return not disableChannel[channelId]
end

-- 是否要定位功能
pMainChannel.isNeedGeoFunc = function(self)
	local disableChannel = {
		nc_tianjiuwang = true,
		test = true,
	}
	local channelId = modUtil.getOpChannel()
	return not disableChannel[channelId]
end

-- 是否展示金币
pMainChannel.isNeedGold = function(self)
	local disableChannel = {
		nc_tianjiuwang = true,
		test = true,
	}
	local channelId = modUtil.getOpChannel()
	return not disableChannel[channelId]
end

-- 俱乐部是否禁止玩法
pMainChannel.clubForbidGameType = function(self, gameType)
	local clubForbidInfo = {
		nc_tianjiuwang = {
			paijiu_mpqz = true,
		},
	}
	local channelId = modUtil.getOpChannel()
	if not clubForbidInfo[channelId] then
		return false
	else
		return clubForbidInfo[channelId][gameType]
	end
end

local currentChannel = nil
getCurChannel = function()
	if not currentChannel then
		currentChannel = pMainChannel:new(modUtil.getOpChannel())
	end
	return currentChannel
end
