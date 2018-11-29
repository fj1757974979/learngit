local modJson = import("common/json4lua.lua")
local modUtil = import("util/util.lua")

pLoadMgr = pLoadMgr or class(pSingleton)

pLoadMgr.init = function(self)
	self.mainMenuResList = {
		"ui:main_room_card.png",
		"ui:main_room_card_bg.png",
		"ui:main_gb_2.png",
		"ui:icon_3.png",
		"ui:icon_2.png",
		"ui:icon_1.png",
		"ui:hair_left_2.png",
		"ui:hair_left_1.png",
		"ui:hair_right_2.png",
		"ui:hair_right_1.png",
		"ui:eye_1.png",
		"ui:main_woman.png",
		"ui:main_notes.png",
		"ui:main_radio_front.png",
		"ui:main_radio_bg.png",
		"ui:main_speed_icon.png",
		"ui:main_speed_show.png",
		"ui:main_speed_text.png",
		"ui:main_speed.png",
		"ui:main_daikai_text.png",
		"ui:main_daikai.png",
		"ui:main_id.png",
		"ui:bg_top_mini.png",
		"ui:main_icon_bg.png",
		"ui:main_shop_icon.png",
		"ui:main_room_card_bg.png",
		"ui:main_create_shadow.png",
		"ui:main_create_icon.png",
		"ui:main_create_text.png",
		"ui:main_create_room.png",
		"ui:main_join_icon.png",
		"ui:main_join_shadow.png",
		"ui:main_join_text.png",
		"ui:main_join_room.png",
		"ui:main_recharge_icon.png",
		"ui:main_buy_bg.png",
		"ui:main_buy_icon.png",
		"ui:main_standings.png",
		"ui:main_share.png",
		"ui:main_howtoplay.png",
		"ui:main_setting.png",
		"ui:main_bottombar_main.png",
		"ui:main_btn_auth.png",
		"ui:main_invite.png",
	}
	self.hasLoaded = false
end

pLoadMgr.loadAllRes = function(self)
	if not puppy.world.pTexture.loadTextureWrapper then
		self.hasLoaded = true
		return
	end
	-- 优先加载主界面资源
	for _, path in ipairs(self.mainMenuResList) do
		puppy.world.pTexture.loadTextureWrapper(path, 1)
	end
	-- 再加载麻将资源
	self:loadCardRes()
	-- 加载剩余资源
	local ioMgr = app:getIOServer()
	local jsonPath = sf("etc/files_%s", modUtil.getOpChannel())
	if not ioMgr:fileExist(jsonPath) then
		jsonPath = "etc/files"
	end
	local filesData = ioMgr:getFileContent(jsonPath)
	local jsonData = modJson.decode(filesData)
	for _, info in ipairs(jsonData) do
		local path = info[1]
		if path then
			if string.find(path, "resource/ui/") ~= nil then
				if string.find(path, "channel_res/") == nil or 
					string.find(path, modUtil.getOpChannel()) ~= nil then
					path = string.gsub(path, "resource/ui/", "ui:")
					puppy.world.pTexture.loadTextureWrapper(path, 107)
				end
			end
		end
	end
	self.hasLoaded = true
end

pLoadMgr.loadCardRes = function(self)
	if not puppy.world.pTexture.loadTextureWrapper then
		return
	end
	local cardPaths = {}
	local path = "ui:card/"
	for i = 0, 3 do
		local bPath = i .. "/show_"
		if i == 0 then bPath = i .. "/hand_" end
		for n = 0, 41 do
			table.insert(cardPaths, path .. bPath .. n .. ".png")
		end
		table.insert(cardPaths, path .. i .. "/show_hide.png")
		if i > 0 then
			table.insert(cardPaths, path .. "hand_" .. i .. ".png")
		end
	end
	if table.size(cardPaths) >= 0 then
		self:loadImgs(cardPaths)
	end
end

pLoadMgr.loadImgs = function(self, paths, level)
	if not paths or #paths <= 0 then return end
	local pApp = puppy.world.pApp.instance()
	local ioMgr = pApp:getIOServer()

	for _, path in pairs(paths) do
		if ioMgr:fileExist(path) then
			puppy.world.pTexture.loadTextureWrapper(path, level or 107)
		else
			log("error", "can not find img. path:", path)
		end
	end
end

pLoadMgr.hasResourceLoaded = function(self)
	if not puppy.world.pTexture.loadTextureWrapper then
		return true
	end
	return self.hasLoaded
end

getCurLoadMgr = function()
	return pLoadMgr:instance()
end
