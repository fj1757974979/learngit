local modJson = import("common/json4lua.lua")

function initLocale()
	if puppy.sys.getLanguage then
		local modLocaleMgr = import("locale/main.lua")
		local localeMgr = modLocaleMgr.pLocaleMgr:instance()
		local savedArea = localeMgr:getSavedArea()
		if savedArea then
			localeMgr:updateLocale(savedArea, true)
		else
			local language = puppy.sys.getLanguage()
			local country = puppy.sys.getCountry()
			local modUtil = import("util/util.lua")
			modUtil.consolePrint(sf("====== language = %s, country = %s ======", language, country))
			localeMgr:loadLocale(language, country)
		end
	end
end




function initFS()
	local app = puppy.world.app.instance()
	app.onExit = function(self)
		log("error", "app on exit!!!!!!")
		gWidget = nil
		gWorld.__gameSocket = nil
		gWorld = nil
	end
	local platform = app:getPlatform()
	local ioServer = app:getIOServer()
	local modUtil = import("util/util.lua")
	local fsRoot = modUtil.getFsRoot()
	ioServer:mountUpdate("ui", "resource/ui")
	ioServer:mountUpdate("sound", "resource/sound")
	ioServer:mountUpdate("music", "resource/music")
	ioServer:mountUpdate("effect", "resource/effect")
	ioServer:mountUpdate("font", "resource/font")
	if platform == "android" then
		ioServer:mount("ui", fsRoot.."resource/ui")
		ioServer:mount("sound", fsRoot.."resource/sound")
		ioServer:mount("music", fsRoot.."resource/music")
		ioServer:mount("font", fsRoot.."resource/font")
		ioServer:mount("effect", fsRoot.."resource/effect")
	elseif platform == "ios" then
		ioServer:mount("ui", fsRoot.."resource/ui.pdb")
		ioServer:mount("sound", fsRoot.."resource/sound")
		ioServer:mount("sound", fsRoot.."resource/sound.pdb")
		ioServer:mount("music", fsRoot.."resource/music")
		ioServer:mount("music", fsRoot.."resource/music.pdb")
		ioServer:mount("font", fsRoot.."resource/font.pdb")
		ioServer:mount("effect", fsRoot.."resource/effect.pdb")
	else
		--puppy.debug.toggleDebug(true)

		ioServer:mount("ui", fsRoot.."resource/ui")
		ioServer:mount("sound", fsRoot.."resource/sound")
		ioServer:mount("music", fsRoot.."resource/music")
		ioServer:mount("font", fsRoot.."resource/font")
		ioServer:mount("effect", fsRoot.."resource/effect")
	end
end

function initOptions()

end

function seedRand()
	math.randomseed(tostring(os.time()):reverse():sub(1,6))
end

function initWorld()
	gWorld = puppy.world.pWorld:new()

	-- init texture pack manager
	--local tpMgr = puppy.world.pTexturePackMgr.instance()
	--tpMgr:addTexturePack("ui:ui_texture.png", "ui:ui_texture.json")
	--tpMgr:addTexturePack("ui:fight_texture.png", "ui:fight_texture.json")
	--tpMgr:addTexturePack("ui:icon_texture.png", "ui:icon_texture.json")

	local scene = gWorld:getSceneRoot()

	-- scene:loadCfg(1000, true)
	-- scene:show(true)

	scene:setScale(gSceneScale, gSceneScale)
	scene.canDrag = true
	scene.canScale = false
	scene.onDrag = nil
	listenerFun , scene.dragListener = scene:addListener("ec_mouse_drag", function(e)
		--log("info", "drag", x, y, dx, dy)
		local x, y, dx, dy = 0,0,0,0
		if e:touchCount() == 1 then
			if scene.canDrag then
				dx = e:dx()
				dy = e:dy()
			end
		elseif e:touchCount() == 2 and scene.canScale then
			local point1 = e:getTouchPoint(0)
			local point2 = e:getTouchPoint(1)
			local x1,y1 = point1:x(), point1:y()
			local dx1,dy1 = point1:dx(), point1:dy()
			local px1, py1 = x1 - dx1, y1 - dy1

			local x2,y2 = point2:x(), point2:y()
			local dx2,dy2 = point2:dx(), point2:dy()
			local px2, py2 = x2 - dx2, y2 - dy2

			local scale = distance({x2, y2}, {x1, y1}) / distance({px2,py2}, {px1, py1})

			local center = {x = (px1 + px2) / 2, y = (py1 + py2) / 2}
			local sceneCenter = scene:getLocalCoord((px1 + px2) / 2,
							      (py1 + py2) / 2)
			local oldScale = scene:getSX()
			local finalScale = max({oldScale * scale,
					       gGameWidth/scene:getWidth(),
					       gGameHeight/scene:getHeight()})
			finalScale = min({finalScale, gSceneScale * 1.25})

			local scaleFactor = finalScale / oldScale
			scene:setScale(finalScale, finalScale)
			dx = sceneCenter.x * (oldScale - finalScale)
			dy = sceneCenter.y * (oldScale - finalScale)
		end

		--[[
		-- 禁掉上下拖动
		dy = 0
		]]--
		x = scene:getX() + dx
		y = scene:getY() + dy
		local sx,sy = scene:getSX(), scene:getSY()
		if x > 0 then x = 0 end
		if x + scene:getWidth()*sx < gGameWidth then x = - scene:getWidth()*sx + gGameWidth end
		if y > 0 then y = 0 end
		if y + scene:getHeight()*sy < gGameHeight then y = - scene:getHeight()*sy + gGameHeight end
		scene:setPosition(x, y)
		if scene.onDrag then
			scene:onDrag()
		end
	end)

	gWorld.scene = scene

	math.randomseed(getCurrentTime())
