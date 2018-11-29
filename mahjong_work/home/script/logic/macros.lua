C_INTERVAL_RET = "release"

T_LOGIN_TOUR = 1
T_LOGIN_WX = 2

T_CARD_TONG = 0
T_CARD_SUO = 1
T_CARD_WAN = 2
T_CARD_DONG = 3
T_CARD_NAN = 4
T_CARD_XI = 5
T_CARD_BEI = 6
T_CARD_ZHONG = 7
T_CARD_FA = 8
T_CARD_BAI = 9

T_CARD_HAND = "hand"
T_CARD_SHOW = "show"
T_CARD_SHOW_HIDE = "show_hide"
T_CARD_DISCARD = "discard"
T_CARD_FLOWER = "flower"

T_POOL_HAND = 1
T_POOL_DISCARD = 2
T_POOL_SHOW = 3
T_POOL_FLOWER = 4

T_PIAO_0 = 0
T_PIAO_1 = 1
T_PIAO_2 = 2
T_PIAO_3 = 3

T_DIR_E = 0
T_DIR_S = 1
T_DIR_W = 2
T_DIR_N = 3

C_MENU_MAIN_RL = 1
C_BATTLE_UI_RL = 2
C_MAX_RL = 6

C_MENU_MAIN_Z = -1
C_BATTLE_UI_Z = -2000
C_BATTLE_WIDGET = -2001
C_MAX_Z = -99999

UID_SYSTEM_ID = 0
UID_CLUB_ID = 1
UID_NOROMAL_ID_START = 1000
CLUB_NAME_MAX_LEN = 30
CLUB_DESC_MAX_LEN = 140
MAIL_TEXT_MAX_LEN = 140

-- 进入房间
K_ROOM_UIDS = "uids"
K_ROOM_PLAYER_IDS = "pis"
K_ROOM_OWNER = "owner"
K_ROOM_IS_GAMING = "isGaming"
K_ROOM_STATE = "state"
K_ROOM_MY_PLAYER_ID = "mypi"
K_ROOM_TOTAL_CNT = "tc"			-- 总共几局
K_ROOM_CUR_CNT = "cc"			-- 打了几局
K_ROOM_ONLINE_INFO = "oi"		-- 玩家的在线信息
K_ROOM_ID = "rid"				-- 房间号
K_ROOM_INFO = "ri"				-- 房间信息
K_USER_INFO = "ui"
-- 事件定义
EV_ADD_USER = "au"				-- seatId
--EV_USER_ONLINE = "uo"			-- seatid
--EV_USER_OFFLINE = "eo"			-- seatId
EV_CARD_POOL_UPDATE = "cu"		-- seatId, poolType
EV_DEAL_NEW_CARD = "dnc"		-- seatId, cardId
EV_CHOOSE_COMBS = "cb"			-- combs
EV_CHOOSE_ANGANGS = "ca"		-- angangs
EV_NEXT_TURN = "nt"				-- seatId
EV_GAME_CALC = "gc"				-- message
EV_UPDATE_USER_PROP = "uup"		-- name,avatarUrl
EV_UPDATE_DISSROOM_RESULT = "udr" -- name,image
EV_UPDATE_DISSROOM_NAME = "uda" -- playerId,nickName
EV_REFRESH_DAIKAI = "rd"		-- 代开刷新
EV_UPDATE_VIDEO_USER_PROP = "uvup" -- 录像请求玩家属性
EV_BACK_GROUND = "bg"			-- 切后台清除
EV_AFTER_DRAW = "aftDraw"		-- 完成每帧的渲染
EV_BATTERY_LEVEL_CHANGED = "bc" -- 电池电量改变
EV_BATTERY_STATUS_CHANGED = "bs" -- 电池电量改变
EV_SHARE_TIME_LINE = "stl"      -- 分享朋友圈奖励
EV_PROCESS_MAIL = "pm"			-- 操作邮件
EV_BATTLE_BEGIN = "BB"			-- 战斗开始
EV_BATTLE_END = "BE"			-- 战斗结束
EV_NEW_MAIL = "nm"				-- 新邮件
EV_PROCESS_POST = "pp"			-- 有邮件需要操作（新邮件系统）

EV_PAIJIU_KZ_100 = "EV_PAIJIU_KZ_100"
EV_PAIJIU_KZ_200 = "EV_PAIJIU_KZ_200"
EV_PAIJIU_KZ_500 = "EV_PAIJIU_KZ_500"

EV_DISMISS_GROUP = "ev_dismiss_group"
EV_LEAVE_GROUP = "ev_leave_group"

EV_RECONNECT_DONE = "ev_reconnect_done"

T_SEAT_MINE = 0
T_SEAT_RIGHT = 1
T_SEAT_OPP = 2
T_SEAT_LEFT = 3

C_DISCARD_COUNTDOWN = 15		-- 出牌倒计时
C_DEFAULT_MUSIC_VOLUME = 1.0
C_DEFAULT_SOUND_VOLUME = 1.0

T_DRAG_LIST_VERTICAL = 1
T_DRAG_LIST_HORIZONTAL = 2

T_GENDER_UNKOW = 0
T_GENDER_MALE = 1
T_GENDER_FEMALE = 2

T_PAY_NONE = -1
T_PAY_TEST = 0
T_PAY_APPSTORE = 1
T_PAY_WX_IOS = 2
T_PAY_SDK_IOS = 3
T_PAY_WX_ANDROID = 4
T_PAY_SDK_ANDROID = 5

K_PAY_PID = "pid"
K_PAY_PRICE = "price"
K_PAY_STORE_PRICE = "store_price"
K_PAY_NAME = "name"
K_PAY_NUM = "num"

T_PAY_METHOD_WEIXIN = 0
T_PAY_METHOD_APPSTORE = 1

T_IM_SESSION_P2P = 1
T_IM_SESSION_TEAM = 2

T_IM_MSG_TEXT = 1
T_IM_MSG_AUDIO = 2
T_IM_MSG_SOUND = 3
T_IM_MSG_EJOY = 4

C_IM_MAX_AUDIO_DU = 10 -- sec

C_NET_CONNECT_RETRY_MAX_CNT = 10
C_NET_TIMEOUT_LIMIT = 8000
C_NET_TIMEOUT_MAX_LIMIT = 3600000

T_MAHJONG_ROOM = 1
T_POKER_ROOM = 2

T_TOPIC_GROUP = 0

__init__ = function(module)
	loadglobally(module)
end
