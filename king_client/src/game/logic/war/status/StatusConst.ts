// TypeScript file
module War {
    export var ST_NONE = -1;

    export enum BattleStatusName {
        ST_NORMAL = 0,   // 
        ST_PREPARE = 1,  // 战前
        ST_DURING = 2,  // 战中
        ST_END = 3,    // 战后
        ST_UNIFIED = 4, // 统一
    }

    export enum CountryStatusName {
        ST_ALIVE = 0,          // 存活
        ST_DEFEAT = 1,         // 消灭
    }

    export enum CityStatusName {
        ST_NORMAL = 0,         // 正常态
        ST_ATTACKED = 1,       // 被攻击
        ST_FALLEN = 2,         // 被攻陷
    }

    export enum PlayerStatusName {
        ST_NORMAL = 0,         // 正常
        ST_ARREST = 1,         // 被抓
        ST_KICKOUT = 2,        // 驱逐
        ST_SUPPORT = 3,        // 支援
        ST_EXPEDITION = 4,     // 出征
        ST_DEFEND = 5,         // 守城
        ST_RECTIFY = 6,        // 整顿
        ST_REST = 7,           // 休养
    }

    export enum TeamStatusName {
        ST_NORMAL = 0,            // 正常行走
        ST_FIELD_BATTLE = 1,      // 野战中，如果一个队伍变成这个状态，让队伍在地图上停下来，直到变成ST_NORMAL，再继续走
        ST_CAN_ATT_CITY = 2,      // 到达敌城，能攻城，但没攻，如果这个队伍是MyTeam，界面需要显示攻城/撤退选项
        ST_ATTACKING_CITY = 3,    // 正在攻城
        ST_DISAPPEAR = 4,         // 消失
        ST_FIELD_BATTLE_END = 5,  // 野战结束，如果是MyTeam，显示继续行军或撤退，如果别人的队伍，在地图上停下来
        ST_ATT_CITY = 6,          // 攻城战中
        ST_DEF_CITY = 7,          // 守城战中
        ST_DEF_BATTLE_END = 8,    // 守城战结束，显示继续守城/取消
    }
}