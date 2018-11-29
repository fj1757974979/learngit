uicontrol = uicontrol or {}
uicontrol.propsheet = import("propsheet.lua")
uicontrol.tabwnd = import("tabwnd.lua")
uicontrol.bar = import("bar.lua")
uicontrol.propsheet = import("propsheet.lua")
uicontrol.fwindow = import("fwindow.lua")
uicontrol.image_text = import("image_text.lua")
uicontrol.filelist = import("filelist.lua")
uicontrol.filetree = import("filetree.lua")
uicontrol.confirm_dlg = import("confirm_dlg.lua")
uicontrol.input_dlg = import("input_dlg.lua")
uicontrol.input_confirm = import("input_confirm.lua")
uicontrol.rich_list = import("rich_list.lua")
uicontrol.popup_wnd = import("popup_wnd.lua")
uicontrol.cash_wnd = import("cash_wnd.lua")
uicontrol.rich_wnd = import("rich_wnd.lua")
uicontrol.item_wnd = import("itemwnd.lua")
uicontrol.itempanel = import("itempanel.lua")
uicontrol.ui_sprite = import("ui_sprite.lua")
uicontrol.verify_wnd = import("verify_wnd.lua")
uicontrol.color_picker = import("color_picker.lua")
uicontrol.date_picker = import("date_picker.lua")
uicontrol.date_picker_edit = import("date_picker_edit.lua")
uicontrol.skill_wnd = import("skill_wnd.lua")
uicontrol.summon_list = import("summon_list.lua")
uicontrol.fabao_list = import("fabao_list.lua")
uicontrol.ride_list = import("ride_list.lua")

__init__ = function(self)
	export("uicontrol", uicontrol)
end
