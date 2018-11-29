local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")

pMenuCreate = pMenuCreate or class(pWindow)

pMenuCreate.init = function(self, clubInfo, memberInfos, host)
	self:load("data/ui/club_desk_card_new.lua")
	self:setParent(gWorld:getUIRoot())
	self.clubInfo = clubInfo
	self.host = host
	self:initUI()
	self:regEvent()
end

pMenuCreate.initUI = function(self)
	self.txt_new:setText("新建牌局")
end

pMenuCreate.regEvent = function(self)
	self:addListener("ec_mouse_click", function() 
		local modClubCreate = import("ui/club/create_ground.lua")
		if modClubCreate.pMainCreate:getInstance() then
			modClubCreate.pMainCreate:instance():show(true)
			return
		end
		modClubCreate.pMainCreate:instance():open(self.clubInfo, function() 
			self:successCallback()
		end)
	end)
end

pMenuCreate.successCallback = function(self)
	if not self.host then return end
	self.host:refreshGrounds()
end


