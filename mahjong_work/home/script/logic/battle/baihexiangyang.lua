local modXiangyangGame = import("logic/battle/xiangyanggame.lua")

pBaiheGame = pBaiheGame or class(modXiangyangGame.pXiangyangGame)

pBaiheGame.init = function(self, options)
	modXiangyangGame.pXiangyangGame.init(self, options)
end
