local m_event = import("common/event.lua")
local m_wndmgr = import("wndmgr.lua")
local m_propmgr = import("common/propmgr.lua")

local contexts = contexts or {}
local context_map = context_map or new_weak_table()
local count = count or 1

new_context = function()
	local new_ctx = puppy.fgamecontext:new()
	contexts[new_ctx] = true

	new_ctx:init_logic(#contexts)
	new_ctx:init_wnd(m_wndmgr.create_main_wnd())
	new_ctx:set_id(count)
	count = count + 1

	--new_ctx:show_debug(true)
	log("info|onlyu", "create new context success")
	m_event.fire_event("startgame", { context = new_ctx } )
	return new_ctx
end

get_context = function(id)
	return context_map[id]
end

function puppy.fgamecontext:init_logic()
	self.hero = nil
	self.scene = nil
	self.ui = nil
	self.socket = nil
	self.syswnd = nil
	self.chatwnd = nil

	self.root = self:getRoot()
	self.ui = self:getUIRoot()
	self.scene = self:getSceneRoot()

	self.root:show_child(true)
	self.ui:show_child(true)
	self.scene:show(false)
	
	--所有角色
	self.characters = {}
	self.elements = {}
	
	-- self.rq = self:create_render_queue()
	
	--热键
	self.root:add_listener( "ec_key_down", function(e)
		self:on_hot_key(e)
	end)
	
end

local old_set_id = puppy.fgamecontext.set_id
function puppy.fgamecontext:set_id(id)
	old_set_id(self, id)
	context_map[self:get_id()] = self
end

function puppy.fgamecontext:init_wnd(wnd)
	
	self.syswnd = wnd
	self.syswnd:set_context(self)
	--[[
	self.chatwnd = puppy.syswnd:new()
	self.chatcontext = puppy.fgamecontext:new()
	self.chatcontext:set_render_queue(self.rq)
	self.chatcontext.ui = self.chatcontext:get_ui_root()
	self.chatcontext:get_scene_root():show(false)
	
	local chatwnd = self.chatwnd
	chatwnd:set_context(self.chatcontext)
	chatwnd:create(300,self.syswnd:get_height(),self.syswnd)
	chatwnd:set_min_size(0, 0)
	chatwnd:create_graphic()
	chatwnd:show(false)
	--]]
	local chatwnd = {}

	--local ss = app:get_sound_system()
	local check_syswnd_active = function()
		if keep_master_volume then return end
		
		local active1 = self.syswnd:is_iconic()==false and self.syswnd:is_active()
		local active2 = self.chatwnd:is_active()

		if active1 or active2 then
			--ss:set_master_volume(1)
		else
			--ss:set_master_volume(0)			
		end
	end	

	wnd.on_active = function(_,b)
		if b and self.chatwnd:is_show() then
			self.chatwnd:insert_after(syswnd)
		end
		
		set_timeout(1,check_syswnd_active)
	end

	wnd.on_close = function()
		self:exit_game()
	end
	
	wnd.on_pos_changed = function()		
	end
	
	wnd.on_size_changed = function(_, w, h)
		m_event.fire_event("syswnd_size_change", { context = self, 
						   pWindow = wnd, })
	end


	chatwnd.on_active = function(_,b)
		if b then
			wnd:insert_after(chatwnd)
		end
	end

	chatwnd.on_exit_sizemove = function(_, cx, cy)
		local x, y = self.syswnd:get_x(), self.syswnd:get_y()
		local w, h = {1},{1}
		self.syswnd:get_window_size(w,h)
	end
	
	chatwnd.on_size_changed = function(_, w, h)
	end
	
	chatwnd.on_close=function()
	end
end

function puppy.fgamecontext:destroy()
	if self.verify_socket then
		self.verify_socket:close()
	end

	if self.game_socket then
		self.game_socket:close()
	end
	if self.syswnd then
		self.syswnd:show(false)
	end
	if self.root then
		self.root:clear_child()
	end

	for id,element in pairs(self.elements) do
		log("info", "destory ", id)
		element:destroy()
	end
	self.elements = {}
	self.characters = {}
end

function puppy.fgamecontext:exit_game()
	m_event.fire_event("exitgame", { context = self })
	self:destroy()
	contexts[self] = nil
	if #table.keys(contexts) == 0 then
		app:exit()
	end
end

function puppy.fgamecontext:get_syswnd()
	return self.syswnd
end

-- 对象创建
function puppy.fgamecontext:create_element(id, cls, ...)
	if not id then
		log("error", "create_element: id is nil", debug.traceback())
		return 
	end
	    
	if not cls then
		log("error", "create_element: class is nil", debug.traceback())
		return
	end

	local element = cls(...)
	if self.elements[id] then
		self.elements[id]:destroy()
	end
	element.id = id
	self.elements[id] = element
	return element
end

function puppy.fgamecontext:get_element(id)
	if not id then
		log("error", "id is nil")
		return 
	end

	return self.elements[id]
end

function puppy.fgamecontext:get_create_element(id, cls, ...)
	return self:get_element(id) or self:create_element(id, cls, ...)
end

function puppy.fgamecontext:delete_element(id)
	if not id then
		log("error", "id is nil")
		return 
	end

	local element = self.elements[id]
	if element then
		element:destroy()
		self.elements[id] = nil
	end

end

function puppy.fgamecontext:get_char(uid)
	local char = self.characters[uid] or m_propmgr.propmgr()
	self.characters[uid] = char
	return char
end

function puppy.fgamecontext:get_hero()
	return self:get_char(self:get_id())
end

function puppy.fgamecontext:on_hot_key(e)
	local hotkey_mgr = self:get_element("hotkey_mgr")
	if hotkey_mgr then
		hotkey_mgr:fire_hot_key( e )
	end
end

-------------------- events from engine ------------------
function puppy.fgamecontext:on_add_player(id)
	local pak = m_socket.fpacket(m_socket.PID_SERVER_UPDATE_PLAYER)
	pak:push_int32(id)
	self.game_socket:send_packet(pak)
end

function puppy.fgamecontext:on_hero_goto(scene, x, y)
	local p = self.scene:get_pixel_pos(x,y)
	self.scene:get_control_player():to(p[1], p[2])
end

function puppy.fgamecontext:on_player_click(id, e)
	logv("info|scene|onlyu", "点击玩家:", id)
	local statusmgr = self:get_element("op_status_mgr")

	if not statusmgr then return end

	local status = statusmgr:get_status()
	
	if status == "attack" then
		rpc_server_do_kill_player(self, id)
		self.op_status_mgr:to_status("normal")
	elseif status == "normal" then

	elseif status == "team" then
		if id == self.scene:get_control_player():get_id() then
			rpc_server_create_team(self)
		else
			rpc_server_join_team(self, id)
		end
		statusmgr:to_status("normal")
	elseif status == "trade" then
		rpc_server_trade_request(self, id)
		statusmgr:to_status("normal")
	elseif status == "add_friend" then
		rpc_server_add_friend(self, id)
		statusmgr:to_status("normal")
	elseif status == "use_item" then
		rpc_server_item_use(self, statusmgr:get_param(), id)
		statusmgr:to_status("normal")
	end
	
	self.on_hero_enter_scene = nil
	local hero = self.scene:get_control_player()
	if hero and not hero:is_following() and self:get_control_flag() then
		hero:stand()
	end
	e:bubble(false)
end

function puppy.fgamecontext:on_send_walk_packet(timestamp, walk_path)
	local pak = m_socket.fpacket(m_socket.PID_SERVER_MOVE)
	pak:push_string(walk_path)
	pak:push_int32(timestamp)
	self.game_socket:send_packet(pak)
	m_event.fire_event("sync_walk_path", {context = self,
					      timestamp = timestamp,
					      walk_path = walk_path})
end


function puppy.fgamecontext:on_npc_click(id, e)
	log("onlyu", "点击npc:", id)
	local npc = self.scene:get_player(id)
	local hero = self.scene:get_player(self:get_id())
	if not npc then return end
	if not hero then return end

	local nx, ny = npc:get_x(), npc:get_y()
	local hx, hy = hero:get_x(), hero:get_y()
	local dx = nx-hx
	local dy = ny-hy
	
	-- 距离很远的话走过去
	hero:sync_with_server()
	if math.sqrt(dx*dx+dy*dy) >= 20*16 and self:get_control_flag() then
		hero:to(nx, ny)
		-- rpc_server_click_npc(self, {id})
		return
	end

	rpc_server_click_npc(self, {id})

	if not hero:is_following() and self:get_control_flag() then
		hero:stand()
	end
	e:bubble(false)
end

function puppy.fgamecontext:on_fighter_click(id, e)
	m_event.fire_event("fighter_click", {
				   context = self,
				   id = id,})
end

__init__ = function(self)
	export("new_context", new_context)
	export("getWorld", getWorld)
end
