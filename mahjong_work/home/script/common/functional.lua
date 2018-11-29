--[[-----------------------------------------------------------
lua-functional.lua

The lua-functional library.
version 1.102
for Lua 5.2.0

An implementation of common functional-programming functions.

Bo Waggoner
Modified: 2012-02-02

This software is free.
-------------------------------


Usage:

lfunc = dofile('lua-functional.lua')
lfunc.add() and so on.


Functions:

add = function(...)
apply = function(f, ...)
applyn = function(f,n,val,...)
_and = function(...)
case = function(...)
casef = function(...)
choose = function(pred, a, b)
compose = function(...)
concat = function(...)
curry = function(f,n)
div = function(a,b)
eq = function(...)
filter = function(func, t, iter)
filterkey = function(func, t, iter)
filterkeyp = function(func, t, iter)
filterp = function(func, t, iter)
flatten = function(t,iter,t2,ind)
foldl = function(func, val, t, iter)
foldl1 = function(func, t, iter)
foldr1 = function(func, t, iter)
foldr = function(func, val, t, iter)
geq = function(...)
gen = function(seed, succ, cond)
gent = function(seed, succ, cond)
gt = function(...)
id = function(...)
indicator = function(pred)
len = function(...)
leq = function(...)
listcomp = function(func, arr, ...)
loadglobally = function(lf, t)
lt = function(...)
map = function(func, t, iter)
maptup = function(func, t, iter)
max = function(t, compare, iter)
min = function(t, compare, iter)
mod = function(a,b)
mult = function(...)
neg = function(...)
neq = function(...)
_not = function(...)
_or = function(...)
pow = function(a,b)
range = function(start,stop,step)
reverse = function(t, iter)
scanl = function(func, val, t, iter)
scanl1 = function(func, t, iter)
scanr = function(func, val, t, iter)
scanr1 = function(func, t, iter)
sub = function(a,b)
takewhile = function(func, t, iter)
zip = function(iter, t1, ...)
zipor = function(iter, ...)
zipwith = function(func, iter, ...)
zipwithtup = function(func, iter, ...)

--]]-----------------------------------------------------------


-- lfunc
-- This is the table of functions.


-- map
-- Apply a function to each element of an array or table.
-- Return a new table satisfying that, for each k,v returned
-- by 'iter', t2[k] = func(v)
-- Parameters:
--   func: the function to apply
--   t: the table we apply 'func' to
--   iter: (optional) an iterator over t
--     Default value: pairs
-- Return:
--   t2: the new table
map = function(func, t, iter)
    iter = iter or pairs
    local t2 = {}
    
    for k,v in iter(t) do
        t2[k] = func(v)
    end
    
    return t2
end

-- maptup
-- Exactly the same as map, except that all of func's
-- return values are packed into a table (tuple)
-- so that t2[k][3] is the 3rd return val of func(t[k])
maptup = function(func, t, iter)
    iter = iter or pairs
    local t2 = {}
    
    for k,v in iter(t) do
        t2[k] = table.pack(func(v))
        t2[k].n = nil
    end
    
    return t2
end

foreach = function(func, t, iter)
	iter = iter or pairs
	for k,v in iter(t) do
		func(v)
	end
end

-- foldl
-- Fold from left. ('reduce'.) Given a starting value,
-- apply a function to each element of an array or table,
-- using as arguments the result so far and the next element.
-- We accumulate the result as we go along the array.
-- For example, foldl(add, start, arr) is
-- the sum of all the elements of 'arr' plus 'start'.
-- Parameters:
--   func: the accumulator function to apply
--   val:  the starting value
--   t:    the table we apply 'func' to
--   iter: (optional) an iterator over t
--     Default value: ipairs
-- Return:
--   val: the final value obtained
--     if 't' is empty, return the parameter val
foldl = function(func, val, t, iter)
    iter = iter or ipairs
    
    for k,v in iter(t) do
        val = func(val,v)
    end
    
    return val
end


-- foldr
-- Fold from right. In all other respects,
-- exactly the same effect as foldl. But slower/more memory.
foldr = function(func, val, t, iter)
    iter = iter or ipairs
    
    local vals = {}
    local num = 0
    for k,v in iter(t) do
        table.insert(vals,v)
        num = num + 1
    end
    
    for j=num,1,-1 do
        val = func(vals[j],val)
    end
    
    return val
