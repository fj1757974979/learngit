gApplication = puppy.world.app.instance()
gGameConfig = gApplication:getConfig()

gWorld = gWorld or nil
gWidget = gWidget or nil

gKeyBoard = gKeyBoard or {}
gGameWidth = 1024
gGameHeight = 768
gSceneScale = 1

function initFS()
	local app = puppy.world.app.instance()
	local platform = app:getPlatform()
	local fsRoot = ""
	if platform == "android" then
		fsRoot = "apk:"
	elseif platform == "ios" then
		fsRoot = "bundle:"
	else
		fsRoot = ""
	end

	local ioServer = app:getIOServer()

	local l = gameconfig:getConfigStr("global", "locale", DEF_LAN_CHINESE)
	if l == "yn" then
		ioServer:mount("ui", fsRoot.."vega_resource/ui")
		ioServer:mount("icon", fsRoot.."vega_resource/icon")
		ioServer:mount("font", fsRoot.."vega_resource/font")
	end

	ioServer:mount("ui", fsRoot.."resource/ui")
	--ioServer:mount("ui", fsRoot.."resource/ui_to_pack")
	ioServer:mount("ui", fsRoot.."resource/uipack")
	ioServer:mount("ui", fsRoot.."home/iphone")
	ioServer:mount("icon", fsRoot.."resource/icon")
	ioServer:mount("map", fsRoot.."resource/map")
	ioServer:mount("effect", fsRoot.."resource/effect")
	ioServer:mount("character", fsRoot.."resource/character")
end

function initOptions()

end

function initWorld()
	gWorld = puppy.world.pWorld:new()
	--gWorld:cursor():show(false)

	local scene = gWorld:getSceneRoot()
	scene:loadCfg(1101, false)
	scene:show(true)
end

puppy.world.pObject.isOutOfWorld = function(self)
	local x,y = self:getPos()
	return x < 0 or x > gGameWidth or y < 0 or y > gGameHeight
end

function initWidget()
	gWidget = puppy.world.widget:new()
	gWidget:create(gGameWidth + 200, gGameHeight, nil)
	gGameWidth = gWidget:getWidth()
	gGameHeight = gWidget:getHeight()
	gWidget:show(true)
	gWidget:setContext(gWorld)
	gWidget:enableResize(false)
	gWidget.onClose = function(self)
		app:exit()
	end
	local tpMgr = puppy.world.pTexturePackMgr.instance()
	tpMgr:addTexturePack("ui:ui_texture.png", "ui:ui_texture.json")
	tpMgr:addTexturePack("ui:fight_texture.png", "ui:fight_texture.json")
	tpMgr:addTexturePack("ui:icon_texture.png", "ui:icon_texture.json")
end

initFS()
initOptions()
initWorld()
initWidget()

__init__ = function(module)
	loadglobally(module)
end

