local m_const = import("common/const.lua")
local confirm_dlg_list = {}

confirm_dlg = class(puppy.gui.pWindow)

confirm_dlg.init = function(self, parent, text, on_ok, on_cancel, on_nevertips)
	self:set_parent(parent)
	self:load_template("data/uitemplate/control/confirm.lua")
	self:set_layer(m_const.LAYER_TYPE.LT_MODAL)
	self:set_movable(true)
	
	local org_total_h = self:get_height()
	local org_text_h = self.wnd_context:get_height()

	self:bring_top()
	self:center()
	self:capture_mouse(true)
	
	self.chk_nevertips:show(on_nevertips ~= nil)
	self.wnd_context:set_text(text)
	
	self.btn_ok:add_listener("ec_mouse_left_up", function()
		on_ok()

		self:unit()		
	end)

	self.btn_cancel:add_listener("ec_mouse_left_up", function()
		if on_cancel then
			on_cancel()
		end

		self:unit()
	end)
	
	self.chk_nevertips:add_listener("ec_select_change", function()
		if on_nevertips then
			on_nevertips(self.chk_nevertips:is_checked())
		end
	end)

	local context_h = self.wnd_context:get_height()
	if context_h > 15 then
		self:set_height(context_h + org_total_h - org_text_h)
	end

	confirm_dlg_list[self] = 1
end

confirm_dlg.unit = function(self)
	self:capture_mouse(false)
	self:detach()
	confirm_dlg_list[self] = nil
end

confirm_dlg.on_close = function(self)
	self:unit()
end
