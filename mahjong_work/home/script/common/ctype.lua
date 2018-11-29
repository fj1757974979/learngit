
function isascii(ch)--判断是不是ascii码
	return ch < 128
end

function isdigit(char)--判断是不是数字0-9
	return char >= 48 and char <= 57
end

function isalpha(char) --判断是不是字母(含大小写字母)
	return (char >= 97 and char <= 122) or (char >= 65 and char <= 90)
end

function isalpnum(char)--判断是不是字母和数字
	return isalpha(char) or isdigit(char)
end

function islower(char)--判断是不是小写字母a-z
	return char >= 97 and char <=122
end


function isupper(char)--判断是不是大写字母A-Z
	return char >=65 and char <=90
end

function isnumber(num)--判断是不是数字
	return type(num) == "number"
end

function equal_num(ary)--判断数组中相同的数最多有几次
	local max_num = 1
	local cur_num = 1
	table.sort(ary,function(e1,e2)
		return e1< e2
	end)
	for k, v in ipairs(ary) do
		if k >=2 then
			if ary[k-1]==ary[k] then 
				cur_num = cur_num + 1
			else 
				max_num = math.max(cur_num,max_num)
				cur_num = 1
			end
		end
	end	
	return math.max(cur_num,max_num)
end
