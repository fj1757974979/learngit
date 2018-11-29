local modBattleRpc = import("logic/battle/rpc.lua")

pStopAutoPlaying = pStopAutoPlaying or class(pWindow)

pStopAutoPlaying.init = function(self, callback)
	self:load("data/ui/auto_playing_bg.lua")
	self:setZ(C_BATTLE_UI_Z)
	self.txt_title:setText("点击取消托管")
	self.txt:setText("#cr 托管状态将会跳过所有操作，吃碰杠等，也不能胡牌哟 #n")
	self:addListener("ec_mouse_click", function()
		modBattleRpc.stopAutoPlaying(function(success, reason, reply)
			if success then
				infoMessage("欢迎回到游戏")
				if callback then
					callback()
				end
				self:close()	
			else
				infoMessage(reason)
			end
		end)	
	end)
end

pStopAutoPlaying.close = function(self)
	self:setParent(nil)
end
