module Shop {
	export class TreasureInfoWnd extends Core.BaseWindow {

		private _nameText: fairygui.GTextField;
		private _rareCardNumText: fairygui.GTextField;
		private _buyBtn: fairygui.GButton;
		private _effBox0: fairygui.GLoader;
		private _effBox1: fairygui.GLoader;
		private _openTrans0: fairygui.Transition;
		private _rewardList: fairygui.GList;

		private _buyCallback: () => void;
		private _product: Payment.Product;
	
		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._rareCardNumText = this.contentPane.getChild("txt1").asTextField;
			this._nameText = this.contentPane.getChild("treasureName").asTextField;
			this._buyBtn = this.contentPane.getChild("btnBuy").asButton;
			// this._payBtn = this.contentPane.getChild("btnPay").asButton;
			this._effBox0 = this.contentPane.getChild("box0").asLoader;
			this._effBox1 = this.contentPane.getChild("box1").asLoader;
			this._openTrans0 = this.contentPane.getTransition("t0");

			this._rewardList = this.contentPane.getChild("rewardList").asList;

			this._buyBtn.addClickListener(async () => {
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

			// this._payBtn.addClickListener(() => {
			// 	if (this._buyCallback) {
			// 		this._buyCallback();
			// 	}
			// 	Core.ViewManager.inst.closeView(this);
			// }, this);
		}

		public async open(...param: any[]) {
			super.open(...param);
			let product: Payment.ResPayProduct = param[0];
			let treasureType = null;
			if (product.type == Payment.ProductType.T_GIFT) {
				treasureType = product.conf.reward;
			} else if (product.type == Payment.ProductType.T_TREASURE) {
				treasureType = product.id;
			}
			this._buyCallback = param[1];

			// let treasureType = conf.treasureId;
			let treasure = new Treasure.TreasureItem(-1, treasureType);

			let rewardComs = Treasure.TreasureReward.genRewardItemComsByTreasure(treasure);
			rewardComs.forEach(com => {
				this._rewardList.addChild(com);
			});

			this._rewardList.height = Math.ceil(rewardComs.length / 2) * 50;
			
			this._nameText.text = `${treasure.getName()}`;
			
			let rareCardNum = treasure.getRareCardNum();
			if (rareCardNum <= 0) {
				this._rareCardNumText.visible = false;
			} else {
				this._rareCardNumText.visible = true;
				this._rareCardNumText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60130), rareCardNum);
			}

			let rareType = treasure.getRareType();
			this._effBox0.url = `treasure_${rareType}0_png`;
			this._effBox1.url = `treasure_${rareType}1_png`;

			this._buyBtn.title = `${product.price}`;
			if (!product.hasEnoughResToBuy()) {
				this._buyBtn.getChild("title").asTextField.color = 0xff0000;
			} else {
				this._buyBtn.getChild("title").asTextField.color = 0xffffff;
			}
			this._buyBtn.icon = product.resIcon;
			this._product = product;
			// this.root.addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
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
			this._buyCallback = null;
			this.root.removeEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
			this._rewardList.removeChildren(0, -1, true);
		}
	}
}