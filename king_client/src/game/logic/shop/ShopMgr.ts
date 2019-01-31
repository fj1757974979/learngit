module Shop {

	export class ShopMgr {

		private static _inst: ShopMgr = null;

		public static get inst(): ShopMgr {
			if (!ShopMgr._inst) {
				ShopMgr._inst = new ShopMgr();
			}
			return ShopMgr._inst;
		}

		private _jadeProducts: Collection.Dictionary<string, Payment.JadeProduct>;
		private _giftProducts: Collection.Dictionary<string, Payment.GiftProduct>;
		private _goldProducts: Collection.Dictionary<string, Payment.GoldProduct>;
		private _treasureProducts: Collection.Dictionary<string, Payment.TreasureProduct>;
		private _treasureIdToConfigId: Collection.Dictionary<string, any>;

		public constructor() {
			this._jadeProducts = new Collection.Dictionary<string, Payment.JadeProduct>();
			this._giftProducts = new Collection.Dictionary<string, Payment.GiftProduct>();
			this._goldProducts = new Collection.Dictionary<string, Payment.GoldProduct>();
			this._treasureProducts = new Collection.Dictionary<string, Payment.TreasureProduct>();
			this._treasureIdToConfigId = new Collection.Dictionary<string, any>();
		}

		private _initJadeProducts() {
			if (this._jadeProducts.isEmpty()) {
				let products = Payment.PayMgr.inst.getProducts();
				if (products) {
					products.forEach((productId, product) => {
						if (product.type == Payment.ProductType.T_JADE) {
							this._jadeProducts.setValue(product.id, <Payment.JadeProduct>product);
						}
					});
					
				}
			}
		}

		public getJadeProduct(id: string): Payment.JadeProduct {
			if (this._jadeProducts.isEmpty()) {
				this._initJadeProducts();
			}
			return this._jadeProducts.getValue(id);
		}

		private _initGiftProducts() {
			if (this._giftProducts.isEmpty()) {
				let products = Payment.PayMgr.inst.getProducts();
				if (products) {
					products.forEach((productId, product) => {
						if (product.type == Payment.ProductType.T_GIFT) {
							this._giftProducts.setValue(product.id, <Payment.GiftProduct>product);
						}
					});
				}
			}
		}

		public getGiftProduct(id: string): Payment.GiftProduct {
			if (this._giftProducts.isEmpty()) {
				this._initGiftProducts();
			}
			return this._giftProducts.getValue(id);
		}

		private _initTreasureProducts() {
			if (this._treasureProducts.isEmpty()) {
				let confs = null;
				if (window.gameGlobal.channel == "lzd_handjoy") {
					confs = Data.sold_treasure_handjoy;
				} else {
					confs = Data.sold_treasure;
				}
				let ids = confs.keys;
				ids.forEach(id => {
					let conf = confs.get(id);
					let product = new Payment.TreasureProduct(conf.treasureId, conf);
					this._treasureProducts.setValue(product.id, product);
				});
			}
		}

		public getTreasureProduct(type: string): Payment.TreasureProduct {
			if (this._treasureProducts.isEmpty()) {
				this._initTreasureProducts();
			}
			return this._treasureProducts.getValue(type);
		}

		private _initGoldProducts() {
			if (this._goldProducts.isEmpty()) {
				let ids: Array<number> = null;
				if (window.gameGlobal.channel == "lzd_handjoy") {
					let confs = Data.sold_gold_handjoy;
					confs.keys.forEach(id => {
						let conf = confs.get(id.toString());
						let product = new Payment.GoldProduct(id.toString(), conf);
						this._goldProducts.setValue(product.id, product);
					});
				} else {
					let confs = Data.sold_gold;
					confs.keys.forEach(id => {
						let conf = confs.get(id.toString());
						let product = new Payment.GoldProduct(id.toString(), conf);
						this._goldProducts.setValue(product.id, product);
					});
				}
				
			}
		}

		public getGoldProduct(id: string): any {
			if (this._goldProducts.isEmpty()) {
				this._initGoldProducts();
			}
			return this._goldProducts.getValue(id);
		}

		public static getProductResIconByConf(conf: {jadePrice:number, bowlderPrice:number}) {
			if (conf.bowlderPrice && conf.bowlderPrice > 0) {
				return Reward.RewardMgr.inst.getRewardIcon(Reward.RewardType.T_BOWLDER);
			} else {
				return Reward.RewardMgr.inst.getRewardIcon(Reward.RewardType.T_JADE);
			}
		}

		public static getProductResCntByConf(conf: {jadePrice:number, bowlderPrice:number}) {
			if (conf.bowlderPrice && conf.bowlderPrice > 0) {
				return conf.bowlderPrice;
			} else {
				return conf.jadePrice;
			}
		}
	}

	export function init() {
		initRpc();
		

        let registerView = Core.ViewManager.inst.registerView.bind(Core.ViewManager.inst);
        let createObject = fairygui.UIPackage.createObject;

		registerView(ViewName.advipInfo, () => {
			let giftVipInfoWnd = new GiftVipInfoWnd();
			giftVipInfoWnd.contentPane = fairygui.UIPackage.createObject(PkgName.shop, ViewName.advipInfo).asCom;
			return giftVipInfoWnd
		});

		registerView(ViewName.minivipInfo, () => {
			let giftMiniVipInfoWnd = new GiftMiniVipInfoWnd();
			giftMiniVipInfoWnd.contentPane = fairygui.UIPackage.createObject(PkgName.shop, ViewName.minivipInfo).asCom;
			return giftMiniVipInfoWnd
		});

		registerView(ViewName.shopView, () => {
			return createObject(PkgName.shop, ViewName.shopView, ShopView).asCom;
		});

		registerView(ViewName.shopGoldInfoWnd, () => {
			let goldInfoWnd = new GoldInfoWnd();
			goldInfoWnd.contentPane = createObject(PkgName.shop, ViewName.shopGoldInfoWnd).asCom;
			return goldInfoWnd;
		});

		registerView(ViewName.shopTreasureInfoWnd, () => {
			let treasureInfoWnd = new TreasureInfoWnd();
			treasureInfoWnd.contentPane = createObject(PkgName.shop, ViewName.shopTreasureInfoWnd).asCom;
			return treasureInfoWnd;
		});

		registerView(ViewName.freeGoldInfoWnd, () => {
			let freeGoldInfoWnd = new FreeGoldInfoWnd();
			freeGoldInfoWnd.contentPane = createObject(PkgName.shop, ViewName.freeGoldInfoWnd).asCom;
			return freeGoldInfoWnd;
		});

		
		registerView(ViewName.freeJadeInfoWnd, () => {
			let freeJadeInfoWnd = new FreeJadeInfoWnd();
			freeJadeInfoWnd.contentPane = createObject(PkgName.shop, ViewName.freeJadeInfoWnd).asCom;
			return freeJadeInfoWnd;
		});

		
		registerView(ViewName.freeTreasureInfoWnd, () => {
			let freeTreasureInfoWnd = new FreeTreasureInfoWnd();
			freeTreasureInfoWnd.contentPane = createObject(PkgName.shop, ViewName.freeTreasureInfoWnd).asCom;
			return freeTreasureInfoWnd;
		});

		registerView(ViewName.freeTreasureInfoFacebookWnd, () => {
			let freeTreasureInfoFacebookWnd = new FreeTreasureInfoFacebookWnd();
			freeTreasureInfoFacebookWnd.contentPane = createObject(PkgName.shop, ViewName.freeTreasureInfoFacebookWnd).asCom;
			return freeTreasureInfoFacebookWnd;
		});

		registerView(ViewName.resourceGetView, () => {
			return createObject(PkgName.shop, ViewName.resourceGetView, GetResAniWnd).asCom;
		});
	}
}