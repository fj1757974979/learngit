module War {

    export class BaseFightReleaseWnd extends Core.BaseWindow {

        protected _city: City;

        protected _cityName: fairygui.GTextField;
        protected _memberCnt: fairygui.GSlider;
        protected _memberInput: fairygui.GTextField;
        protected _foodCnt: fairygui.GSlider;
        protected _foodInput: fairygui.GTextField;
        protected _foodText: fairygui.GTextField;
        protected _foodCom: CityInfoCom;

        protected _closeBtn: fairygui.GButton;
        protected _confirmBtn: fairygui.GButton;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;
            this._cityName = this.contentPane.getChild("cityName").asTextField;
            this._memberCnt = this.contentPane.getChild("memberCnt").asSlider;
            this._memberInput = this.contentPane.getChild("memberInput").asTextField;
            this._foodCnt = this.contentPane.getChild("foodCnt").asSlider;
            this._foodInput = this.contentPane.getChild("foodInput").asTextField;
            this._foodText = this.contentPane.getChild("foodTxt2").asTextField;
            this._foodCom = this.contentPane.getChild("food").asCom as CityInfoCom;

            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;

            this._closeBtn.addClickListener(this.onCloseBtn, this);

            this._memberCnt.addEventListener(fairygui.StateChangeEvent.CHANGED, this._memberInputChange, this);
            this._foodCnt.addEventListener(fairygui.StateChangeEvent.CHANGED, this._foodInputChange, this);
        }

        public async open(...param: any[]) {
            super.open(...param);

            this._city = param[0];

            this._memberCnt.getChild("title").asTextField.visible = false;
            this._foodCnt.getChild("title").asTextField.visible = false;


            this.refreshView();
        }
        protected async refreshView() {
            this._memberCnt.value = 0;
            let memberMax = this._city.inCityPlayerNum * 5;
            this._memberCnt.max = memberMax == 0? 5: memberMax;
            this._foodCnt.value = 0;
            this._foodCnt.max = this._city.forage;

            this._memberInputChange();
            this._foodInputChange();
        }

        private _memberInputChange() {
            let curMember = this._memberCnt.value;
            let curFood = this._foodCnt.value;
            this._memberInput.text = `${curMember}`;
            let countMember = curMember;
            if (countMember == 0) {
                countMember = 1;
            }
            let maxFood = Math.min(3,Math.floor(this._city.forage / countMember));
            if (curFood > maxFood) {
                this._foodInput.text = maxFood.toString();
                this._foodCnt.value = maxFood;
            }
            if (maxFood <= 0) {
                this._foodCnt.max = 1;
                this._foodCnt.touchable = false;
                this._foodCom.grayed = true;
            } else {
                this._foodCnt.max = maxFood;
                this._foodCnt.touchable = true;
                this._foodCom.grayed = false;
            }
            this._countFold();
        }
        private _foodInputChange() {
            this._foodInput.text = `${this._foodCnt.value}`;
            this._countFold();
        }
        private _countFold() {
            let curMember = this._memberCnt.value;
            let curFood = this._foodCnt.value;
            let allFood = curMember * curFood;
            if (allFood == 0) {
                this._foodText.text = ``;
            } else {
                this._foodText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70263), allFood);
            }
            if (this._cityName.text == "" || allFood > this._city.forage || curMember <= 0) {
                this._confirmBtn.touchable = false;
                this._confirmBtn.grayed = true;
            } else {
                this._confirmBtn.touchable = true;
                this._confirmBtn.grayed = false;
            }

            this._foodCom.setInfo(WarResType.Forage, this._city.forage - allFood);
        }
        
        protected async onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }

    export class QuestAttackReleaseWnd extends BaseFightReleaseWnd {

        private _toCity: City;
        private _canMoveAttackCitys: number[];
        private _selectCityBtn: fairygui.GLoader;
        
        private _cityPath: number[];
        public initUI() {
            super.initUI();
            this._selectCityBtn = this.contentPane.getChild("chooseCity").asLoader;

            this._selectCityBtn.addClickListener(this._onSelectCity, this);
            this._confirmBtn.addClickListener(this._onConfirmBtn, this);
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._cityPath = new Array<number>();
            this._canMoveAttackCitys = this._city.getNeighborEnemyCity();
            this._toCity = null;
            this._cityName.text = "";
        }
        private _refreshCity(cityID: number) {
            this._toCity = CityMgr.inst.getCity(cityID);
            this._cityName.text = this._toCity.cityName;
            this._cityPath = CityMgr.inst.getShortestPathBetweenCityForAttack(this._city, this._toCity);
            if (this._cityName.text == "" || this._memberCnt.value * this._foodCnt.value  > this._city.forage || this._memberCnt.value <= 0) {
                this._confirmBtn.touchable = false;
                this._confirmBtn.grayed = true;
            } else {
                this._confirmBtn.touchable = true;
                this._confirmBtn.grayed = false;
            }

        }
        private _onSelectCity() {
            if (this._canMoveAttackCitys.length <= 0) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70264)));
                return;
            }
            WarMgr.inst.joinSelectCityMode(true, MapState.SelectEnemy, this._canMoveAttackCitys);
            Core.EventCenter.inst.addEventListener(WarMgr.SelectCity, this._reCity, this);
        }
        private _reCity(evt: egret.Event) {
            let cityID = evt.data;
            if (cityID) {
                if (this._canMoveAttackCitys.indexOf(cityID) < 0) {
                    Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70265)));
                    return;
                }
                this._refreshCity(cityID);
            }
            WarMgr.inst.joinSelectCityMode(false, MapState.SelectEnemy,);
            Core.EventCenter.inst.removeEventListener(WarMgr.SelectCity, this._reCity, this);
        }
        private async _onConfirmBtn() {
            if (this._cityPath.length <= 0) {
                return;
            }
            // Core.TipsUtils.confirm(`确定发布进攻${this._toCity.cityName}军令吗`, () => {
            //     this._onConfirn();
            // }, null,this);
            this._onConfirn();
        }
        private async _onConfirn() {
            let ok = await WarMgr.inst.publishMilitaryOrders(this._city, pb.MilitaryOrderType.ExpeditionMT, this._foodCnt.value, this._memberCnt.value, this._cityPath);
            if (ok) {
                // this._city.forage -= this._foodCnt.value * this._memberCnt.value;
                Core.ViewManager.inst.closeView(this);
            }
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }

    export class QuestDefenseReleaseWnd extends BaseFightReleaseWnd {

        public initUI() {
            super.initUI();

            this._confirmBtn.addClickListener(this._onConfirmBtn, this);
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._cityName.text = this._city.cityName;
        }
        private _onConfirmBtn() {
            // Core.TipsUtils.confirm(`确定发布防守${this._city.cityName}军令吗`, () => {
            //     this._onConfirn();
            // }, null,this);
            this._onConfirn();
        }
        private async _onConfirn() {
            let ok = await WarMgr.inst.publishMilitaryOrders(this._city, pb.MilitaryOrderType.DefCityMT, this._foodCnt.value, this._memberCnt.value);
            if (ok) {
                // this._city.forage -= this._foodCnt.value * this._memberCnt.value;
                Core.ViewManager.inst.closeView(this);
            }
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }

    export class QuestMoveReleaseWnd extends Core.BaseWindow {

        private _city: City;
        private _toCity: City;
        private _cityPath: number[];
        private _canMoveCitys: number[];
        private _canMovePath: Collection.Dictionary<number, number[]>;

        private _cityName: fairygui.GTextField;
        private _selectCityBtn: fairygui.GLoader;
        private _memberCnt: fairygui.GSlider;
        private _memberInput: fairygui.GTextField;

        private _closeBtn: fairygui.GButton;
        private _confirmBtn: fairygui.GButton;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;

            this._cityName = this.contentPane.getChild("cityName").asTextField;
            this._selectCityBtn = this.contentPane.getChild("n24").asLoader;
            this._memberCnt = this.contentPane.getChild("memberCnt").asSlider;
            this._memberInput = this.contentPane.getChild("memberInput").asTextField;

            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;

            this._closeBtn.addClickListener(this._onCloseBtn, this);
            this._confirmBtn.addClickListener(this._onConfirmBtn, this);
            this._selectCityBtn.addClickListener(this._onSelectCity, this);
            this._memberCnt.addEventListener(fairygui.StateChangeEvent.CHANGED, this._memberChange, this);
        }
        public async open(...param: any[]) {
            super.open(...param);
            this._canMoveCitys = [];
            this._cityPath = [];
            this._canMovePath = new Collection.Dictionary<number, number[]>();
            this._city = param[0];
            let myCountryCityID = CountryMgr.inst.getCountry(MyWarPlayer.inst.countryID).cityList.keys();
            myCountryCityID.forEach(cityID => {
                if (cityID != this._city.cityID) {
                    let city = CityMgr.inst.getCity(cityID);
                    let path = CityMgr.inst.getShortestPathBetweenCityForSupportFight(this._city, city);
                    if (path.length >= 2) {
                        this._canMoveCitys.push(cityID);
                        this._canMovePath.setValue(city.cityID, path);
                    }
                }
            });
            this._toCity = null;
            this._setConfirmBtn(false);
            
            this._cityName.text = "";
            this._memberCnt.value = 0;
            this._memberCnt.getChild("title").asTextField.visible = false;
            this._memberInput.text = "0";
            // if (this._city.playerNum <= 0) {
            //     this._memberCnt.max = 1;
            //     this._memberCnt.touchable = false;
            //     this._memberCnt.grayed = true;
            // } else {
            //     this._memberCnt.max = this._city.playerNum;
            //     this._memberCnt.touchable = true;
            //     this._memberCnt.grayed = false;
            // }
            this._memberCnt.max = this._city.inCityPlayerNum <= 0? 1: this._city.inCityPlayerNum;
        }

        private _memberChange() {
            this._memberInput.text = `${this._memberCnt.value}`;
            if (this._toCity && this._memberCnt.value > 0) {
                this._setConfirmBtn(true);
            } else {
                this._setConfirmBtn(false);
            }
        }
        private _setConfirmBtn(bool: boolean) {
            this._confirmBtn.grayed = !bool;
            this._confirmBtn.touchable = bool;
        }

        private _refreshCity(cityID: number) {
            this._toCity = CityMgr.inst.getCity(cityID);
            this._cityPath = this._canMovePath.getValue(cityID);
            this._cityName.text = this._toCity.cityName;
        }
        private _onSelectCity() {
            if (this._canMoveCitys.length <= 0) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70266)));
                return;
            }
            WarMgr.inst.joinSelectCityMode(true, MapState.SelectMy, this._canMoveCitys);
            Core.EventCenter.inst.addEventListener(WarMgr.SelectCity, this._reCity, this);
        }
        private _reCity(evt: egret.Event) {
            let cityID = evt.data;
            if (cityID) {
                if (this._canMoveCitys.indexOf(cityID) < 0) {
                    return;
                }
                this._refreshCity(cityID);
            }
            WarMgr.inst.joinSelectCityMode(false, MapState.SelectMy);
            Core.EventCenter.inst.removeEventListener(WarMgr.SelectCity, this._reCity, this);
        }

        private _onConfirmBtn() {
            if (!this._toCity) {
                return;
            }
            this._onConfirm();
            // Core.TipsUtils.confirm(`确定发布军令前往${this._toCity.cityName}支援？`, ()=> {
            //     this._onConfirm();
            // }, null, this)
        }
        private async _onConfirm() {
            let ok = await WarMgr.inst.publishMilitaryOrders(this._city, pb.MilitaryOrderType.SupportMT, 0, this._memberCnt.value, this._cityPath);
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