end


-- scanr
-- Do a foldr but store each value produced as we go.
-- Return an array t2, indexed starting at ind,
-- of the result after each step (starting at far
-- right, with val).
-- Parameters:
--   func: the accumulator function to apply
--   val:  the starting value
--   t:    the table to use
--   iter: (optional) an iterator over table
--     Default value: ipairs
--   ind:  (optional) starting index of the array to make
--     Default value: 1
-- Return:
--   t2: a table of values produced
--     if t is empty, return a table with just val
scanr = function(func, val, t, iter)
    iter = iter or ipairs
    local ind = 1
    local t2 = {}
    
    local num = ind
    for k,v in iter(t) do
        t2[num] = v
        num = num + 1
    end
    t2[num] = val
    
    for j=num-1,ind,-1 do
        val = func(t2[j],val)
        t2[j] = val
    end
    
    return t2
end


-- scanl
-- Exactly like scanr, but proceed from left to right).
-- Faster, less memory-intensive.
scanl = function(func, val, t, iter)
    iter = iter or ipairs
    local ind = 1
    local t2 = {}
    
    t2[ind] = val
    ind = ind + 1
    for k,v in iter(t) do
        val = func(val,v)
        t2[ind] = val
        ind = ind + 1
    end
    
    return t2
end


-- foldr1
-- Exactly like foldr, except with no starting value.
-- Instead, start with the first element of 't'.
--   if 't' is empty, return nil
--   if 'iter' returns only one value, return that value
foldr1 = function(func, t, iter)
    iter = iter or ipairs
    
    local vals = {}
    local num = 0
    for k,v in iter(t) do
        table.insert(vals,v)
        num = num + 1
    end
    
    local val = vals[num]
    for j=num-1,1,-1 do
        val = func(vals[j],val)
    end
    
    return val
end

-- foldl1
-- Exactly like foldr1, but from left.
foldl1 = function(func, t, iter)
    iter = iter or ipairs
    local initialized = false
    local val = nil
    
    for k,v in iter(t) do
        if not initialized then
            val = v
            initialized = true
        else
            val = func(val,v)
        end
    end
    
    return val
end

-- scanr1
-- Exactly like scanr, except with no starting value.
-- Thus, the first element of 't2' will be the same
-- as the first element of 't'.
-- Instead, start with the first element of 't'.
--   if 't' is empty, return an empty table
--   if 'iter' returns only one value, return a
--     table containing just that value
scanr1 = function(func, t, iter)
    iter = iter or ipairs
    local ind = 1
    local t2 = {}
    local val = nil
    
    local num = ind-1
    for k,v in iter(t) do
        num = num + 1
        t2[num] = v
    end
    
    val = t2[num]
    for j=num-1,ind,-1 do
        val = func(t2[j],val)
        t2[j] = val
    end
    
    return t2
end


-- scanl1
-- Exactly like scanr, but from left.
scanl1 = function(func, t, iter)
    iter = iter or ipairs
    local ind = 1
    local t2 = {}
    local initialized = false
    local val = nil
    
    for k,v in iter(t) do
        if not initialized then
            val = v
            initialized = true
        else
            val = func(val,v)
        end
        t2[ind] = val
        ind = ind+1
    end
    
    return t2
end


-- filter
-- Take out all elements of a pList not satisfying some condition.
-- Parameters:
--   func: a function applied to each element and returning true or false
--   t:    a table (the pList)
--   iter: (optional) an iterator to use with t
--     Default value: ipairs
-- Return:
--   t2: a new table satisying that, for each k,v returned by iter,
--       if func(v) then add v to t2
filter = function(func, t, iter)
    iter = iter or ipairs
    local t2 = {}
    
    for k,v in iter(t) do
        if func(v) then table.insert(t2,v) end
    end
    
    return t2
end

-- filterp
-- Exactly the same as filter, but preserve each elements'
-- place in the table, so the same key maps to them.
-- Thus, the default iterator is pairs.
filterp = function(func, t, iter)
    iter = iter or pairs
    local t2 = {}
    
    for k,v in iter(t) do
        if func(v) then t2[k] = v end
    end
    
    return t2
