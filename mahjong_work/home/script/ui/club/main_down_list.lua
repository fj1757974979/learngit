
pClubDownlist = pClubDownlist or class(pWindow)

pClubDownlist.init = function(self, host)
	self:load("data/ui/club_main_down.lua")
	self.host = host
	self:setParent(host.club_list)
	self:initUI()
	self:regEvent()
end

pClubDownlist.initUI = function(self)
end

pClubDownlist.regEvent = function(self)
	self.btn_create:addListener("ec_mouse_click", function()
		local modClubCreate = import("ui/club/create.lua")
		if modClubCreate.pClubCreate:getInstance() then
			modClubCreate.pClubCreate:instance():setParent(self.host)
		end
		modClubCreate.pClubCreate:instance():open()
		self:clearSelf()
	end)

	self.btn_join:addListener("ec_mouse_click", function() 
		local modClubJoin = import("ui/club/join.lua")
		modClubJoin.pClubJoin:instance():open()
		self:clearSelf()
	end)
end

pClubDownlist.clearSelf = function(self)
	if not self.host then return end
	self.host:clearDownlistWnd()
end

