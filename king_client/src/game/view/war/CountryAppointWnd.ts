module War {
    
    export class CountryAppointWnd extends Core.BaseWindow {

        private _appointCom: CountryAppointCom;
        private _country: Country;
        //private _city: City;
        private _campCom: CampIconCom;
        private _closeBtn: fairygui.GButton;
        private _surrenderBtn: fairygui.GButton;
        private _txt: fairygui.GTextField;

        private _campObjWatchers: Core.Watcher[];

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;
            this._campObjWatchers = [];
            this._campCom = this.contentPane.getChild("modifyFlag").asCom as CampIconCom;
            this._appointCom = this.contentPane.getChild("n1").asCom as CountryAppointCom;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._surrenderBtn = this.contentPane.getChild("surrenderBtn").asButton;
            this._surrenderBtn.visible = false;
            this._txt = this.contentPane.getChild("txt").asTextField;

            this._closeBtn.addClickListener(this._onClose, this);
            this._campCom.addClickListener(this._onCamp, this);
            this._surrenderBtn.addClickListener(this._onSurrenderBtn, this);
            
        }

        private async _onClose() {
            Core.ViewManager.inst.closeView(this);
        }
        
        public async open(...param: any[]) {
            
            super.open(...param);
            let country = param[0];
            this._country = country;
            this._updateSurrenderBtn();
            Core.EventCenter.inst.addEventListener(WarMgr.RefreshAppoint, this._refreshJob, this);
            this.refreshWnd();
            this._refreshJob();
            this._watch();
        }
        private _updateSurrenderBtn() {
            this._surrenderBtn.visible = true;
            this._surrenderBtn.grayed = !MyWarPlayer.inst.employee.hasSameJob(Job.YourMajesty);
        }
        private _watch() {
            this._country.watchProp(Country.PropCampName, this.refreshWnd, this);
            this._country.watchProp(Country.PropFlag, this.refreshWnd, this);
        }
        private _unwatch() {
            this._country.unwatchProp(Country.PropCampName, this.refreshWnd, this);
            this._country.unwatchProp(Country.PropFlag, this.refreshWnd, this);
        }
        public refreshWnd() {
            this._campCom.setCamp(this._country);
            
            if (MyWarPlayer.inst.employee.hasSameJob(Job.YourMajesty)) {
                this._txt.visible = true;
            } else {
                this._txt.visible = false;
            }
        }
        private _onSurrenderBtn() {
            if (WarMgr.inst.checkWarIsOver()) {
                return;
            }
            if (!MyWarPlayer.inst.employee.hasSameJob(Job.YourMajesty)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70253)));
                return;
            }
            if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING) || WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70254)));
                return;
            }
            WarMgr.inst.joinSelectCityMode(true, MapState.SurrenderCamp);
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
                Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70256), country.countryName, off), () => {
                    this._onSurrender(city.countryID);
                } , null, this);
            } else {
                WarMgr.inst.joinSelectCityMode(false, MapState.SurrenderCamp);
                Core.EventCenter.inst.removeEventListener(WarMgr.SelectCity, this._selectCity, this);
            }
        }
        private async _onSurrender(countryID: number) {
            WarMgr.inst.joinSelectCityMode(false, MapState.SurrenderCamp);
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
        private _onCamp() {
            if (WarMgr.inst.checkWarIsOver()) {
                return;
            }
            if (MyWarPlayer.inst.employee.canSetCampFlag()) {
                Core.ViewManager.inst.open(ViewName.modifyCampFlagWnd, this._country);
            }
        }
        public async _refreshJob() {
            this._appointCom.refreshJob(this._country);
        }
        public async close(...param: any[]) {
            this._unwatch();
            Core.EventCenter.inst.removeEventListener(WarMgr.SelectCity, this._selectCity, this);
            Core.EventCenter.inst.removeEventListener(WarMgr.RefreshAppoint, this._refreshJob, this);
            super.close(...param);
        }
    }
}
