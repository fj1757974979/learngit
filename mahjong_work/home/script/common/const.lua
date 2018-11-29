import("common/locale.lua")

CHANNEL_TEAM      = 0      --//组队频道                  
CHANNEL_WORLD     = 1      --//世界频道                  
CHANNEL_CURRENT   = 2      --//当前频道                  
CHANNEL_SYSTEM    = 3      --//系统频道                  
CHANNEL_TIPS      = 4      --//提示频道                  
CHANNEL_SCHOOL     = 5      --//门派频道                  
CHANNEL_FACTION   = 6      --//帮派频道                  
CHANNEL_BROADCAST = 7      --//传音                    
CHANNEL_KEFU      = 8      --//和客服在线聊天的频道            
CHANNEL_FRIEND    = 9      --//好友消息                  




CHANNEL_FIGHT = 999

CHANNEL_NAME = {
	[CHANNEL_TEAM] = TEXT("队伍"),
	[CHANNEL_WORLD] = TEXT("世界"),
	[CHANNEL_CURRENT] = TEXT("当前"),
	[CHANNEL_SYSTEM] = TEXT("系统"),
	[CHANNEL_TIPS] = TEXT("提示"),
	[CHANNEL_BROADCAST] = TEXT("传音"),
	[CHANNEL_FACTION] = TEXT("帮派"),
	[CHANNEL_SCHOOL] = TEXT("门派"),
}

CHANNEL_ICON_NAME = {
	[CHANNEL_TEAM] = "队伍",
	[CHANNEL_WORLD] = "世界",
	[CHANNEL_CURRENT] = "当前",
	[CHANNEL_SYSTEM] = "系统",
	[CHANNEL_TIPS] = "系统",
	[CHANNEL_BROADCAST] = "传音",
	[CHANNEL_FACTION] = "家族",
	[CHANNEL_SCHOOL] = "门派",
}


CHANNEL_ICON_RES = {
	["队伍"] = {"ui", "skin/slhx/image/image_29.TGA"},
	["世界"] = {"ui", "skin/slhx/image/image_28.TGA"},
	["当前"] = {"ui", "skin/slhx/image/image_32.TGA"},
	["系统"] = {"ui", "skin/slhx/image/image_31.TGA"},
	["家族"] = {"ui", "skin/slhx/image/image_30.TGA"},
	["门派"] = {"ui", "skin/slhx/image/image_58.TGA"},
	["传音"] = {"ui", "skin/slhx/image/image_28_1.TGA"},
}





ZVALUE_LOADING_PANEL	= -20000 -- loading界面
ZVALUE_ITEM_MENU	= -10001	-- 物品菜单
ZVALUE_TIPS		= -10000	-- tips窗口
ZVALUE_OFFLINE_REWARD	= -1000 -- 离线奖励
ZVALUE_POPUPWND		= -10	-- 右下角弹窗
ZVALUE_SELECTCHANNEL	= -1	-- 选择频道
ZVALUE_SECONDMENU	= 0	-- 二级菜单
ZVALUE_NORMAL		= 0	-- 默认值
ZVALUE_TASKTRACE_UI	= 0	-- 任务追踪UI
ZVALUE_PANEL		= 0	-- 面板UI(有按钮打开和关闭)
ZVALUE_CHAT_INPUT	= 5	-- 聊天输入框，里面的聊天频道选择框，需要挡住其他主界面UI
ZVALUE_MAIN_UI		= 10	-- 主界面UI(即一直在界面上显示的UI)
ZVALUE_FESTIVAL_UI	= 12	-- 内测狂欢节
ZVALUE_SHORTCUT_PANEL	= 15	-- 快捷栏
ZVALUE_NOTICE_UI	= 20 --系统公告栏UI
ZVALUE_RIGHT_MENU	= -10000
ZVALUE_MODAL		= -1000


LAYER_TYPE = {
	LT_EDIT_BUTTON   = 1,
	LT_NORMAL	 = 1000,	-- 普通窗口层
	LT_FIGHT_SPECIAL = 1002,	-- 战斗中特殊面板（回合面板、倒计时面板）
	LT_TEAM		 = 1003,	-- 队伍面板层
	LT_MODAL_BG      = 1100,	-- 模态框背景
	LT_MODAL	 = 1150,	-- 模态框
	LT_STORY	 = 1200,	-- 剧情面板
	LT_EXIT_CONFIRM  = 1300,	-- 退出游戏确认框
}

