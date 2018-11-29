local m_base = import("feditor_base.lua")
--local m_fabao_info = import( "data/info/info_fabao.lua" )
local page_max_show = 5
fabao_list = fabao_list or class(puppy.gui.pWindow, m_base.feditor_base)

fabao_list.destroy = function(self)

end

__update__ = function(self)
	fabao_list:updateObject()
end 

fabao_list:__set_name("法宝列表")
fabao_list:__set_default_size(150, 150)

fabao_list.init = function( self, parent )
	self:set_parent(parent)
	self:load_template("data/uitemplate/fabao/fabao_list.lua")
	self:set_movable(false)	
	self.page = {
		cur_page = 1,
		max_page = 1,		
	}	
	self.wnd_list ={}
	self:init_wnd()--init五个窗口	
	self:bind_fabao_event()
	self.btn_pup:add_listener("ec_mouse_left_up",function()
		self.page.cur_page = self.page.cur_page - 1	
		self:update_fabao()
		self:set_default_selected()
	end)

	self.btn_pdown:add_listener("ec_mouse_left_up",function() 
		self.page.cur_page = self.page.cur_page + 1
		self:update_fabao()
		self:set_default_selected()	
	end)	
end

fabao_list.bind_fabao_event = function( self )
	local hero = self:getWorld() and self:getWorld():get_hero()
	if hero then
		self:bind( hero, "fabao_prop_list", function( fabao_prop_list )
				self:update_fabao()
		end, {})
	end
end


init_to_fabao_list = function(self)
	class_cast(fabao_list, self)
	
	fabao_list.init(self)
end

fabao_list.init_wnd= function(self)	
	for i =1,page_max_show do		
		local image_wnd = fabao_image_wnd:new(	self["wnd_show" .. i] )
		image_wnd.get_parent = function() return self end		
		image_wnd:set_pos(0,0)
		image_wnd:disable_event()
		self.wnd_list["fabao_wnd" .. i] = image_wnd 			
	end
end

