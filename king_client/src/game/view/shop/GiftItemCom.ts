module Shop {

	export class GiftItemCom extends fairygui.GComponent {

		// private _treasureImg: fairygui.GLoader;
		private _treasureNameText: fairygui.GTextField;
		private _priceText: fairygui.GTextField;
		private _restTimeText: fairygui.GTextField;
		// private _cardNum: fairygui.GTextField;
		private _treasure: Treasure.DailyTreasureItem;

		//new
		private _bg1: fairygui.GLoader;
		private _bg2: fairygui.GLoader;
		private _list: fairygui.GList;
		private _resIcon: fairygui.GLoader;

		private _product: Payment.GiftProduct;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._treasureNameText = this.getChild("treasureName").asTextField;
			this._priceText = this.getChild("price").asTextField;
			this._bg1 = this.getChild("bg1").asLoader;
			this._bg2 = this.getChild("bg2").asLoader;
			this._resIcon = this.getChild("resIcon").asLoader;
			this._list = this.getChild("list").asList;

			this._bg1.addClickListener(this._onBox, this);
			this._bg2.addClickListener(this._onBox, this);
			this.getChild("buy").asLoader.addClickListener(this._onBox, this);
			this.addEventListener(egret.TouchEvent.TOUCH_BEGIN, () => {
				this.getTransition("t0").play();
			}, this);

			if (!LanguageMgr.inst.isChineseLocale()) {
				this._treasureNameText.fontSize = 14;
			}
		}

		public setProduct(product: Payment.GiftProduct) {

			this._treasureNameText.text = product.desc;
			this._bg1.url = `shop_${product.bgImage1}_png`;
			if (product.bgImage2) {
				this._bg2.url = `shop_${product.bgImage2}_png`;
			} else {
				this._bg2.url = ``;
			}

			if (product.isNotMoneyPay()) {
				this._priceText.text = `${product.price}`;
				if (product.hasEnoughResToBuy()) {
					this._priceText.color = 0xffffff;
				} else {
					this._priceText.color = 0xff0000;
				}
			} else {
				this._priceText.text = `${product.localizedPrice}`;
			}

			this._resIcon.url = product.resIcon;
			
			if (product.icon) {
				let treasureType = product.treasureType;
				let _com = fairygui.UIPackage.createObject(PkgName.shop, "giftCnt").asCom;
				let treasureData = new Pvp.SeasonTreasureInfo(Data.treasure_config.get(product.treasureType));
				_com.getChild("treasureIcon").asLoader.url = `treasure_box${treasureData.rare}_png`;
				_com.getChild("treasureName").asTextField.text = treasureData.title;

				_com.addClickListener(() => {
					Core.ViewManager.inst.open(ViewName.shopTreasureInfoWnd, product, () => {
						if (this._product.isNotMoneyPay()) {
							this._onJadePay();
						} else {
							this._onPay();
						}
					})
				}, this);
				this._list.addChild(_com);
			}
			if (product.general.length > 0) {
				let _com = fairygui.UIPackage.createObject(PkgName.shop, "cardCnt").asCom as CardCntCom;
				let cardData = CardPool.CardPoolMgr.inst.getCardData(parseInt(product.general[0]),1);
				let cardCnt = parseInt(product.general[1]);
				_com.setCardInfo(cardData.__id__, cardCnt);
				this._list.addChild(_com);
			}
			if (product.glod) {
				let _com = fairygui.UIPackage.createObject(PkgName.shop, "goldCnt").asCom as GoldCntCom;
				let goldCnt = product.glod;
				_com.setGoldInfo(product.glod);
				this._list.addChild(_com);
			}
			if (product.jade) {
				let _com = fairygui.UIPackage.createObject(PkgName.shop, "jadeCnt").asCom as JadeCntCom;
				let jadeCnt = product.jade;
				_com.setJadeInfo(jadeCnt);
				this._list.addChild(_com);
			}
			if (product.skin) {
				let _com = fairygui.UIPackage.createObject(PkgName.shop, "skinCnt").asCom;
				let cardObj = _com.getChild("card").asCom;
				Utils.setImageUrlPicture(cardObj.getChild("cardImg").asImage, `skin_m_${product.skin}_png`);
				cardObj.getChild("nameText").asTextField.text = CardPool.CardSkinMgr.inst.getSkinConf(product.skin).name;
				_com.getChild("title").asTextField.text = "x1";
				this._list.addChild(_com);

				let card = CardPool.CardPoolMgr.inst.getCollectCard(CardPool.CardSkinMgr.inst.getSkinConf(product.skin).general);
				Core.ViewManager.inst.open(ViewName.skinView, card, product.skin);
			}

			this._product = product;
		}

		private _onBox() {
			let conf = Data.treasure_config.get(this._product.id);
			
			Core.ViewManager.inst.open(ViewName.shopTreasureInfoWnd, this._product, () =>{
				if (this._product.isNotMoneyPay()) {
					this._onJadePay();
				} else {
					this._onPay();
				}
			} );
		}

		private async _onJadePay() {
			let myTeam = Pvp.Config.inst.getPvpTeam(Pvp.PvpMgr.inst.getPvpLevel());

			if (myTeam < this._product.payTeamLv) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70127));
				return;
			}

			this._onBuy();
		}

		private async _onBuy() {
			let args = {
				GiftID: this._product.treasureType
			}
			let result = await Net.rpcCall(pb.MessageID.C2S_BUY_LIMIT_GITF_BY_JADE, pb.BuyLimitGiftByJadeArg.encode(args));
			if (result.errcode == 0) {
				let reply = pb.BuyLimitGiftReply.decode(result.payload);
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60095));
				let reward = new Treasure.TreasureReward();
				reward.setRewardForOpenReply(reply.GiftReward);

				Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward, new Treasure.TreasureItem(-1, this._product.treasureType));
				Core.EventCenter.inst.dispatchEventWith(GameEvent.LimitGiftSoldOutEv);
				let shopView = <ShopView>Core.ViewManager.inst.getView(ViewName.shopView);
				shopView.onBuyGift();
			} else {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60081));
			}
		}

		private async _onPay() {
			let payResult = await Payment.PayMgr.inst.payProduct(this._product.id, 1);
			if (payResult.success) {
				let reply = null;
				// if (window.gameGlobal.isSDKPay) {
				if (!Payment.PayMgr.inst.needSendBuyRpc()) {
					let payload = <pb.SdkRechargeResult>payResult.param;
					reply = payload.LimitGift;
				} else {
					let args = {
						GiftID: this._product.treasureType,
						Receipt: payResult.result
					}
					let result = await Net.rpcCall(pb.MessageID.C2S_BUY_LIMIT_GITF, pb.BuyLimitGiftArg.encode(args));
					if (result.errcode == 0) {
						reply = pb.BuyLimitGiftReply.decode(result.payload);
					}
				}

				if (reply) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60073));
					let reward = new Treasure.TreasureReward();
					reward.gold = reply.GiftReward.GoldAmount;
					reward.jade = reply.GiftReward.Jade;
					reply.GiftReward.CardIDs.forEach(cardId => {
						reward.addCardId(cardId);
					});
					reward.shareId = reply.GiftReward.ShareHid;
					Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward, new Treasure.TreasureItem(-1, this._product.treasureType));
					Core.EventCenter.inst.dispatchEventWith(GameEvent.LimitGiftSoldOutEv);
					// if (reply.NextGift) {
					// 	let product = ShopMgr.inst.getGiftProduct(reply.NextGift.GiftID);
					// 	if (product) {
					// 		product.remainTime = reply.NextGift.RemainTime;
					// 		product.price = reply.NextGift.Price;
					// 		Core.EventCenter.inst.dispatchEventWith(GameEvent.RefreshLimitGiftEv, false, product);
					// 	} else {
					// 		egret.log(`can't find next gift ${reply.NextGift.GiftID}`);
					// 		Core.EventCenter.inst.dispatchEventWith(GameEvent.LimitGiftSoldOutEv);
					// 	}
					// } else {
					// 	Core.EventCenter.inst.dispatchEventWith(GameEvent.LimitGiftSoldOutEv);
					// }
					let shopView = <ShopView>Core.ViewManager.inst.getView(ViewName.shopView);
					shopView.onBuyGift();
				} else {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60116));
				}
			} else {
				Core.TipsUtils.showTipsFromCenter(payResult.result);
			}
		}

		public get treasure(): Treasure.DailyTreasureItem {
			return this._treasure;
		}
	}
}
