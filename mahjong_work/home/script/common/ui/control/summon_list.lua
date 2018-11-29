--local m_pinyin = import("common/pinyin.lua")
local m_type = import("common/ctype.lua")
local m_base = import("feditor_base.lua")
local page_max_show = 5
summon_list = summon_list or class(puppy.gui.pWindow, m_base.feditor_base)

summon_list.destroy = function(self)

end

summon_list:__set_name("召唤兽列表")
summon_list:__set_default_size(150, 150)

__update__ = function(self)
	summon_list:updateObject()
end

summon_list.init = function( self, parent )	
	self:set_parent(parent)
	self:load_template("data/uitemplate/summon/summon_list.lua")
	self:set_movable(false)	
	self.page = {
		cur_page = 1,
		max_page = 1,		
	}	
	self.wnd_list ={}
	self:init_wnd()--init五个窗口	
	self:bind_summon_event()
	self.btn_pup:add_listener("ec_mouse_left_up",function()
		self.page.cur_page = self.page.cur_page - 1	
		self:update_summon()
		self:set_default_selected()
	end)

	self.btn_pdown:add_listener("ec_mouse_left_up",function() 
		self.page.cur_page = self.page.cur_page + 1
		self:update_summon()
		self:set_default_selected()	
	end)	
end

summon_list.bind_summon_event = function( self )
	local hero = self:getWorld() and self:getWorld():get_hero()
	if hero then	
		self:bind( hero, "summon_prop_list", function( summon_prop_list )	
			self:update_summon()				
		end,{})		
	end	
end

summon_list.init_wnd= function(self)
	for i =1,page_max_show do		
		local image_wnd = summon_image_wnd:new(	self["wnd_show" .. i] )
		image_wnd.get_parent = function() return self end		
		image_wnd:set_pos(0,0)
		image_wnd:disable_event()
		image_wnd.wnd_fight:show( false )	
		self.wnd_list["summon_wnd" .. i] = image_wnd 			
	end
end

