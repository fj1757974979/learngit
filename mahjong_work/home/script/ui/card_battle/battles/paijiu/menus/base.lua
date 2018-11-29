local modMenuBase = import("ui/card_battle/menu.lua")

pPaijiuMenuBase = pPaijiuMenuBase or class(modMenuBase.pMenuWndBase)

pPaijiuMenuBase.adjustUI = function(self)
	local parent = self:getParent()
	if parent then
		local w = parent:getWidth()
		local sw = self:getWidth()
		if sw > w then
			self:setScale(w/sw, w/sw)
		end
	end
end
