module Shop {
	export class GoldItemCom extends fairygui.GComponent {

		private _nameText: fairygui.GTextField;
		private _priceText: fairygui.GTextField;
		private _goldCntText: fairygui.GTextField;
		private _cardImg: fairygui.GLoader;
		private _resIcon: fairygui.GLoader;

		private _product: Payment.GoldProduct;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			this._nameText = this.getChild("name").asTextField;
			this._priceText = this.getChild("price").asTextField;
			this._goldCntText = this.getChild("goldCnt").asTextField;
			this._cardImg = this.getChild("icon").asLoader;
			this._resIcon = this.getChild("resIcon").asLoader;

			this.addClickListener(this._onBuy, this);
			this.addEventListener(egret.TouchEvent.TOUCH_BEGIN, () => {
				this.getTransition("t0").play();
			}, this);

			if (!LanguageMgr.inst.isChineseLocale()) {
				this._nameText.fontSize = 14;
			}
		}

		public setGoldProduct(product: Payment.GoldProduct) {
			this._nameText.text = product.desc;
			this._priceText.text = `${product.price}`;
			this._goldCntText.text = `x${product.soldGold}`;
			this._resIcon.url = product.resIcon;
			if (product.icon != "") {
				this._cardImg.url = product.icon;
			}
			this._product = product;
		}

		private async _onBuy() {
			Core.ViewManager.inst.open(ViewName.shopGoldInfoWnd, this._product, async () => {
				let args = {
					GoodsID: this._product.id
				}
				let result = await Net.rpcCall(pb.MessageID.C2S_BUY_GOLD, pb.BuyGoldArg.encode(args));
				if (result.errcode == 0) {
					let reply = pb.BuyGoldReply.decode(result.payload);
					let shopView = <ShopView>Core.ViewManager.inst.getView(ViewName.shopView);
					Core.EventCenter.inst.dispatchEventWith(GameEvent.RefreshSoldGoldEv, false, reply.NextRemainTime);
					shopView.onBuyGold(reply.Gold);
				} else {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60081));
				}
			});
		}
	}
}