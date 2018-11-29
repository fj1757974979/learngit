import("common/class/singleton.lua")

sf = string.format

local areaToResourcePrefix = {
	tw = "tw",
	hk = "tw",
	mo = "tw",
	en = "en",
	cn = "cn",
}

local areaToScriptPrefix = {
	tw = "tw",
	hk = "tw",
	mo = "tw",
	en = "en",
	cn = "cn",
}

local areaToLanguageName = {
	tw = "繁體中文",
	--hk = "繁體中文（香港）",
	--mo = "繁體中文（澳門）",
	cn = "简体中文",
	en = "English",
}

local allNotAlphaBetaArea = {
	cn = true,
	tw = true,
	hk = true,
	mo = true,
}

local getPackageRoot = function()
	local platform = puppy.world.app.instance():getPlatform()
	if platform == "android" then
		return "apk:"
	elseif platform == "ios" then
		return "bundle:"
	else
		return ""
	end
end

local getScriptDeviceByArea = function(area)
	local root = getPackageRoot()
	local app = puppy.world.app.instance()
	local platform = app:getPlatform()
	local prefix = areaToResourcePrefix[area]
	if not prefix then
		return nil
	end
	if platform == "andoird" then
		return sf("%shome/locale/%s/script", root, prefix)
	elseif platform == "ios" then
		if puppy.sys.isArm64Arch() then
			return sf("%shome/%s_script64.pdb", root, prefix)
		else
			return sf("%shome/%s_script.pdb", root, prefix)
		end
	else
		return sf("%shome/locale/%s/script", root, prefix)
	end
end

local getResourceDeviceByArea = function(area, path)
	local root = getPackageRoot()
	local app = puppy.world.app.instance()
	local platform = app:getPlatform()
	local prefix = areaToResourcePrefix[area]
	if not prefix then
		return nil
	end
	if platform == "android" then
		return sf("%s%s_%s", root, prefix, path)
	elseif platform == "ios" then
		local ret = sf("%s%s_%s.pdb", root, prefix, path)
		local modUtil = import("util/util.lua")
		modUtil.consolePrint(sf("========= getResourceDeviceByArea area = %s, path = %s, device = %s ==========", area, path, ret))
		return ret
	else
		return sf("%s%s_%s", root, prefix, path)
	end
end

local getScriptUpdateDeviceByArea = function(area)
	local prefix = areaToResourcePrefix[area]
	if prefix then
		return sf("home/locale/%s/script", prefix)
	else
		return nil
	end
end

pLocaleMgr = pLocaleMgr or class(pSingleton)

pLocaleMgr.init = function(self)
	self.currentArea = "cn"
	self.defaultArea = gameconfig:getConfigStr("global", "defLocale", "en")
	self.textLocaleData = nil
	self.reverseTextLocaleData = nil
	self.curReverseTextLocaleData = nil
end

pLocaleMgr.textNeedTranslate = function(self)
	return self.currentArea ~= "cn"
end

pLocaleMgr.getCurrentArea = function(self)
	return self.currentArea
end

pLocaleMgr.getSupportLanguageList = function(self)
	return areaToLanguageName
end

pLocaleMgr.isSupportLocalize = function(self)
	return gameconfig:getConfigInt("global", "localized", 1) == 1
end

pLocaleMgr.updateAlphaBetaConf = function(self, area)
	local app = puppy.world.app.instance()
	if not app.setAlphaBetaLocale then
		log("info", "no interface for setAlphaBetaLocale")
		return
	end
	if allNotAlphaBetaArea[area] then
		app:setAlphaBetaLocale(false)
	else
		app:setAlphaBetaLocale(true)
	end
end

pLocaleMgr.updateLocale = function(self, area, noSave)
	if not self:isSupportLocalize() then
		return false
	end
	if area == self.currentArea then
		return true
	end
	local prefix = areaToResourcePrefix[area]
	if not prefix and area ~= "cn" then
		-- not supported
		return false
	end
	--[[
	if area ~= "cn" then
		if not self:isSameResourceArea(area, self.currentArea) then
			self:unloadResource(self.currentArea)
			self:loadResource(area)
		end
		if not self:isSameScriptArea(area, self.currentArea) then
			self:unloadScript(self.currentArea)
			self:loadScript(area)
		end
		self.currentArea = area
	else
		-- just unload previous area
		-- default is zh-CN
		self:unloadResource(self.currentArea)
		self:unloadScript(self.currentArea)
		self.currentArea = area
	end
	]]--
	self.currentArea = area
	self:updateAlphaBetaConf(area)
	--gWorld:unloadAllTexture()
	self.reverseTextLocaleData = self.curReverseTextLocaleData
	self.curReverseTextLocaleData = nil
	self.textLocaleData = nil
	gWorld:refreshAllText()
	iomanager:cleanAllFileCache()
	refresh_imported()
	if not noSave then
		self:saveCurrentArea()
	end
	local modEvent = import("common/event.lua")
	modEvent.fireEvent("LOCALE_CHANGE")
	return true
