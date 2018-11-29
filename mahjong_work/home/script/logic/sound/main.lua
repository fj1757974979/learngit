local modJson = import("common/json4lua.lua")
local modChannelMgr = import("logic/channels/main.lua")
local modEasing = import("common/easing.lua")
local modUserData = import("logic/userdata.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")

local channelToSoundPath = {
	["ds_queyue"] = "dsmj",
	["test"] = "phmj",
	["tj_lexian"] = "tjmj",
	["yy_doudou"] = "yymj",
	["za_queyue"] = "zaqueyue",
}

pSoundMain = pSoundMain or class(pSingleton)

pSoundMain.init = function(self)
	self.soundVolumeRate = 1.0
	self.musicVolumeRate = 0.5
	self.gSound = nil
	self.gMusic = nil
	self:refreshVolumeRate()
end

pSoundMain.refreshVolumeRate = function(self)
	local data = self:loadData()
	if not data then return end
	if data.soundPercent then self.soundVolumeRate = data.soundPercent end
	if data.musicPercent then self.musicVolumeRate = data.musicPercent end
end

pSoundMain.playSound = function(self, path, isLoop)
	isLoop = isLoop or false
	if iomanager:exist(path, 0, true) then
		local sound = puppy.playSound(path, isLoop)
		if sound then
			sound:setVolume(C_DEFAULT_SOUND_VOLUME * self.soundVolumeRate)
		end
		return sound
	else
		log("error", "can't find sound:", path)
		return nil
	end
end

pSoundMain.playMusic = function(self, path, isLoop)
	if iomanager:exist(path, 0, true) then
		local music = puppy.playMusic(path, isLoop)
		if music then
			music:setVolume(C_DEFAULT_MUSIC_VOLUME * self.musicVolumeRate)
			if music.setForgroundMode then
				music:setForgroundMode()
			end
			self.gMusic = music
		end
		return music
	else
		log("error", "can't find music:", path)
		return nil
	end
end

pSoundMain.stopMusic = function(self)
	if self.gMusic then
		self.gMusic:stop()
		self.gMusic = nil
	end
end

pSoundMain.pauseMusic = function(self)
	if self.gMusic then
		if self.gMusic.pause then
			self.gMusic:pause()
		end
	end
end

pSoundMain.resumeMusic = function(self)
	if self.gMusic then
		self.gMusic:play()
	end
end

pSoundMain.muteMusic = function(self, flag)
	if not self.gMusic then
		return
	end

	if flag then
		self.gMusic:setVolume(0)
	else
		self.gMusic:setVolume(self.musicVolumeRate * C_DEFAULT_MUSIC_VOLUME)
	end
end

pSoundMain.getCurrentMusic = function(self)
	return self.gMusic
end

pSoundMain.setSoundVolumeRate = function(self, rate)
	self.soundVolumeRate = math.min(math.max(rate, 0.0), 1.0)
	if puppy.setSoundVolumeRate then
		puppy.setSoundVolumeRate(self.soundVolumeRate)
	end
end

pSoundMain.setMusicVolumeRate = function(self, rate)
	self.musicVolumeRate = math.min(math.max(rate, 0.0), 1.0)
	if self.gMusic then
		self.gMusic:setVolume(self.musicVolumeRate * C_DEFAULT_MUSIC_VOLUME)
	end
end

pSoundMain.getMusicVolumeRate = function(self)
	return self.musicVolumeRate
end

pSoundMain.getSoundVoluMeRate = function(self)
	return self.soundVolumeRate
end

pSoundMain.saveData = function(self, proSound, proMusic, btnPos)
	local data = {}
	data["soundPercent"] = proSound:getPercent()
	data["musicPercent"] = proMusic:getPercent()
	data["btnPos"] = btnPos
	logv("info", data[btnPos])
	data = modJson.encode(data)
	log("info", "save user config")

	local pApp = puppy.world.pApp.instance()
	local ioMgr = pApp:getIOServer()
	local buff= puppy.pBuffer:new()
	buff:initFromString(data, len(data))

	local ret = ioMgr:save(buff, "tmp:setwindowconfig.dat", 0)
	logv("info", "save user config data write file ret")
