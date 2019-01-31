module Pvp {
	export class RankSeasonTreasureInfo extends Core.BaseWindow {

		private _goldText: fairygui.GTextField;
        private _jadeText: fairygui.GTextField;
		private _cardText: fairygui.GTextField;
		private _rareCardNumText: fairygui.GTextField;
		private _boxName: fairygui.GTextField;
		private _treasureCom: fairygui.GObject;
		private _treasureData: SeasonTreasureInfo;
		private _effBox0: fairygui.GLoader;
		private _effBox1: fairygui.GLoader;

		public initUI() {
			super.initUI();
			this._goldText = this.getChild("goldCnt").asTextField;
            this._jadeText = this.getChild("jadeCnt").asTextField;
			this._cardText = this.getChild("cardCnt").asTextField;
			this._rareCardNumText = this.getChild("txt1").asTextField;
			this._boxName = this.getChild("txt2").asTextField;
			this._effBox0 = this.getChild("box0").asLoader;
			this._effBox1 = this.getChild("box1").asLoader;
			this.center();
			this.modal = true;
			this.adjust(this.getChild("closeBg"));
			this.getChild("closeBtn").addClickListener(this._onClose, this);
		}

		public async open(...param: any[]) {
			super.open(...param);
			this._treasureCom = param[1] as fairygui.GObject;
			this._treasureData = param[1] as SeasonTreasureInfo;
			// this.addRelation(this._treasureCom, fairygui.RelationType.Top_Bottom);
			// this.addRelation(this._treasureCom, fairygui.RelationType.Right_Center);

			this._goldText.text = `x${this._treasureData.getMinGoldCnt()}`;
            this._jadeText.text = `x${this._treasureData.getMinJadeCnt()}`;
			this._cardText.text = `x${this._treasureData.getCardNum()}`;
			this._boxName.text = `${this._treasureData.getName()}`;

			
			let rareCardNum = this._treasureData.getRareCardNum();
			if (rareCardNum <= 0) {
				this._rareCardNumText.visible = false;
			} else {
				this._rareCardNumText.visible = true;
				this._rareCardNumText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60130), rareCardNum);;
			}
			let rareType = this._treasureData.getRareType();
			this._effBox0.url = `treasure_${rareType}0_png`;
			this._effBox1.url = `treasure_${rareType}1_png`;

		}

		public async close(...param: any[]) {
			super.close(...param);
		}

		private _onClose(evt:egret.TouchEvent) {
			Core.ViewManager.inst.closeView(this);
		}
	}
}