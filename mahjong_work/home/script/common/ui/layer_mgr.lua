local m_const = import("common/const.lua")

layer_mgr = layer_mgr or class()

layer_mgr.destroy = function(self)

end

__update__ = function(self)
	layer_mgr:updateObject()
end 


layer_mgr.init = function(self, ctx)
	self._context = ctx
end


-- 从某层开始隐藏(隐藏自己及权值比自己小的)
layer_mgr.hide_from = function(self, layer_type)
	self._context:show_layer(layer_type, false)
	for l_type, layer in pairs(m_const.LAYER_TYPE) do
		if layer < layer_type then
			self._context:show_layer(layer, false)
		end
	end
end

-- 隐藏指定的一层或多层
layer_mgr.hide_layer = function(self, ...)
	local layer_list = { ... }

	for _, layer_type in ipairs(layer_list) do
		self._context:show_layer(layer_type, false)
	end
end

-- 恢复全部的显示
layer_mgr.show_all = function(self)
	for l_type, layer in pairs(m_const.LAYER_TYPE) do
		self._context:show_layer(layer, true)
	end
end
