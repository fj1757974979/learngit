local base_symbols = {
	["+"] = { function(l, r)
		return l+r
	end, 2 },
	["-"] = { function(l, r)
		return l-r
	end, 2 },
	["*"] = { function(l, r)
		return l*r
	end, 2 },
	["/"] = { function(l, r)
		return l/r
	end, 2 },
	["^"] = { function(l, r)
		return l^r
	end, 2 },
}

local adv_symbols = {
	["MAX4"] = { function(a1, a2, a3, a4) return math.max(a1, a2, a3, a4) end, 4 },
	["MIN2"] = { function(a1, a2) return math.min(a1, a2) end, 2 },
	["MIN4"] = { function(a1, a2, a3, a4) return math.min(a1, a2, a3, a4) end, 4 },
	["MAX5"] = { function(a1, a2, a3, a4, a5) return math.max(a1, a2, a3, a4, a5) end, 5 },
	["NEED"] = { function(race, lv) return data.get_need_count(race, lv) end, 2 },
}

local symbol_priority = {
	["("] = 0,
	["+"] = 1,
	["-"] = 1,
	["*"] = 2,
	["/"] = 2,
	["^"] = 6,
	["MAX4"] = 10,
	["MIN2"] = 10,
	["MIN4"] = 10,
	["MIN5"] = 10,
}

-- 计算字符串形式的算术表达式
function calc_expression(exp)
	-- 将中缀表达式翻译成后缀表达式
	local output_list = {}	-- 输出列表
	local symbol_list = {}

	local s, e = 1, 1
	while true do
		s, e = string.find(exp, "^([%d%.]+)")

		if s and e then	-- 数字，直接添加到输出列表
			local num = string.sub(exp, s, e)
			exp = string.sub(exp, e+1, -1)
			table.insert(output_list, tonumber(num))
		else
			s, e = 1, 1
			local c = string.sub(exp, s, e)
			if c == "(" then	-- 如果是'('，则push进符号栈
				table.insert(symbol_list, c)
			elseif c == ")" then	-- 如果是')'，则从栈内依次pop符号，直到碰到'('
				while #symbol_list > 0 do
					local symbol = table.remove(symbol_list)
					if symbol == "(" then
						break
					end

					table.insert(output_list, symbol)
				end
			else
				local op_info = base_symbols[c]	-- 看看是不是基础运算符

				if not op_info then	-- 可能是高级运算符
					for op_name, info in pairs(adv_symbols) do
						s, e = string.find(exp, "^"..op_name)
						if s and e then
							c = op_name
							op_info = info
							break
						end
					end
				end

			if op_info then
				if #symbol_list <= 0 then	-- 如果符号表为空，，则push进符号栈
					table.insert(symbol_list, c)
				else
					-- 优先级比栈顶元素高，则push进符号栈
					while #symbol_list > 0 do
						local last_c = symbol_list[#symbol_list]

						if symbol_priority[c] > symbol_priority[last_c] then
--								table.insert(symbol_list, c)
							break
						else	-- 优先级小于等于栈顶元素，则输出栈顶元素，将当前符号push进栈
							table.remove(symbol_list)

--								table.insert(symbol_list, c)
							table.insert(output_list, last_c)
						end
					end

					table.insert(symbol_list, c)
				end
			end
		end

		exp = string.sub(exp, e+1, -1)
	end

	if (not exp) or (string.len(exp) == 0) then
		break
	end
end

 -- 如果字符串读完了，符号表不为空，则将符号依次从栈顶输出
 if #symbol_list > 0 then
	 for i = #symbol_list, 1, -1 do
		 table.insert(output_list, symbol_list[i])
	 end
 end

 -- 计算后缀表达式到最终结果
 local data_list = {}	-- 数据栈
 for _, data in ipairs(output_list) do
	 if type(data) == "number" then	-- 操作数
		 table.insert(data_list, data)
	 elseif type(data) == "string" then	-- 操作符
		 local op_info = adv_symbols[data] or base_symbols[data]
		 if op_info then
			 local arg_list = {}
			 for i = 1, op_info[2] do
				 table.insert(arg_list, 1, table.remove(data_list))
			 end

			 local result = (op_info[1])(unpack(arg_list))
			 table.insert(data_list, result)
		 end
	 end
 end

 return data_list[1]
end

parse_func_str = function(str, prop, opt)
--	if nil then
	if prop then
		opt = opt or {}
		local revise_str = opt.revise_str
		
		-- 校正最终结果的表
		local revise_tbl = {}
		if revise_str then
			revise_tbl = revise_str:split(",")
		end

		-- 校正基础属性数值的表
		local prop_revise_tbl = {}
		if opt.prop_revise then
			prop_revise_tbl = opt.prop_revise
		end

		local prop_index = 0
		str = string.gsub(str, "#k%((%a+)%)", function(key)
			prop_index = prop_index + 1
			local prop_value = prop:getProp(key, 0)

			if prop_revise_tbl[prop_index] then
				local str = prop_revise_tbl[prop_index]

				str = string.gsub(str, "#k%((%a+)%)", function(key)
					return prop:getProp(key, 0)
				end)

				str = string.gsub(str, "R", tostring(prop_value))

				prop_value = calc_expression(str)
			end

			return prop_value
		end)
		
		local i = 0

		str = string.gsub(str, "#f%[(.-)%]", function(f)
			i = i + 1

			local result = calc_expression(f)

			if revise_tbl[i] then	-- 校正最终结果
				local str = revise_tbl[i]

				str = string.gsub(str, "#k%((%a+)%)", function(key)
					return prop:getProp(key, 0)
				end)

				str = string.gsub(str, "R", tostring(result))

				result = calc_expression(str)
				
				if type(result) == "number" then
					result = math.floor(result + 0.5)
				end
			end

			if type(result) == "number" then
				result = math.floor(result)
				
				if not opt.not_ctrl_code then
					result = "#cff2850a0"..result.."#n"
				end
			end

			return result
		end)
	else
		str = string.gsub(str, "#f%[(.-)%]", function(f)
			return "-"
		end)
	end

	return str
end

__init__ = function(self)
	loadglobally(self)
end
