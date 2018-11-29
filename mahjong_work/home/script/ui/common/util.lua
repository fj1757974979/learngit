local modEasing = import("common/easing.lua")
local modJson = import("common/json4lua.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modYouHui = import("data/info/info_youhui.lua")
local modNiuniuProto = import("data/proto/rpc_pb2/pokers/niuniu_pb.lua")
local modPaijiuProto = import("data/proto/rpc_pb2/pokers/paijiu_pb.lua")
local modCardBattleCreate = import("logic/card_battle/create.lua")
local modUtil = import("util/util.lua")

local genInterval = 120
local appearDu = 50
local disappearDu = 50
local imgw, imgh = 98, 98
local lifeRange = {100, 150}
local moveRange = {-500, 500}
local scaleRange = {8, 11}
local sizeRange = {2.5, 4.4, 6}
local circelCntRange = {1, 1}

local T_SEAT_MINE = 0
local T_SEAT_RIGHT = 1
local T_SEAT_OPP = 2
local T_SEAT_LEFT = 3

local T_DIR_E = 0
local T_DIR_S = 1
local T_DIR_W = 2
local T_DIR_N = 3

local idxToImg = {
	[1] = "ui:bg_circle_pink.png",
	[2] = "ui:bg_circle_blue.png",
	[3] = "ui:bg_circle_yellow.png",
}

local youHuiData = modYouHui.data

local dirImages = {
	["bg"] = {
		[T_SEAT_MINE] = "ui:dir/bg_mine.png",
		[T_SEAT_RIGHT] = "ui:dir/bg_right.png",
		[T_SEAT_OPP] = "ui:dir/bg_opp.png",
		[T_SEAT_LEFT] = "ui:dir/bg_left.png",
	},
	["text"] = {
		[T_DIR_E] = {
			[T_SEAT_MINE] = {
				[true] = "ui:dir/e_mine_true.png",
				[false] = "ui:dir/e_mine_false.png",
			},
			[T_SEAT_RIGHT] = {
				[true] = "ui:dir/e_right_true.png",
				[false] = "ui:dir/e_right_false.png",
			},
			[T_SEAT_OPP] = {
				[true] = "ui:dir/e_opp_true.png",
				[false] = "ui:dir/e_opp_false.png",
			},
			[T_SEAT_LEFT] = {
				[true] = "ui:dir/e_left_true.png",
				[false] = "ui:dir/e_left_false.png",
			},
		},
		[T_DIR_S] = {
			[T_SEAT_MINE] = {
				[true] = "ui:dir/s_mine_true.png",
				[false] = "ui:dir/s_mine_false.png",
			},
			[T_SEAT_RIGHT] = {
				[true] = "ui:dir/s_right_true.png",
				[false] = "ui:dir/s_right_false.png",
			},
			[T_SEAT_OPP] = {
				[true] = "ui:dir/s_opp_true.png",
				[false] = "ui:dir/s_opp_false.png",
			},
			[T_SEAT_LEFT] = {
				[true] = "ui:dir/s_left_true.png",
				[false] = "ui:dir/s_left_false.png",
			},
		},
		[T_DIR_W] = {
			[T_SEAT_MINE] = {
				[true] = "ui:dir/w_mine_true.png",
				[false] = "ui:dir/w_mine_false.png",
			},
			[T_SEAT_RIGHT] = {
				[true] = "ui:dir/w_right_true.png",
				[false] = "ui:dir/w_right_false.png",
			},
			[T_SEAT_OPP] = {
				[true] = "ui:dir/w_opp_true.png",
				[false] = "ui:dir/w_opp_false.png",
			},
			[T_SEAT_LEFT] = {
				[true] = "ui:dir/w_left_true.png",
				[false] = "ui:dir/w_left_false.png",
			},
		},
		[T_DIR_N] = {
			[T_SEAT_MINE] = {
				[true] = "ui:dir/n_mine_true.png",
				[false] = "ui:dir/n_mine_false.png",
			},
			[T_SEAT_RIGHT] = {
				[true] = "ui:dir/n_right_true.png",
				[false] = "ui:dir/n_right_false.png",
			},
			[T_SEAT_OPP] = {
				[true] = "ui:dir/n_opp_true.png",
				[false] = "ui:dir/n_opp_false.png",
			},
			[T_SEAT_LEFT] = {
				[true] = "ui:dir/n_left_true.png",
				[false] = "ui:dir/n_left_false.png",
			},
		},
	},
}

local downloadLinkes = {
	["test"] = { ["title"] = "开新棋牌", ["link"] =  "http://www.openew.cn/games/mj/index.html"},
	["openew"] = { ["title"] = "开新棋牌", ["link"] =  "http://www.openew.cn/games/mj/index.html"},
	["tj_lexian"] = { ["title"] = "乐闲桃江将", ["link"] = "http://www.openew.cn/games/tjmj/index.html"},
	["ds_queyue"] = { ["title"] = "雀悦东山麻将", ["link"] = "http://www.openew.cn/games/dsmj/index.html"},
	["za_queyue"] = { ["title"] = "雀跃诏安", ["link"] = "http://www.openew.cn/games/zaqueyue/index.html"},
	["ly_youwen"] = { ["title"] = "长沙友文麻将", ["link"] =  "http://www.openew.cn/games/ywmj/index.html"},
	["jz_laiba"] = { ["title"] = "来8蓟州麻将" , ["link"] = "http://www.openew.cn/games/jzlaiba/index.html"},
	["yy_doudou"] = { ["title"] = "云阳豆豆麻将", ["link"] = "http://www.openew.cn/games/yydoudou/index.html"},
	["xy_hanshui"] = { ["title"] = "汉江王卡五星", ["link"] = "http://www.openew.cn/games/xyhanshui/index.html" },
	["rc_xianle"] = { ["title"] = "荣成麻将", ["link"] = "http://www.openew.cn/games/rcxianle/index.html" },
	["nc_tianjiuwang"] = { ["title"] = "天九王", ["link"] = "http://www.openew.cn/games/nctianjiuwang/index.html" },
	["qs_pinghe"] = { ["title"] = "雀神平和麻将", ["link"] = "http://www.openew.com/games/qsph/index.html" },
}

local combToUI = {
	[-1] = TEXT("ui:battle/guo.png"),
	[modGameProto.ANGANG] = TEXT("ui:battle/gang.png"),
	[modGameProto.XIAOMINGGANG] = TEXT("ui:battle/gang.png"),
	[modGameProto.MINGSHUN] = TEXT("ui:battle/chi.png"),
	[modGameProto.MINGKE] = TEXT("ui:battle/peng.png"),
	[modGameProto.DAMINGGANG] = TEXT("ui:battle/gang.png"),
	[modGameProto.HU] = TEXT("ui:battle/hu.png"),
	[modGameProto.TING] = TEXT("ui:battle/ting.png"),
	[modGameProto.MING] = TEXT("ui:battle_kou.png"),
	["shuai"] = TEXT("ui:battle/shuai.png"),
	["zimo"] = TEXT("ui:battle/zimo.png"),
}

local crr = modLobbyProto.CreateRoomRequest
local ga = modGameProto.AskCheckGameOverRequest.PlayerStatistic
local FAN = {
		[crr.ZHUANZHUAN] = {},
		[crr.HONGZHONG] = {},
		[crr.DAODAO] = {},
		[crr.TAOJIANG] = {
			[ga.TAOJIANG_PINGHU] = "平胡",
			[ga.TAOJIANG_PENGPENGHU] = "碰碰胡",
			[ga.TAOJIANG_QINGYISE] = "清一色",
			[ga.TAOJIANG_QIXIAODUI] = "七小对",
			[ga.TAOJIANG_JIANGJIANGHU] = "将将胡",
			[ga.TAOJIANG_TIANHU] = "天胡",
			[ga.TAOJIANG_TIANTIANHU] = "天天胡",
			[ga.TAOJIANG_DIHU] = "地胡",
			[ga.TAOJIANG_DIDIHU] = "地地胡",
			[ga.TAOJIANG_ZHUANGJIADAODIHU] = "庄家倒地胡",
			[ga.TAOJIANG_HEITIANHU] = "黑天胡",
			[ga.TAOJIANG_YINGZHUANG] = "硬庄",
			[ga.TAOJIANG_GANGSHANGKAIHUA] = "杠上开花",
			[ga.TAOJIANG_GANGSHANGPAO] = "杠上炮",
			[ga.TAOJIANG_QIANGGANGHU] = "抢杠胡",
			[ga.TAOJIANG_QISHOUTIN] = "起手听"

		},
		[crr.DONGSHAN] = {
			[ga.DONGSHAN_SIXIPAI] = "四喜牌",
			[ga.DONGSHAN_BAXIANGUOHAI] = "八仙过海",
			[ga.DONGSHAN_SHISANYAO] = "十三幺",
			[ga.DONGSHAN_WUHUAZI] = "无花字",
			[ga.DONGSHAN_BUJIANTIAN] = "不见天",
			[ga.DONGSHAN_GANGSHANGKAIHUA] = "杠上开花",
			[ga.DONGSHAN_HUNYISE] = "混一色",
			[ga.DONGSHAN_QINGYISE] = "清一色",
			[ga.DONGSHAN_DUIDUIHU] = "对对胡",
			[ga.DONGSHAN_QUANQIUREN] = "全求人",
			[ga.DONGSHAN_QIANGGANGHU] = "抢杠胡",
			[ga.DONGSHAN_HAIDILAO] = "海底捞",
			[ga.DONGSHAN_WUZHANGNEI] = "五张内",
			[ga.DONGSHAN_BENJIATAI] = "本家台",
			[ga.DONGSHAN_TONGYONGTAI3A] = "通用台",
			[ga.DONGSHAN_TONGYONGTAI4A] = "通用台",
			[ga.DONGSHAN_TONGYONGTAI3B] = "通用台",
			[ga.DONGSHAN_TONGYONGTAI4B] = "通用台",
			[ga.DONGSHAN_HUAPAIBENJIATAI1A] = "花牌本家台",
			[ga.DONGSHAN_HUAPAIBENJIATAI4A] = "花牌本家台",
			[ga.DONGSHAN_HUAPAIBENJIATAI1B] = "花牌本家台",
			[ga.DONGSHAN_HUAPAIBENJIATAI4B] = "花牌本家台",
			[ga.DONGSHAN_HUAPAITONGYONGTAI3] = "花牌通用台",
			[ga.DONGSHAN_HUAPAITONGYONGTAI4] = "花牌通用台",
			[ga.DONGSHAN_HUNYAOJIU] = "混幺九",
			[ga.DONGSHAN_BAXIAODUI] = "八小对",
		},
		[crr.ZHAOAN]= {
			[ga.ZHAOAN_MENQIANQING] = "门前清",
			[ga.ZHAOAN_GANGSHANGKAIHUA] = "杠上开花",
			[ga.ZHAOAN_GANGSHANGGANGKAIHUA] = "杠上杠开花",
			[ga.ZHAOAN_QIANGGANGHU] = "抢杠胡",
			[ga.ZHAOAN_HUNYISE] = "混一色",
			[ga.ZHAOAN_DASANYUAN] = "大三元",
			[ga.ZHAOAN_XIAOSANYUAN] = "小三元",
			[ga.ZHAOAN_DASIXI] = "大四喜",
			[ga.ZHAOAN_XIAOSIXI] = "小四喜",
			[ga.ZHAOAN_DUIDUIHU] = "对对胡",
			[ga.ZHAOAN_HUNYAOJIU] = "混幺九",
			[ga.ZHAOAN_QUANQIUREN] = "全球人",
			[ga.ZHAOAN_TIANHU] = "天胡",
			[ga.ZHAOAN_QISHOUTIN] = "起手听",
			[ga.ZHAOAN_HAIDILAOYUE] = "海底捞月",
			[ga.ZHAOAN_QINGYISE] = "清一色",
			[ga.ZHAOAN_PINGHU] = "平胡",
			[ga.ZHAOAN_SANANKE] = "三暗刻",
			[ga.ZHAOAN_SIANKE] = "四暗刻",
			[ga.ZHAOAN_WUANKE] = " 五暗刻",
		},
		[crr.MAOMING] = {
			[ga.MAOMING_DUIDUIPENG] = "对对碰",
			[ga.MAOMING_QIDUI] = "七对",
			[ga.MAOMING_HUANGJIN] = "黄金",
			[ga.MAOMING_HUANGSHANGHUANG] = "皇上皇",
			[ga.MAOMING_QINGYISE] = "清一色",
			[ga.MAOMING_QINGYAOJIU] = "清幺九",
			[ga.MAOMING_HUNYISE] = "混一色",
			[ga.MAOMING_HUNYAOJIU] = "混幺九",
			[ga.MAOMING_ZIYISE] = "字一色",
			[ga.MAOMING_XIAOSANYUAN] = "小三元",
			[ga.MAOMING_DASANYUAN] = "大三元",
			[ga.MAOMING_XIAOSIXI] = "小四喜",
			[ga.MAOMING_DASIXI] = "大四喜",
			[ga.MAOMING_SHISANYAO] = "十三幺",
			[ga.MAOMING_JIULIANBAODENG] = "九莲宝灯",
			[ga.MAOMING_TIANHU] = "天胡",
			[ga.MAOMING_DIHU] = "地胡",
			[ga.MAOMING_SIDAJINGANG] = "四大金刚",

			[ga.MAOMING_WUGUI] = "无鬼",
			[ga.MAOMING_QIANGGANG] = "抢杠",
			[ga.MAOMING_GANGSHANGKAIHUA] = "杠上开花",

			[ga.MAOMING_FENZHUROU] = "分猪肉",
			[ga.MAOMING_GANGBAOCHENGBAO] = "杠爆承包",
			[ga.MAOMING_SHIERZHANGLUODICHENGBAO] = "十二张落地承包",
			[ga.MAOMING_QIANGGANGCHENGBAO] = "抢杠承包",
		},
		[crr.TIANJIN] = {
			[ga.TIANJIN_CHAN] = "铲",
			[ga.TIANJIN_TIANHU] = "天胡",
			[ga.TIANJIN_QIDUI] = "七对",
			[ga.TIANJIN_HAOHUAQIDUI] = "豪华七对",
			[ga.TIANJIN_SHUANGHAOHUAQIDUI] = "双豪华七对",
			[ga.TIANJIN_SANHAOHUAQIDUI] = "三豪华七对",
			[ga.TIANJIN_GANGKAI] = "杠开",
			[ga.TIANJIN_SUDILIU] = "素提溜",
			[ga.TIANJIN_DANHUNDIAO] = "单混吊",
			[ga.TIANJIN_SHUANGHUNDIAO] = "双混吊",
			[ga.TIANJIN_ZHUOWU] = "捉五",
			[ga.TIANJIN_LONG] = "龙",
			[ga.TIANJIN_BENHUNLONG] = "本混龙",
			[ga.TIANJIN_JINGANG] = "金杠",
		},
		[crr.YUNYANG] = {
			[ga.YUNYANG_PINGHU] = "平胡",
			[ga.YUNYANG_DUIDUIHU] = "对对胡",
			[ga.YUNYANG_QIDUI] = "七对",
			[ga.YUNYANG_LONGQIDUI] = "龙七对",
			[ga.YUNYANG_SHUANGLONGQIDUI] = "双龙七对",
			[ga.YUNYANG_SANLONGQIDUI] = "三龙七对",
			[ga.YUNYANG_QINGYISE] = "清一色",
			[ga.YUNYANG_ZHUANGSANDA] = "撞三哒",
			[ga.YUNYANG_JINGOUDIAO] = "金钩钓",
			[ga.YUNYANG_QIANSI] = "前四",
			[ga.YUNYANG_HOUSI] = " 后四",
			[ga.YUNYANG_GANGSHANGKAIHUA] = " 杠上开花",
			[ga.YUNYANG_QIANGGANG] = " 抢杠",
			[ga.YUNYANG_GANGSHANGPAO] = " 杠上炮",
		},
		[crr.XIANGYANG] = {
			[ga.XIANGYANG_PINGHU] = "平胡",
			[ga.XIANGYANG_PENGPENGHU] = "碰碰胡",
			[ga.XIANGYANG_QIXIAODUI] = "七小对",
			[ga.XIANGYANG_HAOHUAQIXIAODUI] = "豪华七小对",
			[ga.XIANGYANG_CHAOHAOHUAQIXIAODUI] = "超豪华七小对",
			[ga.XIANGYANG_CHAOCHAOHAOHUAQIXIAODUI] = "超超豪华七小对",
			[ga.XIANGYANG_QINGYISE] = "清一色",
			[ga.XIANGYANG_SHOUZHUAYI] = "手抓一",
			[ga.XIANGYANG_XIAOSANYUAN] ="小三元",
			[ga.XIANGYANG_DASANYUAN] = "大三元",
			[ga.XIANGYANG_MINGSIGUI] = "明四归",
			[ga.XIANGYANG_ANSIGUI] = "暗四归",
			[ga.XIANGYANG_KAWUXING] = "卡五星",
			[ga.XIANGYANG_HAIDILAO] = "海底捞",
			[ga.XIANGYANG_HAIDIPAO] = "海底炮",
			[ga.XIANGYANG_GANGSHANGKAIHUA] = "杠上开花",
			[ga.XIANGYANG_GANGSHANGPAO] = "杠上炮",
			[ga.XIANGYANG_QIANGGANG] = "抢杠",
			[ga.XIANGYANG_LIANGDAO] = "亮倒",
		},
		[crr.RONGCHENG] = {
			[ga.RONGCHENG_JIHU] = "平胡",
			[ga.RONGCHENG_PENGPENGHU] = "碰碰胡",
			[ga.RONGCHENG_QIXIAODUI] = "七小对",
			[ga.RONGCHENG_QIDADUI] = "七大对",
			[ga.RONGCHENG_SHISANYAO] = "十三幺",
			[ga.RONGCHENG_QINGYISE] = "清一色",
			[ga.RONGCHENG_FENGYISE] = "风一色",
			[ga.RONGCHENG_ZHANGYISE] = "掌一色",
			[ga.RONGCHENG_MOBAO] = "摸宝",
			[ga.RONGCHENG_BAOZHONGBAO] = "宝中宝",
			[ga.RONGCHENG_HAIDILAO] = "海底捞",
			[ga.RONGCHENG_MINGLOU] = "放倒",
			[ga.RONGCHENG_GANGSHANGHUA] = "杠上花",
			[ga.RONGCHENG_TIANHU] = "天胡",
			[ga.RONGCHENG_DIHU] = "地胡",
			[ga.RONGCHENG_QIANGGANGHU] = "抢杠胡",
		},
		[crr.CHENGDU] = {
			[ga.CHENGDU_PINGHU] = "平胡",
			[ga.CHENGDU_QIDUI] = "七对",
			[ga.CHENGDU_LONGQIDUI] = "龙七对",
			[ga.CHENGDU_SHUANGLONGQIDUI] = "双龙七对",
			[ga.CHENGDU_SANLONGQIDUI] = "三龙七对",
			[ga.CHENGDU_YIGEN] = "一根",
			[ga.CHENGDU_LIANGGEN] = "两根",
			[ga.CHENGDU_SANGEN] = "三根",
			[ga.CHENGDU_JINGOUDIAO] = "金钩钓",
			[ga.CHENGDU_QINGYISE] = "清一色",
			[ga.CHENGDU_MENQING] = "门清",
			[ga.CHENGDU_YITIAOLONG] = "一条龙",
			[ga.CHENGDU_QUANDAIYAO] = "全带幺",
			[ga.CHENGDU_JIANGDUI] = "将对",
			[ga.CHENGDU_TIANHU] = "天胡",
			[ga.CHENGDU_DIHU] = "地胡",
			[ga.CHENGDU_GANGSHANGHUA] = "杠上花",
			[ga.CHENGDU_HAIDILAO] = "海底捞",
			[ga.CHENGDU_QIANGGANGHU] = "抢杠胡",
			[ga.CHENGDU_GANGSHANGPAO] = "杠上炮",
			[ga.CHENGDU_HAIDIPAO] = "海底炮",
			[ga.CHENGDU_DUIDUIHU] = "对对胡",
			[ga.CHENGDU_SIGEN] = "四根",
		},
		[crr.XIANGYANG_BAIHE] = {
			[ga.XIANGYANG_PINGHU] = "平胡",
			[ga.XIANGYANG_PENGPENGHU] = "碰碰胡",
			[ga.XIANGYANG_QIXIAODUI] = "七小对",
			[ga.XIANGYANG_HAOHUAQIXIAODUI] = "豪华七小对",
			[ga.XIANGYANG_CHAOHAOHUAQIXIAODUI] = "超豪华七小对",
			[ga.XIANGYANG_CHAOCHAOHAOHUAQIXIAODUI] = "超超豪华七小对",
			[ga.XIANGYANG_QINGYISE] = "清一色",
			[ga.XIANGYANG_SHOUZHUAYI] = "手抓一",
			[ga.XIANGYANG_XIAOSANYUAN] ="小三元",
			[ga.XIANGYANG_DASANYUAN] = "大三元",
			[ga.XIANGYANG_MINGSIGUI] = "明四归",
			[ga.XIANGYANG_ANSIGUI] = "暗四归",
			[ga.XIANGYANG_KAWUXING] = "卡五星",
			[ga.XIANGYANG_HAIDILAO] = "海底捞",
			[ga.XIANGYANG_HAIDIPAO] = "海底炮",
			[ga.XIANGYANG_GANGSHANGKAIHUA] = "杠上开花",
			[ga.XIANGYANG_GANGSHANGPAO] = "杠上炮",
			[ga.XIANGYANG_QIANGGANG] = "抢杠",
			[ga.XIANGYANG_LIANGDAO] = "亮倒",
		},
		[crr.JINING] = {
			[ga.JINING_PINGHU] = "平胡",
			[ga.JINING_DUIDUIHU] = "对对胡",
			[ga.JINING_QIDUI] = "七对",
			[ga.JINING_QIDADUI] = "七大对",
			[ga.JINING_HAOHUAQIDADUI] = "豪华七大对",
			[ga.JINING_SHISANBUKAO] = "十三不靠",
			[ga.JINING_QINGYISE] = "清一色",
			[ga.JINING_YITIAOLONG] = "一条龙",
			[ga.JINING_TIANHU] = "天胡",
			[ga.JINING_DIHU] = "地胡",
			[ga.JINING_GANGSHANGKAIHUA] = "杠上开花",
			[ga.JINING_QIANGGANGHU] = "抢杠胡",
			[ga.JINING_GENZHUANG] = "跟庄",
			[ga.JINING_SANKOUBAOHU] = "三口包胡",
		},
		[crr.PINGHE] = {
			[ga.PINGHE_ZIMO]  = "自摸";
            [ga.PINGHE_SIJINDAO] = "四金倒";
            [ga.PINGHE_SANJINDAO] = "三金倒";
            [ga.PINGHE_BADUI] =  "八对";
            [ga.PINGHE_QINGYISE] = "清一色";
            [ga.PINGHE_DANDIAO] = "单调";
            [ga.PINGHE_YOUJIN] = "游金";
            [ga.PINGHE_SHUANGYOU] = "双游";
            [ga.PINGHE_SIYOU] = "四游";
            [ga.PINGHE_BAYOU] = "八游";
            [ga.PINGHE_SHILIUYOU] = "十六游";
            [ga.PINGHE_SANSHIERYOU] = "三十二游";
            [ga.PINGHE_DIANPAO] = "点炮";
		},
	}
local publicShow = {
	["room_type"] = {
		[crr.NORMAL] = "普通房间",
		[crr.SHARED] = "代开房间",
		[crr.AA] = "AA房间",
		[crr.MATCH] = "匹配房间",
		[crr.CLUB_SHARED] = "俱乐部房间",
	},
	["rule_type"] = {
		[crr.ZHUANZHUAN] = "转转麻将",
		[crr.HONGZHONG] = "红中麻将",
		[crr.TAOJIANG] = "桃江麻将",
		[crr.DONGSHAN] = "东山麻将",
		[crr.ZHAOAN] = "雀跃诏安",
		[crr.MAOMING] = "茂名麻将",
		[crr.TIANJIN] = "蓟州麻将",
		[crr.YUNYANG] = "云阳换三张",
		[crr.DAODAO] = "倒倒胡",
		[crr.XIANGYANG] = "襄阳玩法",
		[crr.RONGCHENG] = "荣成麻将",
		[crr.CHENGDU] = "血战到底",
		[crr.XIANGYANG_BAIHE] = "白河玩法",
		[crr.JINING] = "济宁麻将",
		[crr.PINGHE] = "平和麻将",
	},
	["max_number_of_users"] = {
		[1] = "1人",
		[2] = "2人",
		[3] = "3人",
		[4] = "4人",
	},
	["number_of_game_times"] = {
		[1] = "1",
		[2] = "2",
		[3] = "3",
		[4] = "4",
		[5] = "5",
		[6] = "6",
		[7] = "7",
		[8] = "8",
		[9] = "9",
		[10] = "10",
		[11] = "11",
		[12] = "12",
		[16] = "16"
	}
}

local pokerPublicShow = {
	["room_type"] = {
		[crr.NORMAL] = "普通房间",
		[crr.SHARED] = "代开房间",
		[crr.AA] = "AA房间",
		[crr.MATCH] = "匹配房间",
		[crr.CLUB_SHARED] = "俱乐部房间",
	},
	["poker_type"] = {
		[modLobbyProto.NIUNIU] = "牛牛",
		[modLobbyProto.PAIJIU] = "牌九"
	},
	["max_number_of_users"] = {
		[1] = "1人",
		[2] = "2人",
		[3] = "3人",
		[4] = "4人",
		[5] = "5人"
	},
	["number_of_game_times"] = {
		[10] = "10",
		[20] = "20"
	}
}

local np = modNiuniuProto.NiuniuCreateParam
local pp = modPaijiuProto.PaijiuCreateParam
local pokerRuleShow = {
	[modLobbyProto.NIUNIU] = {
		["game_mode"] = {
			[np.GAME_CLASSIC] = "经典算分",
			[np.GAME_INSANE] = "加倍算分"
		},
		["banker_mode"] = {
			[np.BANKER_STRIVE] = "抢庄",
			[np.BANKER_IN_TURN] = "轮庄",
			[np.BANKER_FIXED] = "固定庄",
		},
		["bet_mode"] = {
			[np.BET_FIXED] = "固定倍率",
			[np.BET_CHOOSE] = "可选倍率",
		}
	},
	[modLobbyProto.PAIJIU] = {
		["game_mode"] = {
			[pp.GAME_KZWF] = "开庄玩法",
			[pp.GAME_MPQZ] = "明牌抢庄",
		},
		["double_type"] = {
			[pp.DOUBLE_NONE] = "无翻",
			[pp.DOUBLE_NORMAL] = "标翻",
			[pp.DOUBLE_CRAZY] = "豪翻",
		},
	}
}

local ruleShow = {
	 [crr.ZHUANZHUAN] = {
		["allow_magic_cards"] = { [true] = "红中癞子"},
		["allow_zhuangxian"] = { [true] = "庄闲"},
		["allow_chi"] = { [true] = "可吃"},
		["allow_dianpao"] = { [true] = "点炮胡", [false] = "自摸胡"},
		["allow_qianggang"] = {[true] = "抢杠胡"},
		["zhuaniao_count"] = {
			[2] = "抓2鸟",
			[4] = "抓4鸟",
			[6] = "抓6鸟"
		},
	},
	[modLobbyProto.CreateRoomRequest.HONGZHONG] = {
		["zhongniao_rule"] = {
			[crr.ZHONGNIAO_159] = "159鸟",
			[crr.HONGZHONG_ZHONGNIAO_JIN] = "金鸟",
			[crr.HONGZHONG_ZHONGNIAO_FEI] = "飞鸟",
		},
		["allow_zhuangxian"] = { [true] = "庄闲"},
		["allow_dianpao"] = { [true] = "点炮胡", [false] = "自摸胡"},
		["allow_qianggang"] = {[true] = "抢杠胡"},
		["allow_piao"] = {[true] = "飘分"},
		["zhuaniao_count"] = {
			[1] = "抓1鸟",
			[2] = "抓2鸟",
			[4] = "抓4鸟",
			[6] = "抓6鸟"
		},
	},
	[modLobbyProto.CreateRoomRequest.TAOJIANG] = {
		["zhongniao_rule"] = {[crr.ZHONGNIAO_159] = "159鸟"},
		["allow_chi"] = {[true] = "可吃"},
		["allow_qianggang"] = {[true] = "抢杠胡"},
		["allow_dianpao"] = { [true] = "点炮胡", [false] = "自摸胡"},
		["zhuaniao_count"] = {
			[1] = "抓1鸟",
			[2] = "抓2鸟",
		},
		["allow_piao"] = {[true] = "搭马"},
		["dibei"] = {
			[2] = "2倍分",
			[3] = "3倍分",
			[4] = "4倍分",
			[5] = "5倍分",
			[10] = "10倍分",
			[20] = "20倍分",
			[30] = "30倍分",
			[40] = "40倍分",
			[50] = "50倍分",
			[60] = "60倍分",
			[70] = "70倍分",
			[80] = "80倍分",
			[90] = "90倍分",
			[100] = "100倍分",
		},
	},
	[modLobbyProto.CreateRoomRequest.DONGSHAN] = {
		["allow_dui_hu"] = { [true] = "八小对" },
		["allow_dianpao"] = { [true] = "点炮胡", [false] = "自摸胡"},
		["fgsjkf"] = {
			[true] = "放杠三家扣分",
			[false] = "放杠一家扣分",
		},
		["dibei"] = {
			[2] = "2倍分",
			[3] = "3倍分",
			[4] = "4倍分",
			[5] = "5倍分",
			[10] = "10倍分",
			[20] = "20倍分",
			[30] = "30倍分",
			[40] = "40倍分",
			[50] = "50倍分",
			[60] = "60倍分",
			[70] = "70倍分",
			[80] = "80倍分",
			[90] = "90倍分",
			[100] = "100倍分",
		},
	},
	[modLobbyProto.CreateRoomRequest.ZHAOAN] = {
		["allow_yipaoduoxiang"] = { [true] = "一炮三响" },
		["allow_dianpao"] = { [true] = "点炮胡", [false] = "自摸胡"},
		["allow_piao"] = { [true] = "插台" },
	},
	[modLobbyProto.CreateRoomRequest.MAOMING] = {
		["zhuaniao_count"] = {
			[1] = "买1马",
			[4] = "买4马",
			[8] = "买8马",
			[12] = "买12马",
		},
		["allow_chi"] = { [true] = "可吃"},
		["allow_dui_hu"] = { [true] = "七小对" },
		["allow_word_cards"] = { [true] = "风头牌"},
		["allow_qiangangang"] = { [true] = "可抢暗杠"},
		["allow_sidajingang"] = { [true] = "四大金刚" },
		["gangbao_chengbao"] = { [true] = "杠爆承包"},
		["shierzhangluodi_chengbao"] = { [true] = "十二张落地承包" },
		["qianggang_chengbao"] = { [true] = "抢杠承包"},
		["fenzhurou"] = { [true] = "分猪肉" },
		["wugui_x2"] = { [true] = "无鬼x2"},
		["qianggang_x2"] = { [true] = "抢杠胡x2" },
		["gangshangkaihua_x2"] = { [true] = "杠上开花x2" },
		["allow_qianggang"] = {[true] = "抢杠胡"},
	},
	[modLobbyProto.CreateRoomRequest.PINGHE] = {
		["sijinban"] = { [true] = "四金版", [false] = "三金版"},
		["sanjindao_or_sijindao"] = { [true] = "三金倒/四金倒" },
		["shuangyou_can_hu"] = {[true] = "双游以上可以胡"}	,
		["dibei"] = {
			[1] = "1倍分",
			[2] = "2倍分",
			[3] = "3倍分",
			[4] = "4倍分",
			[5] = "5倍分",
			[10] = "10倍分",
			[20] = "20倍分",
			[30] = "30倍分",
			[40] = "40倍分",
			[50] = "50倍分",
			[60] = "60倍分",
			[70] = "70倍分",
			[80] = "80倍分",
			[90] = "90倍分",
			[100] = "100倍分",
		},
	},
	[crr.TIANJIN] = {
		["allow_jingang"] = { [true] = "带金杠" },
		["allow_chuai"] = { [true] = "可踹" },
		["allow_la"] = { [true] = "可拉" },
		["allow_chan"] = { [true] = "带铲" },
		["conceal_discarded_cards"] = { [true] = "扣牌模式" },
		["allow_dui_hu"] = { [true] = "七对" },
		["dibei"] = {
			[2] = "2倍分",
			[3] = "3倍分",
			[4] = "4倍分",
			[5] = "5倍分",
			[10] = "10倍分",
			[20] = "20倍分",
			[30] = "30倍分",
			[40] = "40倍分",
			[50] = "50倍分",
			[60] = "60倍分",
			[70] = "70倍分",
			[80] = "80倍分",
			[90] = "90倍分",
			[100] = "100倍分",
		},
	},
	[crr.YUNYANG] = {
		["dingque"] = { [true] = "定缺" },
		["allow_qiansi"] = { [true] = "前四后四" },
		["allow_zhuangsanda"] = { [true] = "撞三哒" },
		["allow_jingoudiao"] = { [true] = "金钩钓" },
		["max_fan_count"] = {
			[3] = "3番封顶",
			[4] = "4番封顶",
			[5] = "5番封顶",
		},
		["huazhu_score"] = {
			[5] = "花猪x5",
			[10] = "花猪x10"
		}
	},
	[crr.DAODAO] = {
		["allow_dianpao"] = { [true] = "点炮胡", [false] = "自摸胡"},
		["xy_scores"] = {
			[11] = "1拖1",
			[12] = "1拖2",
			[23] = "2拖3",
			[35] = "3拖5",
		},
	},
	[crr.XIANGYANG] = {
		["banpindao"] = { [true] = "半频道", [false] = "全频道"},
		["liangdaomaima"] = { [true] = "亮倒买马", [false] = "自摸买马"},
		["max_fan_count"] = { [8] = "8番封顶" },
		["zhuaniao_count"] = {
			[1] = "买1马",
			[6] = "买6马",
		},
	},
	[crr.RONGCHENG] = {
		["erwubazhang"] = { [true] = "二五八掌" },
		["qiluo"] = { [true] = "七摞" },
		["allow_minglou"] = { [true] = "放倒" },
		["allow_shuaiquan"] = { [true] = "甩圈" },
		["allow_word_cards"] = { [true] = "带风牌" },
		["allow_chi"] = { [true] = "可吃" },
		["allow_piao"] = { [true] = "飘分" },
		["allow_yipaoduoxiang"] = { [true] = "一炮多响" },
	},
	[crr.CHENGDU] = {
		["huansanzhang"] = { [true] = "换三张" },
		["dingque"] = { [true] = "定缺" },
--		["dianganghua"] = { [true] = "点杠花(点炮)" },
		["hujiaozhuanyi"] = { [true] = "呼叫转移" },
		["zimojiadi"] = { [true] = "自摸加底" },
		["zimojiafan"] = { [true] = "自摸加番" },
--		["allow_tiandihu"] = { [true] = "天地胡" },
--		["allow_yaojiujiangdui"] = { [true] = "幺九将对" },
--		["allow_yitiaolong"] = { [true] = "一条龙" },
--		["allow_menqing"] = { [true] = "门清中张" },
		["max_fan_count"] = {
			[2] = "2番封顶",
			[3] = "3番封顶",
			[4] = "4番封顶",
			[5] = "5番封顶",
		},
		["min_fan_count"] = {
			[2] = "2番起胡",
			[3] = "3番起胡",
		},
	},
	[crr.XIANGYANG_BAIHE] = {
		["banpindao"] = { [true] = "半频道", [false] = "全频道"},
		["liangdaomaima"] = { [true] = "亮倒买马", [false] = "自摸买马"},
		["max_fan_count"] = { [8] = "8番封顶" },
		["zhuaniao_count"] = {
			[1] = "买1马",
			[6] = "买6马",
		},
	},
	[crr.JINING] = {
		["genzhuang"] = { [true] = "跟庄" },
		["sankoubaohu"] = { [true] = "三口包胡" },
	},
}


local flagValues = {
	[modLobbyProto.CreateRoomRequest.TAOJIANG] = {
		[modGameProto.PIAO_A] = 0,
		[modGameProto.PIAO_B] = 1,
		[modGameProto.PIAO_C] = 2,
		[modGameProto.PIAO_D] = 3,
		[modGameProto.PIAO_E] = 4,
		[modGameProto.TING] = true,
		[modGameProto.GAME_OVER_CHECKED] = true,
	},
	[modLobbyProto.CreateRoomRequest.HONGZHONG] = {
		[modGameProto.PIAO_A] = 0,
		[modGameProto.PIAO_B] = 1,
		[modGameProto.PIAO_C] = 2,
		[modGameProto.PIAO_D] = 3,
		[modGameProto.PIAO_E] = 4,
		[modGameProto.TING] = true,
	},
	[modLobbyProto.CreateRoomRequest.ZHAOAN] = {
		[modGameProto.PIAO_A] = 0,
		[modGameProto.PIAO_B] = 1,
		[modGameProto.PIAO_C] = 2,
		[modGameProto.PIAO_D] = 3,
		[modGameProto.PIAO_E] = 4,
		[modGameProto.TING] = true,
	},
	[modLobbyProto.CreateRoomRequest.TIANJIN] = {
		[modGameProto.PIAO_A] = 0,
		[modGameProto.PIAO_B] = 1,
		[modGameProto.PIAO_C] = 2,
		[modGameProto.PIAO_D] = 3,
		[modGameProto.PIAO_E] = 4,
		[modGameProto.TING] = true,
	},
	[modLobbyProto.CreateRoomRequest.YUNYANG] = {
		[modGameProto.YUNYANG_QUE_TONG] = 0,
		[modGameProto.YUNYANG_QUE_SUO] = 1,
		[modGameProto.TING] = true,
		[modGameProto.YUNYANG_QUE_WAN] = 2,
	},
	[modLobbyProto.CreateRoomRequest.XIANGYANG] = {
		[modGameProto.TING] = true,
	},
	[modLobbyProto.CreateRoomRequest.PINGHE] = {
	[modGameProto.PINGHE_YOUJIN] = 0,
	[modGameProto.PINGHE_SHUANGYOU] = 1,
	[modGameProto.PINGHE_SIYOU] = 2,
	[modGameProto.PINGHE_BAYOU] = 3,
	[modGameProto.PINGHE_HU] = 4,
	[modGameProto.PINGHE_ROBANGANG] = 5,
	},
	--[[
	[modLobbyProto.CreateRoomRequest.XIANGYANG_BAIHE] = {
		[modGameProto.TING] = true,
	},
	]]--
	[modLobbyProto.CreateRoomRequest.RONGCHENG] = {
		[modGameProto.PIAO_A] = 0,
		[modGameProto.PIAO_B] = 1,
		[modGameProto.PIAO_C] = 2,
		[modGameProto.PIAO_D] = 3,
		[modGameProto.PIAO_E] = 4,
		[modGameProto.TING] = true,
	},
	[modLobbyProto.CreateRoomRequest.CHENGDU] = {
		[modGameProto.YUNYANG_QUE_TONG] = 0,
		[modGameProto.YUNYANG_QUE_SUO] = 1,
		[modGameProto.TING] = true,
		[modGameProto.YUNYANG_QUE_WAN] = 2,
	},
}

local piaoImage = {
	[modLobbyProto.CreateRoomRequest.TAOJIANG] = {
		[modGameProto.PIAO_A] = "ui:battle/dama_selected_0.png",
		[modGameProto.PIAO_B] = "ui:battle/dama_selected_1.png",
		[modGameProto.PIAO_C] = "ui:battle/dama_selected_2.png",
		[modGameProto.PIAO_D] = "ui:battle/dama_selected_3.png",
		[modGameProto.PIAO_E] = "ui:battle/dama_selected_4.png",
		[-1] = "ui:battle/dama_selected.png",
	},
	[modLobbyProto.CreateRoomRequest.HONGZHONG] = {
		[modGameProto.PIAO_A] = "ui:battle/piaofen_selected_0.png",
		[modGameProto.PIAO_B] = "ui:battle/piaofen_selected_1.png",
		[modGameProto.PIAO_C] = "ui:battle/piaofen_selected_2.png",
		[modGameProto.PIAO_D] = "ui:battle/piaofen_selected_3.png",
		[modGameProto.PIAO_E] = "ui:battle/piaofen_selected_4.png",
		[-1] = "ui:battle/piaofen_selected.png",
	},
	[modLobbyProto.CreateRoomRequest.ZHAOAN] = {
		[modGameProto.PIAO_A] = "ui:battle/chatai_selected_0.png",
		[modGameProto.PIAO_B] = "ui:battle/chatai_selected_1.png",
		[modGameProto.PIAO_C] = "ui:battle/chatai_selected_2.png",
		[modGameProto.PIAO_D] = "ui:battle/chatai_selected_3.png",
		[modGameProto.PIAO_E] = "ui:battle/chatai_selected_4.png",
		[-1] = "ui:battle/chatai_selected.png",
	},
	[modLobbyProto.CreateRoomRequest.TIANJIN] = {
		[modGameProto.PIAO_B] = "ui:battle/la_selected_2.png",
		[modGameProto.PIAO_D] = "ui:battle/chuai_selected_4.png",
		["la"] = "ui:battle/la_selected.png",
		["chuai"] = "ui:battle/chuai_selected.png",
	},
	[modLobbyProto.CreateRoomRequest.YUNYANG] = {
		[modGameProto.YUNYANG_QUE_TONG] = "ui:battle/quetong_0.png",
		[modGameProto.YUNYANG_QUE_SUO] = "ui:battle/quesuo_1.png",
		[modGameProto.YUNYANG_QUE_WAN] = "ui:battle/quewan_2.png",
		[-1] = "ui:battle/card_selected.png",
		["que"] = "ui:battle/dingque_selected.png",
	},--暂时用其他四张图片代替
	[modLobbyProto.CreateRoomRequest.PINGHE] = {
		[modGameProto.PINGHE_YOUJIN] = "ui:battle/youjin_pf.png",
		[modGameProto.PINGHE_SHUANGYOU] = "ui:battle/shuangyou_pf.png",
		[modGameProto.PINGHE_SIYOU] = "ui:battle/siyou_pf.png",
		[modGameProto.PINGHE_BAYOU] = "ui:battle/bayou_ph.png",
		[modGameProto.PINGHE_ROBANGANG] = "ui:battle/qianggangzhong.png",
	},
	[modLobbyProto.CreateRoomRequest.CHENGDU] = {
		[modGameProto.YUNYANG_QUE_TONG] = "ui:battle/quetong_0.png",
		[modGameProto.YUNYANG_QUE_SUO] = "ui:battle/quesuo_1.png",
		[modGameProto.YUNYANG_QUE_WAN] = "ui:battle/quewan_2.png",
		[-1] = "ui:battle/card_selected.png",
		["que"] = "ui:battle/dingque_selected.png",
	},
	[modLobbyProto.CreateRoomRequest.RONGCHENG] = {
		[modGameProto.PIAO_A] = "ui:battle/piaofen_selected_0.png",
		[modGameProto.PIAO_B] = "ui:battle/piaofen_selected_1.png",
		[modGameProto.PIAO_C] = "ui:battle/piaofen_selected_2.png",
		[modGameProto.PIAO_D] = "ui:battle/piaofen_selected_3.png",
		[modGameProto.PIAO_E] = "ui:battle/piaofen_selected_4.png",
		[-1] = "ui:battle/piaofen_selected.png",
	},
}

local ruleLinks = {
	["test"] = "http://www.openew.cn/games/mj/rule.php",
	["openew"] = "http://www.openew.cn/games/mj/rule.php",
	["ly_youwen"] = "http://www.openew.cn/games/mj/rule.php",
	["tj_lexian"] = "http://www.openew.cn/games/tjmj/rule.php",
	["ds_queyue"] = "http://www.openew.cn/games/dsmj/rule.php",
	["za_queyue"] = "http://www.openew.cn/games/zaqueyue/rule.php",
	["jz_laiba"] = "http://www.openew.cn/games/jzlaiba/rule.php",
	["yy_doudou"] = "http://www.openew.cn/games/yydoudou/rule.php",
	["xy_hanshui"] = "http://www.openew.cn/games/xyhanshui/rule.php",
	["rc_xianle"] = "http://www.openew.cn/games/rcxianle/rule.php",
	["nc_tianjiuwang"] = "http://www.openew.com/games/nctianjiuwang/rule.php",
	["qs_pinghe"] = "http://www.openew.com/games/qsph/rule.php",
}

local idxRange = {1, 3}
local starCount = 0

getRuleLink = function(t)
	return ruleLinks[t] or ruleLinks["openew"]
end

generateBackgroundBubbleAnimation = function(parentWnd, param)
	param = param or {}
	local noNetFrame = param["noNetFrame"] or false
	local sizeRate = param["sizeRate"] or 1
	local cntRate = param["cntRate"] or 1

	local gw = gGameWidth
	local gh = gGameHeight
	local areaw = gw / 2
	local areah = gh / 2

	local w, h = parentWnd:getWidth(), parentWnd:getHeight()
	local backWnd = pBatchWindow:new()
	backWnd:setSize(w, h)
	backWnd:setParent(parentWnd)
	backWnd:setPosition(0, 0)
	backWnd:showSelf(false)
	backWnd:enableEvent(false)

	local xCnt = math.ceil(w/gw)
	local yCnt = math.ceil(h/gh)
	local unitw = w/xCnt
	local unith = h/yCnt
	log("info", xCnt, yCnt, unitw, unith)

	local tick = 1
	local id = 1
	local allCircle = {}
	local genParam = function(wnd, tick)
		local sidx = math.random(1, #sizeRange)
		local size = sizeRange[sidx] * sizeRate
		local w, h = imgw*size, imgh*size
		wnd:setSize(w, h)
		wnd:setKeyPoint(w/2, h/2)
		local life = math.random(lifeRange[1], lifeRange[2])
		local offsetx = math.random(moveRange[1], moveRange[2])
		local offsety = math.random(moveRange[1], moveRange[2])
		local scale = math.random(scaleRange[1], scaleRange[2])
		wnd.__du = life + appearDu + disappearDu
		wnd.__born_time = tick
		wnd.__t_offx = offsetx
		wnd.__t_offy = offsety
		wnd.__t_scale = scale/10
		wnd.__dying = false
	end
	local intervalFunc = setNetInterval
	if noNetFrame then
		intervalFunc = setInterval
	end
	return intervalFunc(1, function()
		if tick == 1 or tick % genInterval == 0 then
			-- 产生新的圆形
			for i = 1, xCnt do
				for j = 1, yCnt do
					local fx = unitw*(i-1)
					local tx = unitw*i
					local fy = unith*(j-1)
					local ty = unith*j
					local cnt = math.random(circelCntRange[1], circelCntRange[2]) * cntRate
					for c = 1, cnt do
						local wnd = pBatchWindow:new()
						wnd.__id = id
						local idx = math.random(idxRange[1], idxRange[2])
						wnd:setImage(idxToImg[idx])
						local x = math.random(fx, tx)
						local y = math.random(fy, ty)
						wnd:setPosition(x, y)
						wnd:setParent(backWnd)
						wnd:setAlpha(0)
						genParam(wnd, tick)
						allCircle[id] = wnd
						id = id + 1
					end
				end
			end
		end

		local doneId = {}
		for _, wnd in pairs(allCircle) do
			local life = wnd.__du
			local borntime = wnd.__born_time
			local deadtime = borntime + life - disappearDu
			local offsetx = wnd.__t_offx
			local offsety = wnd.__t_offy
			local offx = modEasing.linear(tick - borntime, 0, offsetx, life)
			local offy = modEasing.linear(tick - borntime, 0, offsety, life)
			wnd:setOffsetX(offx)
			wnd:setOffsetY(offy)
			local s = modEasing.linear(tick - borntime, 1, wnd.__t_scale - 1, life)
			wnd:setScale(s, s)
			if borntime + appearDu > tick then
				local a = modEasing.linear(tick - borntime, 0, 255, appearDu)
				wnd:setAlpha(a)
			elseif deadtime <= tick and borntime + life > tick then
				local a = modEasing.linear(tick - deadtime, 255, -255, disappearDu)
				wnd:setAlpha(a)
			elseif borntime + life < tick then
				table.insert(doneId, wnd.__id)
			end
		end

		for _, id in ipairs(doneId) do
			allCircle[id]:setParent(nil)
			allCircle[id] = nil
		end

		tick = tick + 1
	end)
end

getFan = function(t)
	return FAN[t]
end

adjustSize = function(wnd, tw, th)
	local w, h = wnd:getWidth(), wnd:getHeight()
	local diffx = tw - w
	local diffy = th - h
	if diffx > diffy then
		local nw = w + diffx
		local nh = h + diffx * h/w
		wnd:setSize(nw, nh)
	else
		local nh = h + diffy
		local nw = w + diffy * w/h
		wnd:setSize(nw, nh)
	end
end

adjustWidth = function(wnd, tw)
	local w, h = wnd:getWidth(), wnd:getHeight()
	local nw, nh = tw, h/w*tw
	wnd:setSize(nw, nh)
end

utf8len = function(input)
	if not input then
		return 0
	end
	local len  = string.len(input)
	local left = len
	local cnt  = 0
	local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
	while left ~= 0 do
		local tmp = string.byte(input, -left)
		local i   = #arr
		while arr[i] do
			if tmp >= arr[i] then
				left = left - i
				break
			end
			i = i - 1
		end
		cnt = cnt + 1
	end
	return cnt
end


-- 截取指定长度 超过指定个数的，截取，然后添加...
getMaxLenString = function(s,maxLen)

	-- 分离字符
	local stringToTable = function(s)
		local tb = {}
		--[[
		UTF8的编码规则：
		1. 字符的第一个字节范围： 0x00—0x7F(0-127),或者 0xC2—0xF4(194-244); UTF8 是兼容 ascii 的，所以 0~127 就和 ascii 完全一致
		2. 0xC0, 0xC1,0xF5—0xFF(192, 193 和 245-255)不会出现在UTF8编码中
		3. 0x80—0xBF(128-191)只会出现在第二个及随后的编码中(针对多字节编码，如汉字)
		]]
		for utfChar in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
			table.insert(tb, utfChar)
		end
		return tb
	end

	-- 获取字符串长度，设一个中文长度为2，其他长度为1
	local getUTFLen = function(s)
		local sTable = stringToTable(s)
		local len = 0
		local charLen = 0
		for i=1,#sTable do
			local utfCharLen = string.len(sTable[i])
			if utfCharLen > 1 then -- 长度大于1的就认为是中文
				charLen = 2
			else
				charLen = 1
			end

			len = len + charLen
		end
		return len
	end

	-- 获取指定字符个数的字符串的实际长度
	local getUTFLenWithCount = function(s,count)
		local sTable = stringToTable(s)
		local len = 0
		local charLen = 0
		local isLimited = (count >= 0)

		for i=1,#sTable do
			local utfCharLen = string.len(sTable[i])
			if utfCharLen > 1 then -- 长度大于1的就认为是中文
				charLen = 0.5
			else
				charLen = 0.5
			end
			len = len + utfCharLen
			if isLimited then
				count = count - charLen
				if count <= 0 then
					break
				end
			end
		end
		return len
	end

	local len = getUTFLen(s)

	local dstString = s
	-- 超长，裁剪，加...
	if len > maxLen then
		dstString = string.sub(s, 1, getUTFLenWithCount(s, maxLen))
		dstString = dstString .. ".."
	end
	return dstString
end

stringToIP = function(ip)
	local p4 = ip % 256
	ip = math.floor(ip / 256)
	local p3 = ip % 256
	ip = math.floor(ip / 256)
	local p2 = ip % 256
	ip = math.floor(ip / 256)
	local p1 = ip % 256
	ip = math.floor(ip / 256)
	return p1 .. "." .. p2 .. "." .. p3 .. "." .. p4
end

timeOutDo = function(endTime, doSomething, afterDo)
	if type(endTime) ~= "number" then
		return
	end
	local time = endTime
	local frameRate = modUtil.getFrameRate()
	local timeOutEvent = runProcess(1,function()
		for i = 1,time do
			if doSomething then
				if (i % frameRate) == 0 then
					doSomething((endTime / frameRate) - (i / frameRate))
				end
			end
			yield()
		end
		if afterDo then
			afterDo()
		end
	end)
	return timeOutEvent
end

floatUp = function(wnd, time, vy)
	local floatUpEvent = runProcess(1,function()
		local endTime = time
		local endY = wnd:getOffsetY() + vy
		local startY = wnd:getOffsetY()
		local distance = endY - startY
		for i = 1, endTime do
			if wnd then
				local ny = modEasing.inOutSine(i,startY,distance,endTime)
				wnd:setOffsetY(ny)
				yield()
			else
				break
			end
		end
		if wnd then
			floatUp(wnd,time,-vy)
		end
		if floatUpEvent then
			floatUpEvent = nil
		end
	end)
end

turnAround = function(btnWnd, time, deepWnd)
	if deepWnd["wnd_star_" .. starCount] then
		deepWnd["wnd_star_" .. starCount]:setParent(nil)
	end
	local wnd = pWindow:new()
	wnd:setName("wnd_star_" .. starCount)
	starCount = starCount + 1
	wnd:setParent(btnWnd)
	wnd:setSize(42,42)
	wnd:setZ(-2)
	wnd:setAlignX(ALIGN_LEFT)
	wnd:setAlignY(ALIGN_TOP)
	wnd:setImage("ui:login_star.png")
	wnd:setColor(0xFFFFFFFF)
	deepWnd[wnd:getName()] = wnd
	deepWnd:insertControl(wnd)
	wnd:setPosition(-wnd:getWidth() / 2, -wnd:getHeight() / 2)
	local time = time
	local speed = math.abs(btnWnd:getWidth() / time)
	local diff = wnd:getWidth() / 2
	rightMove(time,wnd,btnWnd,speed,diff)
end

starRun = function(time,spos,epos,dirString,wnd,affterDo)
	local endTime = time
	runProcess(1,function()
		local startPos = spos
		local endPos = epos
		local distance = endPos - startPos
		local dirStr = dirString
		for i = 1,endTime do
			if not wnd then
				break
			end
			local n = modEasing.linear(i,startPos,distance,endTime)
			if dirStr == "x" then
				wnd:setPosition(n,wnd:getY())
			elseif dirStr == "y" then
				wnd:setPosition(wnd:getX(),n)
			end
			yield()
		end
		if affterDo and wnd then
			affterDo()
		end
	end)
end

rightMove = function(time,starWnd,btnWnd,s,diff)
	if time and starWnd and btnWnd then
		local speed = math.abs(btnWnd:getWidth() / time)
		local curTime = time
		if speed ~= s then
			curTime = btnWnd:getWidth() / s
		end
		starRun(curTime,starWnd:getX(),btnWnd:getWidth() - diff,"x",starWnd,function()
			downMove(time,starWnd,btnWnd,s,diff)
		end)
	end
end

upMove = function(time,starWnd,btnWnd,s,diff)
	if time and starWnd and btnWnd then
		local speed = math.abs(-btnWnd:getHeight() / time)
		local curTime = time
		if speed ~= s then
			curTime = btnWnd:getHeight() / s
		end
		starRun(curTime,starWnd:getY(), - diff,"y",starWnd,function()
			rightMove(time,starWnd,btnWnd,s,diff)
		end)
	end
end

leftMove = function(time,starWnd,btnWnd,s,diff)
	if time and starWnd and btnWnd then
		local speed = math.abs(btnWnd:getWidth() / time)
		local curTime = time
		if speed ~= s then
			curTime = btnWnd:getWidth() / s
		end
		starRun(curTime,starWnd:getX(), - diff,"x",starWnd,function()
			upMove(time,starWnd,btnWnd,s,diff)
		end)
	end
end

downMove = function(time,starWnd,btnWnd,s,diff)
	if time and starWnd and btnWnd then
		local speed = math.abs(btnWnd:getHeight() / time)
		local curTime = time
		if speed ~= s then
			curTime = btnWnd:getHeight() / s
		end
		starRun(curTime,starWnd:getY(),btnWnd:getHeight() - diff,"y",starWnd,function()
			leftMove(time,starWnd,btnWnd,s,diff)
		end)
	end
end

isPlatform = function(str)
	local opp = puppy.world.app.instance()
	local platform = app:getPlatform()
	-- macos mac
	if platform == str then
		return true
	else
		return false
	end
end


getFlagValue = function(index, t)
	logv("error","getFlagValue",index,t)
	if not flagValues[t] or not flagValues[t][index] then return end

	return flagValues[t][index]
end

getPiaoImage = function(mjt, t)
	if not piaoImage[mjt] or not piaoImage[mjt][t] then
		return nil
	end
	return piaoImage[mjt][t]
end

addPublicRule = function()
	local rule = {}
	local tableConcat = function(t1, t2)
		for k, v in pairs(t2) do
			t1[k] = v
		end
		return t1
	end
	local t = {}
	for k, v in pairs(ruleShow) do
		t[k] = tableConcat(v, publicShow)
	end
	rule = t
	return rule
end

addPokerPublicRule = function()
	local rule = {}
	local tableConcat = function(t1, t2)
		for k, v in pairs(t2) do
			t1[k] = v
		end
		return t1
	end
	local t = {}
	for k, v in pairs(pokerRuleShow) do
		t[k] = tableConcat(v, pokerPublicShow)
	end
	rule = t
	return rule
end

-- 传入房间信息 返回房间规则
getRuleStr = function(roomInfo, splitStr)
	addPublicRule()
	local nameEnum = { "allow_magic_cards", "allow_zhuangxian", "allow_chi", "allow_dianpao", "allow_yipaoduoxiang", "allow_qianggang", "zhuaniao_count", "zhongniao_rule", "allow_piao", "allow_dui_hu", "allow_word_cards", "allow_qiangangang", "allow_sidajingang", "gangbao_chengbao", "shierzhangluodi_chengbao", "qianggang_chengbao", "fenzhurou", "wugui_x2", "qianggang_x2", "gangshangkaihua_x2", "dinggui", "maima", "allow_chan", "allow_jingang", "allow_la", "allow_chuai", "dibei", "fgsjkf", "dingque", "allow_qiansi", "allow_zhuangsanda", "allow_jingoudiao", "huazhu_score", "max_fan_count", "conceal_discarded_cards", "xy_scores", "banpindao", "erwubazhang", "qiluo", "allow_minglou", "allow_shuaiquan", "huansanzhang", "dianganghua", "hujiaozhuanyi", "zimojiadi", "zimojiafan", "allow_tiandihu", "allow_yaojiujiangdui", "allow_yitiaolong", "allow_menqing", "min_fan_count", "genzhuang", "sankoubaohu", "sijinban", "sanjindao_or_sijindao", "shuangyou_can_hu"}
	local r = roomInfo.rule_type
	local ruleStr = ""

	if not splitStr then
		splitStr = ","
	end

	for idx, s in pairs(nameEnum) do
		if roomInfo[s] ~= nil or roomInfo.maoming_extras[s] ~= nil
			or roomInfo.tianjin_extras[s] ~= nil
			or roomInfo.dongshan_extras ~= nil
			or roomInfo.yunyang_extras ~= nil
			or roomInfo.xiangyang_extras ~= nil
			or roomInfo.daodao_extras ~= nil
			or roomInfo.rongcheng_extras ~= nil
			or roomInfo.chengdu_extras ~= nil
			or roomInfo.jining_extras ~= nil
			or roomInfo.pinghe_extras ~= nil
			then
			if ruleShow[r][s] ~= nil then
				if ruleShow[r][s][roomInfo[s]] or
					ruleShow[r][s][roomInfo.maoming_extras[s]] or
					ruleShow[r][s][roomInfo.tianjin_extras[s]] or
					ruleShow[r][s][roomInfo.dongshan_extras[s]] or
					ruleShow[r][s][roomInfo.yunyang_extras[s]] or
					ruleShow[r][s][roomInfo.xiangyang_extras[s]] or
					ruleShow[r][s][roomInfo.daodao_extras[s]] or
					ruleShow[r][s][roomInfo.rongcheng_extras[s]] or
					ruleShow[r][s][roomInfo.chengdu_extras[s]] or
					ruleShow[r][s][roomInfo.jining_extras[s]] or
					ruleShow[r][s][roomInfo.pinghe_extras[s]]
					then
					ruleStr = ruleStr .. (ruleShow[r][s][roomInfo[s]] or
					ruleShow[r][s][roomInfo.maoming_extras[s]] or
					ruleShow[r][s][roomInfo.tianjin_extras[s]] or
					ruleShow[r][s][roomInfo.dongshan_extras[s]] or
					ruleShow[r][s][roomInfo.yunyang_extras[s]] or
					ruleShow[r][s][roomInfo.xiangyang_extras[s]] or
					ruleShow[r][s][roomInfo.daodao_extras[s]] or
					ruleShow[r][s][roomInfo.rongcheng_extras[s]] or
					ruleShow[r][s][roomInfo.chengdu_extras[s]] or
					ruleShow[r][s][roomInfo.jining_extras[s]] or
					ruleShow[r][s][roomInfo.pinghe_extras[s]]
					) .. splitStr
				end
			end
		end
	end
	if string.sub(ruleStr,-1,-1) == "," then
		ruleStr = string.sub(ruleStr,1, -2)
	end
	return ruleStr
end

getPokerRuleStr = function(roomInfo, splitStr)

	return modCardBattleCreate.getClubRoomDesc(roomInfo, true)

	--[==[
	addPokerPublicRule()

	local nameEnum = { "game_mode", "banker_mode", "bet_mode" }
	local r = roomInfo.poker_type
	local info = modNiuniuProto.NiuniuCreateParam()
	info:ParseFromString(roomInfo.create_param)
	local ruleStr = ""

	if not splitStr then
		splitStr = ","
	end

	for idx, s in pairs(nameEnum) do
		if info then
			if pokerRuleShow[r] and pokerRuleShow[r][s] and info[s] and pokerRuleShow[r][s][info[s]] then
				ruleStr = ruleStr .. pokerRuleShow[r][s][info[s]] .. splitStr or ","
			end
		end
	end

	if string.sub(ruleStr,-1,-1) == "," then
		ruleStr = string.sub(ruleStr,1, -2)
	end
	return ruleStr
	]==]--
end

getRuleShow = function()
	return addPublicRule()
end

-- 玩家是否听牌
getIsTing = function(player, protoFlag)
	if not player then
		return false
	end
	local pflag = modGameProto.TING
	if protoFlag then
		pflag = modGameProto.PRE_TING
	end

	local flags = player:getFlags()
	local isTing = false

	for idx, f in pairs(flags) do
		if f == pflag then
			isTing = true
			break
		end
	end
	return isTing
end

-- 全屏界面统一关闭按钮位置
setClosePos = function(btn)
	btn:setOffsetX(0)
	btn:setPosition(0, gGameHeight * 0.006)
end

getDefaultImage = function(gender)
	local image = "ui:image_default_female.png"
	if gender == T_GENDER_MALE then
		image = "ui:image_default_male.png"
	end
	return image
end

getRuleStringByType = function(t)
	return publicShow["rule_type"][t]
end

getPokerRuleStringByType = function(t)
	return pokerPublicShow["poker_type"][t]
end

getRoomTypeStr = function(t)
	return publicShow["room_type"][t]
end

getDownloadLink = function()
	local opChannel = modUtil.getOpChannel()
	local info = downloadLinkes[opChannel] or {}
	local link = info["link"]
	if not link or link == "" then
		link = "http://www.openew.cn/games/mj/index.html"
	end
	return link
end

getDownloadTitle = function()
	local opChannel = modUtil.getOpChannel()
	local info = downloadLinkes[opChannel] or {}
	return info["title"] or ""
end

getDirImage = function(t, dir, seatId, isSelected)
	if t == "bg" then
		return dirImages[t][seatId]
	end
	return dirImages[t][dir][seatId][isSelected]
end

getYouHuiAuthCard = function()
	if not youHuiData[modUtil.getOpChannel()] then return 0 end
	return youHuiData[modUtil.getOpChannel()]["rn_room_card_gift"] or 0
end

getYouHuiAuthPer = function()
	if not youHuiData[modUtil.getOpChannel()] then return 0 end
	return youHuiData[modUtil.getOpChannel()]["rn_recharge_gift"] * 100 or 0
end

getYouHuiInviteCard = function()
	if not youHuiData[modUtil.getOpChannel()] then return 0 end
	return youHuiData[modUtil.getOpChannel()]["bic_room_card_gift"] or 0
end

getYouHuiInvitePer = function()
	if not youHuiData[modUtil.getOpChannel()] then return 0 end
	return youHuiData[modUtil.getOpChannel()]["bic_recharge_gift"] * 100 or 0
end

getImageByComb = function(t, isZimo)
	logv("info","getImageByComb")
	logv("info","t","isZimo",t,isZimo)
	if not t then return end
	if isZimo then t = "zimo" end
	return combToUI[t]
end

combEffect = function(time, wnd, startScale)
	if not wnd or not startScale then return end
	wnd:show(true)
	local effect = runProcess(1, function()
		local endTime = time
		local endWidth = wnd:getWidth() * 1.2
		local endHeight = wnd:getHeight() * 1.2
		local endX = wnd:getX()
		local endY = wnd:getY()
		local startX = wnd:getX() + wnd:getWidth() * startScale
		local startY = wnd:getY() + wnd:getHeight() * startScale
		local distanceX = endX - startX
		local distanceY = endY - startY
		local distanceW = endWidth - wnd:getWidth() * startScale
		local distanceH = endHeight - wnd:getHeight() * startScale
		for i = 1, endTime do
			local nx = modEasing.outQuad(i, startX, distanceX, endTime)
			local ny = modEasing.outQuad(i, startY, distanceY, endTime)
			local nw = modEasing.outQuad(i, wnd:getWidth() * startScale, distanceW, endTime)
			local nh = modEasing.outQuad(i, wnd:getHeight() * startScale, distanceH, endTime)
			wnd:setPosition(nx, ny)
			wnd:setSize(nw, nh)
			yield()
		end
	end)
end

fadeOut = function(wnd, endTime)
	if not wnd or not endTime then return end
	local time = endTime or 60
	local fadeSpeed = 255 / time
	timeOutDo(1, nil, function()
		local alpha = wnd.alpha or 255
		wnd:setAlpha(alpha - fadeSpeed)
		wnd.alpha = alpha - fadeSpeed
		if alpha - fadeSpeed <= 0 then
			wnd:setParent(nil)
			wnd = nil
		end
		fadeOut(wnd, endTime)
	end)
end

fadeIn = function(wnd, endTime)
	if not wnd or not endTime then return end
	local time = endTime or 60
	local fadeSpeed = 255 / time
	timeOutDo(1, nil, function()
		local alpha = wnd.alpha or 0
		wnd:setAlpha(alpha + fadeSpeed)
		wnd.alpha = alpha + fadeSpeed
		if alpha + fadeSpeed >= 255 then
			return
		end
		fadeIn(wnd, endTime)
	end)
end

local hasChannelRes = {
	tj_lexian = true,
	ds_queyue = true,
	jz_laiba = true,
	yy_doudou = true,
	ly_youwen = true,
	xy_hanshui = true,
	rc_xianle = true,
	test = true,
	nc_tianjiuwang = true,
	za_queyue = true,
	qs_pinghe = true,
}

getChannelRes = function(name)
	local opChannel = modUtil.getOpChannel()
	logv("warn",opChannel)
	if hasChannelRes[opChannel] then
		local path = "ui:channel_res/" .. opChannel .. "/" .. name
		if app:getIOServer():fileExist(path) then
			return path
		else
			return "ui:" .. name
		end
	else
		local path = "ui:" .. name
		if app:getIOServer():fileExist(path) then
			return path
		else
			return nil
		end
	end
end

hasFileByPath = function(path)
	if not path then return end
	return app:getIOServer():fileExist(path)
end

getChannelIsJZ = function()
	local opChannel = modUtil.getOpChannel()
	return opChannel == "jz_laiba"
end

getChannelIsQSPinghe = function (  )
	local opChannel = modUtil.getOpChannel()
	return opChannel == "qs_pinghe"
end

getChannelIsXYHanshui = function()
	local opChannel = modUtil.getOpChannel()
	return opChannel == "xy_hanshui"
end

getChannelIsRCXianle = function()
	local opChannel = modUtil.getOpChannel()
	return opChannel == "rc_xianle" or modUtil.isDebugVersion()
end

getIsNormalCard = function(id)
	return id >= 0 and id<= 41
end

getListIdToCount = function(list)
	if not list then return end
	local cardCounts = {}
	for _, id in pairs(list) do
		if not cardCounts[id] then
			cardCounts[id] = 1
		else
			cardCounts[id] = cardCounts[id] + 1
		end
	end
	return cardCounts
end

-- 根据经纬度取距离
local EARTH_RADIUS = 6378137
rad = function(d)
	return d * math.pi / 180
end
getDistanceByLatitudeLogitude = function(lon1, lat1, lon2, lat2)
	if not lon1 or not lon2 or not lat1 or not lat2 then
		return
	end
	local radLat1 = rad(lat1)
	local radLat2 = rad(lat2)
	local radLon1 = rad(lon1)
	local radLon2 = rad(lon2)
	if (radLat1 < 0) then
		radLat1 = math.pi / 2 + math.abs(radLat1) -- south
	end
	if (radLat1 > 0) then
		radLat1 = math.pi / 2 - math.abs(radLat1) -- north
	end
	if (radLon1 < 0) then
		radLon1 = math.pi * 2 - math.abs(radLon1) -- west
	end
	if (radLat2 < 0) then
		radLat2 = math.pi / 2 + math.abs(radLat2) -- south
	end
	if (radLat2 > 0) then
		radLat2 = math.pi / 2 - math.abs(radLat2) -- north
	end
	if (radLon2 < 0) then
		radLon2 = math.pi * 2 - math.abs(radLon2) -- west
	end
	local x1 = EARTH_RADIUS * math.cos(radLon1) * math.sin(radLat1)
	local y1 = EARTH_RADIUS * math.sin(radLon1) * math.sin(radLat1)
	local z1 = EARTH_RADIUS * math.cos(radLat1)

	local x2 = EARTH_RADIUS * math.cos(radLon2) * math.sin(radLat2)
	local y2 = EARTH_RADIUS * math.sin(radLon2) * math.sin(radLat2)
	local z2 = EARTH_RADIUS * math.cos(radLat2)

	local d = math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)+ (z1 - z2) * (z1 - z2))
	local theta = math.acos((EARTH_RADIUS * EARTH_RADIUS + EARTH_RADIUS * EARTH_RADIUS - d * d) / (2 * EARTH_RADIUS * EARTH_RADIUS))
	local dist = theta * EARTH_RADIUS
	log("info", "distance:", dist)
	return dist;
