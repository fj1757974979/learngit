module Shop {
	export class JadeItemCom extends fairygui.GComponent {

		private _nameText: fairygui.GTextField;
		private _priceText: fairygui.GTextField;
		private _jadeCntText: fairygui.GTextField;
		private _cardImg: fairygui.GLoader;

		private _product: Payment.JadeProduct;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			this._nameText = this.getChild("name").asTextField;
			this._priceText = this.getChild("price").asTextField;
			this._jadeCntText = this.getChild("jadeCnt").asTextField;
			this._cardImg = this.getChild("icon").asLoader;

			this.addClickListener(this._onPay, this);
			this.addEventListener(egret.TouchEvent.TOUCH_BEGIN, () => {
				this.getTransition("t0").play();
			}, this);

			if (!LanguageMgr.inst.isChineseLocale()) {
				this._nameText.fontSize = 14;
			}
		}

		public setProduct(product: Payment.JadeProduct) {
			this._nameText.text = product.desc;
			this._priceText.text = product.localizedPrice;
			this._jadeCntText.text = `x${product.jade}`;
			this._cardImg.url = product.icon;
			this._product = product;
		}

		private async _onPay() {
			let payResult = await Payment.PayMgr.inst.payProduct(this._product.id, 1);
			let jade = 0;
			if (payResult.success) {
				// if (window.gameGlobal.isSDKPay) {
				if (!Payment.PayMgr.inst.needSendBuyRpc()) {
					let payload = <pb.SdkRechargeResult>payResult.param;
					let reply = payload.Jade;
					jade = reply.Jade + reply.RewardJade;
				} else {
					let args = {
						GoodsID: this._product.id,
						Receipt: payResult.result,
					}
					let result = await Net.rpcCall(pb.MessageID.C2S_BUY_JADE, pb.BuyJadeArg.encode(args));
					if (result.errcode == 0) {
						let reply = pb.BuyJadeReply.decode(result.payload);
						jade = reply.Jade + reply.RewardJade;
					} else {
						Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60116));
					}
				}
			} else {
				Core.TipsUtils.showTipsFromCenter(payResult.result);
			}

			if (jade > 0) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60073));
				let args = new Pvp.GetRewardData();
				args.jade = jade;
				Core.ViewManager.inst.open(ViewName.getRewardWnd, args);
			}
		}
	}
}
