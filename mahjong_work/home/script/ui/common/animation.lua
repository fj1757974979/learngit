local modEasing = import("common/easing.lua")

blinkText = function(wnd, fromA, toA)
	fromA = fromA or 180
	toA = toA or 20
	local t = 60
	local i = 1
	return setInterval(1, function()
		local txt = wnd:getTextControl()
		if i <= t/2 then
			local a = modEasing.linear(i, fromA, toA - fromA, t / 2)
			txt:setAlpha(a)
			i = i + 1
		elseif i > t / 2 and i <= t then
			local a = modEasing.linear(i - t/2, toA, fromA - toA, t / 2)
			txt:setAlpha(a)
			i = i + 1
		else
			i = 1
		end
	end)
end

subEnergy = function(parent, sub, callback)
	runProcess(1, function()
		local wnd = pWindow:new()
		local w, h = parent:getWidth(), parent:getHeight()
		wnd:setParent(parent)
		wnd:setSize(w, h)
		wnd:setColor(0)
		wnd:setAlignX(ALIGN_CENTER)
		wnd:setAlignY(ALIGN_MIDDLE)
		wnd:getTextControl():setColor(0xffffffff)
		wnd:getTextControl():setStrokeColor(0xff000000)
		wnd:getTextControl():setFontSize(40)
		wnd:getTextControl():setFontBold(1)
		wnd:setText(sub)
		local icon = pWindow:new()
		icon:setParent(wnd)
		icon:setImage("ui:res_energy.png")
		local iconw = 50
		icon:setSize(iconw, iconw)
		icon:setAlignX(ALIGN_CENTER)
		icon:setAlignY(ALIGN_MIDDLE)
		local w = wnd:getTextControl():getWidth()
		local offsetx = w - iconw / 2 + 5
		icon:setOffsetX(offsetx)
		wnd:getTextControl():setOffsetX(-iconw/2 - 5)
		local t = 20
		for i = 1, t do
			local offy = modEasing.linear(i, 0, -h, t)
			wnd:setOffsetY(offy)
			yield()
		end
		wnd:setParent(nil)
		icon:setParent(nil)
		if callback then
			callback()
		end
	end)
end
