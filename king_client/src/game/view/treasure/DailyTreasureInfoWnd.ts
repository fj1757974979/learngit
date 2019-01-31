module Treasure {
	export class DailyTreasureInfoWnd extends Core.BaseWindow {

		private _goldText: fairygui.GTextField;
		private _cardText: fairygui.GTextField;
		private _rareCardNumText: fairygui.GTextField;
		private _boxName: fairygui.GTextField;
		private _treasureCom: DailyTreasureItemCom;
		private _effBox0: fairygui.GLoader;
		private _effBox1: fairygui.GLoader;
		private _text: fairygui.GTextField;

		public initUI() {
			super.initUI();
			this._goldText = this.contentPane.getChild("goldCnt").asTextField;
			this._cardText = this.contentPane.getChild("cardCnt").asTextField;
			this._rareCardNumText = this.contentPane.getChild("txt1").asTextField;
			this._boxName = this.contentPane.getChild("txt2").asTextField;
			this._effBox0 = this.contentPane.getChild("box0").asLoader;
			this._effBox1 = this.contentPane.getChild("box1").asLoader;
			this._text = this.contentPane.getChild("txt3").asTextField;
			this.center();
			this.modal = true;
			this.adjust(this.contentPane.getChild("closeBg"));
			this.contentPane.getChild("closeBtn").addClickListener(this._onClose, this);
		}

		public async open(...param: any[]) {
			super.open(...param);
			this._treasureCom = param[0] as DailyTreasureItemCom;
			this.addRelation(this._treasureCom, fairygui.RelationType.Top_Bottom);
			this.addRelation(this._treasureCom, fairygui.RelationType.Right_Center);
			let treasure = this._treasureCom.treasure;
			if (treasure.getMinGoldCnt() == treasure.getMaxGoldCnt()) {
				this._goldText.text = `x${treasure.getMinGoldCnt()}`;
			} else {
				this._goldText.text = `x${treasure.getMinGoldCnt()} ~ ${treasure.getMaxGoldCnt()}`;
			}
			let cardNum = 0;
			if (treasure.getRareType() == 8 || treasure.getRareType() == 9 ) {
				if (Player.inst.hasPrivilege(Priv.DAILY_ADD_CARD)) {
					cardNum += 20;
				}
			}
			this._cardText.text = `x${treasure.getCardNum() + cardNum}`;
			this._boxName.text = `${treasure.getName()}`;
			// console.log(treasure.totalStarCount);
			if (!treasure.totalStarCount) {
				this._text.text = "";//Core.StringUtils.TEXT(60171);
			} else {
				this._text.text = Core.StringUtils.format(Core.StringUtils.TEXT(60195), treasure.totalStarCount);
			}

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

			//this.root.addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
		}

		public async close(...param: any[]) {
			super.close(...param);
			//this.root.removeEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
		}

		private _onClose(evt:egret.TouchEvent) {
			Core.ViewManager.inst.closeView(this);
		}
	}
}
