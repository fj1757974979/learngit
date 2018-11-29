-- use for statistics

local uri = "http://192.168.0.18:3000/action"

function post_request(uri, dict)
	--[[
	local request = puppy.value.new_null()
	for k,v in pairs(dict) do
		request:setk(k, puppy.value.new_str(tostring(v)))
	end
	curl:post_content(uri, request);
	--]]
	local url = uri .. "/" 
		.. dict["name"] .. "/"
		.. dict["event"] .. "/"
		.. dict["time"] .. "/"
		.. dict["uid"] .. "/"
		.. dict["server"] .. "/"
		.. dict["grade"] 
	curl:http_get_asyn(url);
end

function get_obj_name(obj)
	local p = obj:get_parent()
	if p then
		return get_obj_name(p) ..",".. string.gsub(obj:get_name(), "/", "-") 
	else
		return string.gsub(obj:get_name(), "/", "-")
	end
end

local need_push = {
	ec_mouse_left_down = true,
	ec_mouse_left_up = true,
	ec_mouse_left_doubleclick = true,
	ec_mouse_right_up = true,
	ec_mouse_right_down = true,
	ec_mouse_mid_down = true, 
	ec_mouse_mid_up = true,
}

function push_action(ctx, obj, event)
	if not need_push[event] then return end
	if not ctx then return end
	try {
		post_request(uri, {
				     name = get_obj_name(obj),
				     event = event,
				     time = os.time(),
				     uid = ctx:get_id(),
				     server = ctx.server and ctx.server.id or 0,
				     grade = ctx:get_hero() and ctx:get_hero():getProp("iGrade") or 0,
			     })
	} catch {
		do_nothing
	} finally {
		do_nothing
	}
end
