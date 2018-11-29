local modClubMgr = import("logic/club/main.lua")
local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")
local modUserData = import("logic/userdata.lua")
local modProvince = import("data/info/info_club_province.lua")
local modCity = import("data/info/info_club_city.lua")
local modChannleMgr = import("logic/channels/main.lua")
local modUtil = import("util/util.lua")

pClubCreate = pClubCreate or class(pWindow, pSingleton)

pClubCreate.init = function(self)
	self:load("data/ui/club_create.lua")
	self:setParent(gWorld:getUIRoot())
	self:initUI()
	self:regEvent()
	modUIUtil.makeModelWindow(self, false, false)
end

pClubCreate.initEditText = function(self, edit)
end

pClubCreate.initUI = function(self)
	self.edit_name:setupKeyboardOffset(gWorld:getUIRoot())
	self:initLocation()
	self.txt_name:setText(TEXT("点击输入俱乐部名称"))
	self.txt_location:setText(TEXT("点击选择地区"))
	self.txt_desc:setText(TEXT("点击输入俱乐部介绍"))
	self.edit_name:set_max_input_str_len(20)
	self.edit_desc:set_max_input_str_len(200)
	local channel = modUtil.getOpChannel()
	if channel == "nc_tianjiuwang" then
		self.room_card:setImage("ui:channel_res/nc_tianjiuwang/main_room_card.png")
	end
	self.wnd_cost:setText(modChannleMgr.getCurChannel():getClubCost() or 100)
end

pClubCreate.initLocation = function(self)
	self.cityData = modCity.data
	self.provinceData = modProvince.data
	self.currProvinceCode = nil
	self.currCityCode = nil
--	self.btn_location:setText(self.provinceData[self.currProvinceCode]["name"])
end

pClubCreate.regEvent = function(self)
	self.edit_name:addListener("ec_focus", function() 
		self.txt_name:setText("")
	end)

	self.edit_name:addListener("ec_unfocus", function()
		local text = self.edit_name:getText()
		if not text then
			self.txt_name:setText(TEXT("点击输入俱乐部名称"))
		end
	end)

	self.edit_desc:addListener("ec_focus", function() 
		self.txt_desc:setText("")
	end)

	self.edit_desc:addListener("ec_unfocus", function()
		local text = self.edit_desc:getText()
		if not text then
			self.txt_desc:setText(TEXT("点击输入俱乐部介绍"))
		end
	end)

	self.btn_close:addListener("ec_mouse_click", function() 
		self:close()
	end)

	self.btn_ok:addListener("ec_mouse_click", function() 
		self:createClub()
	end)

	self.btn_location:addListener("ec_mouse_click", function()
		self.txt_location:setText("")
		local modLocaltion = import("ui/club/location.lua")
		modLocaltion.pClubLocation:instance():open(self, function(provinceCode, cityCode) 
			self:selectedCode(provinceCode, cityCode)
		end)
	end)
end

pClubCreate.selectedCode = function(self, provinceCode, cityCode)
	if not provinceCode then return end
	self.provinceCode = provinceCode
	self.cityCode = cityCode
	local provinceData = self:findData(provinceCode, self.provinceData)
	local cityData = self:findData(cityCode, self.cityData)
	if not provinceData then return end
	if not cityData then
		self.btn_location:setText(provinceData["name"])
	else
		self.btn_location:setText(provinceData["name"] .. "-" .. cityData["name"])
	end
end

pClubCreate.findData = function(self, code, datas)
	if not code or not datas then return end
	for _, data in pairs(datas) do
		if data["code"] == code then
			return data
		end
	end
	return nil
end

pClubCreate.open = function(self)
	self:show(true)
end

pClubCreate.createClub = function(self)
	local list = {
		["uid"] = modUserData.getUID(),
		["province_code"] = self.provinceCode,
		["city_code"] = self.cityCode,
		["club_name"] = self.edit_name:getText(),
		["club_text"] = self.edit_desc:getText(),
		["avatar"] = modUserData.getUserAvatarUrl()--self.wnd_icon:getTexturePath()
	}
	if not list["club_name"] or list["club_name"] == "" then 
		infoMessage("请输入俱乐部名称")
		return
	end

	if not list["province_code"] then 
		infoMessage("请选择俱乐部所在地")
		return
	end

	if not list["club_text"] then
		list["club_text"] = "这家伙很懒，什么都没留下。"
	end	

	modClubRpc.createClub(list, function(success, reason, reply)
		if success then
			infoMessage("俱乐部创建成功，赶紧邀请小伙伴们加入吧！")
			modClubMgr.getCurClub():refreshMgrClubs()
			self:close()
		else
			infoMessage(reason)
		end
	end)
end

pClubCreate.destroy = function(self)
	pClubCreate:cleanInstance()
end

pClubCreate.close = function(self)
	self:show(false)
end