end

-- filterkey
-- Exactly the same as filter, but test the keys
-- AND the values. (Of course, a test function
-- taking only one argument will just test the keys.)
filterkey = function(func, t, iter)
    iter = iter or ipairs
    local t2 = {}
    
    for k,v in iter(t) do
        if func(k,v) then table.insert(t2,v) end
    end
    
    return t2
end

-- filterkeyp
-- Exactly the same as filterkey, but preserve each elements'
-- place in the table, so the same key maps to them.
-- Thus, the default iterator is pairs.
filterkeyp = function(func, t, iter)
    iter = iter or pairs
    local t2 = {}
    
    for k,v in iter(t) do
        if func(k,v) then t2[k] = v end
    end
    
    return t2
end



-- zip
-- Take multiple tables and return a table of ordered tuples;
-- for example, if t1[k] = v1 and t2[k] = v2, then
-- ans[k] = {[1]=v1, [2]=v2}.
-- Any key,value pair not shared by all tables is ignored.
-- Parameters:
--   iter: (optional) an iterator over the first table
--     Default value: pairs
--   t1:   the first table
--   ...:  other tables
-- Return:
--   ans: a new table of ordered pairs of values from t1,t2,
--        indexed by the keys of t1 and t2
zip = function(iter, t1, ...)
    local arg = table.pack(...)
    iter = iter or pairs
    local ans = {}
    if not t1 then return ans end
    
    for k,v1 in iter(t1) do
        local include = true
        for _,t2 in ipairs(arg) do
            if t2[k] == nil then
                include = false
                break
            end
        end
        if include then
            ans[k] = {}
            table.insert(ans[k],v1)
            for _,t2 in ipairs(arg) do
                table.insert(ans[k],t2[k])
            end
        end
    end
    
    return ans
end

-- zipor
-- The exact same as zip, except it includes all values
-- which are present in any table.
-- Thus the ordered tuples may not all be the same size.
-- iter is the iterator used for every table
zipor = function(iter, ...)
    local arg = table.pack(...)
    iter = iter or pairs
    local ans = {}
    
    for _,t1 in ipairs(arg) do
        for k,v in iter(t1) do
            if ans[k] == nil then
                ans[k] = {}
            end
            table.insert(ans[k],v)
        end
    end
    
    return ans
end

-- flatten
-- Turn a deep array into a one-dimensional array
-- and move all arguments into indices ind,ind+1,...
flatten = function(t,iter,t2,ind)
    iter = iter or ipairs
    t2 = t2 or {}
    ind = ind or 1
    
    for _,val in iter(t) do
        if type(val) == 'table' then
            flatten(val,iter,t2,ind)
            while t2[ind] do ind = ind+1 end
        else
            t2[ind] = val
            ind = ind+1
        end
    end
    
    return t2
end

-- max
-- Return the maximal element of a table and the key which
--   indexes it.
-- Parameters:
--   t:       the table
--   compare: (optional) a function to compare two elements
--   iter:    (optional) an iterator over the table
--     Default value: ipairs
-- Return:
--   ans: the (first) maximal element of the table
--     If t is empty, return nil
--   key: first key according to iter satisfying t[key] = ans
--     If t is empty, return nil
max = function(t, compare, iter)
    compare = compare or gt
    iter = iter or ipairs
    
    local ans = nil
    local key = nil
    
    for k,v in iter(t) do
        if ans==nil then
            ans = v
            key = k
        else
            if compare(v,ans) then
                ans = v
                key = k
            end
        end
    end
    
    return ans,key
end


-- apply
-- Partially apply a functoin.
-- Takes a function f of a1,...,an and the first k arguments
-- a1,...,ak and returns a function g which takes arguments
-- bk+1,...,bn so that calling g(bk+1,...,bn) is equivalent
-- to calling f(a1,...,ak,bk+1,...,bn).
-- Parameters:
--   f:   the function to be partially applied
--   ...: the arguments to pass in
-- Return:
--   g: a function so that g(b1,...) = f(...,b1,b2,b3)
apply = function(f, ...)
    local origarg = table.pack(...)
    return function(...)
        local arg = table.pack(...)
        local ind = 1
        local input = {}
        for i,v in ipairs(origarg) do
            table.insert(input,v)
        end
        for i,v in ipairs(arg) do
            table.insert(input,v)
        end
        return f(table.unpack(input))
    end