end

getListFromMessage = function(list)
	if not list then return end
	local ls = {}
	for _, v in ipairs(list) do
		table.insert(ls, v)
	end
	return list
end

local discardCombs = {
	[modGameProto.ANGANG] = true,
	[modGameProto.XIAOMINGGANG] = true,
}

getIsCanDiscardComb = function(t)
	if not t then return end
	return discardCombs[t]
end

findCardCountInlist = function(id, list)
	if not id or not list then return 0 end
	local count = 0
	for _, card in pairs(list) do
		if id == card:getId() then
			count = count + 1
		end
	end
	return count
end

-- 不算暗杠统计的麻将类型
local lcr = modLobbyProto.CreateRoomRequest
local angangVisibles = {
	[lcr.DONGSHAN] = true,
	[lcr.PINGHE] = true,
	[lcr.ZHAOAN] = true,
}

getCurrentMJType = function()
	local modBattleMgr = import("logic/battle/main.lua")
	return modBattleMgr.getCurBattle():getCurGame():getRuleType()
end

-- 判断hu comb是否是自摸
getIsZimoComb = function(comb, player)
	if not comb or not player then return end
	if comb.t ~= modGameProto.HU then return end
	local tpid = comb:getTriggerPid()
	local pid = player:getPlayerId()
	return tpid == pid
