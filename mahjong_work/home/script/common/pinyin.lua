local m_data = import("data/info/info_pinyin.lua")

function get_pinyin( wchar )

	if not is_string(wchar) then return nil end
	if string.len(wchar) > 3 then
		wchar = string.sub(wchar, 1, 3)
	end

	if m_data.data[wchar] then	
		return (m_data.data[wchar][1])
	end
	return nil
end

__init__ = function(self)
	loadglobally(self)
end
