cpp_object_map = {}
setmetatable(cpp_object_map,{__mode="kv"})

weak_table = function(mode)
	mode = mode or "kv"
	local ret = {}
	setmetatable(ret, {__mode=mode})
	return ret;
end

local search_base 
search_base = function(t,k)

	local base_list = rawget(t,"__base_list")
	
	if not base_list then
		return
	end

	local v
	for i=1,#base_list do
		local base = base_list[i]		

		v = rawget(base,k)
		if v then
			t[k] = v -- 缓存搜索结果
			return v
		end
		
		v = search_base(base,k)
		if v then
			t[k] = v -- 缓存搜索结果
			return v
		end
			
	end
end

is_base_class = function(base, derive)
	local base_list = rawget(derive, "__base_list")

	if not base_list then return false end

	for _, b_class in ipairs(base_list) do
		if (base == b_class) or is_base_class(base, b_class) then
			return true
		end
	end

	return false
end

class_cast = function( cls, obj )
	-- 不允许子类往基类转，因为这样可能导致转完后的对象找不到子类上的函数
	if obj.__class and is_base_class(cls, obj.__class) then
		return obj
	end

	setmetatable( obj, cls.__objmt )
	obj.__class = cls
	cls.__objs = cls.__objs or weak_table()
	cls.__objs[obj] = true
	return obj
end

allClasses = {}
class = function( ... )
	local arg = {...}
	local newClass = {}

	allClasses[newClass] = 1

	newClass.__base_list = {}
	newClass.__objs = weak_table()

	for i = 1, #arg do
		if arg[i]==nil then
			print("ClassDefine:传入的基类为nil!")
		end
		
		table.insert( newClass.__base_list, arg[i] )

		-- 将基类记录到类的table里面用于查询继承关系
		newClass[ arg[i] ] = true
	end
	-- 将基类记录到类的table里面用于查询继承关系
	newClass[ newClass ] = true
	
	newClass.__objmt = { 
		__index = newClass,
	}
	
	newClass.new = function( self, ... )
		local luaobj = {}
		class_cast(newClass, luaobj)

		--在调用Ctor之前先把_createingInstance属性设置好，不然在Ctor里又引用自己的话就会导致额外创建。wellbye
		self._createingInstance = luaobj
		
		--c++类的构造
		if self.ctor then
			self.ctor( luaobj )
		elseif self.__cppclass then
			if self.__proxy_class and self.__proxy_class.ctor then -- 使用代理类构建的对象
				class_cast(self.__proxy_class, luaobj)
				self.__proxy_class.ctor(luaobj)
				real_obj = luaobj:val()
				real_obj.__proxy = luaobj
				luaobj = real_obj
			else
				error("试图创建不允许构造的cpp类！")
			end
		end

		-- lua类的初始化
		if self.init then 
			self.init(luaobj, ...)
		end
		
		self._createingInstance = nil
		return luaobj
	end

	newClass.updateObjects = function(self)
		for obj,_ in pairs(newClass.__objs) do
			if obj.__update__ then
				obj:__update__()
			end
		end
	end
	newClass.updateObject = newClass.updateObjects

	setmetatable(newClass,{
			     __index=search_base,
			     __call = newClass.new
		     })
		
	return newClass
end

local pwd
function get_pwd()
	if pwd then return pwd end
	local info = debug.getinfo(2, 'S')
	return info.source
end

local lastLoadTime = {}
----------------------------------------------------
__fs_require_loaded = {}
import = function(name)
	local pApp = puppy.world.pApp.instance()
	local iomanager = pApp:getIOServer()

	local info = debug.getinfo(2, 'S')
	-- print(info.what)
	if info.what == "main" or info.what == 'Lua' then
		local source = info.source
		-- print(source)
		-- if info.what == 'Lua' then
			local p = string.gsub(get_pwd(), "[^\\]*lua", "")
			source = string.gsub(source, p, "")
			source = string.gsub(source, "\\", "/")
			source = string.gsub(source, "@home/script/", "")
		-- end
			-- print(source)
		local new_source = string.gsub(source, "[^/]*lua", name)
		if iomanager:exist(string.format("script:%s", new_source), 0, true) then
			name = new_source
		end
		-- print("import", source, name)
		--print(name)
	end

	ret = __fs_require_loaded[name]
	if ret then return ret end
	return _import(name)
end

_import = function(name, reload)
	local pApp = puppy.world.pApp.instance()
	local iomanager = pApp:getIOServer()

	reload = reload or false
	if reload then
		if not __fs_require_loaded[name] then
			return
		end
	end

	local callinit = function(mod)
		if mod.__init__ then
			mod.__init__(mod)
		end
	end

	local calldestroy = function(mod)
		if mod.__destroy__ then
			mod.__destroy__(mod)
		end
	end

	local callupdate = function(mod)
		for k,v in pairs(mod) do
			if type(v) == "table" and rawget(v, "__objmt") then
				v:updateObjects()
			end
		end
		print(string.format("update module %s", name))
	end

	print(name)
	local func = loadfile(name)
	lastLoadTime[name] = iomanager:getFileTime("script:"..name)
	if type(func) == "function" then
		local ok
		local env 
		if reload then
			env = __fs_require_loaded[name]
			calldestroy(env)
		else
			__fs_require_loaded[name] = {}
			env = __fs_require_loaded[name]
			setmetatable(env, {__index = _G})
		end

		ok, ret = xpcall( 
			function()
				setfenv(func, env)()
				if reload then
					callupdate(env)
				else
					callinit(env)
				end

				for k,v in pairs(env) do
					if type(v) == "table" and rawget(v, "__objmt") then
						v.__class_name = k
					end
				end
				return env
			end,
			function(e)
				print("---import failed---\n",e,"\n",debug.traceback())
			end)

		return ret
	else
		print("---import failed---\n", name, ":", func, "\n", debug.traceback())
		return nil
	end
end

function update(path)
	local pApp = puppy.world.pApp.instance()
	local iomanager = pApp:getIOServer()

	-- make sure all dead object are collected
	collectgarbage("collect")
	collectgarbage("collect")
	if path then
		_import(path, true)
	else
		for name, module in pairs(__fs_require_loaded) do
			local t_lua = iomanager:getFileTime("script:"..name)
			local t_lo = lastLoadTime[name] or 0
			--print(name, t_lua, t_lo)
			if t_lua > t_lo then
				_import(name, true)
			end
		end
	end
end

function export(name, value)
	_G[name] = value
end

-- load a module globally, except the '__init__','__destroy__',... method
loadglobally = function(lf, t)
	t = t or _G
	for k,v in pairs(lf) do
		if type(k) == "string" and string.match(k, "__.*__") then
		else
			t[k] = v
		end
	end
	return lf
end

dofile = function(name)
	local func = nil

	func = loadfile(name)
	if type(func) ~= "function" then
		 log("error", string.format("safe_dofile failed\nfile:%s\nerr:%s\n",name,func ))
		 return
	end

	local env = {}
	setmetatable( env,{__index=_G})
	return setfenv(func,env)()
end


refresh_imported = function()
	for name, module in pairs(__fs_require_loaded) do
		if string.find(name, "data/info") ~= nil then
			_import(name, true)
		end
	end
end

destroy_imported = function()
	__fs_require_loaded = {}
end
