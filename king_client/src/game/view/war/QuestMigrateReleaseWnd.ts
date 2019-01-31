module War {

    export class QuestMigrateReleaseWnd extends Core.BaseWindow {

        private _toCity: City;
        private _fromCity: City;
        private _cityPath: Array<number>;
        private _money: number;

        private _cityNameText: fairygui.GTextField;
        private _cityLoader: fairygui.GLoader;
        private _memberInput: fairygui.GTextField;
        private _memberCnt: fairygui.GSlider;
        private _goldInput: fairygui.GTextField;
        private _goldCnt: fairygui.GSlider;
        private _text1: fairygui.GTextField;
        private _text2: fairygui.GTextField;
        private _totalGoldText: fairygui.GTextField;
        private _resCom: CityInfoCom;
        private _confirmBtn: fairygui.GButton;
        private _closeBtn: fairygui.GButton;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;

            this._cityNameText = this.contentPane.getChild("cityName").asTextField;
            this._cityLoader = this.contentPane.getChild("n30").asLoader;
            this._memberInput = this.contentPane.getChild("memberInput").asTextField;
            this._memberCnt = this.contentPane.getChild("memberCnt").asSlider;
            this._memberCnt.getChild("title").visible = false;
            this._goldInput = this.contentPane.getChild("goldInput").asTextField;
            this._goldCnt = this.contentPane.getChild("goldCnt").asSlider;
            this._goldCnt.getChild("title").visible = false;
            this._text1 = this.contentPane.getChild("txt1").asTextField;
            this._text2 = this.contentPane.getChild("txt2").asTextField;
            this._totalGoldText = this.contentPane.getChild("totalGold").asTextField;
            this._resCom = this.contentPane.getChild("res").asCom as CityInfoCom;
            this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;

            this._cityLoader.addClickListener(this._reSelect, this);
            this._closeBtn.addClickListener(this._onCloseBtn, this);
            this._confirmBtn.addClickListener(this._onConfirmBtn, this);

            this._memberCnt.addEventListener(fairygui.StateChangeEvent.CHANGED, this._memberChange, this);
            this._goldCnt.addEventListener(fairygui.StateChangeEvent.CHANGED, this._goldChange, this);
        }
        public async open(...param: any[]) {
            super.open(...param);
            this._fromCity = WarMgr.inst.nowSelectCity;
            this._cityPath = new Array<number>();
            
            this._resCom.setInfo(WarResType.Gold, this._fromCity.gold);

            this._refresh(param[0]);

        }
        private _refresh(cityID: number) {
            this._toCity = CityMgr.inst.getCity(cityID);
            this._cityPath = CityMgr.inst.getShortestPathBetweenCityForTransport(this._fromCity, this._toCity);
            this._cityNameText.text = this._toCity.cityName;
            let day = Road.countCityPathDistance(this._cityPath);
            this._money = day * Data.parameter.get("transfer_cost").para_value[0];

            this._memberInput.text = "0";
            this._memberCnt.value = 0;
            this._goldInput.text = "0";
            this._goldCnt.value = 0;
            if (this._fromCity.gold < this._money) {
                this._memberCnt.max = 1;
                this._memberCnt.touchable = false;
                this._memberCnt.grayed = true;
            } else {
                let maxCur = Math.floor(this._fromCity.gold / this._money);
                this._memberCnt.max = Math.min(maxCur, this._fromCity.playerNum);
                this._memberCnt.touchable = true;
                this._memberCnt.grayed = false;
            }
            this._memberChange();
            this._goldChange();
        }

        private async _reSelect() {
            let country = CountryMgr.inst.getCountry(MyWarPlayer.inst.countryID);
            if (country) {
                let citys = country.cityList.keys();
                let index = citys.indexOf(this._fromCity.cityID);
                if (index >= 0) {
                    citys.splice(index, 1);
                }
                WarMgr.inst.joinSelectCityMode(true, MapState.SelectMy, citys);
                Core.EventCenter.inst.addEventListener(WarMgr.SelectCity, this._reCity, this);
            }
            
            // Core.ViewManager.inst.closeView(this);
        }
        private _reCity(evt: egret.Event) {
            let cityID = evt.data;
            if (cityID) {
                let country = CountryMgr.inst.getCountry(MyWarPlayer.inst.countryID);
                let citys = country.cityList.keys();
                if (citys.indexOf(cityID) >= 0) {
                    this._refresh(cityID);
                } else {
                    return;
                }
                
            }
            WarMgr.inst.joinSelectCityMode(false, MapState.SelectMy);
            Core.EventCenter.inst.removeEventListener(WarMgr.SelectCity, this._reCity, this);
        }
        private async _memberChange() {
            let curCut = this._memberCnt.value;
            let curReward = this._goldCnt.value;
            let countCur = curCut;
            if (countCur == 0) {
                countCur = 1;
            }
            let maxReward = Math.min(10000, Math.floor((this._fromCity.gold - (countCur * this._money))/countCur));
            if (curReward > maxReward) {
                this._goldInput.text = maxReward.toString();
                this._goldCnt.value = maxReward;
            }
            if (maxReward <= 0) {
                this._goldCnt.max = 1;
                this._goldCnt.value = 0;
                this._goldCnt.touchable = false;
                this._goldCnt.grayed = true;
            } else {
                this._goldCnt.max = maxReward;
                this._goldCnt.touchable = true;
                this._goldCnt.grayed = false;
            }
            this._countGold();
        }
        private async _goldChange() {
            this._goldInput.text = `${this._goldCnt.value}`;
            this._countGold();
        }
        private async _countGold() {
            let num = this._memberCnt.value;
            let reward = this._goldCnt.value;
            let allGold = num * (this._money + reward);
            this._memberInput.text = num.toString();
            this._goldInput.text = reward.toString();
            this._text1.text = Core.StringUtils.format(Core.StringUtils.TEXT(70285), num * this._money);
            this._text2.text = Core.StringUtils.format(Core.StringUtils.TEXT(70286), num * reward);
            this._totalGoldText.text = allGold.toString();
            this._resCom.setNum(this._fromCity.gold - allGold);
        }
        private async _onConfirmBtn() {
            let rewardGold = parseInt(this._goldInput.text);
            let cnt = parseInt(this._memberInput.text);
            if (parseInt(this._totalGoldText.text) > this._fromCity.gold) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70287)));
            }
            if (cnt <= 0) {
                return;
            }
            let ok = await WarMgr.inst.publishMission(pb.CampaignMsType.Dispatch, rewardGold, cnt, null, this._cityPath);
            if (ok) {
                Core.ViewManager.inst.closeView(this);
            }
        }
        private _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}