end

pLocaleMgr.getAreaByLanguageAndCountry = function(self, language, country)
	if app:getPlatform() == "android" then
		local country = string.lower(country)
		if string.find(country, "cn") ~= nil then
			return "cn"
		else
			return country
		end
	elseif app:getPlatform() == "ios" then
		local lan = ""
		if string.find(string.lower(language), "zh") ~= nil then
			local modUtil = import("util/util.lua")
			modUtil.consolePrint(sf("====== getAreaByLanguageAndCountry language = %s ======", language))
			-- 中文
			if language == "zh-TW" or 
				language == "zh-Hant-TW" then
				-- 繁体台湾
				return "tw"
			elseif language == "zh-HK" or 
				language == "zh-Hant-HK" then
				-- 繁体香港
				return "hk"
			elseif language == "zh-MO" or
				language == "zh-Hant-MO" then
				return "mo"
			elseif language == "zh-Hant-CN" then
				-- 繁体
				return "tw"
			elseif language == "zh-Hans-CN" then
				-- 简体
				return "cn"
			else
				-- 配置的默认
				return self.defaultArea
			end
		else
			-- 非中文
			local langs = string.split(language, "-")
			return string.lower(langs[1])
		end
	else
		return nil
	end
end

pLocaleMgr.loadLocale = function(self, language, country)
	if not self:isSupportLocalize() then
		return
	end
	if not language or not country then
		return
	end
	local area = self:getAreaByLanguageAndCountry(language, country)
	local modUtil = import("util/util.lua")
	modUtil.consolePrint(sf("======= language area = %s =======", area))
	if not area then
		area = self.defaultArea
	end
	if area == "cn" then
		-- 默认简体中文
		return
	end
	local prefix = areaToResourcePrefix[area] 
	modUtil.consolePrint(sf("======= language prefix = %s =======", prefix))
	if not prefix then
		area = self.defaultArea
		prefix = areaToResourcePrefix[area]
		if not prefix then
			return
		end
	end
	--[[
	self:loadResource(area)
	self:loadScript(area)
	]]--
	self.currentArea = area
	self.textLocaleData = nil
	self.reverseTextLocaleData = nil
	self.curReverseTextLocaleData = nil
end

pLocaleMgr.saveCurrentArea = function(self)
	local data = {}
	data["area"] = self.currentArea
	local modJson = import("common/json4lua.lua")
	data = modJson.encode(data)
	local app = puppy.world.pApp.instance()
	local iomgr = app:getIOServer()
	local buff = puppy.pBuffer:new()
	buff:initFromString(data, len(data))
	iomgr:save(buff, "tmp:locale.dat", 0)
end

pLocaleMgr.getSavedArea = function(self)
	local app = puppy.world.pApp.instance()
	local iomgr = app:getIOServer()
	if not iomgr:fileExist("tmp:locale.dat") then
		return nil
	end
	local data = iomgr:getFileContent("tmp:locale.dat")
	if data and data ~= "" then
		local modJson = import("common/json4lua.lua")
		local data = modJson.decode(data)
		if data then
			return data["area"]
		else
			return nil
		end
	else
		return nil
	end
end

pLocaleMgr.isSameResourceArea = function(self, area1, area2)
	return areaToResourcePrefix[area1] == areaToResourcePrefix[area2]
end

pLocaleMgr.isSameScriptArea = function(self, area1, area2)
	return areaToScriptPrefix[area1] == areaToScriptPrefix[area2]
end

pLocaleMgr.loadScript = function(self, area)
	local app = puppy.world.app.instance()
	local ioServer = app:getIOServer()
	-- mount script update
	local path = getScriptUpdateDeviceByArea(area)
	if path then
		ioServer:mountUpdateFront("script", path)
	end
	-- mount script
	path = getScriptDeviceByArea(area)
	if path then
		ioServer:mountFront("script", path)
	end
end

