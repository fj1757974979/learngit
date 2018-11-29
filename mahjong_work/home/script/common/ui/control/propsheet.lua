propsheet = class( puppy.gui.pList )

propsheet.init = function(self, parent)
	self:create(parent)
	
	self:set_resizable(true)
	self:set_movable(true)
	self:set_client_region_layout("x=2% y=%2 w=96% h=96%")

	self:set_column_count(2)
	self:set_column_width(0,"50%")
	self:set_column_width(1,"50%")
	
	self:set_header_text(0,"属性")
	self:set_header_text(1,"值")
end

propsheet.set_prop_info = function(self, prop_info)

end
