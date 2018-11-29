--从沙盒里取下一个密种。标准rc4算法
local GetNextSeed = function( RC4Context )
	local bit = bit
	local f = function()
		i	= bit.band(0xff, i+1)
		j	= bit.band(0xff, j+SBox[i])
		
		local si = SBox[i]
		local sj = SBox[j]
		
		SBox[i]  = sj
		SBox[j]  = si
		return SBox[ bit.band(0xff,si+sj) ]
	end
	
	return setfenv(f,RC4Context)()
end

local DisturbFunc1 = function( Context )
	SBox, Seed = Context.SBox, Context.InitSeed
	
	for i = 0, 255 do SBox[i] = i end

	local k = {}
	for i = 0, 63  do
		k[(i)*4]	= bit.bxor( bit.band(0xff, i), 
						 bit.band(0xff, Seed) )
						 
		k[(i)*4+1]	= bit.bxor( bit.band(0xff, bit.rshift(i,8)), 
						 bit.band(0xff, bit.rshift(Seed,8))  )
		
		k[(i)*4+2]	= bit.bxor( bit.band(0xff, bit.rshift(i,8)), 
						 bit.band(0xff, bit.rshift(Seed,16)) )
						 
		k[(i)*4+3]	= bit.bxor( bit.band(0xff, bit.rshift(i,8)), 
						 bit.band(0xff, bit.rshift(Seed,24)) )
	end
	
	local j = 0
	for i = 0, 255 do		
		j = j + SBox[i] + k[i]
		j = math.mod(j,256)
		SBox[i], SBox[j] = SBox[j], SBox[i]
	end
	
	
--	pt(SBox,"DisturbFunc1 sbox 1 ")
	local d={}
	for i = 2, 64 do
		for j = 0, i-2 do
			d[#d+1] = GetNextSeed( Context )
		end
	end
--	pt(d,"d")
--	pt(SBox,"DisturbFunc1 sbox 2")
end

local DisturbFunc2 = function( Context )
	SBox, Seed = Context.SBox, Context.InitSeed
	for i = 0, 255 do SBox[i] = i end

	local k = {}
	for i = 0, 63  do
		k[(i)*4]	= bit.band(0xff, Seed) 
		k[(i)*4+1]	= bit.band(0xff, bit.rshift(Seed,8))  
		k[(i)*4+2]	= bit.band(0xff, bit.rshift(Seed,16)) 
		k[(i)*4+3]	= bit.band(0xff, bit.rshift(Seed,24)) 
	end
	
	local j = 0
	for i = 0, 255 do		
		j = j + SBox[i] + k[i]
		j = math.mod(j,256)
		SBox[i], SBox[j] = SBox[j], SBox[i]
	end
end

local PreDisturbFuncList = { DisturbFunc1, DisturbFunc2}

RC4_CreateContext = function( Arg )
	--基本的状态：沙盒，i/j计数器
	local Context = {}
	for k,v in pairs(Arg) do
		Context[k] = v
	end
	
	Context.SBox	= {}
	Context.i	= 0
	Context.j	= 0
	
	--初始种子
	Context.InitSeed = Arg.InitSeed
	
	--初始化沙盒，并简单扰乱之。非标准，可任意实现，只要求两端相同-----------------
	local DisturbFunc = Arg.DisturbFunc
	if type(DisturbFunc) == "function" then --用户直接提供了扰乱函数
		DisturbFunc( Context )
	else
		PreDisturbFuncList[ DisturbFunc ]( Context )
	end
	--------------------------------------------------------------------------------
	
	return Context
end

RC4_Transform = function( RC4Context, Data )
	local Output = {}
	for i = 1, #Data do
		local Code = GetNextSeed(RC4Context)
		if RC4Context.ShowCode then
			print( string.format("RC4_Transform data:%u, code:%u",Data[i],Code))
		end
		Output[i] = bit.bxor( Code, Data[i] )		
	end
	return Output
end


---------------------------------------------------------
print_t = function(s,t)
	print(s)
	local ts = ""
	for i = 1, #t do
		ts = ts..string.format("%03d ",t[i])
	end
	print(ts)
end

Test = function()
	local send_rc4ctx = RC4_CreateContext{
		InitSeed = 1361849378,
		DisturbFunc = 2,
	}

	local recv_rc4ctx = RC4_CreateContext{
		InitSeed = 1361849378,
		DisturbFunc = 2,
	}

	--local str = "12812989123512"
	local str = "测试数据d\x00ata"
	local data = {}
	local len = string.len(str)
	for i = 1, len do
		table.insert(data, string.byte(str, i))
	end

	--local data = {1,2,3,4,5,6,7,8,9,0,234,6,67,2,24,5,6,7,8,9,3,233,5,6,88,}
	logv("error", "origin", data)
	
	local output = RC4_Transform( send_rc4ctx, data )
	logv("error", "transform1",output)
	
	local output2 = RC4_Transform( recv_rc4ctx, output )
	logv("error", "transform2",output2)
end

Test_repeat = function()
	local send_rc4ctx = RC4_CreateContext {
		InitSeed = 1361849378,
		DisturbFunc = 2,
	}

	local str = "测试数据d\x00ata"
	local data = {}
	local len = string.len(str)
	for i = 1, len do
		table.insert(data, string.byte(str, i))
	end

	local output = RC4_Transform( send_rc4ctx, data )
	logv("error", "transform1",output)
	logv("error", "sbox",send_rc4ctx.SBox)

	output = RC4_Transform( send_rc4ctx, output)
	logv("error", "transform2",output)
	logv("error", "sbox",send_rc4ctx.SBox)

	output = RC4_Transform( send_rc4ctx, output)
	logv("error", "transform3",output)
	logv("error", "sbox",send_rc4ctx.SBox)
end

--Test()
