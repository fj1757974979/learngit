module Shop {
	export class GoldInfoWnd extends Core.BaseWindow {

		private _nameText: fairygui.GTextField;
		private _goldCntText: fairygui.GTextField;
		private _cardImg: fairygui.GLoader;
		private _btnBuy: fairygui.GButton;

		private _buyCallback: () => void;
		private _product: Payment.GoldProduct;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;
			this._nameText = this.contentPane.getChild("name").asTextField;
			this._goldCntText = this.contentPane.getChild("goldCnt").asTextField;
			this._cardImg = this.contentPane.getChild("icon").asLoader;
			this._btnBuy = this.contentPane.getChild("btnBuy").asButton;

			this._btnBuy.addClickListener(async () => {
				if (!await this._product.askSubRes(true)) {
					return;
				}
				if (this._buyCallback) {
					this._buyCallback();
				}
				Core.ViewManager.inst.closeView(this);
			}, this);
			this.contentPane.getChild("closeBtn").addClickListener(()=>{
                Core.ViewManager.inst.closeView(this);
            }, this);
			this.adjust(this.contentPane.getChild("closeBg"));
			this.contentPane.getChild("closeBg").addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			},this);
		}

		public async open(...param: any[]) {
			super.open(...param);

			let product = <Payment.GoldProduct>param[0];
			let buyCallback = param[1];
			if (LanguageMgr.inst.isChineseLocale()) {
				this._nameText.text = Core.StringUtils.TEXT(60034)+`${product.desc}?`;
			} else {
				this._nameText.text = Core.StringUtils.TEXT(60034)+` ${product.desc}?`;
			}
			this._goldCntText.text = `x${product.soldGold}`;
			if (product.icon != "") {
				this._cardImg.url = product.icon;
			}
			this._btnBuy.title = `${product.price}`;
			if (!product.hasEnoughResToBuy()) {
				this._btnBuy.getChild("title").asTextField.color = 0xff0000;
			} else {
				this._btnBuy.getChild("title").asTextField.color = 0xffffff;
			}
			this._btnBuy.icon = product.resIcon;
			this._product = product;
			this._buyCallback = buyCallback;
		}

		private _onClose(evt:egret.TouchEvent) {
			let x = evt.stageX / fairygui.GRoot.contentScaleFactor;
			let y = evt.stageY / fairygui.GRoot.contentScaleFactor;
			if (x >= this.x && x <= this.x + this.width && y >= this.y && y <= this.y + this.height) {
				return;
			} else {
				Core.ViewManager.inst.closeView(this);
			}
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._product = null;
			this._buyCallback = null;
			this.root.removeEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
		}
	}
}