local modUIUtil = import("ui/common/util.lua")
local modDismissMgr = import("logic/dismiss/main.lua")
local modUser = import("logic/userdata.lua")
local modEvent = import("common/event.lua")
local modSet = import("ui/menu/set.lua")

pCommonCue = pCommonCue or class(pWindow, pSingleton)

pCommonCue.init = function(self)
	self:load("data/ui/dissroom.lua")
	self:setParent(gWorld:getUIRoot())
	self:setZ(C_BATTLE_UI_Z )
	self:regEvent()
	self:showSelf(true)
	self.isOwnedDis = false
	modUIUtil.makeModelWindow(self, false, true)
end

pCommonCue.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_ok:addListener("ec_mouse_click", function()
		self:answerCloseRoom()
	end)

	self.btn_cancel:addListener("ec_mouse_click", function()
		self:close()
	end)
end

pCommonCue.open = function(self, host, roomId, gameType, callback)
	self.host = host
	self.roomId = tonumber(roomId)
	self.callback = callback
	self.gameType = gameType
	self.dismissMgr = modDismissMgr.pDismissMgr:instance(gameType)
	self:setParent(host:getParent())
	self:setZ(C_BATTLE_UI_Z)
	self.wnd_text:setText("您要解散房间吗?")
end

pCommonCue.answerCloseRoom = function(self)
	if not self.roomId then
		infoMessage("找不到房间号")
		return
	end

	-- 正常房间解散
	if	self.dismissMgr:getIsGaming() then
		self.dismissMgr:dismissRoom(function(success)
			if success then
				self:destroyDismissMgr()
				local modDisMissRoomList = import("ui/battle/dismisslist.lua")
				modDisMissRoomList.pDisMissList:instance():open(modUser.getUID(), self.gameType)
			end
			self:close()
		end)
	else
		self.dismissMgr:dismissRoom(function(success)
			if self.dismissMgr:getDismissBattle() then
				self.dismissMgr:battleDestroy()
			end
			if self.callback then
				self.callback()
			end
			self:close()
		end)
	end

	if modSet.pSetMain:getInstance() then
		modSet.pSetMain:instance():close()
	end
end

pCommonCue.destroyDismissMgr = function(self)
	if self.dismissMgr then
		self.dismissMgr:destroy()
		self.dismissMgr = nil
	end
end

pCommonCue.close = function(self)
	self.host = nil
	self.roomId = nil
	self.gameType = nil
	self:destroyDismissMgr()
	pCommonCue:cleanInstance()
end


