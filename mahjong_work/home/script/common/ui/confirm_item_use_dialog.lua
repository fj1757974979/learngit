local m_const = import("common/const.lua")

function init_item_use_wnd(info_list)
	local context = info_list.context
	local dialog = puppy.gui.pWindow()
	dialog:set_parent(info_list.context.ui)
	dialog:load_template("data/uitemplate/common/confirm_item_use_dialog.lua")	
	dialog:set_layer(m_const.LAYER_TYPE.LT_EXIT_CONFIRM)
	dialog:set_movable(true)
	dialog:set_z(-100)
	
	dialog.txt_title:set_text(info_list.title)
	dialog.txt_message:set_text(info_list.message or info_list.msg)
	local item_name = info_list.item_name or context:get_element("item_data_mgr"):get_type_name(info_list.item_type)
	dialog.txt_item_name:set_text(item_name)	

	dialog.btn_ok:set_text(info_list.btn_ok_name or TEXT("确 定"))
	dialog.btn_cancel:set_text(info_list.btn_cancel_name or TEXT("取 消"))
	dialog.btn_auto_buy:set_text(info_list.btn_auto_buy_name or TEXT("自动购买材料"))

	local item_data_mgr = context:get_element("item_data_mgr")
	local equal_item_type = item_data_mgr:get_by_itype(info_list.item_type).equaltype
	dialog.wnd_show_image1:map_item(info_list.item_type,{equal_item_type},1)
	
	dialog.on_ok = info_list.on_ok
	dialog.on_cancel = info_list.on_cancel
	
	dialog.btn_ok:add_listener("ec_mouse_left_up",function(e) 		
		if dialog.on_ok then
			dialog.on_ok(e)
		end
		dialog:close()
	end)
		
	
	dialog.btn_cancel:add_listener("ec_mouse_left_up",function(e) 	
		if dialog.on_cancel then	
			dialog.on_cancel(e)
		end
		dialog:close()
	end)
	return dialog
end
