
enum ResType {
        T_WEAP = 1,   // 武器
        T_HORSE = 2,  // 马匹
        T_MAT = 3,    // 辎重
        T_GOLD = 4,   // 金币
        T_FORAGE = 5, // 粮草
        T_MED = 6,    // 医药箱
        T_BAN = 7,    // 绷带
        T_WINE = 8,   //酒
        T_BOOK = 9,   //书
        T_JADE = 11,  // 宝玉
        T_FEAT = 12, //功勋
        T_FAME = 13, //名望
        T_EQUIP = 14, //购买武器的货币
        T_BOWLDER = 15, // 玉石
        T_EXCHANGE_ITEM = 17, // 用于兑换活动的物品
        T_SCORE = 100,  //分
        T_GUIDE_PRO = 101,  // 新手进度
        T_MAX_SCORE = 102,  // 历史最高分
        T_ACC_TREASURE_CNT = 103, // 剩余宝箱加速次数
        T_NO_SUB_STAR_CNT = 104, // 不掉星次数
        PvpTreasureCnt = 105, //每日对战可获得宝箱次数
        PvpGoldCnt = 106, //每日对战可获得金币次数
        SeasonWinDiff = 107, //赛季净胜分
}
enum Priv {
        VIP_PRIV = 0,                   //VIP跳过广告
        TREASURE_ADD_CARD = 1,          //宝箱增加卡牌
        TREASURE_ADD_GOLD = 2,          //宝箱增加金币
        REWARD_ADD_TREASURE = 3,        //增加宝箱数量
        TREASURE_ADD_ACC_CNT = 4,       //增加加速次数
        DAILY_ADD_CARD = 5,             //每日宝箱增加卡牌数量
        TREASURE_SUB_TIME = 6,          //宝箱开启时间减少
        BATTLE_ADD_GOLD = 7,            //对战增加金币
        BATTLE_ADD_STAR = 8,            //对战增加星星
        BATTLE_NOT_SUB_STAR = 9,        //对战不减星星
}

enum Camp {
        WEI = 1,
        SHU = 2,
        WU = 3,
        HEROS = 4
}
enum Job {
        UnknowJob = 0,
        YourMajesty = 1,  // 主公
        Counsellor = 2,   // 军师
        General = 3,      // 中郎将
        Prefect = 4,      // 太守
        DuWei = 5,        // 都尉
        FieldOfficer = 6, // 校尉
}
enum JobType {
        Null = 0,
        CityJob = 1,
        CountryJob = 2,
}
enum WarResType {
        Gold = 0,       //金币
        Defense =1,     //城防
        Agriculture = 2,//农业
        Business = 3,   //商业
        Forage = 4,     //粮食
        Glory = 5,      //荣耀
        Contribution = 100, // 战功
}
enum WarMsType {
        UnknowMsType = 0,
        Irrigation = 1,  // 灌溉
        Trade = 2,       // 贸易
        Build = 3,       // 修筑
        Transport = 4,   // 运输
        Dispatch = 5,    // 调派
}
enum WarTranType {
        Gold = 0,       //运金币
        Forage = 1,     //运粮食
}

enum RewardType {
        REWARD = 0,    // 宝箱奖励
        DAILY = 1,     // 日常奖励
}

enum CardQuality {
        NORMAL = 1,     // 普通
        RARE = 2,       // 稀有
        EPIC = 3,       // 史诗
        LEGENDARY = 4,  // 传奇
        BOOM = 5,       // 爆炸
        LIMITED = 99,   // 限定
}
enum CardJade {
        NORMAL = 3,     // 普通
        RARE = 4,       // 稀有
        EPIC = 5,       // 史诗
        LEGENDARY = 6,  // 传奇
        BOOM = 7,       // 爆炸
        LIMITED = 0,   // 限定
}

let IOS_EXAMINE_VERSION = false;