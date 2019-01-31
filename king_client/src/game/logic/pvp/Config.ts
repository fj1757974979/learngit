// TypeScript file
module Pvp {

    export class Config {
         public static _inst: Config = null;
         
        private _levelInfo: Collection.Dictionary<number, Collection.Dictionary<string, number>>;
        private _pvpTeamToLevels: Collection.Dictionary<number, Array<number>>;
	    private _cardUnlockLevel:Collection.Dictionary<number, number>;

        public static get inst() {
            if (!Config._inst) {
                Config._inst = new Config();
            }
            return Config._inst;
        }

        public static MIN_RANK_TAEM = 2;
        public static MAX_RANK_TEAM = 8;

        constructor() {
            let allLevel = Data.rank.keys;
            let tmpTeam = 0;
            let tmpRankLv = 0;
            let tmpTotalStars = 0;
            this._levelInfo = new Collection.Dictionary<number, Collection.Dictionary<string, number>>();
	        this._cardUnlockLevel = new Collection.Dictionary<number, number>();
            this._pvpTeamToLevels = new Collection.Dictionary<number, Array<number>>();
            for (let i = 0; i < allLevel.length; i ++) {
                let level = allLevel[i];
                let conf = Data.rank.get(level);
                let team = conf.team;
                let maxStar = conf.levelUpStar;
                let data = new Collection.Dictionary<string, number>();
                data.setValue("maxStar", maxStar);
                if (team != tmpTeam) {
                    tmpTeam = team;
                    tmpRankLv = 5;
                } else {
                    tmpRankLv --;
                }
                data.setValue("rankLv", tmpRankLv);
                data.setValue("totalStars", tmpTotalStars + 1);
                tmpTotalStars += maxStar;
                this._levelInfo.setValue(level, data);

		        let unlockCards: number[] = conf.unlock;
		        for (let j=0;j<unlockCards.length; j++) {
		            this._cardUnlockLevel.setValue(unlockCards[j], level);
		        }
                
                if (!this._pvpTeamToLevels.containsKey(team)) {
                    this._pvpTeamToLevels.setValue(team, []);
                }
                let arr = this._pvpTeamToLevels.getValue(team);
                arr.push(level);
            }
        }

        /*
         * 获取大段位
         */
        public getPvpTeam(level: number): number {
            let config = Data.rank.get(level);
            return config.team;
        }
        
        public getPvpTeamName(level: number): string {
            let config = Data.rank.get(level);
            if (config) {
                return config.name;
            } else {
                return "";
            }
        }

        /*
         * 获取大段位中的小分段
         */
        public getPvpRankLv(level: number): number {
            let data = this._levelInfo.getValue(level);
            if (data) {
                return data.getValue("rankLv");
            } else {
                return 0;
            }
        }

        public getPvpTitle(level: number): string {
            let config = Data.rank.get(level);
            if (config) {
                return config.title;
            } else {
                return "";
            }
        }

        public isPvpLevelProtected(level: number): boolean {
            let config = Data.rank.get(level);
            return config.protection == 1;
        }

	    /*
	     * 获取等级解锁的卡片
	     */
	    public getUnlockCard(level:number):number[] {
	        return Data.rank.get(level).unlock;
	    }

	    /*
	     * 获取卡片对应的解锁等级
	     */
	    public getCardUnlockLevel(id:number):number {
	        return this._cardUnlockLevel.getValue(id);
	    }

        /*
         * 获取该分段的升段需要的总星数
         */
        public getPvpMaxStar(level: number): number {
            let config = Data.rank.get(level);
            return config.levelUpStar;
        }

        /*
         *  获取到达该等级需要的总星数
         */
        public getTotalStar(level: number): number {
            let data = this._levelInfo.getValue(level);
            if (data) {
                return data.getValue("totalStars");
            } else {
                return 0;
            }
        }

        public getMaxPvpLevel(): number {
            return Data.rank.keys[Data.rank.keys.length - 1];
        }

        /*
         * 获取该大分段中最小的段位
         */
        public getMiniLevelInPvpTeam(pvpTeam: number): number {
            let arr = this._pvpTeamToLevels.getValue(pvpTeam);
            return arr[0];
        }

        /*
         * 获取 
         */
    }
}
