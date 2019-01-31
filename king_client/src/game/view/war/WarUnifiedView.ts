module War {
	export class WarUnifiedView extends Core.BaseWindow {

		private _campCom: CampIconCom;
		private _majestyNameText: fairygui.GTextField;
		private _confirmBtn: fairygui.GButton;

		public initUI() {
			super.initUI();

			this.modal = true;
			this.center();

			this._campCom = this.getChild("n27").asCom as CampIconCom;
			this._majestyNameText = this.getChild("lordName").asTextField;
			this._confirmBtn = this.getChild("confirmBtn").asButton;

			this._confirmBtn.addClickListener(this._onClose, this);
		}

		public async open(...param: any[]) {
			super.open(...param);

			let data = <pb.CaStateUnifiedArg>param[0];
			let countryId = data.CountryID;
			let country = CountryMgr.inst.getCountry(countryId);
			this._campCom.setCamp(country);

			this._majestyNameText.text = data.YourMajestyName;
		}

		private async _onClose() {
			Core.ViewManager.inst.closeView(this);
		}

		public async close(...param: any[]) {
			super.close(...param);
		}
	}
}