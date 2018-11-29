-- 顺序执行 应用于多个函数回调的情况
gSeqList = {}

function sequenceRun(callback)
	local co = nil
	local next, wait = nil
	local blance = 0
	co = coroutine.create(function()
		callback(wait,next)
		gSeqList[co] = nil
	end)
	next = function()
		blance = blance + 1
		if blance == 1 then
			coroutine.resume(co)
		end
	end
	wait = function()
		blance = blance - 1
		if blance == 0 then
			coroutine.yield()
		end
	end
	next()
	gSeqList[co] = true
end

__init__ = function()
	export("sequenceRun", sequenceRun)
end
