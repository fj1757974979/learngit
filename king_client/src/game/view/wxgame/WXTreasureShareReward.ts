module WXGame {
	export class WXTreasureShareReward extends Core.BaseWindow {

		private _hid: number;
		public async initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this.contentPane.getChild("closeBtn").asButton.addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			}, this);

			this.contentPane.getChild("shareBtn").asButton.addClickListener(() => {
				WXShareMgr.inst.wechatShareReward(this._hid);
				Core.ViewManager.inst.closeView(this);
			}, this);
		}

		public async open(...param: any[]) {
			super.open(...param);

			this._hid = param[0];
		}

		public async close(...param: any[]) {
			super.close(...param);
		}
	}
}