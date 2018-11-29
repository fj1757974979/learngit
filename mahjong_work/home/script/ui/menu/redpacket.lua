local modUIUtil = import("ui/common/util.lua")

pRedpacket = pRedpacket or class(pWindow, pSingleton)

pRedpacket.init = function(self)
	self:load("data/ui/hongbao_open.lua")
	self:setParent(gWorld:getUIRoot())
	self.btn_ok:addListener("ec_mouse_click", function()
		self:openRedpacket()
	end)
	modUIUtil.makeModelWindow(self, false, false)
end

pRedpacket.open = function(self, num)
	local count = num or 0
	self.txt_money:setText(sf("%.2f", count or 0))
	self.txt1:setText("小手一抖，红包到手")
	self.txt2:setText("红包已发送到你的账号，可通过微信提现")
	self.btn_ok:setText("提现到微信")
end

pRedpacket.openRedpacket = function(self)
	local modBattleRpc = import("logic/battle/rpc.lua")
	modBattleRpc.openRedpacket(function(success, reason) 
		if success then
			self:close()	
		else
			infoMessage(reason)
		end
	end) 
end

pRedpacket.close = function(self)
	pRedpacket:cleanInstance()
end