pLocaleMgr.unloadScript = function(self, area)
	local app = puppy.world.app.instance()
	local ioServer = app:getIOServer()
	-- unmount script update
	local path = getScriptUpdateDeviceByArea(area)
	if path then
		ioServer:unmountUpdate("script", path)
	end
	-- unmount script
	path = getScriptDeviceByArea(area)
	if path then
		ioServer:unmountDevice("script", path)
	end
end

pLocaleMgr.loadResource = function(self, area)
	local app = puppy.world.app.instance()
	local ioServer = app:getIOServer()
	-- mount resource update
	local prefix = areaToResourcePrefix[area]
	if prefix then
		ioServer:mountUpdateFront("ui", prefix.."_resource/ui")
		ioServer:mountUpdateFront("icon", prefix.."_resource/icon")
		-- mount resource
		local root = getPackageRoot()
		ioServer:mountFront("ui", getResourceDeviceByArea(area, "resource/ui"))
		ioServer:mountFront("icon", getResourceDeviceByArea(area, "resource/icon"))
		ioServer:mountFront("sound", getResourceDeviceByArea(area, "resource/sound"))
		ioServer:mountFront("music", getResourceDeviceByArea(area, "resource/music"))
	end
end

pLocaleMgr.unloadResource = function(self, area)
	local app = puppy.world.app.instance()
	local ioServer = app:getIOServer()
	-- unmount resource update
	local prefix = areaToResourcePrefix[area]
	if prefix then
		ioServer:unmountUpdate("ui", prefix.."_resource/ui")
		ioServer:unmountUpdate("icon", prefix.."_resource/icon")
		-- unmount resource
		local root = getPackageRoot()
		ioServer:unmountDevice("ui", getResourceDeviceByArea(area, "resource/ui"))
		ioServer:unmountDevice("icon", getResourceDeviceByArea(area, "resource/icon"))
		ioServer:unmountDevice("sound", getResourceDeviceByArea(area, "resource/sound"))
		ioServer:unmountDevice("music", getResourceDeviceByArea(area, "resource/music"))
	end
end

pLocaleMgr.resetTextLocaleData = function(self)
	self.textLocaleData = nil
end

pLocaleMgr.wrapText = function(self, id)
	--[[
	if not self:textNeedTranslate() then
		return text
	end
	]]--
	if not id then
		return "NaN"
	end
	local currentArea = self.currentArea
	local prefix = areaToScriptPrefix[currentArea]
	if not prefix then
		log("error", "can't find language prefix")
		return id
	end
	if not self.textLocaleData then
		self.textLocaleData = {}
		self.curReverseTextLocaleData = {}
		local reverse = function(data)
			local reverseData = {}
			for _id, info in pairs(data) do
				local tarWord = info[prefix]
				reverseData[tarWord] = _id
			end
			return reverseData
		end
		local modTextLocale = import("data/info/info_locale.lua")
		table.insert(self.textLocaleData, modTextLocale.data)
		table.insert(self.curReverseTextLocaleData, reverse(modTextLocale.data))
		for i = 2, 100 do
			local path = sf("data/info/info_locale%d.lua", i)
			if iomanager:fileExist("script:"..path) then
				modTextLocale = import(path)
				table.insert(self.textLocaleData, modTextLocale.data)
				table.insert(self.curReverseTextLocaleData, reverse(modTextLocale.data))
			else
				break
			end
		end
	end
	for idx, localeData in pairs(self.textLocaleData) do
		if not table.isEmpty(localeData or {}) and localeData[id] then
			return localeData[id][prefix]
		end
	end
	return id
end

pLocaleMgr.reverseText = function(self, text)
	if not self.reverseTextLocaleData then
		return text
	end
	for idx, reverseData in pairs(self.reverseTextLocaleData) do
		if reverseData[text] then
			return reverseData[text]
		end
	end
	return nil
end

TEXT = function(id, ...)
	if not tonumber(id) then
		return id
	end
	local mgr = pLocaleMgr:instance()
	return mgr:wrapText(tonumber(id))
end

puppy.world.pWorld.refreshLocalizedText = function(self, texObj)
	local text = texObj:getText()
	if text and text ~= "" then 
		local mgr = pLocaleMgr:instance()
		local id = mgr:reverseText(text)
		if not id then
			texObj:setText(text)
		else
			texObj:setText(TEXT(id))
		end
	end
end

__init__ = function(self)
	export("TEXT", TEXT)
	export("sf", sf)
end
