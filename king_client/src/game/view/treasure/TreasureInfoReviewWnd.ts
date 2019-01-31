module Treasure {
	export class TreasureInfoReviewWnd extends Core.BaseWindow {

		private _rewardList: fairygui.GList;
		private _nameText: fairygui.GTextField;
		private _rareCardNumText: fairygui.GTextField;
		private _effBox0: fairygui.GLoader;
		private _effBox1: fairygui.GLoader;
		private _openTrans0: fairygui.Transition;
		private _openTrans1: fairygui.Transition;
		private _openTrans2: fairygui.Transition;
		private _openTrans3: fairygui.Transition;

		private _treasure: Treasure.TreasureItem;

		public initUI() {
			super.initUI();

			this._openTrans0 = this.contentPane.getTransition("t0");
			this._openTrans1 = this.contentPane.getTransition("t1");
			this._openTrans2 = this.contentPane.getTransition("t2");
			this._openTrans3 = this.contentPane.getTransition("t3");
			this._effBox0 = this.contentPane.getChild("box0").asLoader;
			this._effBox1 = this.contentPane.getChild("box1").asLoader;
			this._nameText = this.contentPane.getChild("treasureName").asTextField;
			this._rareCardNumText = this.contentPane.getChild("txt1").asTextField;
			this._rewardList = this.contentPane.getChild("rewardList").asList;

			this.modal = true;
			this.center();
			this.adjust(this.contentPane.getChild("closeBg"));

			this.contentPane.getChild("closeBtn").addClickListener(this._onClose, this);
		}

		public async open(...param: any[]) {
			super.open(...param);
			this._treasure = param[0];

			this._rewardList.removeChildren(0, -1, true);

			let rewardComs = Treasure.TreasureReward.genRewardItemComsByTreasure(this._treasure);
			rewardComs.forEach(com => {
				this._rewardList.addChild(com);
			});
			this._rewardList.height = Math.ceil(rewardComs.length / 2) * 50;
			this._nameText.text = `${this._treasure.getName()}`;
			let rareCardNum = this._treasure.getRareCardNum();
			if (rareCardNum <= 0) {
				this._rareCardNumText.visible = false;
			} else {
				this._rareCardNumText.visible = true;
				this._rareCardNumText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60130), rareCardNum);
			}

			let rareType = this._treasure.getRareType();
			this._effBox0.url = `treasure_${rareType}0_png`;
			this._effBox1.url = `treasure_${rareType}1_png`;

			await new Promise<void>(resolve => {
				this._openTrans1.play(()=>{
					resolve();
				}, this);
			});

			this.contentPane.getChild("closeBg").addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
		}

		private async _onClose() {
			Core.ViewManager.inst.closeView(this);
		}

		public async close(...param: any[]) {
			super.close(...param);

			this.contentPane.getChild("closeBg").removeEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
		}
	}
}