end

pSoundMain.loadData = function(self)
	local pApp = puppy.world.pApp.instance()
	local ioMgr = pApp:getIOServer()
	if not ioMgr:fileExist("tmp:setwindowconfig.dat") then
		return nil
	end

	local data = ioMgr:getFileContent("tmp:setwindowconfig.dat")
	if data and data ~= "" then
		local setData = modJson.decode(data)
		log("info", "load setWindowConfig.dat")
		return setData
	else
		return nil
	end
end

randomCardsSound = {
	[modLobbyProto.CreateRoomRequest.TAOJIANG] = {
		["tiao"] = { [2] = 1, [4] = 1, [6] = 1 },
		["tong"] = { [2] = 1, [4] = 1, [5] = 1, [8] = 1, [9] = 1 },
		["wan"] = { [1] = 1, [2] = 1, [3] = 1, [4] = 1, [7] = 1, [9] = 1 },
		["peng"] = 1,
		["chi"] = 2,
		["gang"] = 2,
		["hu"] = 1,
		["zimo"] = 1
	},
	["public"] = {
		["tiao"] = { [2] = 1, [4] = 1, [6] = 1 },
		["tong"] = { [8] = 1, [9] = 1 },
		["wan"] = { [1] = 1, [2] = 1, [3] = 1, [4] = 1, [7] = 1, [9] = 1 },
		["peng"] = 2,
		["chi"] = 2,
		["gang"] = 2,
		["hu"] = 1,
		["zimo"] = 1
	},
}

pSoundMain.playCardSound = function(self, cardId, gender)
	if gender == T_GENDER_UNKOW then gender = T_GENDER_FEMALE end
	local tongNumber = {0, 8}
	local tiaoNumber = {9, 17}
	local wanNumber = {18, 26}
	local fengNumber = {27, 33}
	local str = ""
	local id = -1
	local typeStr = nil
	local soundName = self:getChannelSoundPath() .. "male/"
	if gender == T_GENDER_FEMALE then
		soundName = self:getChannelSoundPath() .. "female/g_"
	end
	if cardId >= tiaoNumber[1] and cardId <= tiaoNumber[2] then
		str = "tiao.mp3"
		typeStr = "tiao"
		id = cardId % tiaoNumber[1] + 1
	elseif cardId >= tongNumber[1] and cardId <= tongNumber[2] then
		str = "tong.mp3"
		typeStr = "tong"
		id = cardId / 1 + 1
	elseif cardId >= wanNumber[1] and cardId <= wanNumber[2] then
		str = "wan.mp3"
		typeStr = "wan"
		id = cardId % wanNumber[1] + 1
	elseif cardId >= fengNumber[1] and cardId <= fengNumber[2] then
		if cardId == 27 then
			soundName = soundName .. "dongfeng.mp3"
		elseif cardId == 28 then
			soundName = soundName .. "nanfeng.mp3"
		elseif cardId == 29 then
			soundName = soundName .. "xifeng.mp3"
		elseif cardId == 30 then
			soundName = soundName .. "beifeng.mp3"
		elseif cardId == 31 then
			soundName = soundName .. "zhong.mp3"
		elseif cardId == 32 then
			soundName = soundName .. "fa.mp3"
		elseif cardId == 33 then
			soundName = soundName .. "bai.mp3"
		end
	end
	-- 随机播
	local modBattleMgr = import("logic/battle/main.lua")
	local rule = modBattleMgr.getCurBattle():getCurGame():getRuleType()
	local isFangYan = modChannelMgr.getCurChannel():getIsFangYanState()
	if not isFangYan then
		rule = "public"
	end

	local saveStr = str

	if typeStr and  randomCardsSound[rule] then
		if randomCardsSound[rule][typeStr] and randomCardsSound[rule][typeStr][id] then
			local cardCount = randomCardsSound[rule][typeStr][id]
			local rnum = math.random(0, cardCount + 1)
			if rnum == 1 then
				str = typeStr .. "_1.mp3"
				local tmpPath  = soundName .. id .. str
				if not iomanager:exist(tmpPath, 0, true) then
					str = saveStr
				end
			end
		end
	end

	if not (cardId >= fengNumber[1] and cardId <= fengNumber[2]) then
		soundName = soundName .. id .. str
	end
	self:playSound(soundName)