end

findCardBySeat = function(seatId, id)
	if not seatId or not id then return end
	local modBattleMgr = import("logic/battle/main.lua")
	local players = modBattleMgr.getCurBattle():getAllPlayers()
	local player = players[seatId]
	if not player then return end
	local pid = player:getPlayerId()
	local curPid = modBattleMgr.getCurBattle():getCurPlayer():getPlayerId()
	-- 血战到底不算hu comb
	local addHuOnlyTiggerCard = modBattleMgr.getCurBattle():getBattleUI():huCombOnleAddTrigger()
	-- 自己取手牌 发牌 弃牌 明牌
	-- 别人取弃牌和明牌
	local hands = {}
	local combs = {}
	local discards = {}
	local deals = {}
	--
	local count = 0
	-- 取值
	if seatId == T_SEAT_MINE then
		hands = player:getAllCardsFromPool(T_POOL_HAND)
		deals = player:getCurrentDealCard()
	end
	combs = player:getAllCardsFromPool(T_POOL_SHOW)
	discards = player:getAllCardsFromPool(T_POOL_DISCARD)
	-- 取手牌
	count = count + findCardCountInlist(id, hands)
	-- 发牌
	count = count + findCardCountInlist(id, deals)
	-- 明牌
	for _, comb in pairs(combs) do
		-- 胡comb
		local tpid = comb:getTriggerPid()
		if comb.t == modGameProto.HU then
			-- 血战到底 自摸加1 否则不加
			local combTriggerCards = comb:getTriggerCards()
			if addHuOnlyTiggerCard then
				if getIsZimoComb(comb, player) then
					local isHas = false
					for _, tid in ipairs(combTriggerCards) do
						if tid == id then
							isHas = true
							break
						end
					end
					if isHas then
						count = count + table.getn(combTriggerCards)
					end
				end
			else
				-- 其他麻将 接炮-1 自摸不加
				count = count + findCardCountInlist(id, comb:getCards())
				if not getIsZimoComb(comb, player) then
					count = count - table.getn(combTriggerCards)
				end
			end
		elseif comb.t == modGameProto.ANGANG then
			-- 东山和诏安麻将暗杠
			if angangVisibles[getCurrentMJType()] then
				-- 自己打的暗杠统计
				if curPid == tpid then
					count = count + findCardCountInlist(id, comb:getCards())
				end
			else
				count = count + findCardCountInlist(id, comb:getCards())
			end
		else
			count = count + findCardCountInlist(id, comb:getCards())
		end
	end
	-- 弃牌
	count = count + findCardCountInlist(id, discards)
	return count
