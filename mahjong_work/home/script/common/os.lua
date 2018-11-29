local platformName = {
	["iPhone1,1"] = "iPhone 2G",
	["iPhone1,2"] = "iPhone 3G",
	["iPhone2,1"] = "iPhone 3GS",
	["iPhone3,1"] = "iPhone 4",
	["iPhone3,2"] = "iPhone 4",
	["iPhone3,3"] = "iPhone 4 (CDMA)",    
	["iPhone4,1"] = "iPhone 4S",
	["iPhone5,1"] = "iPhone 5",
	["iPhone5,2"] = "iPhone 5 (GSM+CDMA)",

	["iPod1,1"] = "iPod Touch (1 Gen)",
	["iPod2,1"] = "iPod Touch (2 Gen)",
	["iPod3,1"] = "iPod Touch (3 Gen)",
	["iPod4,1"] = "iPod Touch (4 Gen)",
	["iPod5,1"] = "iPod Touch (5 Gen)",

	["iPad1,1"] = "iPad",
	["iPad1,2"] = "iPad 3G",
	["iPad2,1"] = "iPad 2 (WiFi)",
	["iPad2,2"] = "iPad 2",
	["iPad2,3"] = "iPad 2 (CDMA)",
	["iPad2,4"] = "iPad 2",
	["iPad2,5"] = "iPad Mini (WiFi)",
	["iPad2,6"] = "iPad Mini",
	["iPad2,7"] = "iPad Mini (GSM+CDMA)",
	["iPad3,1"] = "iPad 3 (WiFi)",
	["iPad3,2"] = "iPad 3 (GSM+CDMA)",
	["iPad3,3"] = "iPad 3",
	["iPad3,4"] = "iPad 4 (WiFi)",
	["iPad3,5"] = "iPad 4",
	["iPad3,6"] = "iPad 4 (GSM+CDMA)",
	["i386"] = "Simulator",
	["x86_64"] = "Simulator",
}

os.getPlatform = function()
	local platform = os.getMachine()
	return platformName[platform] or platform
end

__init__ = function()

end
