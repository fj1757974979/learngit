
------------------------------
-- X轴
DEF_D_LEFT = 1 		-- 左对齐
DEF_D_RIGHT = 2 	-- 右对齐
DEF_D_CENTER = 3 	-- 居中
DEF_D_NONE_X = 4 	-- 排列时只排列y值
-- Y轴
DEF_D_TOP = 11		-- 顶对齐
DEF_D_BOTTOM = 12	-- 底对齐
DEF_D_MIDDLE = 13	-- 居中
DEF_D_NONE_Y = 14	-- 排列时只排列x值

------------------------------
local getLen1 = function(wnd)
	return wnd:getWidth()
end

local getLen2 = function(wnd)
	return wnd:getHeight()
end

local setPos1 = function(wnd, x, y)
	wnd:setPosition(x, y)
end

local setPos2 = function(wnd, x, y)
	local _x = wnd:getX()
	wnd:setPosition(_x, y)
end

local setPos3 = function(wnd, x, y)
	local _y = wnd:getY()
	wnd:setPosition(x, _y)
end

local calStartPos = function(alignType, getLenFunc, parentWnd, wnds, cnt, gap)
	local t = alignType % 10

	-- DEF_D_LEFT or DEF_D_TOP
	if t == 1 then
		return 0

	-- DEF_D_RIGHT or DEF_D_BOTTOM
	elseif t == 2 then
		return getLenFunc(parentWnd)

	-- DEF_D_NONE_X or DEF_D_NONE_Y
	elseif t == 4 then
		return 0

	end

	-- DEF_D_CENTER or DEF_D_MIDDLE
	local parentLen = getLenFunc(parentWnd)
	local wndsLen = 0
	for i = 1, cnt do
		local wnd = wnds[ i ]
		if not wnd then
			break
		end
		wndsLen = wndsLen + getLenFunc(wnd)
	end
	local gapLen = (cnt - 1) * gap
	local ret = (parentLen - wndsLen - gapLen) / 2
	return ret
end

local getNextPos = function(idx, wndLen, gap, dire, offset)
	return (idx - 1) * (wndLen + gap) * dire + offset * dire
end

createWndListMatrix = function(parentWnd, wnds, col, alignX, alignY, gapx, gapy)
	if not parentWnd or table.isEmpty(wnds or {}) then
		return false
	end
	if alignX == DEF_D_NONE_X and alignY == DEF_D_NONE_Y then
		return false
	end
	
	alignX = alignX or DEF_D_LEFT
	alignY = alignY or DEF_D_TOP
	gapx = gapx or 0
	gapy = gapy or 0
	col = col or 1
	local wndsCnt = #wnds
	local row = math.ceil(wndsCnt / col)
	
	local sX = calStartPos(alignX, getLen1, parentWnd, wnds, col, gapx)	-- startX
	local sY = calStartPos(alignY, getLen2, parentWnd, wnds, row, gapy)	-- startY
	local oX = (alignX % 2 == 1) and 0 or getLen1(wnds[ 1 ])	-- offsetX
	local oY = (alignY % 2 == 1) and 0 or getLen2(wnds[ 1 ])	-- offsetY
	local direX = (alignX % 2 == 1) and 1 or -1 	-- diretionX
	local direY = (alignY % 2 == 1) and 1 or -1 	-- diretionY
	local setPos = setPos1
	if alignX == DEF_D_NONE_X or alignY == DEF_D_NONE_Y then
		setPos = (alignX == DEF_D_NONE_X) and setPos2 or setPos3
	end

	parentWnd.__refreshArray = function(parentWnd)
		local _r, _c = 1, 1
		local nextX, nextY = 0, 0
		local upColAndRow = function()
			_c = _c + 1
			if _c > col then
				_c = 1
				_r = _r + 1
			end
			return _r <= row
		end

		for k, wnd in ipairs(wnds) do
			if wnd:isShow() then
				nextX = getNextPos(_c, getLen1(wnd), gapx, direX, oX)
				nextY = getNextPos(_r, getLen2(wnd), gapy, direY, oY)
				-- wnd:setPosition(nextX + sX, nextY + sY)
				setPos(wnd, nextX + sX, nextY + sY)
				upColAndRow()
			end
		end
	end

	for _, wnd in ipairs(wnds) do
		wnd:setParent(parentWnd)
		wnd:setAlignX(ALIGN_LEFT)
		wnd:setAlignY(ALIGN_TOP)
		if is_function(wnd.__oldShow) then
			-- 防止嵌套
			wnd.show = wnd.__oldShow
		end
		wnd.__oldShow = wnd.show
		wnd.show = function(wnd, flg)
			flg = flg or false

			-- 当新的显示状态和旧的不一样时，才去更新控件
			local refreshFlg = (wnd:isShow() ~= flg)
			-- 一定要先更新到新的状态再去更新控件
			wnd:__oldShow(flg)
			
			if refreshFlg then
				wnd:getParent():__refreshArray()
			end
		end
	end

	parentWnd:__refreshArray()
	return true
end

------------------------------
__init__ = function()
	export("DEF_D_LEFT", DEF_D_LEFT)
	export("DEF_D_RIGHT", DEF_D_RIGHT)
	export("DEF_D_CENTER", DEF_D_CENTER)
	export("DEF_D_NONE_X", DEF_D_NONE_X)

	export("DEF_D_TOP", DEF_D_TOP)
	export("DEF_D_BOTTOM", DEF_D_BOTTOM)
	export("DEF_D_MIDDLE", DEF_D_MIDDLE)
	export("DEF_D_NONE_Y", DEF_D_NONE_Y)
end
