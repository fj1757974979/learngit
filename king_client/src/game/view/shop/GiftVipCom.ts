module Shop {

	export class GiftVipInfoWnd extends Core.BaseWindow {

		private _privCom: Social.PrivCom;
		private _titleText: fairygui.GTextField;
		private _buyBtn: fairygui.GButton;
		private _payBtn: fairygui.GButton;

		private _product: Payment.GiftProduct;
		private _callback: () => void;

		public initUI():void {
			super.initUI();
			this.modal = true;
			this.center();
			this._privCom = this.contentPane.getChild("priv").asCom as Social.PrivCom;
			this._privCom.setPriv(Social.PrivType.vip);
			this._buyBtn = this.contentPane.getChild("btnBuy").asButton;
			this._payBtn = this.contentPane.getChild("btnPay").asButton;

			this.adjust(this.contentPane.getChild("closeBg"));
			this.contentPane.getChild("closeBg").addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			},this);
			this._buyBtn.addClickListener(this._onBuy, this);
			this._payBtn.addClickListener(this._onPay, this);
		}

		public async open(...param: any[]) {
			await super.open(...param);
			let product = <Payment.GiftProduct>param[0];
			this._callback = param[1];
			let treasureType = product.treasureType;

			this._product = product;
			if (product.isNotMoneyPay()) {
				this._buyBtn.visible = true;
				this._payBtn.visible = false;
				this._buyBtn.title = `${product.jadePrice}`;
				if (Player.inst.getResource(ResType.T_JADE) < product.jadePrice) {
					this._buyBtn.getChild("title").asTextField.color = 0xff0000;
				} else {
					this._buyBtn.getChild("title").asTextField.color = 0xffffff;
				}
			} else {
				this._buyBtn.visible = false;
				this._payBtn.visible = true;
				this._payBtn.title = `${product.localizedPrice}`;
			}
		}

		private async _onPay() {
			if (this._callback) {
				this._callback();
			}
			Core.ViewManager.inst.closeView(this);
		}

		private async _onBuy() {
			if (!Player.inst.hasEnoughJade(this._product.jadePrice)) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60085));
				return;
			}
			let result = await Net.rpcCall(pb.MessageID.C2S_BUY_VIP_CARD, null);
			if (result.errcode == 0) {
				let reply = pb.BuyVipCardReply.decode(result.payload);
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60095));
				let rewardData = new Pvp.GetRewardData();
				 rewardData.addHeadFrame(reply.HeadFrame);
				 let vipData = Payment.PayMgr.inst.getProducts().getValue("advip") as Payment.GiftProduct;
				 rewardData.addOther(vipData.name, `shop_${vipData.icon}_png`);
                Core.ViewManager.inst.open(ViewName.getRewardWnd, rewardData);
				Core.EventCenter.inst.dispatchEventWith(GameEvent.LimitGiftSoldOutEv);
				// Player.inst.isVip = true;
				Player.inst.vipTime = reply.RemainTime;
				let shopView = <ShopView>Core.ViewManager.inst.getView(ViewName.shopView);
				shopView.onBuyGift();
				Core.ViewManager.inst.closeView(this);
			} else {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60081));
			}
		}

		public async close(...param: any[]) {
			await super.close(...param);
			this._product = null;
			this._callback = null;
		}
	}

	export class GiftMiniVipInfoWnd extends Core.BaseWindow {
		private _privCom: Social.PrivCom;
		private _titleText: fairygui.GTextField;
		private _buyBtn: fairygui.GButton;

		private _product: Payment.GiftProduct;
		private _callback: () => void;

		public initUI():void {
			super.initUI();
			this.modal = true;
			this.center();

			this._buyBtn = this.contentPane.getChild("btnBuy").asButton;
			this._privCom = this.contentPane.getChild("priv").asCom as Social.PrivCom;
			this._privCom.setPriv(Social.PrivType.miniVip);

			this.adjust(this.contentPane.getChild("closeBg"));
			this.contentPane.getChild("closeBg").addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			},this);
			this._buyBtn.addClickListener(this._onBuy, this);
		}

		private async _onBuy() {
			if (!Player.inst.hasEnoughJade(this._product.jadePrice)) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60085));
				return;
			}
			let args = {
				GiftID: this._product.treasureType
			}
			let result = await Net.rpcCall(pb.MessageID.C2S_BUY_LIMIT_GITF_BY_JADE, pb.BuyLimitGiftByJadeArg.encode(args));
			if (result.errcode == 0) {
				Core.ViewManager.inst.closeView(this);
				let reply = pb.BuyLimitGiftReply.decode(result.payload);
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60095));
				let reward = new Treasure.TreasureReward();
				reward.setRewardForOpenReply(reply.GiftReward);

				let rewardData = new Pvp.GetRewardData();
				rewardData.addOther(this._product.name, `shop_${this._product.icon}_png`, this._product.desc);
				Core.ViewManager.inst.open(ViewName.getRewardWnd, rewardData, () => {
					Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward, new Treasure.TreasureItem(-1, this._product.treasureType));
					Core.EventCenter.inst.dispatchEventWith(GameEvent.LimitGiftSoldOutEv);
					let shopView = <ShopView>Core.ViewManager.inst.getView(ViewName.shopView);
					shopView.onBuyGift();
				});	
			} else {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60081));
			}
		}

		public async open(...param: any[]) {
			await super.open(...param);
			let product = <Payment.GiftProduct>param[0];
			this._callback = param[1];
			let treasureType = product.treasureType;

			this._product = product;
			this._buyBtn.visible = true;
			this._buyBtn.title = `${product.jadePrice}`;
			if (!Player.inst.hasEnoughJade(product.jadePrice)) {
				this._buyBtn.getChild("title").asTextField.color = 0xff0000;
			} else {
				this._buyBtn.getChild("title").asTextField.color = 0xffffff;
			}
		}

		public async close(...param: any[]) {
			await super.close(...param);
		}
	}

	export class GiftVipCom extends fairygui.GComponent {

		private _priceText: fairygui.GTextField;
		private _dayText: fairygui.GTextField;
		private _remainDayText: fairygui.GTextField;

		private _product: Payment.GiftProduct;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			
			this._priceText = this.getChild("price").asTextField;
			this._dayText = this.getChild("day").asTextField;
			this._remainDayText = this.getChild("time").asTextField;

			this.addClickListener(this._onJadePay, this);
			this.getChild("buy").asLoader.addClickListener(()=> {
				if (this._product.isNotMoneyPay()) {
					this._onJadePay();
				} else {
					if (this._product.isVipCard()) {
						Core.ViewManager.inst.open(ViewName.advipInfo, this._product, () => {
							this._onPay();
						});
					} else {
						Core.ViewManager.inst.open(ViewName.advipInfo, this._product, () => {
							this._onPay();
						});
					}
				}
			}, this);

			this.addEventListener(egret.TouchEvent.TOUCH_BEGIN, () => {
				this.getTransition("t0").play();
			}, this);
		}

		public setProduct(product: Payment.GiftProduct) {
			if (product.isNotMoneyPay()) {
				this._priceText.text = `${product.jadePrice}`;
				if (Player.inst.hasEnoughJade(product.jadePrice)) {
					this._priceText.color = 0xffffff;
				} else {
					this._priceText.color = 0xff0000;
				}
			} else {
				this._priceText.text = `${product.localizedPrice}`;
			}

			if (product.isVipCard()) {
				if (window.gameGlobal.channel == "lzd_handjoy" ||
				 	Player.inst.isNewVersionPlayer()) {
					this._dayText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60382), 30);
				} else {
					this._dayText.text = "";
				}
			} else {
				this._dayText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60382), 7);
			}

			this._product = product;

			this._setVipRemainTime();
			this._startCountDown();
		}

		private _startCountDown() {
			fairygui.GTimers.inst.remove(this._setVipRemainTime, this);
			fairygui.GTimers.inst.add(1000, -1, this._setVipRemainTime, this);
		}

		private _setVipRemainTime() {
			if (this._product.isVipCard()) {
				if (Player.inst.isVip) {
					this._remainDayText.text = "剩余" + Core.StringUtils.secToString(Player.inst.vipTime, "dhm");
				} else {
					this._remainDayText.text = "";
				}
			} else if (this._product.isMiniVipCard()) {
				if (Player.inst.isMiniVip) {
					this._remainDayText.text = Core.StringUtils.secToString(Player.inst.miniVipTime, "dhm");
				} else {
					this._remainDayText.text = "";
				}
			} else {
				this._remainDayText.text = "";
			}
		}

		private async _onJadePay() {
			if (this._product.isVipCard()) {
				Core.ViewManager.inst.open(ViewName.advipInfo, this._product);
			} else {
				Core.ViewManager.inst.open(ViewName.minivipInfo, this._product);
			}
		}

		private async _onPay() {
			let payResult = await Payment.PayMgr.inst.payProduct(this._product.id, 1);
			if (payResult.success) {
				let reply = null;
				if (!Payment.PayMgr.inst.needSendBuyRpc()) {
					let payload = <pb.SdkRechargeResult>payResult.param;
					reply = payload.LimitGift;
				} else {
					let result = await Net.rpcCall(pb.MessageID.C2S_BUY_VIP_CARD, null);
					if (result.errcode == 0) {
						reply = pb.BuyLimitGiftReply.decode(result.payload);
					}
				}

				if (reply) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60095));
					Core.EventCenter.inst.dispatchEventWith(GameEvent.LimitGiftSoldOutEv);
					// Player.inst.isVip = true;
					Player.inst.vipTime = -1;
					let shopView = <ShopView>Core.ViewManager.inst.getView(ViewName.shopView);
					shopView.onBuyGift();
				} else {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60116));
				}
			} else {
				Core.TipsUtils.showTipsFromCenter(payResult.result);
			}
		}
	}
}