end

testCallProtoFunciton = function(name, message)
	if not message then return end
	local modTest = import("net/rpc/proto_to_function.lua")
	modTest.getProtoFunction(name)(message)
end


jiebaoEffect = function(wnd, time, ex, ey, w, h, s)
	if not wnd or not time then return end
	local scale = s or 1
	local fream = modUtil.s2f(1)
	local effect = timeOutDo(1, nil, function()
		local endTime = time or fream
		local endWidth = w or 502
		local endHeight = h or 329
		local endX = ex or 28
		local endY = ey or 0 + 10 + 13
		local startPosX = wnd:getX()
		local distanceX = endX - startPosX
		local startPosY = wnd:getY()
		local distanceY = endY - startPosY
		local startWidth = endWidth * scale
		local distanceWidth = endWidth - startWidth
		local startHeight = endHeight * scale
		local distanceHeight = endHeight - startHeight
		for i = 1,endTime do
			local nx = modEasing.outElastic(i,startPosX,distanceX,endTime)
			local ny = modEasing.outElastic(i,startPosY,distanceY,endTime)
			local nw = modEasing.outElastic(i,startWidth,distanceWidth,endTime)
			local nh = modEasing.outElastic(i,startHeight,distanceHeight,endTime)

			wnd:setPosition(nx,ny)
			wnd:setSize(nw,nh)
			yield()
		end
		local etime = modUtil.s2f(2.3)
		timeOutDo(etime, nil, function()
			wnd:setParent(nil)
		end)
	end)
	return effect
