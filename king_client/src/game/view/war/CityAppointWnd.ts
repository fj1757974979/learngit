module War {
    
    export class CityAppointWnd extends Core.BaseWindow {

        private _city: City;
        private _appointCom: CityAppointCom;
        
        private  _surrenderBtn: fairygui.GButton;
        private _closeBtn: fairygui.GButton;
        private _quitBtn: fairygui.GButton;
        private _indeBtn: fairygui.GButton;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;
            this._appointCom = this.contentPane.getChild("n1").asCom as CityAppointCom;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._surrenderBtn = this.contentPane.getChild("surrenderBtn").asButton;
            this._quitBtn = this.contentPane.getChild("quitBtn").asButton;
            this._indeBtn = this.contentPane.getChild("indeBtn").asButton;
            //this._surrenderBtn.visible = false;
            this._closeBtn.addClickListener(this._onClose, this);
            this._quitBtn.addClickListener(this._onQuit, this);
            this._surrenderBtn.addClickListener(this._onSurrenderBtn, this);
            this._indeBtn.addClickListener(this._onAutocephalyBtn, this);

            
        }

        private async _onClose() {
            Core.ViewManager.inst.closeView(this);
        }
        
        public async open(...param: any[]) {
            
            super.open(...param);
            this._city = CityMgr.inst.getCity(param[0]);
            
            Core.EventCenter.inst.addEventListener(WarMgr.RefreshAppoint, this._refreshJob, this);
            this.refreshWnd();
            this._refreshJob();
        }
        private _watch() {
            
        }
        private _updateIndeBtn() {
            if (MyWarPlayer.inst.isMyCity(this._city.cityID) && MyWarPlayer.inst.employee.canAutocephaly()) {
                this._indeBtn.touchable = true;
                this._indeBtn.grayed = false;
            } else {
                this._indeBtn.touchable = true;
                this._indeBtn.grayed = true;
            }
        }
        private _updateSurrenderBtn() {
            if (MyWarPlayer.inst.isMyCity(this._city.cityID) && MyWarPlayer.inst.employee.canSurrender()) {
                this._surrenderBtn.touchable = true;
                this._surrenderBtn.grayed = false;
            } else {
                this._surrenderBtn.touchable = true;
                this._surrenderBtn.grayed = true;
            }
        }

        public refreshWnd() {
            if (this._city.cityID == MyWarPlayer.inst.cityID && this._city.countryID != 0) {
                this._quitBtn.visible = true;
            } else {
                this._quitBtn.visible = false;
            }
            this._updateSurrenderBtn();
            this._updateIndeBtn();
        }
        public async _refreshJob() {
            this._appointCom.refreshCityJob(this._city.cityID);
        }
        public async close(...param: any[]) {
            Core.EventCenter.inst.removeEventListener(WarMgr.SelectCity, this._selectCity, this);
            Core.EventCenter.inst.removeEventListener(WarMgr.RefreshAppoint, this._refreshJob, this);
            super.close(...param);
        }
        private async _onSurrenderBtn() {
            if (WarMgr.inst.checkWarIsOver()) {
                return;
            }
            if (!MyWarPlayer.inst.isMyCity(this._city.cityID) || !MyWarPlayer.inst.employee.canSurrender()) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70227)));
                return;
            }
            if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING) || WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70254)));
                return;
            }
            WarMgr.inst.joinSelectCityMode(true, MapState.SurrenderCity);
            Core.EventCenter.inst.addEventListener(WarMgr.SelectCity, this._selectCity, this);
        }
        private async _selectCity(evt: egret.Event) {
            let cityID = evt.data;
            if (cityID) {
                let city = CityMgr.inst.getCity(cityID);
                if (city.countryID == 0) {
                    Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70255)));
                    return;
                }
                let country = CountryMgr.inst.getCountry(city.countryID);
                let ratio = 0.2;
                let off = MyWarPlayer.inst.getOffContribution(ratio); 
                Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70228), this._city.cityName, country.countryName, off), () => {
                    this._onSurrender(city.countryID);
                } , null, this);
            } else {
                WarMgr.inst.joinSelectCityMode(false, MapState.SurrenderCity);
                Core.EventCenter.inst.removeEventListener(WarMgr.SelectCity, this._selectCity, this);
            }
            
        }
        private async _onSurrender(countryID: number) {
            if (WarMgr.inst.checkWarIsOver()) {
                return;
            }
            WarMgr.inst.joinSelectCityMode(false, MapState.SurrenderCity);
            Core.EventCenter.inst.removeEventListener(WarMgr.SelectCity, this._selectCity, this);
            if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING) || WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70254)));
                return;
            }
            let ok = await WarMgr.inst.surrenderCity(countryID);
            if (ok) {
                Core.ViewManager.inst.closeView(this);
            }
        }
        private async _onAutocephalyBtn() {
            if (WarMgr.inst.checkWarIsOver()) {
                return;
            }
            if (!MyWarPlayer.inst.isMyCity(this._city.cityID) || !MyWarPlayer.inst.employee.canSurrender()) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70227)));
                return;
            }
            if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING) || WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70254)));
                return;
            }
            let country = CountryMgr.inst.getCountry(this._city.countryID);
            if (country) {
                let ratio = 0.2;
                let off = MyWarPlayer.inst.getOffContribution(ratio); 
                Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70367), country.countryName, ratio * 100, off), () => {
                    this._onAutocephaly();
                } , null, this);
            }
            
        }
        private async _onAutocephaly() {
            let ok = await WarMgr.inst.autocephaly();
            if (ok) {
                Core.ViewManager.inst.closeView(this);
            }
        }

        private async _onQuit() {
            if (WarMgr.inst.checkWarIsOver()) {
                return;
            }
            if (MyWarPlayer.inst.lastCountryID > 0) {
                Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70229)), this._quit, null, this);
            } else {
                let ratio = 0.1;
                let off = MyWarPlayer.inst.getOffContribution(ratio);
                Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70230), this._city.cityName, ratio * 100, off), this._quit, null, this);
            }
            
        }
        private async _quit(evt?: egret.Event) {
            if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING) || WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70372));
                Core.EventCenter.inst.removeEventListener(WarMgr.KingDie, this._quit, this);
                return;
            }
            let ok = null;
            if (evt) {
               ok = await WarMgr.inst.quitCountry(evt.data);
               Core.EventCenter.inst.removeEventListener(WarMgr.KingDie, this._quit, this);
            } else {
                if (MyWarPlayer.inst.employee.hasSameJob(Job.YourMajesty)) {
                    let playerList = await WarMgr.inst.fetchCountryMember(this._city.countryID, 0);
                    if (playerList && playerList.Players.length > 1) {
                        if (Core.EventCenter.inst.hasEventListener(WarMgr.KingDie)) {
                            Core.EventCenter.inst.removeEventListener(WarMgr.KingDie, this._quit, this);
                        }
                        Core.EventCenter.inst.addEventListener(WarMgr.KingDie, this._quit, this);
                        Core.ViewManager.inst.open(ViewName.appointChooseWnd, this._city.countryID, Job.YourMajesty, playerList);
                        let view = Core.ViewManager.inst.getView(ViewName.appointChooseWnd) as AppointChooseWnd;
                        view.setKingDie(true);
                    } else {
                        ok = await WarMgr.inst.quitCountry(0);
                    }
                } else {
                    ok = await WarMgr.inst.quitCountry(0);
                }
            }

            if (ok) {
                Core.ViewManager.inst.closeView(this);
                Core.ViewManager.inst.close(ViewName.cityInfoPanel);
                MyWarPlayer.inst.countryID = 0;
                WarMgr.inst.warView.updateHomeTip();
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70231), this._city.cityName));
                Core.EventCenter.inst.dispatchEventWith(WarMgr.RefreshCityInfo);
            }
        }
    }
}
