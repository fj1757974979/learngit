local modMenuMain = import("ui/menu/main.lua")
local menuMain = modMenuMain.pMainMenu
local modUserData = import("logic/userdata.lua")

pMainNcTianjiuwang = pMainNcTianjiuwang or class(menuMain)

pMainNcTianjiuwang.init = function(self)
	menuMain.init(self)
end

pMainNcTianjiuwang.adjustUI = function(self)
	if self.wnd_adjust_bottom then
		local pw = self.wnd_adjust_bottom:getWidth()
		local ph = self.wnd_adjust_bottom:getHeight()
		local w = self.btn_adjust_parent:getWidth()
		local h = self.btn_adjust_parent:getHeight()
		local sw = pw / w
		local sh = ph / h
		local scale = math.min(sw, sh)
		self.btn_adjust_parent:setScale(scale, scale)
	end
end

pMainNcTianjiuwang.getBottomParent = function(self)
	return self.bottom_bg
end

pMainNcTianjiuwang.open = function(self)
	menuMain.open(self)
	local modUtil = import("util/util.lua")
	if modUtil.isAppstoreExamineVersion() then
		self.btn_group:show(false)
		self.btn_create_niuniu:show(false)
		self.btn_create_room:setAlignY(ALIGN_MIDDLE)
		self.btn_create_room:setAlignX(ALIGN_CENTER)
		self.btn_join_room:setAlignY(ALIGN_MIDDLE)
		self.btn_join_room:setAlignX(ALIGN_CENTER)
		self.btn_create_room:setOffsetX(-self.btn_create_room:getWidth()/ 2)
		self.btn_join_room:setOffsetX(self.btn_join_room:getWidth() / 2)
	end
end

pMainNcTianjiuwang.regEvent = function(self)
	menuMain.regEvent(self)
	self.btn_create_niuniu:addListener("ec_mouse_click", function()
		self:touchCreateNiuniu()
	end)
	self.btn_match_new:addListener("ec_mouse_click", function()
		infoMessage(TEXT("玩法暂未开放"))
	end)
	self.wnd_name:addListener("ec_mouse_click", function()
		if app:getPlatform() == "macos" or modUserData.getUID() == 1330 then
			local modGmPanel = import("ui/common/gm.lua")
			modGmPanel.pGmPanel:instance():open()
		end
	end)
	--[[
	self.btn_group:addListener("ec_mouse_click", function()
		--infoMessage(TEXT("玩法暂未开放"))
	end)
	]]--
end

--[[
pMainNcTianjiuwang.entrance = function(self)
	return
end
]]--

pMainNcTianjiuwang.isHideInviteWnd = function(self)
	return true
end

pMainNcTianjiuwang.showGroundEnter = function(self)
	self.btn_group:show(true)
end

pMainNcTianjiuwang.touchCreateNiuniu = function(self)
	menuMain.touchCreate(self, {niuniu = true})
end

pMainNcTianjiuwang.touchCreate = function(self)
	menuMain.touchCreate(self, {
					  paijiu_kzwf = true,
					  paijiu_mpqz = true,
				  })
end

pMainNcTianjiuwang.close = function(self)
	menuMain.close(self)
end
