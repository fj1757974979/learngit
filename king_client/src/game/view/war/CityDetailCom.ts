module War {

    export class CityDetailCom extends fairygui.GComponent {

        private _city: City;
        private _myNameText: fairygui.GTextField;
        private _myJobText: fairygui.GTextField;
        private _myCountryText: fairygui.GTextField;
        private _myContributionCom: CityInfoCom;
        private _mySalaryCom: CityInfoCom;
        private _cityNameText: fairygui.GTextField;
        private _defenceBar: CityInfoBar;
        private _cityGoldCom: CityInfoCom;
        private _cityForageCom: CityInfoCom;
        private _addGoldBtn: fairygui.GButton;
        private _setFoodPriceBtn: fairygui.GButton;
        private _independeBtn: fairygui.GButton;
        private _memberBtn: fairygui.GButton;
        private _isAttackText: fairygui.GTextField;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);

            this._myNameText = this.getChild("n61").asTextField;
            this._myNameText.textParser = Core.StringUtils.parseColorText;
            this._myJobText = this.getChild("n77").asTextField;
            this._myJobText.textParser = Core.StringUtils.parseColorText;
            this._myCountryText = this.getChild("n85").asTextField;
            this._myContributionCom = this.getChild("gongji").asCom as CityInfoCom;
            this._mySalaryCom = this.getChild("fenglu").asCom as CityInfoCom;
            this._cityNameText = this.getChild("n86").asTextField;
            this._defenceBar = this.getChild("chengfang").asCom as CityInfoBar;
            this._cityGoldCom = this.getChild("jinbi").asCom as CityInfoCom;
            this._cityForageCom = this.getChild("liangcao").asCom as CityInfoCom;
            this._addGoldBtn = this.getChild("addGoldBtn").asButton;
            this._setFoodPriceBtn = this.getChild("setFoodPrice").asButton;
            this._independeBtn = this.getChild("independeBtn").asButton;
            this._memberBtn = this.getChild("memberBtn").asButton;
            this._isAttackText = this.getChild("n54").asTextField;

            this._addGoldBtn.addClickListener(this._onAddGoldBtn, this);
            this._setFoodPriceBtn.addClickListener(this._onSetFoodPriceBtn, this);
            this._independeBtn.addClickListener(this._onIndependeBtn, this);
            this._memberBtn.addClickListener(this._onMemberBtn, this);
        }

        public setInfo(city: City) {
            this._city = city;
            this._myNameText.text = Player.inst.name;
            this._myJobText.text = Utils.job2Text(MyWarPlayer.inst.employee.cityJob.type, true);
            this._myCountryText.text = MyWarPlayer.inst.countryID == 0? "" : CountryMgr.inst.getCountry(MyWarPlayer.inst.countryID).countryName;
            this._myContributionCom.setNum(MyWarPlayer.inst.contribution);
            this._mySalaryCom.setNum(MyWarPlayer.inst.salary);
            this._cityNameText.text = city.cityName;
            this._defenceBar.setProgress(city.defence, city.defenceMax);
            this._defenceBar.setProgress2(city.defence, city.defenceMax);
            this._defenceBar.setIconUrl(Utils.warResType2Url(WarResType.Defense));
            this._cityGoldCom.setNum(city.gold);
            this._cityGoldCom.setIconUrl(WarResType.Gold);
            this._cityForageCom.setNum(city.forage);
            this._cityForageCom.setIconUrl(WarResType.Forage);

            this._isAttackText.visible = this._city.isBeAttack;
            
            // let myJob = MyWarPlayer.inst.getMyCityJob(city.cityID);
            // let myCountryJob = MyWarPlayer.inst.getMyCountryJob(city.cityID);
            // if(myCountryJob != Job.YourMajesty && myJob == Job.Prefect) {
            //     this._independeBtn.visible = true;
            // } else {
            //     this._independeBtn.visible = false;
            // }
        }

        private async _onAddGoldBtn() {
            Core.ViewManager.inst.open(ViewName.addGoldWnd, this._city);
        }
        private async _onSetFoodPriceBtn() {
            //如果不是我所属城市
            if (this._city.cityID != MyWarPlayer.inst.cityID) {
                return;
            }
            //职位判断
            if (MyWarPlayer.inst.employee.hasSameJob(Job.Prefect) || MyWarPlayer.inst.employee.hasSameJob(Job.DuWei)) {
                WarMgr.inst.openSetFoodPriceWnd(this._city);
            }
        }
        private async _onIndependeBtn() {
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_AUTOCEPHALY_INFO, null);
            if (result.errcode == 0) {
                let reply = pb.AutocephalyInfo.decode(result.payload);
                Core.ViewManager.inst.open(ViewName.independentWnd, reply);
            }
        }
        private async _onMemberBtn() {
            let memberList = await WarMgr.inst.fetchCityMember(this._city.cityID, 0);
            if (memberList) {
                Core.ViewManager.inst.open(ViewName.allMemberPanel, this._city.cityID, memberList);
            }
        }
    }
}