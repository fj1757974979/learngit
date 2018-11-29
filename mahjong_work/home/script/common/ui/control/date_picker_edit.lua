local m_base = import("feditor_base.lua")

date_picker_edit = class(puppy.gui.pEdit, m_base.feditor_base)
date_picker_edit:__set_name("日期控件")

date_picker_edit.init = function(self, parent)
	self:set_parent(parent)
	self:init_style("~GmTool专用")
	self:add_listener("ec_active", function(e)
		ui.control.date_picker:new(self:getWorld():get_ui_root(), self)
	end)
end
