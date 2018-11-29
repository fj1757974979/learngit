local modMenuMain = import("ui/menu/main.lua")
local modClubRpc = import("logic/club/rpc.lua")
local modUserData = import("logic/userdata.lua")

local menuMain = modMenuMain.pMainMenu

pMainQspinghe = pMainQspinghe or class(menuMain)

pMainQspinghe.init = function(self)
	menuMain.init(self)
end

pMainQspinghe.isHideInviteWnd = function(self)
	return true
end

pMainQspinghe.getBottomParent = function(self)
	return self.bottom_bg
end

--[[
pMainTest.getRemoveDistance = function(self)
	return self.btn_join_room:getWidth()
end
]]--

pMainQspinghe.adjustUI = function(self)
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

pMainQspinghe.open = function ( self )
	menuMain.open(self)
	local modUtil = import("util/util.lua")
	if modUtil.isAppstoreExamineVersion() then
		self.btn_group:show(false)
		--self.btn_create_niuniu:show(false)
		self.btn_create_room:setAlignY(ALIGN_MIDDLE)
		self.btn_join_room:setAlignX(ALIGN_MIDDLE)
		self.btn_join_room:setAlignY(ALIGN_MIDDLE)
		self.btn_create_room:setOffsetX(-self.btn_create_room:getWidth()/2)
		self.btn_join_room:setOffsetX(self.btn_create_room:getWidth()/2)
	end
end

pMainQspinghe.regEvent = function(self)
	menuMain.regEvent(self)
	-- self.btn_create_niuniu:addListener("ec_mouse_click", function()
	-- 	self:touchCreate()
	-- end)
	-- self.btn_match_new:addListener("ec_mouse_click", function()
	-- 	infoMessage(TEXT("玩法暂未开放"))
	-- end)
	self.wnd_name:addListener("ec_mouse_click", function()
		if app:getPlatform() == "macos" or modUserData.getUID() == 1330 then
			local modGmPanel = import("ui/common/gm.lua")
			modGmPanel.pGmPanel:instance():open()
		end
	end)
end

pMainQspinghe.showGroundEnter = function ( self )
    --平和麻将关闭暂不显示俱乐部图标
	self.btn_group:show(false)
end

-- pMainTest.touchCreateNiuniu = function ( self )
-- 	menuMain.touchCreate(self,{niuniu = true})
-- end

-- pMainTest.touchCreate = function ( self )
-- 	menuMain.touchCreate(self,{
-- 		paijiu_kzwf = true,
-- 		paijiu_mpqz = true,
-- 		})
-- end

pMainQspinghe.close = function(self)
	menuMain.close(self)
end

