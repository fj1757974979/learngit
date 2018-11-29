
addEditWnd = function(wnd)
	wnd:clearListener()

	wnd.bg = pWindow()
	wnd.bg:setParent(wnd)
	wnd.bg:setColor(0x77ff0000)
	wnd.bg:setSize(wnd:getWidth()+4, wnd:getHeight()+4)
	wnd.bg:setPosition(-2, -2)
	wnd.bg:setZ(1)
	wnd.bg:show(false)

	local createMoveButton = function(func)
		local btn = pWindow()
		btn:setParent(wnd.bg)
		btn:setColor(0x77ff5500)
		btn:setSize(10,10)
		btn:addListener("ec_mouse_drag", function(e)
			func(e)
		end)
		return btn
	end

	wnd.tl = createMoveButton(function(e)
		wnd:setSize(wnd:getWidth() - e:dx(), wnd:getHeight() - e:dy())
		wnd:setPosition(wnd:getX() + e:dx(), wnd:getY() + e:dy())
	end)
	wnd.tl:setPosition(-5, -5)

	wnd.tr = createMoveButton(function(e)
		wnd:setSize(wnd:getWidth() + e:dx(), wnd:getHeight() - e:dy())
		wnd:setPosition(wnd:getX(), wnd:getY() + e:dy())
	end)
	wnd.tr:setPosition(wnd.bg:getWidth() - 5, -5)

	wnd.bl = createMoveButton(function(e)
		wnd:setSize(wnd:getWidth() - e:dx(), wnd:getHeight() + e:dy())
		wnd:setPosition(wnd:getX() + e:dx(), wnd:getY())
	end)
	wnd.bl:setPosition(-5, wnd.bg:getHeight() - 5)

	wnd.br = createMoveButton(function(e)
		wnd:setSize(wnd:getWidth() + e:dx(), wnd:getHeight() + e:dy())
	end)
	wnd.br:setPosition(wnd.bg:getWidth() - 5, wnd.bg:getHeight() - 5)

	wnd.l = createMoveButton(function(e)
		wnd:setSize(wnd:getWidth() - e:dx(), wnd:getHeight())
		wnd:setPosition(wnd:getX() + e:dx(), wnd:getY())
	end)
	wnd.l:setPosition(-5, wnd.bg:getHeight()/2 - 5)

	wnd.r = createMoveButton(function(e)
		wnd:setSize(wnd:getWidth() + e:dx(), wnd:getHeight())
	end)
	wnd.r:setPosition(wnd.bg:getWidth() - 5, wnd.bg:getHeight()/2 - 5)

	wnd.t = createMoveButton(function(e)
		wnd:setSize(wnd:getWidth(), wnd:getHeight() - e:dy())
		wnd:setPosition(wnd:getX(), wnd:getY() + e:dy())
	end)
	wnd.t:setPosition(wnd.bg:getWidth()/2 - 5, -5)

	wnd.b = createMoveButton(function(e)
		wnd:setSize(wnd:getWidth(), wnd:getHeight() + e:dy())
	end)
	wnd.b:setPosition(wnd.bg:getWidth()/2 -5, wnd.bg:getHeight() - 5)

	wnd.onSetSize = function(self, w, h)
		wnd.bg:setSize(wnd:getWidth()+4, wnd:getHeight()+4)
		wnd.tr:setPosition(wnd.bg:getWidth() - 5, -5)
		wnd.bl:setPosition(-5, wnd.bg:getHeight() - 5)
		wnd.br:setPosition(wnd.bg:getWidth() - 5, wnd.bg:getHeight() - 5)
		wnd.l:setPosition(-5, wnd.bg:getHeight()/2 - 5)
		wnd.r:setPosition(wnd.bg:getWidth() - 5, wnd.bg:getHeight()/2 - 5)
		wnd.t:setPosition(wnd.bg:getWidth()/2 - 5, -5)
		wnd.b:setPosition(wnd.bg:getWidth()/2 -5, wnd.bg:getHeight() - 5)		
	end

	wnd.makeCurrent = function(wnd, flag)
		wnd.bg:show(flag)
	end
	
	wnd.isEnableEvent_ = wnd:isEnableEvent()
	wnd:enableEvent(true)
	wnd.enableEvent = function(self, flag)
		wnd.isEnableEvent_ = flag
	end
	wnd.isEnableEvent = function(self)
		return wnd.isEnableEvent_
	end

	wnd.isEnableDrag = wnd:canDrag()

	wnd:enableDrag(true)

	wnd.enableDrag = function(self, flag)
		wnd.isEnableDrag = flag
	end
	wnd.canDrag = function(self)
		return wnd.isEnableDrag
	end

	wnd.isSelfShow_ = wnd:isSelfShow()
	wnd:showSelf(true)
	wnd.isSelfShow = function()
		return wnd.isSelfShow_
	end

	wnd.showSelf = function(self, flag)
		wnd.isSelfShow_ = flag
	end

	wnd.isChildShow_ = wnd:isChildShow()
	wnd:showChild(true)
	wnd.isChildShow = function()
		return wnd.isChildShow_
	end
	wnd.showChild = function(self, flag)
		wnd.isChildShow_ = flag
	end
end
