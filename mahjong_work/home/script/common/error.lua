 local error_table = {}
 error_handler = function(msg)
	 log("error",msg)
	 --if app._debug=true then return end
	 local md5 = win32.GetStrMD5(msg)

	 if not error_table[md5] then
		 -- todo: post to web

		 local error = puppy.value.new_null()
		 error:setk("md5", puppy.value.new_str(md5))
		 error:setk("version", puppy.value.new_str(tostring(app:get_version())))
		 error:setk("content", puppy.value.new_str(msg))
		 
		 log("error", error:save())

		 utillib.curl:post_content(const.SCRIPT_ERROR_POST_URL, error)
		 error_table[md5] = true
	 end
 end

 __init__ = function(self)
	 export("error_handler", error_handler)
end
