module Social {

	export class FriendSearchWnd extends Core.BaseWindow {

		private _closeBtn: fairygui.GButton;
		private _confirmBtn: fairygui.GButton;
		private _searchInput: fairygui.GTextInput;
		private _warningText: fairygui.GTextField;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
			this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;
			this._searchInput = this.contentPane.getChild("searchInput").asTextInput;
			this._warningText = this.contentPane.getChild("warning").asTextField;

			this._closeBtn.addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			}, this);

			this._confirmBtn.addClickListener(this._onSearch, this);
			this._searchInput.addEventListener(egret.Event.FOCUS_IN, () => {
				this._warningText.text = "";
			}, this);
		}

		public async open(...param: any[]) {
			super.open(...param);
			this._warningText.text = "";
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._searchInput.text = "";
		}

		private async _onSearch() {
			let uid = Core.StringUtils.stringToLong(this._searchInput.text);
			if (!uid) {
				this._warningText.text = Core.StringUtils.TEXT(60157);
				return;
			}
			if (uid == Player.inst.uid) {
				this._warningText.text = Core.StringUtils.TEXT(60103);
				return;
			}
			let playerInfo = await FriendMgr.inst.fetchPlayerInfo(uid);
			if (!playerInfo) {
				this._warningText.text = Core.StringUtils.TEXT(60135);
			} else {
				this._warningText.text = "";
				Core.ViewManager.inst.open(ViewName.friendInfo, uid, playerInfo);
			}
		}
	}
}