fabao_list.update_fabao = function(self)	
	local sort_fabao_list = self:sort_fabao_list()	
	for i = 1,page_max_show do
		local name = "fabao_wnd" .. i
		self.wnd_list[name]:clear_fabao()	
	end	
	self.wnd_show_num:set_text(string.format("%d/%d",0,0))	
	self.btn_pup:show(self.page.max_page >= 2)
	self.btn_pdown:show(self.page.max_page >= 2)	
	self.wnd_show_num:show(self.page.max_page >= 2)
	if #sort_fabao_list == 0 then return end
	self.page.max_page = math.ceil(#sort_fabao_list/page_max_show) > 0 and math.ceil(#sort_fabao_list/page_max_show) or 0 
	self.page.cur_page = (self.page.cur_page > self.page.max_page) and self.page.max_page or self.page.cur_page--防止最大页面减少时,当前页会大于最大页的bug
	self.btn_pup:enable(self.page.cur_page > 1)
	self.btn_pdown:enable( self.page.cur_page < self.page.max_page )	
	self.wnd_show_num:set_text(string.format("%d/%d",self.page.cur_page,self.page.max_page))
	
	for i = 1,page_max_show do		
		local name = "fabao_wnd" .. i
		local fabao_wnd = self.wnd_list[name]		
		if sort_fabao_list[page_max_show*(self.page.cur_page-1)+i] then
			fabao_wnd:enable_event()
			fabao_wnd.wnd_icon:show(true)
			fabao_wnd.wnd_title_level:show(true)
			fabao_wnd:set_fabao(sort_fabao_list[page_max_show*(self.page.cur_page-1)+i]:getProp("id",0))
		end
	end		
	if #sort_fabao_list == 1 then self:set_default_selected() end --没有选中的
end

fabao_list.sort_fabao_list = function(self)--排序
	local hero = self:getWorld():get_hero()
	if not hero then return end
	local fabao_list = hero:getProp("fabao_prop_list",{})
	local result = table.values(fabao_list)
	local fabao_pos = function(fabao)--以后有排序变化就更改函数体
		local pos = fabao:getProp("iPos")
		return pos	
	end
	
	table.sort(result,function(fabao1,fabao2)
		return fabao_pos(fabao1)<fabao_pos(fabao2)
	end)
	return result
end

fabao_list.set_default_selected = function(self)
	local	sort_fabao_list = self:sort_fabao_list()		
	if #sort_fabao_list == 0 then return end				
	local temp_wnd = nil
	temp_wnd =  self.wnd_list["fabao_wnd1"]	
	for i = 1,page_max_show do
		if sort_fabao_list[page_max_show*(self.page.cur_page-1)+i] then
			local fight_index = sort_fabao_list[page_max_show*(self.page.cur_page-1)+i]:getProp("iInfight", 0 )
			if fight_index == 1 then
				temp_wnd = self.wnd_list["fabao_wnd" .. i]
			end
		end
	end			
	temp_wnd:set_selected()
end





-----------------------------item wnd of fabao pList------------------------------
fabao_image_wnd = class(puppy.gui.pWindow)

fabao_image_wnd.destroy = function(self)

end

__update__ = function(self)
	fabao_image_wnd:updateObject()
end 


fabao_image_wnd.init = function(self ,parent)
	self:set_parent(parent)	
	self:load_template("data/uitemplate/fabao/fabao_icon.lua")
	self:set_movable(false)	
	self.wnd_fight:show( false )
	
	self.wnd_icon:disable_event()
	self.wnd_title_level:disable_event()
	self.wnd_level:disable_event()
	self.wnd_name:disable_event()
	self.wnd_fight:disable_event()	
	self:add_listener( "ec_mouse_left_up", function( e )
		self:set_selected(self)
	end)
end

fabao_image_wnd.set_selected = function(self)
	if self:get_parent().on_select_func then
		self:get_parent().on_select_func(self._fabao_prop)
	end
	
	local all_wnd_list = self:get_parent().wnd_list
	if all_wnd_list then
		for k,v in pairs(all_wnd_list) do
			v.wnd_select_bg:only_check( false )
		end
	end
	self.wnd_select_bg:only_check( true )
end

fabao_image_wnd.set_fabao = function(self, fabao_id )
	local hero = self:getWorld():get_hero()
	local prop_list = hero:getProp("fabao_prop_list", {})
	if prop_list[fabao_id] then
		self._fabao_id = fabao_id
		self._fabao_prop = prop_list[fabao_id]
		
		--self.wnd_icon:set_image{ "photo", "50/10001.fsi" }
		
		self.wnd_icon:bind(self._fabao_prop,"iType",function(itype) 
				if  m_fabao_info.data[itype] then
					self.wnd_icon:set_image{ "ui", string.format("skin/slhx/fabao/%s",m_fabao_info.data[itype].resid)}			
				end
			end,1)
	
		self.wnd_name:bind( self._fabao_prop, "cName", apply( self.wnd_name.set_text, self.wnd_name) ,"" )
		self.wnd_level:bind( self._fabao_prop, "iLevel", apply( self.wnd_level.set_text, self.wnd_level) ,0 )
	--	self.wnd_fight:bind( self._fabao_prop, "iInfight", function( value ) 
	--		if value == 1 then
	--			self.wnd_fight:show( true )
	--		else
	--			self.wnd_fight:show( false )
	--		end
	--	end, 0 )
	end
end


fabao_image_wnd.clear_fabao = function(self, fabao_id )
	self._fabao_id = nil
	self._fabao_prop = nil	
	self.wnd_name:set_text( "" )
	self.wnd_level:set_text( "" )
	self:disable_event()
	self.wnd_icon:show(false)
	self.wnd_fight:show( false )
	self.wnd_title_level:show(false)
end
