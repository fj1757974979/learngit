local modEditPanel = import("defense_edit_wnd.lua")
local modYingZhangEditPanel = import("yingzhang_edit_wnd.lua")
local modDefense = import("td/cultivate/defense.lua")

enableEdit = function(build)
	build.mode = DEFENSE_BUILDING_MODE_EDIT
	build.onEdit = function(self)
		if self.mode ~= DEFENSE_BUILDING_MODE_EDIT then
			log("error", "click edit wnd when no eidt mode!")
			return
		end

		self:hideMenu()
		-- TODO
		if not self.editWnd then
			self.editWnd = modEditPanel.pDefenseEditWnd:new(gWorld:getUIRoot())
		end

		self.editWnd:open(self)
		self.editWnd.clickRetBtn = self:showReturnBtn(function()
			self.editWnd:close()
		end)
	end

	build.onTroopEdit = function(self)
		if self.mode ~= DEFENSE_BUILDING_MODE_EDIT then
			log("error", "click troop edit wnd when no eidt mode!")
			return
		end

		self:hideMenu()

		if not self.troopEditWnd then
			self.troopEditWnd = modYingZhangEditPanel.pYingZhangEditWnd:new(gWorld:getUIRoot(), self)
		end

		self.troopEditWnd:open(self)
		self.troopEditWnd.clickRetBtn = self:showReturnBtn(function()
			self.troopEditWnd:close()
		end)
	end
end