COLOR_CONST = {
	STANDARD_DEFAULT = 0xff3d0000,
	STANDARD_RED = 0xffaa0000,
	STANDARD_BLACK = 0xff1e1e1e,
	STANDARD_YELLOW = 0xffffdc8c,
	STANDARD_ORANGE = 0xfffdbb1c,
	STANDARD_GREEN = 0xff33f140,
	STANDARD_BLUE = 0xff1adcff,
	STANDARD_PURPLE = 0xffb20eff,
	STANDARD_GRAY = 0xff969696,
	STANDARD_WHITE = 0xffffffff,

	STANDARD_DEFAULT_S = "ff3d0000",
	STANDARD_RED_S = "ffaa0000",
	STANDARD_BLACK_S = "ff1e1e1e",
	STANDARD_YELLOW_S = "ffffdc8c",
	STANDARD_ORANGE_S = "fffdbb1c",
	STANDARD_GREEN_S = "ff33f140",
	STANDARD_BLUE_S = "ff1adcff",
	STANDARD_PURPLE_S = "ffb20eff",
	STANDARD_GRAY_S = "ff969696",
	STANDARD_WHITE_S = "ffffffff",
}

GROW_TO_COLOR =
{
	[0] = COLOR_CONST.STANDARD_WHITE,
	[1] = COLOR_CONST.STANDARD_GREEN,
	[2] = COLOR_CONST.STANDARD_BLUE,
	[3] = COLOR_CONST.STANDARD_PURPLE,
	[4] = COLOR_CONST.STANDARD_ORANGE,
}

GROW_TO_COLOR_S =
{
	[0] = COLOR_CONST.STANDARD_WHITE_S,
	[1] = COLOR_CONST.STANDARD_GREEN_S,
	[2] = COLOR_CONST.STANDARD_BLUE_S,
	[3] = COLOR_CONST.STANDARD_PURPLE_S,
	[4] = COLOR_CONST.STANDARD_ORANGE_S,
}

CHANNEL_NAME_COLOR_S = {
		[CHANNEL_TEAM] = "cFF00d8ff",
		[CHANNEL_WORLD] = "cffffd43e",
		[CHANNEL_CURRENT] = "cFF8C68F0",
		[CHANNEL_SCHOOL] = "cff1008ad",
		[CHANNEL_FACTION] = "cff14ff7d",
		[CHANNEL_BROADCAST] = "cFFff7800",
	}
	
ITEM_TYPE_CONST = 
{
	["YP"]	= 1, 
	["DH"]	= 2,
	["DT"]	= 3, 
	["ZH"]	= 4,
	["CL"]  = 5,
	["BF"]	= 6,
	["TS"]	= 7,
	["FX"]	= 8,
	["LS"]	= 9,
	["other"]	= 10,
	["ZB"]  = 201,
}

EQUIP_LOCATE = 
{
	["EQUIP_LOCATE_WEAPON"] = TEXT("武器"),
	["EQUIP_LOCATE_HAT"] = TEXT("帽子"),
	["EQUIP_LOCATE_CLOTHES"] = TEXT("衣服"),
	["EQUIP_LOCATE_BELT"] = TEXT("腰带"),
	["EQUIP_LOCATE_BRACELET"] = TEXT("项链"),
	["EQUIP_LOCATE_SHOES"] = TEXT("鞋子"),
	["EQUIP_LOCATE_LOCK"] = TEXT("幸运星"),
	["EQUIP_LOCATE_WING"] = TEXT("翅膀"),
}

EQUIP_COLOR_LEV = {
	["EQUIP_COLOR_GREEN"] = 1,
 	["EQUIP_COLOR_BLUE"] = 2,
 	["EQUIP_COLOR_PURPLE"] = 3,
 	["EQUIP_COLOR_ORANGE"] = 4,
}

EQUIP_TYPE = 
{
	["EQUIP_TYPE_JIAN"] = "剑",
	["EQUIP_TYPE_DAO"] = "刀",
	["EQUIP_TYPE_ZHANG"] = "杖",
	["EQUIP_TYPE_ZHUA"] = "爪",
}


PROP_NAME = {
	["hp"]							= TEXT("气血"),
	["mp"]							= TEXT("法力"),

	["tizhi"]						= TEXT("体质"),
	["naili"]						= TEXT("士气"),
	["liliang"]					= TEXT("力量"),
	["lingli"]					= TEXT("灵力"),
	["minjie"]					= TEXT("敏捷"),
	["maxHp"]						= TEXT("气血"),
	["maxMp"]						= TEXT("法力"),
	["attack"]					= TEXT("攻击"),
	["defence"]					= TEXT("防御"),
	["fagong"]					= TEXT("法攻"),
	["fakang"]					= TEXT("法防"),
	["speed"]						= TEXT("速度"),
	["baoShang"]				= TEXT("暴伤"),
	["fashuBaoShang"]		= TEXT("暴伤"),

	["tizhiRate"]				= TEXT("体质"),
	["nailiRate"]				= TEXT("士气"),
	["liliangRate"]			= TEXT("力量"),
	["lingliRate"]			= TEXT("灵力"),
	["minjieRate"]			= TEXT("敏捷"),
	["maxHpRate"]				= TEXT("气血"),
	["maxMpRate"]				= TEXT("法力"),
	["attackRate"]			= TEXT("攻击"),
	["defenceRate"]			= TEXT("防御"),
	["fagongRate"]			= TEXT("法攻"),
	["fafangRate"]			= TEXT("法防"),
	["speedRate"]				= TEXT("速度"),
	["shenyou"]					= TEXT("神佑"),
	["gedang"]					= TEXT("格挡"),
	["baoJi"]						= TEXT("物暴"),
	["baoChengdu"]			= TEXT("物暴程度"),
	["fashuBaoJi"]			= TEXT("法暴"),
	["fashuBaoChengdu"]	= TEXT("法暴程度"),
	["fanZhen"]					= TEXT("反震"),
	["fanZhenChengdu"]	= TEXT("反震程度"),
	["fengYinHit"]			= TEXT("强控"),
	["fengYinDefence"]	= TEXT("免控"),
	["fanJi"]						= TEXT("反击"),
	["lianJi"]					= TEXT("连击"),
}

