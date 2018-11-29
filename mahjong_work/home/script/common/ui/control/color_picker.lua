RGBToHSB = function (rgb)
	local hsb = {
		h= 0,
		s= 0,
		b= 0
	}
	
	local min = math.min(rgb.r, rgb.g, rgb.b)
	local max = math.max(rgb.r, rgb.g, rgb.b)
	local delta = max - min;
	hsb.b = max;
	
	hsb.s = (max~=0) and (255*delta/max) or 0
	if (hsb.s ~= 0) then
		if (rgb.r == max) then
			hsb.h = (rgb.g - rgb.b) / delta;
		elseif (rgb.g == max) then
			hsb.h = 2 + (rgb.b - rgb.r) / delta;
		else
			hsb.h = 4 + (rgb.r - rgb.g) / delta;
		end
	else
		hsb.h = -1;
	end
	hsb.h = hsb.h*60;
	if (hsb.h < 0) then
		hsb.h = hsb.h+360;
	end
	hsb.s = hsb.s*100/255;
	hsb.b = hsb.b*100/255;
	return hsb;
end
			
HSBToRGB = function (hsb)
	local rgb = {};
	local h = floor(hsb.h);
	local s = floor(hsb.s*255/100);
	local v = floor(hsb.b*255/100);
	if(s == 0) then
		rgb.r,rgb.g,rgb.b = v,v,v;
	else
		local t1 = v;
		local t2 = (255-s)*v/255;
		local t3 = (t1-t2)*(h%60)/60;
		if(h==360) then h = 0 end
		if(h<60) then rgb.r=t1;	rgb.b=t2; rgb.g=t2+t3
		elseif(h<120) then rgb.g=t1; rgb.b=t2;	rgb.r=t1-t3
		elseif(h<180) then rgb.g=t1; rgb.r=t2;	rgb.b=t2+t3
		elseif(h<240) then rgb.b=t1; rgb.r=t2;	rgb.g=t1-t3
		elseif(h<300) then rgb.b=t1; rgb.g=t2;	rgb.r=t2+t3
		elseif(h<360) then rgb.r=t1; rgb.g=t2;	rgb.b=t1-t3
		else rgb.r=0; rgb.g=0;	rgb.b=0 end
	end
	return {r=floor(rgb.r), g=floor(rgb.g), b=floor(rgb.b)}
end

RGBToHex = function (rgb,a) 
	return (a or 0xff)*256*256*256+rgb.r*256*256+rgb.g*256+rgb.b
end

HexToRGB = function(c)
	local rgb = {}
	rgb.a = bit.band(bit.rshift(c,24),0xff)
	rgb.r = bit.band(bit.rshift(c,16),0xff)
	rgb.g = bit.band(bit.rshift(c,8),0xff)
	rgb.b = bit.band(c,0xff)
	return rgb
end


local cursor_min_x=14-5
local cursor_min_y=13-5
local cursor_max_x=cursor_min_x+150
local cursor_max_y=cursor_min_y+150
			
color_picker = class( puppy.gui.pWindow )

color_picker.init = function(self, parent)
	self:set_parent(parent)
	self:load_template{"script/data", "uitemplate/uieditor/color_picker.lua"}
	
	self.hsb = {h=360,s=100,b=100}
	self.alpha = 255
	
	self.prg_alpha:set_range(255)
	self.prg_alpha:add_listener2("ec_scrollbar_pos_change",function(e)
		self.alpha=self.prg_alpha:get_pos()
		self:update()
	end)
	self.prg_alpha:scroll_to(255)
	
	self.wnd_cursor_h:set_parent(self.wnd_h)
	self.wnd_cursor_h:set_layout_info("clear w=34")
	self.wnd_h:add_listener2("ec_mouse_drag",function(e)
		local y = limit(e:y(),0,150)		
		self.hsb.h = floor((150-y)/150*360)		
		self:update()		
	end)
	self.wnd_h:add_listener2("ec_mouse_left_up",function(e)
		self.wnd_h.ec_mouse_drag(e)
	end)
	
	self.wnd_HSB_H:add_listener2("ec_mouse_drag",function(e)
		self.hsb.h = limit(self.hsb.h-e:dy(),0,360)
		self:update()		
	end)
	self.wnd_HSB_S:add_listener2("ec_mouse_drag",function(e)
		self.hsb.s = limit(self.hsb.s+e:dx(),0,100)
		self:update()		
	end)
	self.wnd_HSB_B:add_listener2("ec_mouse_drag",function(e)
		self.hsb.b = limit(self.hsb.b-e:dy(),0,100)
		self:update()		
	end)
	
	
	self.wnd_cursor_sb:set_parent(self.wnd_sb)
	self.wnd_cursor_sb:disable_event()
	self.wnd_sb:add_listener2("ec_mouse_drag",function(e)
		local x,y=limit(e:x(),0,150),limit(e:y(),0,150)		
		self.hsb.s = floor((x)/150*100)
		self.hsb.b = floor((150-y)/150*100)		
		self:update()
	end)
	
	self.wnd_sb:add_listener2("ec_mouse_left_up",function(e)
		self.wnd_sb.ec_mouse_drag(e)
	end)
	
	self.wnd_color1:add_listener2("ec_mouse_left_up",function(e)
		if self.on_color_selected then
			self:on_color_selected(self.color)
		end
	end)
	
	self.wnd_color2:add_listener2("ec_mouse_left_up",function(e)
		if self.on_color_selected then
			self:on_color_selected(self.init_color)
		end
	end)
end

color_picker.update = function(self,oping)
	local hsb=self.hsb
	local rgb=HSBToRGB(hsb)
	local rgb2=HSBToRGB({h=self.hsb.h,s=100,b=100})

	self.edit_RGB_R:set_text(rgb.r)
	self.edit_RGB_G:set_text(rgb.g)
	self.edit_RGB_B:set_text(rgb.b)
	
	self.edit_HSB_H:set_text(hsb.h)
	self.edit_HSB_S:set_text(hsb.s)
	self.edit_HSB_B:set_text(hsb.b)
	
	self.edit_A:set_text(self.alpha)
	self.prg_alpha:scroll_to(self.alpha,false)
	
	self.wnd_sb:get_image_list(puppy.gui.ip_normal):get_image(0):_color(RGBToHex(rgb2))
	self.wnd_color1:get_image_list(puppy.gui.ip_normal):get_image(0):_color(RGBToHex(rgb,self.alpha))
	self.color = RGBToHex(rgb,self.alpha)
	
	self.wnd_cursor_h:set_y( 150-self.hsb.h/360*150-4 )
	self.wnd_cursor_sb:set_x( self.hsb.s/100*150-5 )
	self.wnd_cursor_sb:set_y( 150-self.hsb.b/100*150-5 )
	
	if self.on_color_changed then
		self:on_color_changed(self.color)
	end
end

color_picker.set_init_color = function(self,c)
	local rgb = HexToRGB(c)
	self.hsb = RGBToHSB(rgb)
	self.alpha = rgb.a
	
	
	self.wnd_color2:get_image_list(puppy.gui.ip_normal):get_image(0):_color(c)
	self.init_color = c
	self:update()
end