end

puppy.world.pObject.isOutOfWorld = function(self)
	local x,y = self:getPos()
	return x < 0 or x > gGameWidth or y < 0 or y > gGameHeight
end

-- 游戏后台超时时间
local MAX_BACKGROUND_TIME = 1 * 60 * 60

function initWidget()

	app.onEnterBackground = function(self)
		log("info", "切到后台,保存数据...")
		local modUtil = import("util/util.lua")
		modUtil.consolePrint("============= enter backgroud =============")
		app.timeStamp = modUtil.getServerTime()
		local modSessionMgr = import("net/mgr.lua")
		modSessionMgr.pSessionMgr:instance():onEnterBackground()
		local modEvent = import("common/event.lua")
		modEvent.fireEvent(EV_BACK_GROUND)
		app.__is_background = true
	end

	app.onEnterForeground = function(self)
		setTimeout(10, function()
			if not app.__is_background then
				return
			end
			app.__is_background = false
			local modUtil = import("util/util.lua")
			modUtil.consolePrint("============= enter foregroud =============")
			log("info", "切回前台,重新连接...")
			local modSessionMgr = import("net/mgr.lua")
			modSessionMgr.pSessionMgr:instance():onEnterForeground()
		end)
	end

	app.onCallLua = function(self, json)
		local modJson = import("common/json4lua.lua")
		local modUtil = import("util/util.lua")
		modUtil.consolePrint("mlink"..json)
		local jsonData = modJson.decode(json)
		if jsonData.method == "enter_room" then
			self.enter_room_id = jsonData.params[1]
		elseif jsonData.method == "join_club" then
			self.join_club_id = jsonData.params[1]
		elseif jsonData.method == "join_group" then
			self.join_group_id = jsonData.params[1]
		end
	end

	app.onResume = function(self)

	end

	app.onPause = function(self)

	end

	app.onMemoryLow = function(self)
		local modUtil = import("util/util.lua")
		modUtil.consolePrint("low memory, gc")
		gc()
	end

	app.onSDKLogin = function(self, isSuccess, channelId, _userId, userName, token, productCode, channelUserId, phoneInfo)
		setTimeout(33, function()
			local modUtil = import("util/util.lua")
			modUtil.consolePrint(sf("========= %s %s %s %s %s %s =========", userName, token, productCode, channelUserId, phoneInfo, isSuccess))
			local modEvent = import("common/event.lua")
			modEvent.fireEvent("SDK_LOGIN", isSuccess, _userId, userName, channelUserId, token, channelId, phoneInfo, productCode)
		end)
	end

	app.onShowSDKLoginWindow = function(self)

	end

	app.onSDKPayOrderFinish = function(self, isSuccess, orderId, pid)
		setTimeout(33, function()
			local modUtil = import("util/util.lua")
			modUtil.consolePrint(sf("============= orderId: %s, pid: %s ============", orderId, pid))
			local modShop = import("logic/shop/main.lua")
			modShop.pShopMgr:instance():notifySdkOrder(isSuccess, orderId, pid)
		end)
	end

	app.onNotifyRelogin = function(self)
		local modMain = import("init/main.lua")
		if modMain.isDestroying() then
			return
		end
		modMain.setDestroyFlag(true)
		-- 设定延迟，该函数从jvm调入，若接下来的逻辑调回jvm，则会detach jvm，造成crash
		setTimeout(20, function()
			local modPreloadPanel = import("ui/login/preloading_panel.lua")
			local preloadPanel = modPreloadPanel.getPreloadPanel()
			preloadPanel:open()
			preloadPanel:setTips(TEXT(113))

			setTimeout(33, function()
				modMain.destroy(function()
					local modLoginMain = import("logic/login/main.lua")
					modLoginMain.pLoginMgr:instance():resetLogin()
					modLoginMain.pLoginMgr:instance():initLogin(nil, function()
						preloadPanel:show(false)
						modMain.setDestroyFlag(false)
					end)
				end)
			end)

			--[[
			local modConfirmDialog = import("common/ui/confirm_dialog.lua")
			modConfirmDialog.pNoticeDialog:instance():openCustom("您的登录状态已失效，请重新登录游戏", "确定", function()
				local modLoginMain = import("td/main_panel/login_main.lua")
				modLoginMain.resetLogin()
				setTimeout(15, function()
					modLoginMain.initLogin()
				end)
			end)
			]]--
		end)
	end

	app.onNotifyAutoRelogin = function(self, channelId, _userId, userName, token, productCode, channelUserId, phoneInfo)
		local modMain = import("init/main.lua")
		if modMain.isDestroying() then
			return
		end
		modMain.setDestroyFlag(true)
		setTimeout(20, function()
			local modPreloadPanel = import("ui/login/preloading_panel.lua")
			local preloadPanel = modPreloadPanel.getPreloadPanel()
			preloadPanel:open()
			preloadPanel:setTips(TEXT(114))

			setTimeout(33, function()
				modMain.destroy(function()
					local loginInfo = {
						channelId = channelId,
						accountId = _userId,
						account = userName,
						token = token,
						productCode = productCode,
						channelUserId = channelUserId,
						phoneInfo = phoneInfo,
					}
					local modLoginMain = import("logic/login/main.lua")
					modLoginMain.pLoginMgr:instance():resetLogin()
					modLoginMain.pLoginMgr:instance():initAutoRelogin(loginInfo, function()
						preloadPanel:close()
						modMain.setDestroyFlag(false)
					end)
				end)
			end)
		end)
	end

	app.onNotifyWifiStateChanged = function(isConnected)
	end

	gWidget = puppy.world.widget:new()

	gWidget.onInitDone = function(self, start)
		if not gWidget.__isInit then
			_G["gGameWidth"] = gWidget:getWidth()
			_G["gGameHeight"] = gWidget:getHeight()

			if start then
				local modUtil = import("util/util.lua")
				modUtil.consolePrint("============ onInitDone autoupdate ============")
				setTimeout(10, function()
					initLocale()
				end)
				setTimeout(33, function()
					-- 检测更新
					local modUpdate = import("init/update.lua")
					modUpdate.autoUpdate()
				end)
				gWidget.__isInit = true
			else
				setTimeout(1, function()
					local modUpdate = import("init/update.lua")
					modUpdate.preAutoUpdate()
					local modUtil = import("util/util.lua")
					modUtil.consolePrint("============ onInitDone preupdate ============")
				end)
			end
		end
	end

	gWidget.onClose = function(self)
		log("error", "closing game....")
		app:exit()
	end

	gWidget.onResize = function(self, width, height)
		_G["gGameWidth"] = width
		_G["gGameHeight"] = height
	end

	--gWidget:create(1024, 768, nil)
	gWidget:create(1334, 750, nil)
	--gWidget:create(1920, 1080, nil)
	_G["gGameWidth"] = gWidget:getWidth()
	_G["gGameHeight"] = gWidget:getHeight()

	gWidget:show(true)
	gWidget:setContext(gWorld)
	gWidget:enableResize(false)
end

initFS()
initOptions()
initWorld()
initWidget()

__init__ = function(module)
	export("gWorld", gWorld)
	export("gWidget", gWidget)
end
