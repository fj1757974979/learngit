

local history = {}
local curPos = 0

prev = function()
	curPos = math.max(curPos - 1, 1)
end

next = function()
	curPos = math.min(curPos + 1, #history)
end

toEnd = function()
	curPos = #history
end

get = function()
	return history[curPos]
end

push = function(path)
	table.insert(history, path)
	toEnd()
end

remove = function(path)
	local ret = {}
	for _,p in ipairs(history) do
		if p ~= path then
			table.insert(ret, p)
		end
	end
	history = ret
	if curPos > #history then
		curPos = #history
	end
end
