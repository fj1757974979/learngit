-- 提示类型
T_HINT_RED_POINT = 1

-- 红点事件定义
HINT_NEW_SKILL = "ns"
HINT_NEW_SKILL_LVL = "ls"

__init__ = function(mod)
	for k, v in pairs(mod) do
		if not string.match(k, "__.*__") then
			_G[k] = v
		end
	end
end
