module Payment {
	export class ProductType {
		public static T_UNKOWN = 0;
		public static T_JADE = 1;
		public static T_GIFT = 2;
		public static T_GOLD = 3;
		public static T_TREASURE = 4;
		public static T_FREE = 5;
	}

	export class Product {

		protected _id: string;
		protected _localizedPrice: string;
		protected _localizedPriceAmount: number;
		protected _currency: string;
		protected _conf: any;
		protected _type: ProductType;
		protected _price: number;
		
		public constructor(id: string, conf: any) {
			this._id = id;
			this._conf = conf;
			this._type = ProductType.T_UNKOWN;
			this._price = 0;
			this._localizedPriceAmount = 0;
			this._currency = "CNY";
		}

		public get id(): string {
			return this._id;
		}

		public get localizedPrice(): string {
			return this._localizedPrice;
		}

		public set localizedPrice(lp: string) {
			this._localizedPrice = lp;
		}

		public get localizedPriceAmount(): number {
			return this._localizedPriceAmount;
		}

		public set localizedPriceAmount(price: number) {
			this._localizedPriceAmount = price;
		}

		public get currency(): string {
			return this._currency;
		}

		public set currency(cu: string) {
			this._currency = cu;
		}

		public get price(): number {
			if (this._price <= 0) {
				return this._conf.price;
			} else {
				return this._price;
			}
		}

		public set price(price: number) {
			this._price = price;
		}

		public get type(): ProductType {
			return this._type;
		}

		public get desc(): string {
			return this._conf.desc;
		}

		public get conf(): any {
			return this._conf;
		}

		public hasEnoughResToBuy(): boolean {
			return true;
		}

		public async askSubRes(withHint: boolean = true): Promise<boolean> {
			return true;
		}

		public static newProduct(productId: string, conf: any) {
			if (productId.indexOf("gift") >= 0 || productId.indexOf("vip") >= 0) {
				return new GiftProduct(productId, conf);
			} else {
				return new JadeProduct(productId, conf);
			}
		}
	}

	export class MoneyPayProduct extends Product {

	}

	export class ResPayProduct extends Product {
		protected _resType: ResType;
		protected _resIcon: string;

		public constructor(id: string, conf: any) {
			super(id, conf);
			 if (conf.jadePrice && conf.jadePrice > 0) {
				this._resType = ResType.T_JADE;
				this._price = conf.jadePrice;
				this._resIcon = Reward.RewardMgr.inst.getRewardIcon(Reward.RewardType.T_JADE);
			} else {
				this._resType = ResType.T_BOWLDER;
				this._price = conf.bowlderPrice;
				this._resIcon = Reward.RewardMgr.inst.getRewardIcon(Reward.RewardType.T_BOWLDER);
			}
		}

		public get resIcon(): string {
			return this._resIcon;
		}

		public get price(): number {
			return this._price;
		}

		public hasEnoughResToBuy(): boolean {
			if (this._resType == ResType.T_JADE) {
				return Player.inst.hasEnoughJade(this._price);
			} else {
				return Player.inst.hasEnoughBowlder(this._price, true);
			}
		}

		public async askSubRes(withHint: boolean = true): Promise<boolean> {
			if (this._resType == ResType.T_JADE) {
				if (Player.inst.hasEnoughJade(this._price)) {
					return true;
				} else {
					if (withHint) {
						Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60085));
					}
					return false;
				}
			} else {
				if (await Player.inst.askSubBowlder(this._price)) {
					return true;
				} else {
					if (withHint) {
						Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60278));
					}
				}
			}
		}
	}

	export class TreasureProduct extends ResPayProduct {

		public constructor(id: string, conf: any) {
			super(id, conf);
			this._type = ProductType.T_TREASURE;
		}
	}

	export class GoldProduct extends ResPayProduct {
		public constructor(id: string, conf: any) {
			super(id, conf);
			this._type = ProductType.T_GOLD;
		}

		public get soldGold(): number {
			return this._conf.soldGold;
		}

		public get icon(): string {
			return this._conf.icon;
		}
	}

	export class JadeProduct extends MoneyPayProduct {
		private _jade: number;
		public constructor(id: string, conf: any) {
			super(id, conf);
			this._type = ProductType.T_JADE;
			this._jade = 0;
		}

		public get jade(): number {
			if (this._jade <= 0) {
				return this._conf.jadeCnt;
			} else {
				return this._jade;
			}
		}

		public set jade(jade: number) {
			this._jade = jade;
		}

		public get desc(): string {
			return this._conf.desc;
		}

		public get icon(): string {
			return this._conf.icon;
		}
	}

	export class GiftProduct extends ResPayProduct {
		private _remainTime: number;
		private _name: string;

		public constructor(id: string, conf: any) {
			super(id, conf);
			this._type = ProductType.T_GIFT;
			this._name = conf.name;
		}
		
		//new
		public get bgImage1(): string {
			return this._conf.bg1;
		}
		public get bgImage2(): string {
			if (this._conf.bg2) {
				return this._conf.bg2;
			} else {
				return "";
			}
		}

		public isVipCard(): boolean {
			return this._id == "advip";
		}
		public isMiniVipCard(): boolean {
			return this._id == "minivip";
		}
		public get icon(): string {
			return this._conf.icon;
		}
		public get glod(): number {
			return this._conf.gold;
		}
		public get jade(): number {
			return this._conf.jade;
		}
		public get skin(): string {
			return this._conf.skin;
		}
		public get headFrame(): string {
			return this._conf.headFrame;
		}
		public get showTeamLv(): number {
			return this._conf.showTrue;
		}
		public get payTeamLv(): number {
			return this._conf.teamCondition;
		}
		public get hideTeamLv(): number {
			return this._conf.showFalse;
		}
		public get continueTime(): number {
			return this._conf.continueTime;
		}
		public get general(): Array<string> {
			let arr = new Array<string>();
			if (this._conf.general) {
				arr = this._conf.general;
			}
			return arr;
		}
		public get name(): string {
			return this._name;
		}
		//old
		public get treasureType(): string {
			return this._conf.reward;
		}

		// public get iconInfo(): Array<any> {
		// 	let info = this._conf.icon;
		// 	let ret = [];
		// 	ret.push(info[0]);
		// 	ret.push(parseInt(info[1]));
		// 	return ret;
		// }

		// public get requirePvpTeam(): number {
		// 	return this._conf.teamCondition;
		// }

		public get remainTime(): number {
			return this._remainTime;
		}

		public set remainTime(time: number) {
			this._remainTime = time;
		}

		public get refreshInterval(): number {
			return this._conf.refreashTime;
		}

		public get jadePrice(): number {
			return this._conf.jadePrice;
		}

		public isVisible(): boolean {
			return this._conf.visiable == 1;
		}

		public isNotMoneyPay(): boolean {
			return GiftProduct.isNotMoneyPay();
		}

		public hasEnoughResToBuy(): boolean {
			if (this.isNotMoneyPay()) {
				return super.hasEnoughResToBuy();
			} else {
				return true;
			}
		}

		public async askSubRes(withHint: boolean = true): Promise<boolean> {
			if (this.isNotMoneyPay()) {
				return await super.askSubRes(withHint);
			} else {
				return true;
			}
		}

		public static isNotMoneyPay(): boolean {
			if (window.gameGlobal.channel == "lzd_handjoy") {
				return true;
			} else {
				return true;
			}
		}
	}
}