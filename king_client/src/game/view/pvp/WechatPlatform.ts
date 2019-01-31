module Pvp {
	export class WechatPlatform extends Core.BaseView {

		private _closeBtn: fairygui.GButton;

		public initUI() {
			super.initUI();
			this.adjust(this.getChild("bg"));
			this._closeBtn = this.getChild("closeBtn").asButton;
			this.center();

			this._closeBtn.addClickListener(this._onClose, this);
		}

		public async open(...param: any[]) {
			super.open(...param);

			this.getChild("n3").visible = Core.DeviceUtils.isWXGame();
			if (Core.DeviceUtils.isWXGame()) {
				this.getChild("n0").asLoader.url = "common_wechatPlatformBg_png";
			} else {
				this.getChild("n0").asLoader.url = "common_wechatPlatformBg2_png";
			}
		}

		public async close(...param: any[]) {
			super.close(...param);
		}

		private async _onClose() {
			Core.ViewManager.inst.closeView(this);
		}
	}
}