end


-- applyn
-- apply a function to its nth argument.
-- Parameters:
--   f:   the function to be applied
--   ...: pairs in order n1, val1, etc
-- Returns:
--   g:   When called, g(a,b,...) where arg = {a,b,...},
--        inserts val1 into position n1 in arg (shifting elements
--        if necessary), etc, then calls f(arg).
applyn = function(f,...)
    local origarg = table.pack(...)
    return function(...)
        local arg = table.pack(...)
        ind = 1
        while origarg[ind] do
            table.insert(arg,origarg[ind],origarg[ind+1])
            ind = ind + 2
        end
        return f(table.unpack(arg))
    end
end


-- curry
-- Curry a function. Subtly different from apply, and probably much slower.
-- Given a function f that takes n arguments, return
-- a curried version of f, f'.
-- f' satisfies that: f'(a1,...,ak) returns a curried
-- function of f partially applied to those k arguments.
-- Along the chain, once n arguments have been passed to
-- f' (or to f' plus whatever curried function it's created),
-- the function is evaluated and the results returned.
-- Basically, you can call f'(1)(2)(3)(...) 10 times.
-- Any fewer, and you still get a function. At the 10th time
-- it returns the function's results.
-- Example: f is add. f' = curry(f,4). g = f'(10,11). Let
-- h = g(12). Then h(13) = 10+11+12+13. But g(14,15) = 10+11
-- +14+15. Kapeesh?
curry = function(f,n)
    return function(...)
        local myargs = table.pack(...)
        if #myargs == n then
            return f(table.unpack(myargs))
        elseif #myargs > n then
            local a = {}
            for i=1,n do
                a[i] = myargs[i]
            end
            return f(table.unpack(a))
        else
            return curry(apply(f,table.unpack(myargs)),n - #myargs)
        end
    end
end


-- compose
-- Compose zero or more functions. That is, if you write
-- h = compose(f,g), then calling h(x) gives you f(g(x)).
-- Parameters:
--   ...: functions to be composed, in left-to-right order
-- Returns:
--   h: the composition of all function arguments
--     if no arguments are given, h(x) = x
compose = function(...)
    local myfuncs = table.pack(...)
    
    return function(...)
        local results = table.pack(...)
        local ind = #myfuncs
        while myfuncs[ind] do
            results = table.pack(myfuncs[ind](table.unpack(results)))
            ind = ind-1
        end
        return table.unpack(results)
    end
end


-- takewhile
-- Create a new pList from an old one by taking elements as long as they
-- satisfy a predicate.
-- Parameters:
--   t:    the table
--   func: the predicate; if func(v) then include v, else stop
--     Defaults to the identity (take while v)
--   iter: (optional) an iterator over t
--     Default value: ipairs
--   ind:  (optional) where to place the first element
--     Default value: 1
-- Return:
--   t2: a pList (starting at ind)
takewhile = function(func, t, iter, ind)
    iter = iter or ipairs
    ind = ind or 1
    func = func or function(a) return a end
    local t2 = {}
    
    for k,v in iter(t) do
        if func(v) then
            t2[ind] = v
            ind = ind+1
        else
            break
        end
    end
    
    return t2
end


-- choose
-- If pred, return the first argument, else return the second.
-- Basically the ternary operator in function form.
-- Parameters:
--   pred: the predicate
--   a:    return this if pred evaluates to true
--   b:    return this otherwise
-- Return:
--   a or b
choose = function(pred, a, b)
    if pred then return a else return b end
end



-- case
-- Takes as input a set of pairs (test, val)
-- Returns the first val whose test is true
-- (non-false and non-nil).
-- Parameters:
--   ...: each table is ([1]=test, [2]=val)
-- Return:
--   the result, or nil if no case is matched
case = function(...)
    local arg = table.pack(...)
    for i,pair in ipairs(arg) do
        if pair[1] then return pair[2] end
    end
    return nil
end

-- casef
-- Takes as input a set of pairs {pred, result}.
-- Returns a function f so that a call to f(args) returns the first result whose
-- 'pred' is true. If 'pred' is a function, then test the results of pred(args);
-- otherwise, just test the value of pred. If the result is non-nil and
-- non-false, then return the corresponding result. If result is a function,
-- return result(args); otherwise just return result.
-- Parameters:
--   ...: each argument is a table of the form {[1]=pred, [2]=result}
-- Return:
--   f: a function that, when called with 'args', for the
--      first time (cond or cond(args)) is non-nil, non-false,
--      return: (pred or pred(args)). For each, call as a function only if it
--         is of type function.
--      If no tables are passed in or no case matches, f returns nil
casef = function(...)
    local myarg = table.pack(...)
    return function(...)
        for i,pair in ipairs(myarg) do
            if pair[1] then
                if type(pair[1])~='function' or pair[1](...) then
                    if not pair[2] or type(pair[2])~='function' then
                        return pair[2]
                    else
                        return pair[2](...)
                    end
                end
            end
        end
        return nil
    end
end


-- reverse an array or string
-- for ipairs, put them in the right place the first time
-- otherwise, we have to count them first, then place them
reverse = function(t, iter)
    iter = iter or ipairs
    local t2 = {}
    
    if type(t) == 'string' then return string.reverse(t) end
    
    local ind = 0
    for k,v in iter(t) do
        ind = ind+1
        if iter==ipairs then t2[#t-ind+1] = v
        else t2[ind] = v end
    end
    
    if iter ~= ipairs then
        local max = (ind - mod(ind,2))/2
        for ind2=1,max do
            local temp = t2[ind2]
            t2[ind2] = t2[ind-ind2+1]
            t2[ind-ind2+1] = temp
        end
    end
    
    return t2
end



-- operators
-- should make things easier?
add = function(...)
    local arg = table.pack(...)
    local sum = 0;
    for i,val in ipairs(arg) do sum = sum + val end
    return sum
end

sub = function(a,b) return a-b end

mult = function(...)
    local arg = table.pack(...)
    local prod = 1
    for i,val in ipairs(arg) do prod = prod * val end
    return prod
end

div = function(a,b) return a/b end

pow = function(a,b) return a^b end

mod = function(a,b) return a%b end

neg = function(...)
    local arg = table.pack(...)
    for i,val in ipairs(arg) do
        arg[i] = -val
    end
    return table.unpack(arg)
end

eq = function(...)
    local arg = table.pack(...)
    local ind = 2
    while arg[ind]~=nil do
        if not (arg[ind-1] == arg[ind]) then return false end
        ind = ind + 1
    end
    return true
end

neq = function(...)
    local arg = table.pack(...)
    if #arg <= 1 then return false end
    local ind = 2
    while arg[ind]~=nil do
        if not (arg[ind-1] ~= arg[ind]) then return false end
        ind = ind + 1
    end
    return true
end

lt = function(...)
    local arg = table.pack(...)
    local ind = 2
    while arg[ind]~=nil do
        if not (arg[ind-1] < arg[ind]) then return false end
        ind = ind + 1
    end
    return true
end

gt = function(...)
    local arg = table.pack(...)
    local ind = 2
    while arg[ind]~=nil do
        if not (arg[ind-1] > arg[ind]) then return false end
        ind = ind + 1
    end
    return true
end

leq = function(...)
    local arg = table.pack(...)
    local ind = 2
    while arg[ind]~=nil do
        if not (arg[ind-1] <= arg[ind]) then return false end
        ind = ind + 1
    end
    return true
end

geq = function(...)
    local arg = table.pack(...)
    local ind = 2
    while arg[ind]~=nil do
        if not (arg[ind-1] >= arg[ind]) then return false end
        ind = ind + 1
    end
    return true
end

_and = function(...)
    local arg = table.pack(...)
    local v = nil
    for i=1,#arg do
        v = arg[i]
        if not v then return v end
    end
    return v
end

_or = function(...)
    local arg = table.pack(...)
    local v = nil
    for i=1,#arg do
        v = arg[i]
        if v then return v end
    end
    return v
end

_not = function(...)
    local arg = table.pack(...)
    for i=1,#arg do
        arg[i] = not arg[i]
    end
    return table.unpack(arg)
end

concat = function(...)
    local arg = table.pack(...)
    return table.concat(arg)
end

len = function(...)
    local arg = table.pack(...)
    for i,val in ipairs(arg) do
        arg[i] = #val
    end
    return table.unpack(arg)
end

-----------
-- Derived functions
-----------

-- identity
-- return exactly what is passed in, except no named arguments
id = function(...)
    return ...
end



-- zipwith
-- Taking a set of tables, applies a function to the
-- tuple of the ith elements of the tables.
-- So, if you pass in n tables, func should take
-- n arguments. If you want func to return multiple
-- values, it should pack them in a table or use zipwithtup.
-- t2[3] is the return value of func(t1[3],t2[3],...).
-- Parameters:
--   func: the function to apply
--   iter: (optional) the iterator over the 1st table to use
--     Default value: pairs
--   ...:  the tables to apply it to
zipwith = function(func, iter, ...)
    iter = iter or pairs
    return map(compose(func,table.unpack),zip(iter,...),iter)
end


-- zipwithtup
-- Exactly the same as zipwith, except it packs the result
-- of 'func' into a table. So ans[3][2] is the second return
-- value of func(t1[3],t2[3],...).
zipwithtup = function(func, iter, ...)
    iter = iter or pairs
    return maptup(compose(func,table.unpack),zip(iter,...),iter)
end


-- indicator
-- Special case of choose where we return either 1 or 0.
indicator = function(pred)
    if pred then return 1 else return 0 end
end


-- min
-- Exactly the same as max, except that the comparator
--   defaults to minimal element if none is specified.
min = function(t, compare, iter)
    compare = compare or function(a,b) return (a<b) end
    return max(t,compare,iter)
end


-- listcomp
-- a pList comprehension using the provided function,
-- array, and filters
-- Parameters:
--   func: (optional) function to apply after filtering
--     Default value: the identity (just return the pList)
--   arr: the initial pList
--   ...: (optional) filter functions
-- Return:
--   the pList, filtered
listcomp = function(func, arr, ...)
    local arg = table.pack(...)
    func = func or id
    return map(func,foldr(filter,arr,arg),pairs)
    
end


-- gen
-- Generates a bunch of stuff and puts in in a pList.
-- like weak induction
gen = function(seed, succ, cond)
    local t = {}
    local ind = 1
    while not cond(seed,ind) do
        table.insert(t,seed)
        ind = ind+1
        seed = succ(seed,ind)
    end
    return t
end

-- gent
-- Like gen, but use functions of the entire table
-- like strong induction
gent = function(seedt, succ, cond)
    seedt = seedt or {}
    local ind = #seedt + 1
    local val = succ(seedt,ind)
    while not cond(seedt,val,ind) do
        table.insert(seedt,val)
        ind = ind+1
        val = succ(seedt,ind)
    end
    return seedt
end

-- range
-- a special case of gen: a range of numbers.
-- Like lua's for loop, if start < stop, terminates
-- when start > stop. If start > stop, terminates
-- when start < stop.
-- Parameters:
--   start: the starting value to put in
--   stop:   the extreme value to put in
--   step:  (optional) the amount to add each time
range = function(start,stop,step)
    if not stop and not step then return range(1,start) end
    step = step or case({start > stop, -1},
                              {true,          1})
    
    cond = case(
        {start > stop,function(a) return a < stop end},
        {start < stop,function(a) return a > stop end},
        {true,        function(a) return a ~= stop end})
    
    local succ = function(seed,ind) return seed + step end
    return gen(start, succ, cond)
    
end

--秒数转化成标准时间 并返回str
--参数 ：秒
sec_to_standtime = function(second_time)
	local temp_hour = math.floor(second_time/3600)
	local temp_minute = math.floor((second_time/60)%60)
	local temp_second = math.floor(second_time%60)
	
	local str = string.format(TEXT("%s小时%s分%s秒"), temp_hour, temp_minute, temp_second)
	return str
end

--秒数转化成标准时间(无小时) 并返回str
--参数 ：秒
sec_to_minute_time = function(second_time)
	local temp_minute = math.floor((second_time/60))
	local temp_second = math.floor(second_time%60)
	
	local str = string.format(TEXT("%s分%s秒"), temp_minute, temp_second) 
	return str
end


__init__ = function(self)
	loadglobally(self)
end
