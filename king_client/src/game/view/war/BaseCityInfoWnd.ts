module War {

    export class BaseCityInfoWnd extends Core.BaseWindow {
        protected _city: City;
        protected _country: Country;
        protected _cityObjWatchers: Core.Watcher[];

        protected _playerCnt: fairygui.GTextField;
        protected _cityName: fairygui.GTextField;
        protected _kingHead: Social.HeadCom;
        protected _kingName: fairygui.GTextField;
        protected _skillDesc: fairygui.GRichTextField;
        protected _emptyHint: fairygui.GTextField;
        protected _playerList: fairygui.GList;

        protected _campCom: CampIconCom;
        protected _defenceBar: CityInfoBar;
        protected _agricultureBar: CityInfoBar;
        protected _businessBar: CityInfoBar;
        protected _gloryCom: CityInfoCom;
        protected _forageCom: CityInfoCom;
        protected _goldCom: CityInfoCom;

        protected _closeBtn: fairygui.GButton;
        protected _allMemberBtn: fairygui.GButton;
        protected _noticeBtn: fairygui.GButton;
        protected _addGoldBtn: fairygui.GButton;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;
            this._cityObjWatchers = [];
            
            this._cityName = this.contentPane.getChild("cityName").asTextField;
            this._kingHead = this.contentPane.getChild("kingHead") as Social.HeadCom;
            this._kingName =this.contentPane.getChild("kingName").asTextField;
            this._kingName.textParser = Core.StringUtils.parseColorText;
            this._skillDesc = this.contentPane.getChild("skillDesc").asRichTextField;
            this._allMemberBtn = this.contentPane.getChild("allMemberBtn").asButton;
            this._playerCnt = this._allMemberBtn.getChild("playerCnt").asTextField;
            this._emptyHint = this.contentPane.getChild("emptyHint").asTextField;

            
            this._defenceBar = this.contentPane.getChild("chengfang").asCom as CityInfoBar;
            this._agricultureBar = this.contentPane.getChild("nongye").asCom as CityInfoBar;
            this._businessBar = this.contentPane.getChild("shangye").asCom as CityInfoBar;
            this._gloryCom = this.contentPane.getChild("rongyu").asCom as CityInfoCom;
            this._forageCom =this.contentPane.getChild("liangcao").asCom as CityInfoCom;
            this._goldCom = this.contentPane.getChild("jinbi").asCom as CityInfoCom;
            this._campCom = this.contentPane.getChild("campCom").asCom as CampIconCom;

            this._addGoldBtn = this.contentPane.getChild("addGoldBtn").asButton;
            this._noticeBtn = this.contentPane.getChild("noticeBtn").asButton;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;

            this._defenceBar.setIconUrl(Utils.warResType2Url(WarResType.Defense));
            this._businessBar.setIconUrl(Utils.warResType2Url(WarResType.Business));
            this._agricultureBar.setIconUrl(Utils.warResType2Url(WarResType.Agriculture));
            this._gloryCom.setIconUrl(WarResType.Glory)
            this._forageCom.setIconUrl(WarResType.Forage);
            this._goldCom.setIconUrl(WarResType.Gold);            

            this._defenceBar.openClick(WarResType.Defense);
            this._businessBar.openClick(WarResType.Business);
            this._agricultureBar.openClick(WarResType.Agriculture);
            this._goldCom.openClick();
            this._forageCom.openClick();
            this._gloryCom.openClick();

            this._kingHead.addClickListener(this._onKingHead, this);
            this._allMemberBtn.addClickListener(this._onMemberBtn, this);
            this._addGoldBtn.addClickListener(this._onAddGoldBtn, this);
            this._noticeBtn.addClickListener(this._onNotice, this);
            this._closeBtn.addClickListener(this._onClose, this);

            this._skillDesc.addEventListener(egret.TextEvent.LINK, async (event:egret.TextEvent) => {
                let com = await htmlClickCallback(event);
                if (com) {
                    this.addChild(com);
                    com.center();
                    com.y = this._skillDesc.y + this._skillDesc.height;
                }
            }, this);
        }
        //
        public async open(...param: any[]) {
            super.open(...param);
            this._country = null;
            let city = CityMgr.inst.getCity(param[0]);
            this._city = city;
            if (this._city.countryID != 0) {
                this._country = CountryMgr.inst.getCountry(this._city.countryID);
            }
            this._cityName.text = city.cityName;

            this.setCityDetails();
        }
        public watchCityInfo() {
            this._city.watchProp(City.PropGold, this._updateGold, this);
            this._city.watchProp(City.PropForage, this._updateForage, this);
            this._city.watchProp(City.PropGlory, this._updateGlory, this);
            this._city.watchProp(City.PropBusiness, this._updateBusiness, this);
            this._city.watchProp(City.PropAgriculture, this._updateAgriculture, this);
            this._city.watchProp(City.PropDefence, this._updateDefence, this);
            this._city.watchProp(City.PropPlayerNum, this._updatePlayerNum, this);
            this._city.watchProp(City.PropCountry, this._updateCamp, this);
            this._city.watchProp(City.PropYouMajesty, this._updateKing, this);
        }
        public unwatchCityInfo() {
            this._city.unwatchProp(City.PropGold, this._updateGold, this);
            this._city.unwatchProp(City.PropForage, this._updateForage, this);
            this._city.unwatchProp(City.PropGlory, this._updateGlory, this);
            this._city.unwatchProp(City.PropBusiness, this._updateBusiness, this);
            this._city.unwatchProp(City.PropAgriculture, this._updateAgriculture, this);
            this._city.unwatchProp(City.PropDefence, this._updateDefence, this);
            this._city.unwatchProp(City.PropPlayerNum, this._updatePlayerNum, this);
            this._city.unwatchProp(City.PropCountry, this._updateCamp, this);
            this._city.unwatchProp(City.PropYouMajesty, this._updateKing, this);
        }
        public watchCountryInfo() {
            if (this._country) {
                this._country.watchProp(Country.PropFlag, this._updateCampInfo, this);
                this._country.watchProp(Country.PropCampName, this._updateCampInfo, this);
            }
        }
        public unwatchCountryInfo() {
            if (this._country) {
                this._country.unwatchProp(Country.PropFlag, this._updateCampInfo, this);
                this._country.unwatchProp(Country.PropCampName, this._updateCampInfo, this);
            }
        }

        public setCityDetails() {
            this.setCityBaseInfo();
            this._updatePlayerNum();
            this._updateGold();
            this._updateGlory();
            this._updateForage();
            this._updateDefence();
            this._updateBusiness();
            this._updateAgriculture();          
            this._updateKing();
            this._updateCamp();
        }
        public setCityBaseInfo() { 
            this._skillDesc.text = this._city.skillLinkText;
            this._updateAddGoldBtn();
        }
        private _updateAddGoldBtn() {
            if (MyWarPlayer.inst.isMyCity(this._city.cityID)) {
                this._addGoldBtn.visible = !(this._city.countryID == 0);
            } else {
                this._addGoldBtn.visible = false;
            }
        }
        private _updateCamp() {
            this.unwatchCountryInfo();
            this._updateAddGoldBtn();
            if (this._city.countryID == 0) {
                this._campCom.setCamp(null);
            } else {
                this._country = CountryMgr.inst.getCountry(this._city.countryID);
                this._campCom.setCamp(this._country);
                this.watchCountryInfo();
            }
        }
        private _updateCampInfo() {
            this._campCom.setCamp(this._country);
        }
        private _updateGold() {
            this._goldCom.setNum(this._city.gold);
        }
        private _updateForage () {
            this._forageCom.setNum(this._city.forage);
        }
        private _updateGlory() {
            this._gloryCom.setNum(this._city.glory/10);
        }
        private _updateAgriculture() {
            this._agricultureBar.setProgress(this._city.agriculture, this._city.agricultureMax);
            this._agricultureBar.setProgress2(0, this._city.agricultureMax);
        }
        private _updateDefence() {
            this._defenceBar.setProgress(this._city.defence, this._city.defenceMax);
            this._defenceBar.setProgress2(0, this._city.defenceMax);
        }
        private _updateBusiness() {
            this._businessBar.setProgress(this._city.business, this._city.businessMax);
            this._businessBar.setProgress2(0, this._city.businessMax);
        }
        private async _updateKing() {
            this._kingHead.visible = false;
            this._kingName.visible = false;
            if(this._city.countryID != 0) {
                let yourMajesty = this._city.yourMajesty;
                if (yourMajesty) {
                    this._kingHead.visible = true;
                    this._kingName.visible = true;
                    this._kingHead.setAll(yourMajesty.HeadImg, yourMajesty.HeadFrame);
                    this._kingName.text = yourMajesty.Name;
                }
            }
        }
        private async _updatePlayerNum() {
            this._playerCnt.text = this._city.playerNum.toString();
        }
        private async _onMemberBtn() {
            let memberList = await WarMgr.inst.fetchCityMember(this._city.cityID, 0);
            if (memberList) {
                Core.ViewManager.inst.open(ViewName.allMemberPanel, this._city, memberList);
            }
        }
        private async _onAddGoldBtn() {
            if (WarMgr.inst.checkWarIsOver()) {
                return;
            }
            Core.ViewManager.inst.open(ViewName.addGoldWnd, this._city);
        }
        private async _onNotice() {
            let args = {CityID: this._city.cityID};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_CITY_NOTICE, pb.TargetCity.encode(args));
            if (result.errcode == 0) {
                let str = pb.CityNotice.decode(result.payload).Notice;
                let can = (this._city.cityID == MyWarPlayer.inst.cityID && MyWarPlayer.inst.employee.canNotice());
                Core.ViewManager.inst.open(ViewName.cityNoticeWnd, str, can);
            }
        }
        private async _onKingHead() {
            if (this._city.countryID == 0) {
                return;
            }
            let id = <Long>this._city.yourMajesty.Uid;
            let playerInfo = await Social.FriendMgr.inst.fetchPlayerInfo(id);
			if (playerInfo) {
			    Core.ViewManager.inst.open(ViewName.friendInfo, <Long>id, playerInfo);
			}
        }
        public _onClose() {
            Core.ViewManager.inst.closeView(this);
        }
        
        public async close(...param: any[]) {
            super.close(...param);
            WarMgr.inst.nowSelectCity = null;
            this._cityObjWatchers.forEach(w => {
                w.unwatch();
            })
            this._cityObjWatchers = [];
            WarMgr.inst.nowSelectCity = null;
        }

    }


}