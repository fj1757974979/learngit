local modYunyangPanel = import("ui/battle/yunyang_panel.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")

pChengduPanel = pChengduPanel or class(modYunyangPanel.pYunyangPanel)

pChengduPanel.init = function(self)
	modYunyangPanel.pYunyangPanel.init(self)	
end

pChengduPanel.getIsZimoSort = function(self)
	return true 
end

pChengduPanel.getIsShowHuTriggerCard = function(self)
	return true
end

pChengduPanel.huCombOnleAddTrigger = function(self)
	return true 
end

pChengduPanel.destroy = function(self)
	modYunyangPanel.pYunyangPanel.destroy(self)
end

