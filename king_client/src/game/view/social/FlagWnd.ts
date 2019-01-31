module Social {
	export class FlagWnd extends Core.BaseWindow {
		private _confirmBtn: fairygui.GButton;
		private _flagList: fairygui.GList;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;
			this._flagList = this.contentPane.getChild("flagList").asList;
		}
	}
}