module War {
	export class WarEndView extends Core.BaseWindow {

		private _gainResCom: CityInfoCom;
		private _winCityText: fairygui.GTextField;
		private _loseCityText: fairygui.GTextField;
		private _okBtn: fairygui.GButton;
		private _callback: () => void;
		private _data: pb.CaStateWarEndArg;

		public initUI() {
			super.initUI();

			this.modal = true;
			this.center();

			this._gainResCom = this.getChild("liangcao").asCom as CityInfoCom;
			this._winCityText = this.getChild("getCity").asTextField;
			this._loseCityText = this.getChild("loseCity").asTextField;
			this._okBtn = this.getChild("confirmBtn").asButton;

			this._okBtn.addClickListener(this._onClose, this);
		}

		private async _onClose() {
			await WarMgr.inst.changeStatus(BattleStatusName.ST_NORMAL, this._data.NextWarRemainTime);
			Core.ViewManager.inst.closeView(this);
		}

		public async open(...param: any[]) {
			super.open(...param);

			let data: pb.CaStateWarEndArg = param[0];
			this._callback = param[1];
			this._gainResCom.setInfo(WarResType.Contribution, data.Contribution);
			this._gainResCom.setTextAlign(fairygui.AlignType.Center);
			let getCitiesText = "";
			data.OccupyCitys.forEach(cityId => {
				let city = CityMgr.inst.getCity(cityId);
				getCitiesText += " " + city.cityName;
			});
			this._winCityText.text = getCitiesText;
			let loseCitiesText = "";
			data.LostCitys.forEach(cityId => {
				let city = CityMgr.inst.getCity(cityId);
				loseCitiesText += " " + city.cityName;
			});
			this._loseCityText.text = loseCitiesText;
			this._data = data;
		}

		public async close(...param: any[]) {
			super.close(...param);
			if (this._callback) {
				this._callback();
			}
		}
	}
}