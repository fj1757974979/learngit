--local m_pinyin = import("common/pinyin.lua")

local m_base = import("feditor_base.lua")

local max_ride_mount = 5
ride_list = ride_list or  class(puppy.gui.pList, m_base.feditor_base)

ride_list.destroy = function(self)

end

ride_list:__set_name("坐骑列表")
ride_list:__set_default_size(150, 150)

__update__ = function(self)
	ride_list:updateObject()
end

ride_list.init = function( self, parent )	
	self:set_parent(parent)
	self:load_template("data/uitemplate/summon/summon_list.lua")
	self:set_movable(false)	
	self.page = {
		cur_page = 1,
		max_page = 1,		
	}	
	self.wnd_list ={}
	self:init_wnd()--init五个窗口	
	self:bind_ride_event()
	self.btn_pup:add_listener("ec_mouse_left_up",function()
		self.page.cur_page = self.page.cur_page - 1		
		self:update_ride()
		self:set_default_selected()
	end)

	self.btn_pdown:add_listener("ec_mouse_left_up",function() 
		self.page.cur_page = self.page.cur_page + 1	
		self:update_ride()
		self:set_default_selected()	
	end)	
end

ride_list.bind_ride_event = function( self )
	local hero = self:getWorld() and self:getWorld():get_hero()
	if hero then	
		self:bind( hero, "ride_prop_list", function( ride_prop_list )	
			self:update_ride()				
		end,{})		
	end	
end

ride_list.init_wnd= function(self)	
	for i =1,5 do		
		local image_wnd = ride_image_wnd:new(	self["wnd_show" .. i] )
		image_wnd.get_parent = function() return self end
		image_wnd:set_pos(0,0)
		image_wnd:disable_event()	
		self.wnd_list["wnd_name" .. i] = image_wnd 			
	end
end

ride_list.update_ride = function(self)	
	local sort_ride_list = self:sort_ride_list()
	local selected_rideid = nil	
	for i = 1,max_ride_mount do
		local name = "wnd_name" .. i
		if self.wnd_list[name]:is_selected() then --记录原来选中的
			selected_rideid =  self.wnd_list[name]._ride_id
		end
		self.wnd_list[name]:clear_ride()	
	end
	self.wnd_show_num:set_text(string.format("%d/%d",1,1))
	self.btn_pup:show(self.page.max_page >= 2)
	self.btn_pdown:show(self.page.max_page >= 2)	
	self.wnd_show_num:show(self.page.max_page >= 2)	
	if #sort_ride_list == 0 then return end
	self.page.max_page = math.ceil(#sort_ride_list/max_ride_mount) > 0 and math.ceil(#sort_ride_list/max_ride_mount) or 0 
	self.page.cur_page = self.page.cur_page > self.page.max_page and self.page.max_page or self.page.cur_page
	self.btn_pup:enable(self.page.cur_page > 1)
	self.btn_pdown:enable(self.page.cur_page < self.page.max_page)

	self.wnd_show_num:set_text(string.format("%d/%d",self.page.cur_page,self.page.max_page))
	
	for i = 1,max_ride_mount do		
		local name = "wnd_name" .. i
		local ride_prop = sort_ride_list[max_ride_mount*(self.page.cur_page-1)+i]
		if	ride_prop then
			self.wnd_list[name]:enable_event()
			self.wnd_list[name].wnd_title_level:show(true)
			self.wnd_list[name]:set_ride(ride_prop:getProp("id",0))
			if ride_prop:getProp("id",0) == selected_rideid then -- 原来选中的
				self.wnd_list[name].btn_check:only_check( true )	
				self.wnd_list[name]:set_selected(ride_prop)		
			end
		end
	end		
	if #sort_ride_list == 1 and not selected_rideid then self:set_default_selected() end --没有选中的
end

ride_list.sort_ride_list = function( self )--排序
	local hero = self:getWorld():get_hero()
	if not hero then return end
	local ride_prop_list = hero:getProp( "ride_prop_list", {} )
	local result = table.values(ride_prop_list)
	table.sort(result, function(ride1, ride2)
		return ride1:getProp("iPos", 1) < ride2:getProp("iPos", 1)
	end)
	return result
end

ride_list.set_default_selected = function(self)
	local sort_ride_list = self:sort_ride_list()		
	if #sort_ride_list == 0 then return end		
	local rided_id = self:getWorld():get_hero():getProp("rided_ride_id",0)	
	local temp_wnd = self.wnd_list["wnd_name1"]	
	for i = 1,5 do
		if sort_ride_list[5*(self.page.cur_page-1)+i] then
			if sort_ride_list[5*(self.page.cur_page-1)+i]:getProp("id",0) == rided_id then
				temp_wnd = self.wnd_list["wnd_name" .. i]
			end
		end
	end			
	temp_wnd:set_selected()
end

-----------------------------item wnd of ride pList------------------------------
ride_image_wnd = class(puppy.gui.pWindow)

ride_image_wnd.destroy = function(self)

end

__update__ = function(self)
	ride_image_wnd:updateObject()
end 

ride_image_wnd.init = function(self,parent)
	self:set_parent(parent)	
	self:load_template("data/uitemplate/ride/ride_icon.lua")

	self:set_movable(false)
	self.wnd_icon:disable_event()
	self.wnd_show_icon:disable_event()
	self.wnd_title_level:disable_event()
	self.wnd_level:disable_event()
	self.wnd_name:disable_event()
	self.wnd_rided:disable_event()
	self.btn_check:only_check( false )
	self:add_listener( "ec_mouse_left_up", function( e )
		self:set_selected()
	end)
end

ride_image_wnd.set_selected = function(self)
	if self:get_parent().on_select_func then
		self:get_parent().on_select_func( self._ride_prop )
	end
	
	local all_wnd_list = self:get_parent().wnd_list
	if all_wnd_list then
		for k, v in pairs( all_wnd_list ) do
			v.btn_check:only_check( false )
		end
	end
	self.btn_check:only_check( true )
end
ride_image_wnd.is_selected = function(self)
	return self.btn_check:is_checked()
end
ride_image_wnd.set_ride = function(self, ride_id )
	local ride_info = import("data/info/info_ride.lua")
	local hero = self:getWorld():get_hero()
	if not hero then return end	
	local prop_list = hero:getProp("ride_prop_list", {})
	if prop_list[ride_id] then
		self._ride_id = ride_id
		self._ride_prop = prop_list[ride_id]	
		self.wnd_show_icon:show(true)

		local ride_cfg = ride_info.data[self._ride_prop:getProp("iType", 0)]
		if ride_cfg then
			self.wnd_name:set_text( ride_cfg.name )
			self.wnd_show_icon:set_image{"photo",string.format("50/%s.fsi", ride_cfg.resid)}
		end

		self.wnd_level:bind( self._ride_prop, "iLevel", apply( self.wnd_level.set_text, self.wnd_level) ,0 )
		self.wnd_rided:bind(hero,"rided_ride_id", function( id )
			if self._ride_prop:getProp( "id" ) == id then			
				self.wnd_rided:show( true )
			else
				self.wnd_rided:show( false )
			end
		end,0)			
	end
end 

ride_image_wnd.clear_ride = function(self, ride_id )
	self._ride_id = nil
	self._ride_prop = nil
	self.wnd_show_icon:show(false)
	self.wnd_name:set_text( "" )
	self.wnd_level:set_text( "" )	
	self.wnd_rided:show( false )
	self.btn_check:only_check( false )
	self.wnd_title_level:show(false)
	self:disable_event()
end
