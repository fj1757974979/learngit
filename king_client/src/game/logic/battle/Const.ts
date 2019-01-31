module Battle {

    export enum BattleType {
        PVP = 1,
        LEVEL = 2,
        //CAMPAIGN = 3,
        CAMPAIGN_DEF = 4,
        //VIDEO = 5,
        Training = 5,
        Guide = 6,
        Friend = 13,
        LevelHelp = 14,
        Campaign = 15,

        VIDEO = 100,
    }

    export enum Side {
        OWN,
        ENEMY,
    }

    export enum CardNumPos {
        NONE = -1,
        UP = 1,
        DOWN = 2,
        LEFT = 3,
        RIGHT = 4,
    }
}