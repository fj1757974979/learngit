module Social {
	export class HaedBigWnd extends Core.BaseWindow {

		private _headIcon: fairygui.GImage;
		private _uid: Long;
		private _playerInfo: pb.PlayerInfo;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;
			this._headIcon = this.contentPane.getChild("headIcon").asImage;
			let url = Player.inst.avatarUrl;
			let bigHeadUrl = url.replace("132","0");
			Utils.setImageUrlPicture(this._headIcon, bigHeadUrl);
			if (Core.DeviceUtils.isWXGame()) {
				this.contentPane.getChild("bg").addClickListener(this._onClose,this);
			} 
		}

		private async _onClose() {
			Core.ViewManager.inst.closeView(this);
		}

		public async open(...param: any[]) {
			this.battleChangeLayer();
			super.open(...param);
		}

		public async close(...param: any[]) {
			super.close(...param);
		}
	}
}