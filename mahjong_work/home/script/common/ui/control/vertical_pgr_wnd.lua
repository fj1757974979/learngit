
vertical_pgr_wnd = vertical_pgr_wnd or class(puppy.gui.pWindow)

vertical_pgr_wnd.destroy = function(self)

end

__update__ = function(self)
	vertical_pgr_wnd:updateObject()
end 

--[[
args = {
	w
	h
	bg_image
	fill_image
}
--]]

vertical_pgr_wnd.init = function(self, parent, args)
	self:set_parent(parent)
	args.w = args.w or 38
	args.h = args.h or 38
	self:set_size( args.w, args.h )
	
	args.fill_image = args.fill_image or {"ui", "skin/slhx/image/image_78.TGA"}
	self:get_image_list(puppy.gui.ip_normal):clear_image()
	self:get_image_list(puppy.gui.ip_normal):add_image( args.fill_image, "", 0,0,-1,-1, 0xFFFFFFFF)	--fill

	args.bg_image = args.bg_image or {"ui", "skin/slhx/image/image_85.TGA"}
	self.bg_image = args.bg_image
	self.bg_wnd = puppy.gui.pWindow:new(self)
	self.bg_wnd:set_size( args.w, args.h )
	self.bg_wnd:set_pos( 0, 0 )
	self.bg_wnd:clip_draw(true)
	self.bg_wnd:get_image_list(puppy.gui.ip_normal):clear_image()
	self.bg_wnd:get_image_list(puppy.gui.ip_normal):add_image( args.bg_image, string.format("x=0 y=0 w=%s h=%s", args.w, args.h), 0,0,-1,-1, 0xFFFFFFFF)	--bg	
	self.bg_wnd:disable_event()
	
	self.text_wnd = puppy.gui.pWindow:new( self )
	self.text_wnd:set_size( args.w, args.h )
	self.text_wnd:set_pos( 0, 0 )
	self.text_wnd:set_text_align_x( puppy.gui.pWindow.align_center )
	self.text_wnd:set_text_align_y( puppy.gui.pWindow.align_center )
	--self.text_wnd:disable_event()
		
	self._range = 0
	self._pos = 0
	
	self:show( true )
	self:update()
end

vertical_pgr_wnd.set_range = function( self, range )
	self._range = range
	self:update()
end

vertical_pgr_wnd.pos_to = function( self, pos )
	self._pos = pos
	self:update()
end
 
vertical_pgr_wnd.update = function( self )
	local pos = self._pos > 0 and self._pos or 0
	local range = self._range>0 and self._range or 1
	
	pos = pos<range and pos or range
	 
	local cut_wnd_height = self:get_height()*pos/range
	self.bg_wnd:set_size( self:get_width(), self:get_height()-cut_wnd_height )
	self.bg_wnd:get_image_list(puppy.gui.ip_normal):clear_image()
	self.bg_wnd:get_image_list(puppy.gui.ip_normal):add_image( self.bg_image, 
								string.format("x=0 y=0 w=%s h=%s", self:get_width(), self:get_height()-cut_wnd_height), 
								0,0,self:get_width(), self:get_height()-cut_wnd_height, 0xFFFFFFFF)	--

	--self.text_wnd:set_text( string.format("%s/%s", self._pos, self._range) )
	self.text_wnd:set_tip_text( string.format("%s/%s", self._pos, self._range) )
end
