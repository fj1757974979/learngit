local modMenuBase = import("ui/card_battle/battles/paijiu/menus/base.lua")
local modBattleRpc = import("logic/card_battle/rpc.lua")

pGmMenu = pGmMenu or class(modMenuBase.pPaijiuMenuBase)

pGmMenu.getTemplate = function(self)
	return "data/ui/card/paijiu_gm_menu.lua"
end

pGmMenu.initUI = function(self)
end

pGmMenu.regEvent = function(self)
	self.btn_confirm:addListener("ec_mouse_click", function()
		if not self.observer then
			return
		end
		local srcCard = self.observer:getFirstPick()
		local dstCard = self.observer:getSecondPick()

		local userId = self.observer:getFollowee():getUserId()
		local roomId = self.observer:getBattle():getRoomId()
		modBattleRpc.gmSwitchCard(userId, roomId, srcCard:getIdx(), dstCard:getIdx(), function(success, reason)
			if success then
				self.observer:cleanPick()
			else
				infoMessage(reason)
			end
		end)
	end)
end

pGmMenu.getMenuParent = function(self)
	return nil
end

pGmMenu.setObserver = function(self, ob)
	self.observer = ob
end
