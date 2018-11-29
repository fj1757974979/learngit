-- Lua implementation of PHP scandir function
function scandir(directory)
	local i, t, popen = 0, {}, io.popen
	for filename in popen('ls -a "'..directory..'"'):lines() do
        i = i + 1
		t[i] = filename
	end
	return t
end

execute = os.execute

function mkdirs(path)
	execute(string.format("mkdir %s", path))
end