end

checkEditText = function(edit, isCheckNil)
	if not edit then return end
	local text = edit["selfText"]
	if not text then return true end
	if isCheckNil then
		return edit:getText() ~= text and edit:getText() ~= "" and edit:getText()
	end
	return edit:getText() ~= text
end

checkEditTextList = function(list, isCheckNil)
	if not list then return end
	for _, edit in pairs(list) do
		if checkEditText(edit, isCheckNil) then
			return true
		end
	end
	return false
end

initEditTextList = function(list)
	if not list then return end
	local tmp = function(edit)
		if not edit then return end
		local text = edit:getText()
		if not text then return end
		edit["selfText"] = text
	end
	for _, edit in pairs(list) do
		tmp(edit)
	end
end

getNameByProviceCithCode = function(provinceCode, cityCode)
	if provinceCode == 0 then provinceCode = nil end
	if cityCode == 0 then cityCode = nil end
	if not provinceCode then return end
	local modProvince = import("data/info/info_club_province.lua")
	local modCity = import("data/info/info_club_city.lua")
	local findData = function(code, datas)
		if not code or not datas then return end
		for _, data in pairs(datas) do
			if data["code"] == code then
				return data
			end
		end
		return nil
	end
	local provinceData = findData(provinceCode, modProvince.data)
	if not provinceData then return end
	if not cityCode then
		return provinceData["name"]
	else
		local cityData = findData(cityCode, modCity.data)
		return provinceData["name"] .. "-" .. cityData["name"]
	end
end

setWndColorText = function(wnd, num, appointColorStr)
	-- 0 显示为-
	if not wnd or not num then return end
	if not tonumber(num) then return end
	if num == 0 then
		wnd:setText("-")
		return
	end
	-- 指定颜色 绿色+  红色-
	if appointColorStr then
		if appointColorStr == "r" then
			wnd:setText(sf("#cr - %d #n", num))
		elseif appointColorStr == "g" then
			wnd:setText(sf("#cg + %d #n", num))
		end
		return
	end
	-- 没有指定颜色 正数+ 负数-
	if num > 0 then
		wnd:setText(sf("#cg + %d #n", num))
	else
		wnd:setText(sf("#cr - %d #n", num))
	end
end

sortTableByKey = function(datas)
	if not datas then return end
	local keys = table.keys(datas)
	table.sort(keys, function(k1, k2)
		if tonumber(k1) and tonumber(k2) then
			return tonumber(k1) < tonumber(k2)
		end
	end)
	local result = {}
	for _, key in pairs(keys) do
		table.insert(result, datas[key])
	end
	return result
end
