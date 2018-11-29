--简单调用
--local m_float_tip = import("common/ui/float_tip.lua")
--m_float_tip.add_tip(ctx.ui, 100, 100, "#B攻击+100")
--复杂调用，参数依次为(父框, x坐标, y坐标, "#c41E715显示文字", "字体", 字体大小, 字体粗细)
--例如：
--1、在角色上飘数字
--local m_float_tip = import("common/ui/float_tip.lua")
--人物飘字本身也是挂在ctx.ui上，但是人物不是100%居中，所以还是计算人物坐标，对玩家体验较好
--local vp = ctx.scene:get_viewpoint()
--local hero = ctx.scene:get_player(ctx:get_id())
--切换场景可能会导致hero丢失，微端比较明显
--if not vp or not hero then return end
--local x = hero:get_x(false)-vp[1]
--local y = hero:get_y(false)-vp[2]-80 -- 减去80像素令飘字大概从人物腰部启动
--m_float_tip.add_tip(ctx.ui, x, y, "#B攻击+200", nil, 32)
--2、在其他UI窗口上飘数字
--local m_float_tip = import("common/ui/float_tip.lua")
--hello_panel = ctx:get_element("hello_panel") or ctx:create_element("hello_panel", puppy.gui.pWindow, ctx.ui)
--hello_panel:set_pos(800, 500)
--hello_panel:set_size(200, 100)
--local x = hello_panel:get_width()/2
--local y = hello_panel:get_height()/2
--m_float_tip.add_tip(hello_panel, x, y, "#B攻击+200", "宋体", 14, 600)
--m_float_tip.add_tip(hello_panel, x, y, "#B攻击+200", "宋体", 14, 600)
--m_float_tip.add_tip(hello_panel, x, y, "#B攻击+200", "宋体", 14, 600)

local m_const = import("common/const.lua")
local is_floating = false
local move_distance = 110
local waiting_list = {}

add_tip = function(parent, x, y, tip_text, tip_font, tip_size, tip_bold)
	if not parent then
		return
	end
	if parent.is_real_show and not parent:is_real_show() then
		return
	end
	local waiting_key = parent
	local ctx = parent:getWorld()
	-- 如果在飘，则放入waiting_list
	if is_floating then
		local waiting = {
			["parent"] = parent,
			["x"] = x,
			["y"] = y,
			["tip_text"] = tip_text,
			["tip_font"] = tip_font,
			["tip_size"] = tip_size,
			["tip_bold"] = tip_bold,
		}		
		waiting_list[waiting_key] = waiting_list[waiting_key] or {}
		table.insert(waiting_list[waiting_key], waiting)
		return
	end
	
	-- 条件齐全，开始飘字
	is_floating = true
	
	local tip_wnd = puppy.gui.pWindow:new(parent)
	tip_wnd:get_image_list(puppy.gui.ip_window):clear_image()
	tip_wnd:set_z(m_const.ZVALUE_NORMAL)

	tip_wnd:set_size(64, 20)
	tip_wnd:auto_set_width(true)
	tip_wnd:set_font(tip_font or "文泉驿微米黑", tip_size or 24, tip_bold or 800)
	tip_wnd:set_text_color(puppy.gui.ip_window, 0xff000000, 0xff121212)
	tip_wnd:set_text("#c41E715"..tip_text)
	
	local wnd_w, wnd_h = tip_wnd:get_width(), tip_wnd:get_height()
	local wnd_x = x-wnd_w/2
	local wnd_y = y-wnd_h/2

	tip_wnd:set_pos(wnd_x, wnd_y)
	
	local move_list = get_move_list(move_distance, 15, 3) -- 参数依次为：移动的像素、上升的时间长度、顶点停留的时间长度
	local step = 1
	local is_add_next = false -- 还没有运行下一个tip
	set_interval(1, function()
		local is_move_some = step >= 0.6*#move_list -- 当该tip运动到0.6路程的时候
		if is_move_some and not is_add_next then
			is_floating = false
			waiting_list[waiting_key] = waiting_list[waiting_key] or {}
			local waiting = table.remove(waiting_list[waiting_key], 1)
			if waiting then
				add_tip(waiting.parent, waiting.x, waiting.y, waiting.tip_text, waiting.tip_font, waiting.tip_size, waiting.tip_bold)
			end
			is_add_next = true
		end
		
		-- 运动的数据
		local move_y = move_list[step]
		if not move_y then
			tip_wnd:destroy()
			return "release"
		end
		
		local cur_y = tip_wnd:get_y()+move_y
		tip_wnd:set_y(cur_y)
		
		step = step + 1
	end)
end

get_move_list = function(distance, single_count, stop_count)
	local move_list = {}
	-- 计算份额
	local total_portion = 0
	for i = 1, single_count do
		local portion = i^3
		total_portion = total_portion+portion
	end
	portion_value = distance/total_portion
	-- 上升时候，每n帧经过的像素
	for i = single_count, 1, -1 do
		local portion = i^3
		table.insert(move_list, -1*portion_value*portion)
	end
	-- 顶峰时候，停留n帧
	for i = 1, stop_count do
		table.insert(move_list, 0)
	end
	return move_list
end
