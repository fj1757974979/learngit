local modMenu = import("menu.lua")
local modMacor = import("logic/macros.lua")

initUI = function()
	local uiRoot = gWorld:getUIRoot()
	modMenu.showMenu()
end

__init__ = function()
	initUI()
	export("gEditFlg", true)
end
