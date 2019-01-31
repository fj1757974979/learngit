module War {

    export class WarGameOverPanel extends fairygui.GComponent {

        private _titleText: fairygui.GTextField;
        private _descText: fairygui.GTextField;
        private _fleeBtn: fairygui.GButton;
        private _surrenderBtn: fairygui.GButton;
        private _runAwayBtn: fairygui.GButton;

        protected constructFromXML(xml: any): void {
            this._titleText = this.getChild("n1").asTextField;
            this._descText = this.getChild("txt2").asTextField;
            this._surrenderBtn = this.getChild("surrenderBtn").asButton;
            this._runAwayBtn = this.getChild("runAwayBtn").asButton;

            this._surrenderBtn.addClickListener(this._onSurrenderBtn, this);
            this._runAwayBtn.addClickListener(this._onRunAwayBtn, this);
        }
        
        public showPanel() {
            this.visible = true;
            let ratio = 0.1;
            let off = MyWarPlayer.inst.getOffContribution(ratio);
            this._descText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60332), Core.StringUtils.secToString(MyWarPlayer.inst.getCurStatusRemainTime(), "h"), off);
            let city = CityMgr.inst.getCity(MyWarPlayer.inst.locationCityID);
            if (city.countryID != 0) {
                let country = CountryMgr.inst.getCountry(city.countryID);
                if (country) {
                    this._titleText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70301), city.cityName, country.countryName);
                    return;
                }
            }
            
            this._titleText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70302), city.cityName);
        }
        public closePanel() {
            this.visible = false;
        }

        private async _onSurrenderBtn() {
            let city = CityMgr.inst.getCity(MyWarPlayer.inst.locationCityID);
            if (city.countryID != 0) {
                let country = CountryMgr.inst.getCountry(city.countryID);
                if (country) {
                    let ratio = 0.1;
                    let off = MyWarPlayer.inst.getOffContribution(ratio);   //可被扣为负数
                    
                    Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70303), ratio * 100,off, CountryMgr.inst.getCountry(city.countryID).countryName), async ()=> {
                        let ok = await WarMgr.inst.surrender();
                        if (ok) {
                            MyWarPlayer.inst.countryID = country.countryID;
                            MyWarPlayer.inst.cityID = city.cityID;
                            
                            Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70304), city.cityName));
                            WarMgr.inst.warView.map.moveCenter(city);
                        }
                    }, null, this);
                    return;
                }
            }
            
            Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70305)));
        }
        private async _onRunAwayBtn() {
            let countryID = MyWarPlayer.inst.countryID;
            let country = CountryMgr.inst.getCountry(countryID);
            let msg = "";
            if (country) {
                // 有势力
                
                msg = Core.StringUtils.format(Core.StringUtils.TEXT(70306));
            } else {
                
                msg = Core.StringUtils.format(Core.StringUtils.TEXT(70307));
            }
            Core.TipsUtils.confirm(msg, async ()=> {
                let ok = await WarMgr.inst.runAway();
			}, null, this);
        }
    }
}