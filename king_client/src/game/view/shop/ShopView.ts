module Shop {
	export class ShopView extends Core.BaseView {

		private _shopList: fairygui.GList;
		private _goldText: fairygui.GTextField;
		private _jadeText: fairygui.GTextField;
		private _bowlderText: fairygui.GTextField;
		private _closeBtn: fairygui.GButton;
		private _giftList: fairygui.GList;
		private _curListIndex: number;

		private _giftSellCom: GiftSellCom;
		private _freeSellCom: FreeSellCom;
		private _jadeSellCom: JadeSellCom;
		private _treasureSellCom: TreasureSellCom;
		private _goldSellCom: GoldSellCom;

		private _refreshing: boolean;

		public initUI() {
			super.initUI();
			this.adjust(this.getChild("bg"), Core.AdjustType.EXCEPT_MARGIN);
			this.y += window.support.topMargin;
			this._shopList = this.getChild("shopList").asList;
			this._goldText = this.getChild("goldText").asTextField;
			this._jadeText = this.getChild("jadeText").asTextField;
			this._bowlderText = this.getChild("bowlderText").asTextField;
			this._closeBtn = this.getChild("closeBtn").asButton;

			this._giftSellCom = null;
			this._jadeSellCom = null;
			this._treasureSellCom = null;
			this._goldSellCom = null;

			this._refreshing = false;

			this._closeBtn.addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			}, this);

			Player.inst.addEventListener(Player.ResUpdateEvt, this._onResUpdate, this);
			Core.EventCenter.inst.addEventListener(GameEvent.LimitGiftSoldOutEv, () => {
				// if (this._giftSellCom) {
				// 	if (this._shopList) {
				// 		this._shopList.removeChild(this._giftSellCom);
				// 	}
				// }
				this._refresh();
			}, this);

			Core.EventCenter.inst.addEventListener(GameEvent.RefreshSoldTreasureEv, (evt: egret.Event) => {
				this._refresh();
			}, this);

			Core.EventCenter.inst.addEventListener(GameEvent.RefreshLimitGiftEv, (evt: egret.Event) => {
				this._refresh();
			}, this);

			this.getChild("bowlderText").visible = Home.hasBowlderRes();
            this.getChild("bowlderIcon").visible = Home.hasBowlderRes();
		}

		public updateFreeItemCanGetState(freeId: number, freeType: number) {
			if (this._freeSellCom) {
				// console.log("updateFreeItemCanGetState", freeId, freeType);
				this._freeSellCom.updateFreeItemCanGetState(freeId, freeType);
			}
		}

		private async _refresh() {
			if (this._refreshing) {
				return;
			}
			this._refreshing = true;
			this._shopList.removeChildren();
			this._giftSellCom = null;
			this._jadeSellCom = null;
			this._treasureSellCom = null;
			this._goldSellCom = null;

			this._onResUpdate();

			let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_SHOP_DATA, null);
			if (result.errcode != 0) {
				this._refreshing = false;
				return;
			}

			let openPayForUser = true;
			if (Core.DeviceUtils.isWXGame()) {
				// 苹果平台且不在白名单且没有充值记录的不显示充值入口
				if (WXGame.WXGameMgr.inst.platform != "android") {
					if (!WXGame.WXGameMgr.inst.isInHuoshuWhiteList && Player.inst.cumulativePay <= 0) {
						openPayForUser = false;
					}
				}
			}
			let reply = pb.ShopData.decode(result.payload);

			// egret.log(JSON.stringify(reply));
			//new gift
			let giftProducts = new Array<Payment.GiftProduct> ();
			let vipGift = null;
			let miniVipGift = null;
			if (reply.VipCard && Home.FunctionMgr.inst.isVipCardOpen()) {
				
				// if (!Player.inst.vipTime) {
				// 	await Player.inst.getVipTime();
				// }
				// if (!Player.inst.isVip || Player.inst.vipTime != -1) {
					vipGift = new pb.LimitGift();
					vipGift.GiftID = reply.VipCard.GoodsID;
					vipGift.Price = reply.VipCard.JadePrice;
					// reply.Gift.push(vipGift);
				// }
			}
			if ((vipGift || reply.Gift.length > 0) && Home.FunctionMgr.inst.isShopGiftOpen()) {
				let products = new Array<Payment.GiftProduct>();
				let maxLv = Pvp.PvpMgr.inst.getPvpLevel();
				let _myTeam = Pvp.Config.inst.getPvpTeam(maxLv);
				if (vipGift) {
					let product = ShopMgr.inst.getGiftProduct(vipGift.GiftID);
					if (product) {
						product.remainTime = vipGift.RemainTime;
						products.push(product);
					}
				}

				reply.Gift.forEach(giftData => {
					let product = ShopMgr.inst.getGiftProduct(giftData.GiftID);
					if (product && product.isVisible()) {
						if (_myTeam >= product.showTeamLv  && (_myTeam <= product.hideTeamLv || product.hideTeamLv == 0)) {
							product.remainTime = giftData.RemainTime;
							if (product.isMiniVipCard()) {
								miniVipGift = product;
							} else {
								products.push(product);
							}
						}
					}
				});
				if (miniVipGift) {
					products = [miniVipGift].concat(products);
				}
				if (products.length > 0) {
					let com = fairygui.UIPackage.createObject(PkgName.shop, "purchase", GiftSellCom).asCom as GiftSellCom;
					com.setGiftProducts(products);
					this._shopList.addChild(com);
					this._giftSellCom = com;
					await com.playTrans();
					fairygui.GTimers.inst.remove(this._nextGift, this);
					if (products.length > 1) {
						this._giftList = com.getChild("list").asList;
						this._curListIndex = 0;
						fairygui.GTimers.inst.add(3000, this._curListIndex,  this._nextGift, this);
					}

				}
			}
			if (reply.Adses.length > 0 && !Player.inst.isNewVersionPlayer()) { //} && !window.gameGlobal.isMultiLan) {
				let com = fairygui.UIPackage.createObject(PkgName.shop, "free", FreeSellCom).asCom as FreeSellCom;
				com.setFreeSellData(<Array<pb.ShopFreeAds>>reply.Adses);
				this._shopList.addChild(com);
				this._freeSellCom = com;
				await com.playTrans();
			}

			if (reply.SoldTreasures.length > 0) {
				let configs = [];
				let products: Array<Payment.TreasureProduct> = [];
				reply.SoldTreasures.forEach(treasureData => {
					let type = treasureData.TreasureModelID;
					let product = ShopMgr.inst.getTreasureProduct(type);
					if (product) {
						products.push(product);
					}
				});
				if (products.length > 0) {
					let com = fairygui.UIPackage.createObject(PkgName.shop, "treasure", TreasureSellCom).asCom as TreasureSellCom;
					com.setTreasureProducts(products);
					if (reply.SoldTreasureRemainTime > 0) {
						com.setCanBuyMode(false, reply.SoldTreasureRemainTime);
					}
					this._shopList.addChild(com);
					this._treasureSellCom = com;
					await com.playTrans();
				}
			}
			// if (reply.JadeGoodsList.length > 0 && openPayForUser) {
			if (reply.JadeGoodsList.length > 0 && Home.FunctionMgr.inst.isInAppPurchaseOpen()) {
				let products: Array<Payment.JadeProduct> = [];
				reply.JadeGoodsList.forEach(jadeData => {
					let product = ShopMgr.inst.getJadeProduct(jadeData.GoodsID);
					if (product) {
						if ((product.id == `advip` && !(Player.inst.isVip)) || product.id != `advip`) {
							product.price = jadeData.Price;
							product.jade = jadeData.Jade;
							products.push(product);
						}
					}
				});
				if (products.length > 0) {
					let com = fairygui.UIPackage.createObject(PkgName.shop, "jade", JadeSellCom).asCom as JadeSellCom;
					com.setJadeProducts(products);
					this._shopList.addChild(com);
					this._jadeSellCom = com;
					await com.playTrans();
				}
			}

			if (reply.GoldGoodsList.length > 0) {
				let products: Array<Payment.GoldProduct> = [];
				reply.GoldGoodsList.forEach(goldData => {
					let product = ShopMgr.inst.getGoldProduct(goldData.GoodsID);
					if (product) {
						products.push(product);
					} else {
						console.error("can't find gold product " + goldData.GoodsID);
					}
				});
				if (products.length > 0) {
					let com = fairygui.UIPackage.createObject(PkgName.shop, "gold", GoldSellCom).asCom as GoldSellCom;
					com.setGoldProducts(products);
					if (reply.BuyGoldRemainTime > 0) {
						com.setCanBuyMode(false, reply.BuyGoldRemainTime);
					}
					this._shopList.addChild(com);
					this._goldSellCom = com;
					await com.playTrans();
				}
			}
			this._refreshing = false;
		}

		public async open(...param: any[]) {
			await super.open(...param);
			this._refresh();
		}

		private _onResUpdate() {
			this._goldText.text = `${Player.inst.getResource(ResType.T_GOLD)}`;
			this._jadeText.text = `${Player.inst.getResource(ResType.T_JADE)}`;
			this._bowlderText.text = `${Player.inst.getResource(ResType.T_BOWLDER)}`;
		}

		public async onBuyGold(gold: number) {
			let args = new Pvp.GetRewardData();
			args.gold = gold;
			Core.ViewManager.inst.open(ViewName.getRewardWnd, args);
			// Core.ViewManager.inst.open(ViewName.resourceGetView, ResType.T_GOLD, this._goldIconImg.y - 10);
			// fairygui.GTimers.inst.add(1.75 * 1000, 1, () => {
			// 	// 0.47s
			// 	let du = 470; // ms
			// 	let interval = 10;
			// 	let step = gold / du * interval;
			// 	let from = Player.inst.getResource(ResType.T_GOLD) - gold;
			// 	let to = from + gold;
			// 	this._goldText.text = `${from}`;
			// 	fairygui.GTimers.inst.add(interval, du / interval, () => {
			// 		from = from + step;
			// 		this._goldText.text = `${Math.floor(from)}`;
			// 	}, this);
			// }, this);
			// this.getTransition("gold").play();
		}

		public onBuyJade(jade: number) {
			let args = new Pvp.GetRewardData();
			args.jade = jade;
			Core.ViewManager.inst.open(ViewName.getRewardWnd, args);
			// Core.ViewManager.inst.open(ViewName.resourceGetView, ResType.T_JADE, this._jadeIconImg.y - 10);
			// fairygui.GTimers.inst.add(1.75 * 1000, 1, () => {
			// 	// 0.47s
			// 	let du = 470; // ms
			// 	let interval = 10;
			// 	let step = jade / du * interval;
			// 	let from = Player.inst.getResource(ResType.T_JADE) - jade;
			// 	let to = from + jade;
			// 	this._jadeText.text = `${from}`;
			// 	fairygui.GTimers.inst.add(interval, du / interval, () => {
			// 		from = from + step;
			// 		this._jadeText.text = `${Math.ceil(from)}`;
			// 	}, this);
			// }, this);
			// this.getTransition("jade").play();
		}

		public onBuyTreasure() {
			this._onResUpdate();
		}

		public onBuyGift() {
			this._onResUpdate();
		}

		private _nextGift() {
			let a = this._giftList.scrollPane.percX;
			let b = a * (this._giftList.numItems - 1);
			let c = Math.round(b);
			if (this._curListIndex != c) {
				this._curListIndex = c;
			} else {
				this._curListIndex += 1;
				if (this._curListIndex >= this._giftList.numItems) {
					this._curListIndex = 0;
				}
				this._giftList.scrollToView(this._curListIndex, true);
			}

		}

		public async close(...param: any[]) {
			super.close(...param);
			
			if (this._giftSellCom) {
				this._giftSellCom.onDestroy();
				this._giftSellCom = null;
			}
			if (this._jadeSellCom) {
				this._jadeSellCom.onDestroy();
				this._jadeSellCom = null;
			}
			if (this._treasureSellCom) {
				this._treasureSellCom.onDestroy();
				this._treasureSellCom = null;
			}
			if (this._goldSellCom) {
				this._goldSellCom.onDestroy();
				this._goldSellCom = null;
			}

			if (this._freeSellCom) {
				this._freeSellCom.onDestroy();
				this._freeSellCom = null;
			}

			this._shopList.removeChildren(0, -1, true);
			
			this._refreshing = false;

			fairygui.GTimers.inst.remove(this._nextGift, this);
			this._giftList = null;
		}
	}
}
