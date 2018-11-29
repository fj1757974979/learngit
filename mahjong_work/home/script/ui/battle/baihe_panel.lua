local modXiangyangPanel = import("ui/battle/xiangyang_panel.lua")

pBaihePanel = pBaihePanel or class(modXiangyangPanel.pXiangyangPanel)

pBaihePanel.init = function(self)
	modXiangyangPanel.pXiangyangPanel.init(self)
end
