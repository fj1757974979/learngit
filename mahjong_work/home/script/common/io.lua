-- Lua implementation of PHP scandir function
io.scandir = function(directory)
	local str = scandir(directory, "*")
	return string.split(str, ";")
end

io.mkdirs = function(p) os.execute(string.format("mkdir %s", path)) end

io.stat = function(p) return io.popen("stat -f  \"%HT\" "..p) end

io.isFile = puppy.io.psysio.fileExist

io.isDir = puppy.io.psysio.directoryExist

io.concat = function(p1,p2) return table.concat({p1,p2}, "/") end

io.path = {}

io.path.basename = function(path)
	local arr = string.split(path, "/")
	local ret = ""
	for i=1,#arr-1 do
		ret = ret .. arr[i] .. "/"
	end
	return ret
end

io.saveTable = function(t, name)
	local modJson = import("common/json4lua.lua")
	local data = modJson.encode(t)
	-- 存文件
	local pApp = puppy.world.pApp.instance()
	local ioMgr = pApp:getIOServer()
	local buff = puppy.pBuffer:new()
	buff:initFromString(data, len(data))

	ioMgr:save(buff, string.format("tmp:%s.dat", name), 0)
end

io.loadTable = function(name)
	local modJson = import("common/json4lua.lua")
	local pApp = puppy.world.pApp.instance()
	local ioMgr = pApp:getIOServer()
	local data = ioMgr:getFileContent(string.format("tmp:%s.dat", name))
	if data and data ~= "" then
		local t = modJson.decode(data)
		return t
	end
	return {}
end
