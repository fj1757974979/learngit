module Shop {
	export class TreasureItemCom extends fairygui.GComponent {

		private _nameText: fairygui.GTextField;
		private _priceText: fairygui.GTextField;
		private _cardImg: fairygui.GLoader;
		private _boxLight: fairygui.GLoader;
		private _resIcon: fairygui.GLoader;

		private _product: Payment.TreasureProduct;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._nameText = this.getChild("name").asTextField;
			this._priceText = this.getChild("price").asTextField;
			this._cardImg = this.getChild("box").asLoader;
			this._boxLight = this.getChild("canOpenBg").asLoader;
			this._resIcon = this.getChild("resIcon").asLoader;

			this.addClickListener(this._onBuy, this);
			this.addEventListener(egret.TouchEvent.TOUCH_BEGIN, () => {
				this.getTransition("t0").play();
			}, this);
		}

		public setTreasureProduct(product: Payment.TreasureProduct) {
			let treasureType = product.id;
			let treasure = new Treasure.TreasureItem(-1, treasureType);
			this._cardImg.url = treasure.image;
			this._nameText.text = `${treasure.getName()}`;
			this._boxLight.url = `treasure_box${treasure.getRareType()}CanOpen_png`;
			this._priceText.text = `${product.price}`;
			this._resIcon.url = product.resIcon;
			this._product = product;
		}

		private async _onBuy() {
			Core.ViewManager.inst.open(ViewName.shopTreasureInfoWnd, this._product, async () => {
				let args = {
					TreasureModelID: this._product.id
				};
				let result = await Net.rpcCall(pb.MessageID.C2S_BUY_SOLDTREASURE, pb.BuySoldTreasureArg.encode(args));
				if (result.errcode == 0) {
					let reply = pb.BuySoldTreasureReply.decode(result.payload);
					let reward = new Treasure.TreasureReward();
					reward.setRewardForOpenReply(reply.TreasureReward);
					Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward, new Treasure.TreasureItem(-1, this._product.id));
					Core.EventCenter.inst.dispatchEventWith(GameEvent.RefreshSoldTreasureEv, false, reply.NextRemainTime);
					let shopView = <ShopView>Core.ViewManager.inst.getView(ViewName.shopView);
					shopView.onBuyTreasure();
				} else {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60081));
				}
			});
		}
	}
}