summon_list.update_summon = function(self)	
	local sort_summon_list = self:sort_summon_list()
	local selected_summid = nil	
	for i = 1,page_max_show do
		local name = "summon_wnd" .. i
		if self.wnd_list[name]:is_selected() then --记录原来选中的
			selected_summid =  self.wnd_list[name]._summon_id
		end
		self.wnd_list[name]:clear_summon()	
	end
	self.wnd_show_num:set_text(string.format("%d/%d",0,0))
	self.btn_pup:show(self.page.max_page >= 2)
	self.btn_pdown:show(self.page.max_page >= 2)	
	self.wnd_show_num:show(self.page.max_page >= 2)
	if #sort_summon_list == 0 then return end

	self.page.max_page = math.ceil(#sort_summon_list/page_max_show) > 0 and math.ceil(#sort_summon_list/page_max_show) or 0 
	self.page.cur_page = (self.page.cur_page > self.page.max_page) and self.page.max_page or self.page.cur_page--防止最大页面减少时,当前页会大于最大页的bug
	self.btn_pup:enable(self.page.cur_page > 1)	
	self.btn_pdown:enable( self.page.cur_page < self.page.max_page )

	self.wnd_show_num:set_text(string.format("%d/%d",self.page.cur_page,self.page.max_page))
	
	for i = 1,page_max_show do		
		local name = "summon_wnd" .. i
		local summon_wnd = self.wnd_list[name]
		local summon_prop = sort_summon_list[page_max_show*(self.page.cur_page-1)+i] 
		if summon_prop then
			summon_wnd:enable_event()
			summon_wnd:set_summon(sort_summon_list[page_max_show*(self.page.cur_page-1)+i]:getProp("id",0))
			if summon_prop:getProp("id",0) == selected_summid then -- 原来选中的
				self.wnd_list[name].btn_check:only_check( true )	
				self.wnd_list[name]:set_selected(summon_prop)		
			end
		end
	end		
	if #sort_summon_list == 1 and not selected_summid then self:set_default_selected() end --没有选中的
	
end

summon_list.sort_summon_list = function( self )--排序	
	local hero = self:getWorld():get_hero()
	if not hero then return end
	local summon_prop_list = hero:getProp( "summon_prop_list", {} )
	
	local result = table.values(summon_prop_list)
	local get_summon_weight = function(summon)
		local name = summon:getProp("szFullname",0)
		local char = string.byte(name, 1)
		local id = summon:getProp("id", 0)
		if m_type.isalpnum(char)  then
			return char
		elseif m_pinyin.get_pinyin(name) then
			return 256 +string.byte(m_pinyin.get_pinyin(name),1)
		else
			return 1000 + id
		end
	end

	table.sort(result, function(summon1, summon2)
		return get_summon_weight(summon1) < get_summon_weight(summon2)
	end)
	return result
end

summon_list.set_default_selected = function(self)
	local	sort_summon_list = self:sort_summon_list()		
	if #sort_summon_list == 0 then return end		
	local fight_id = self:getWorld():get_hero():getProp("fight_summon_id",0)	
	local temp_wnd = nil
	temp_wnd =  self.wnd_list["summon_wnd1"]	
	for i = 1,page_max_show do
		if sort_summon_list[page_max_show*(self.page.cur_page-1)+i] then
			if sort_summon_list[page_max_show*(self.page.cur_page-1)+i]:getProp("id",0) == fight_id then
				temp_wnd = self.wnd_list["summon_wnd" .. i]
			end
		end
	end			
	temp_wnd:set_selected()
end

summon_list.disable_op = function( self )
	for i =1,page_max_show do	
		local wnd = self.wnd_list["summon_wnd" .. i]
		if wnd then	
			self.wnd_list["summon_wnd" .. i]:disable_event()
			self.wnd_list["summon_wnd" .. i].btn_check:enable( false )
		end		
	end	
end

summon_list.enable_op = function( self )
	for i =1,page_max_show do	
		local wnd = self.wnd_list["summon_wnd" .. i]
		if wnd then		
			self.wnd_list["summon_wnd" .. i]:enable_event()
			self.wnd_list["summon_wnd" .. i].btn_check:enable( true )
		end		
	end	
end


-----------------------------item wnd of summon pList------------------------------
summon_image_wnd = class(puppy.gui.pWindow)

summon_image_wnd.destroy = function(self)

end

__update__ = function(self)
	summon_image_wnd:updateObject()
end 

summon_image_wnd.init = function(self,parent)
	self:set_parent(parent)	
	self:load_template("data/uitemplate/summon/summon_icon.lua")
	self:set_movable(false)
	self.btn_check:only_check(false)
	self.wnd_icon:disable_event()
	self.wnd_title_level:disable_event()
	self.wnd_level:disable_event()
	self.wnd_name:disable_event()
	self.wnd_fight:disable_event()
	self:add_listener( "ec_mouse_left_up", function( e )
		self:set_selected()
	end)
end

summon_image_wnd.set_selected = function(self)
	if self:get_parent().on_select_func then
		self:get_parent().on_select_func( self._summon_prop )
	end
	
	local all_wnd_list = self:get_parent().wnd_list
	if all_wnd_list then
		for k, v in pairs( all_wnd_list ) do
			v.btn_check:only_check( false )
		end
	end
	self.btn_check:only_check( true )
end

summon_image_wnd.is_selected = function(self)
	return self.btn_check:is_checked()
end

summon_image_wnd.set_summon = function(self, summon_id )
	local hero = self:getWorld():get_hero()
	local prop_list = hero:getProp("summon_prop_list", {})
	if prop_list[summon_id] then
		self._summon_id = summon_id		
		self._summon_prop = prop_list[summon_id]
		self.wnd_show_icon:show(true)
		self.wnd_title_level:show( true )
		self.wnd_show_icon:bind(self._summon_prop,"iResid",function(resid) 
			self.wnd_show_icon:set_image{"photo",string.format("50/%s.fsi",resid)}
		end,20005)	
		local name = self._summon_prop:getProp("cName")
		self.wnd_name:set_text(name)
	
		self.wnd_name:bind( self._summon_prop, "szFullname", function(  )
								local name = self._summon_prop:getProp("cName","")
								self.wnd_name:set_text( name )
								self:get_parent():update_summon()
						   end, "", true )
		
		self.wnd_level:bind( self._summon_prop, "iGrade", apply( self.wnd_level.set_text, self.wnd_level) ,0 )
		self.wnd_fight:bind(hero,"fight_summon_id",function(id)
			if self._summon_prop then 
			if self._summon_prop:getProp( "id" ) == id then			
					self.wnd_fight:show( true )
				else
					self.wnd_fight:show( false )
				end
			end
		end,0)			
	end
end 

summon_image_wnd.clear_summon = function( self ,summon_id)
	self._summon_id = nil
	self._summon_prop = nil
	self.wnd_show_icon:show(false)
	self.wnd_name:set_text( "" )
	self.wnd_level:set_text( "" )	
	self.wnd_fight:show( false )
	self.wnd_title_level:show( false )
	self.btn_check:only_check( false )
	self:disable_event()
end