PROP_FORMAT = {
	["tizhi"]						= {"%d", ""},
	["naili"]						= {"%d", ""},
	["liliang"]					= {"%d", ""},
	["lingli"]					= {"%d", ""},
	["minjie"]					= {"%d", ""},
	["maxHp"]						= {"%d", ""},
	["maxMp"]						= {"%d", ""},
	["attack"]					= {"%d", ""},
	["defence"]					= {"%d", ""},
	["fagong"]					= {"%d", ""},
	["fakang"]					= {"%d", ""},
	["speed"]						= {"%d", ""},
	["baoShang"]				= {"%d", ""},
	["fashuBaoShang"]		= {"%d", ""},

	["tizhiRate"]				= {"%.2f", "%"},
	["nailiRate"]				= {"%.2f", "%"},
	["liliangRate"]			= {"%.2f", "%"},
	["lingliRate"]			= {"%.2f", "%"},
	["minjieRate"]			= {"%.2f", "%"},
	["maxHpRate"]				= {"%.2f", "%"},
	["maxMpRate"]				= {"%.2f", "%"},
	["attackRate"]			= {"%.2f", "%"},
	["defenceRate"]			= {"%.2f", "%"},
	["fagongRate"]			= {"%.2f", "%"},
	["fafangRate"]			= {"%.2f", "%"},
	["speedRate"]				= {"%.2f", "%"},
	["shenyou"]					= {"%.2f", "%"},
	["gedang"]					= {"%.2f", "%"},
	["baoJi"]						= {"%.2f", "%"},
	["baoChengdu"]			= {"%.2f", "%"},
	["fashuBaoJi"]			= {"%.2f", "%"},
	["fashuBaoChengdu"]	= {"%.2f", "%"},
	["fanZhen"]					= {"%.2f", "%"},
	["fanZhenChengdu"]	= {"%.2f", "%"},
	["fengYinHit"]			= {"%.2f", "%"},
	["fengYinDefence"]	= {"%.2f", "%"},
	["fanJi"]						= {"%.2f", "%"},
	["lianJi"]					= {"%.2f", "%"},
}

--[[
  5 #define UI_BAG         1                                                                                                                                                                            
  6 #define UI_SKILL       2                                                                                                                                                                            
  7 #define UI_XINFA       3                                                                                                                                                                            
  8 #define UI_RIDE        4                                                                                                                                                                            
  9 #define UI_TEAM        5                                                                                                                                                                            
 10 #define UI_FABAO       6                                                                                                                                                                            
 11 #define UI_PRODUCE     7                                                                                                                                                                            
 12 #define UI_ORG         8                                                                                                                                                                            
 13 #define UI_FRIEND      9 
--]]

SYSTEM_ENTER_UI = {
	UI_BAG     = 1,   
	UI_SKILL   = 2,   
	UI_XINFA   = 3,   
	UI_RIDE    = 4,   
	UI_TEAM    = 5,   
	UI_FABAO   = 6,
	UI_PRODUCT = 7,   
	UI_FACTION     = 8,   
	UI_FRIEND  = 9,   
}


--客户端使用的对象ID
CLIENT_OBJ_ID_ABSROB_NPC = 1001   	--收NPC时使用的ID
CLIENT_OBJ_ID_STORY_PLAYER = 1002	--剧情中 玩家的ID

--function get_attr_format(key, value)
--	-- print(string.format("%d", 39.5))为40，四舍五入
--	return string.format(PROP_FORMAT[key], PROP_NAME[key], math.floor((value/100)))
--end

function get_attr_format(key, value, concat)
	concat = concat or "+"
	value = tostring(tonumber(string.format(PROP_FORMAT[key][1], (value/100))))
	return PROP_NAME[key]..concat..value..PROP_FORMAT[key][2]
end

setmetatable(PROP_NAME, {__index = function(_, key) return key end})
setmetatable(PROP_FORMAT, {__index = function(_, key) return {"%d", ""} end})
