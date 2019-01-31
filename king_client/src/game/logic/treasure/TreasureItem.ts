module Treasure {

	export class TreasureItem {
		protected _pos: number;
		protected _id: number;
		protected _type: string;
		protected _openTime: number; 			// 打开剩余时间。0:已激活完毕；0 < < MAX_OPEN_TIME:正在激活；> MAX_OPEN_TIME:还未激活
		protected _lastUpdateTime:number;
		protected _rewardType: RewardType;

		protected _config: any;

		readonly MAX_STAR_COUNT = 10000;
		readonly MAX_OPEN_TIME = 100000;

		private _isEffectByPrivilege: boolean;

		public constructor(id: number, type: string) {
			this._id = id;
			this._type = type;
			this._config = Data.treasure_config.get(type);
			this._lastUpdateTime = 0;
			this._isEffectByPrivilege = false;
		}

		public get id(): number {
			return this._id;
		}

		public get type(): string {
			return this._type;
		}

		public set type(t: string) {
			this._type = t;
			this._config = Data.treasure_config.get(t);
		}

		public get pos(): number {
			return this._pos;
		}

		public set pos(pos: number) {
			this._pos = pos;
		}

		public get openTime(): number {
			return this._openTime;
		}

		public set openTime(openTime: number) {
			this._openTime = openTime;
		}

		public set lastUpdateTime(time:number) {
			this._lastUpdateTime = time;
		}

		public get lastUpdateTime():number {
			return this._lastUpdateTime
		}

		public getAccResCnt(sec: number = -1): number {
			if (sec == -1) {
				sec = this._openTime;
			}
			if (window.gameGlobal.channel == "lzd_handjoy") {
				return Math.ceil(sec / (10*60));
			} else {
				return Math.ceil(sec / (5*60));
			}
		}

		public get image(): string {
			let rare = this.getRareType();
			return `treasure_box${rare}_png`;
		}

		public fireUpdateEvent() {
			let ev = new TreasureEvent(Core.Event.UpdateTreasureEvt);
			ev.treasureItem = this;
			Core.EventCenter.inst.dispatchEvent(ev);
		}

		public getName(): string {
			//console.debug(`TreasureItem type=${this._type} name=${this._config.title}`);
			return this._config.title
		}

		public get isEffectByPrivilege(): boolean {
			return this._isEffectByPrivilege;
		}

		public set isEffectByPrivilege(b: boolean) {
			this._isEffectByPrivilege = b;
		}

		public getMinGoldCnt(): number {
			if (this._isEffectByPrivilege && Player.inst.hasPrivilege(Priv.TREASURE_ADD_GOLD)) {
				return Math.floor(this._config.goldMin * 1.1);
			} else {
				return this._config.goldMin;
			}
		}

		public getMaxGoldCnt(): number {
			if (this._isEffectByPrivilege && Player.inst.hasPrivilege(Priv.TREASURE_ADD_GOLD)) {
				return Math.floor(this._config.goldMax * 1.1);
			} else {
				return this._config.goldMax;
			}
		}

		public getMinJadeCnt(): number {
			return this._config.jadeMin;
		}

		public getMaxJadeCnt(): number {
			return this._config.jadeMax;
		}

		public getMinBowlderCnt(): number {
			return this._config.bowlderMin;
		}

		public getMaxBowlderCnt(): number {
			return this._config.bowlderMax;
		}

		public getCardNum(): number {
			if (this._isEffectByPrivilege && Player.inst.hasPrivilege(Priv.TREASURE_ADD_CARD)) {
				return this._config.cardCnt + 2;
			} else {
				return this._config.cardCnt;
			}
		}
		
		public getSkinNum(): number {
			let reward = <Array<number>>this._config.skin;
			if (reward.length > 0) {
				return reward.length;
			} else {
				return 0;
			}
		}

		public getHeadFrameNum(): number {
			let reward = <Array<number>>this._config.headFrame;
			if (reward.length > 0) {
				return reward.length;
			} else {
				return 0;
			}
		}

		public getEmojiNum(): number {
			let reward = <Array<number>>this._config.emojis;
			if (reward.length > 0) {
				return reward.length;
			} else {
				return 0;
			}
		}

		public getRareType(): number {
			return this._config.rare;
		}

		public getTeamType(): number {
			return this._config.team;
		}
		
		public getOpenNeedTime(): number {
			return this._config.reward_unlockTime;
		}

		public getNewCardNum(): number {
			let team = this.getTeamType();
			if (team == 1) {
				return 0;
			}
			let rare = this.getRareType();
			if (rare == 3) {
				return 1;
			} else if (rare == 4) {
				return 2;
			} else {
				return 0;
			}
		}

		public getCardstar1Num(): number {
			return this._config.cardStar1;
		}

		public getCardstar2Num(): number {
			return this._config.cardStar2;
		}

		public getCardstar3Num(): number {
			return this._config.cardStar3;
		}

		public getCardstar4Num(): number {
			return this._config.cardStar4;
		}

		public getCardstar5Num(): number {
			return this._config.cardStar5;
		}

		public getRareCardNum(): number {
			let rareCard = 0
			rareCard = this._config.cardStar5 + this._config.cardStar4 + this._config.cardStar3;
			return rareCard;
		}

		public isActivating(): boolean {
			return this._openTime > 0 && this._openTime < this.MAX_OPEN_TIME;
		}

		public canActivate(): boolean {
			return this._openTime > this.MAX_OPEN_TIME;
		}

		public getAccResType(): ResType {
			if (window.gameGlobal.channel == "lzd_handjoy") {
				return ResType.T_BOWLDER;
			} else {
				return ResType.T_JADE;
			}
		}

		public getAccResIcon(): string {
			let resType = this.getAccResType();
			return Utils.resType2Icon(resType);
		}

		public hasEnoughResToAcc(cnt: number) {
			let resType = this.getAccResType();
			if (resType == ResType.T_JADE) {
				return Player.inst.hasEnoughJade(cnt);
			} else {
				return Player.inst.hasEnoughBowlder(cnt, true);
			}
		}

		public async askSubAccRes(cnt: number, withHint: boolean = true): Promise<boolean> {
			let resType = this.getAccResType();
			if (resType == ResType.T_JADE) {
				if (Player.inst.hasEnoughJade(cnt)) {
					return true;
				} else {
					if (withHint) {
						Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60085));
					}
					return false;
				}
			} else {
				if (await Player.inst.askSubBowlder(cnt)) {
					return true;
				} else {
					if (withHint) {
						Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60278));
					}
					return false;
				}
			}
		}

		public canOpen(): boolean {
			if (this._openTime < 0) {
				// 星级奖励
				// TODO
				return false;
			} else {
				return this._openTime == 0;
			}
		}
	}

	export class DailyTreasureItem extends TreasureItem {
		
		protected _isOpen: boolean;
		protected _nextTime: number;
		protected _openStarCount: number;		// 打开还需要获取多少颗星
		protected _isDouble: boolean;
		
		public get openStarCount(): number {
			return this._openStarCount;
		}
		
		public set openStarCount(openStarCount: number) {
			this._openStarCount = openStarCount;
		}

		public get isOpen(): boolean {
			return this._isOpen;
		}

		public set isOpen(b: boolean) {
			this._isOpen = b;
		}

		public get nextTime(): number {
			return this._nextTime;
		}

		public set nextTime(n: number) {
			this._nextTime = n;
		}

		public get isDouble(): boolean {
			return this._isDouble;
		}

		public set isDouble(b: boolean) {
			this._isDouble = b;
		}

		public get totalStarCount(): number {
			return this._config.daily_unlockstar;
		}

		public get totalQuestCount(): number {
			return this._config.quest_unlockCnt;
		}

		public canOpen(): boolean {
			return this._openStarCount <= 0;
		}
	}
}