end

pSoundMain.playCombSound = function(self, combType, gender, isZimo, isBuHua)
	local soundName = self:getChannelSoundPath() .. "male/"
	if gender == T_GENDER_FEMALE then
		soundName = self:getChannelSoundPath() .. "female/g_"
	elseif gender == T_GENDER_UNKOW then
		soundName = self:getChannelSoundPath() .. "female/g_"
	end
	local typeStr = nil
	local str = ""
	if combType == modGameProto.MINGSHUN then
		str = "chi.mp3"
		typeStr = "chi"
	elseif combType == modGameProto.MINGKE then
		str = "peng.mp3"
		typeStr = "peng"
	elseif combType == modGameProto.XIAOMINGGANG then
		str = "gang.mp3"
		typeStr = "gang"
	elseif combType == modGameProto.DAMINGGANG then
		str = "gang.mp3"
		typeStr = "gang"
	elseif combType == modGameProto.ANGANG then
		str = "angang.mp3"
		typeStr = "gang"
	elseif combType == modGameProto.HU then
		if isZimo then
			str = "zimo.mp3"
			typeStr = "zimo"
		else
			str = "hu.mp3"
			typeStr = "hu"
		end
	elseif combType == modGameProto.TING then
		str = "ting.mp3"
		typeStr = "ting"
	elseif isBuHua then
		str = "buhua.mp3"
		typeStr = "buhua"
		self:playSound(soundName .. str)
		return
	end

	local saveStr = str
	-- 随机播
	local modBattleMgr = import("logic/battle/main.lua")
	local rule = modBattleMgr.getCurBattle():getCurGame():getRuleType()
	local isFangYan = modChannelMgr.getCurChannel():getIsFangYanState()
	if not isFangYan then
		rule = "public"
	end
	if typeStr and  randomCardsSound[rule] then
		local combCount = randomCardsSound[rule][typeStr]
		if combCount then
			local rnum = math.random(0, combCount + 1)
			if rnum > 0 and rnum <= combCount then
				str = typeStr .. "_" .. rnum .. ".mp3"
				local tmpPath = soundName .. str
				if not iomanager:exist(tmpPath, 0, true) then
					str = saveStr
				end
			end
		end
	end
	-- 听牌延时
	if typeStr and typeStr == "ting" then
		runProcess(1,function()
			for i = 1, 15 do
				yield()
			end
			self:playSound(soundName .. str)
		end)
	else
		self:playSound(soundName .. str)
	end
end

pSoundMain.destroy = function(self)
	self.soundVolumeRate = 1.0
	self.musicVolumeRate = 1.0
	self.gSound = nil
	self.gMusic = nil
end

pSoundMain.getChannelSoundPath = function(self)
	local modUtil = import("util/util.lua")
	local isFangYan = false
	isFangYan = modChannelMgr.getCurChannel():getIsFangYanState()
	if not isFangYan then return "sound:card/" end
	local str = modUtil.getOpChannel()
	if not channelToSoundPath[str] then return "sound:card/" end
	return "sound:" .. channelToSoundPath[str] .. "/card/"
end

pSoundMain.getVoicePath = function(self, id, gender, mjPath)
	local soundPath = "sound:voices/"
	local genderPath = "female/"
	if gender == T_GENDER_MALE then
		genderPath = "male/"
	end
	if mjPath and mjPath ~= "" then
		return soundPath .. genderPath .. mjPath .. id .. ".mp3"
	end
	return soundPath .. genderPath ..id .. ".mp3"
end

pSoundMain.playBgm = function(self)
	self:playMusic("music:zzmj.mp3", true)
end

------------------------------------------------------

getCurSound = function()
	return pSoundMain:instance()
end
