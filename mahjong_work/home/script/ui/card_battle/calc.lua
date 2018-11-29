
pCalcPanel = pCalcPanel or class(pWindow)

pCalcPanel.init = function(self)
	self:load("data/ui/card/calc.lua")
end

pCalcPanel.updateNumber = function(self, a, b, c, sum)
	self.txt_num1:setText(a)
	self.txt_num2:setText(b)
	self.txt_num3:setText(c)
	self.txt_sum:setText(sum)
end