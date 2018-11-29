local modMajiangGame = import("logic/battle/majianggame.lua")

pZhuanzhuanGame = pZhuanzhuanGame or class(modMajiangGame.pMajiangGame)

pZhuanzhuanGame.init = function(self, options)
	modMajiangGame.pMajiangGame.init(self, options)
end


