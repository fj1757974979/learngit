local modOption = import("options.lua")
local modUIEditor = import("uieditor/main.lua")
local modCharacter = import("tool/character/main.lua")
local modEffect = import("tool/effect/main.lua")

pMenu = pMenu or class(pWindow, pSingleton)

pMenu.init = function(self)
	local root = gWorld:getUIRoot()
	self:setParent(root)
	self:load("tool/template/menu.lua")
	self:setSize(gGameWidth, gGameHeight)
	self:setColor(0x77777777)

	local hideAll = function()
		modUIEditor.hideUIEditor()
	end

	self.btnUI:setText(TEXT("UI编辑器"))
	self.btnUI:addListener("ec_mouse_left_up", function()
		hideAll()
		modUIEditor.showUIEditor()
		self:close()
	end)

	self.btnChar:setText(TEXT("角色"))
	self.btnChar:addListener("ec_mouse_click", function()
		modCharacter.showCharacterTool()
	end)


	self.btnEffect:setText(TEXT("特效"))
	self.btnEffect:addListener("ec_mouse_click", function()
		modEffect.showEffectTool()
	end)

	self.txtMouse = puppy.world.pText:new()
	self.txtMouse:setParent(self)
	self.txtMouse:setAlignX(ALIGN_TOP)
	self.txtMouse:setAlignY(ALIGN_LEFT)
	self.txtMouse:setColor(0xFFFFFFFF)
	self.txtMouse:setPosition(gGameWidth - 200, 10)

	self.hookMouseMove = gWorld:addHook("ec_mouse_move", function(e)
		self.txtMouse:setText(string.format("%d,%d",e:x(), e:y()))
	end)
end

showMenu = function()
	pMenu:instance():open()
	pMenu:instance():show(true)
	puppy.debug.toggleDebug(false)
end

