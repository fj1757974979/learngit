module War {
    
    export class WarHomeView extends Core.BaseView {

        private _closeBtn: fairygui.GButton;
        private _cityBtn: fairygui.GButton;
        private _questBtn: fairygui.GButton;
        private _fightBtn: fairygui.GButton;
        private _defenseBtn: fairygui.GButton;
        private _commonFunction: fairygui.GList;
        private _setupBtn: fairygui.GButton;
        private _publicPlatformBtn: fairygui.GButton;
        private _moreCtr: fairygui.Controller;
        private _functionList: fairygui.GList;
        private _worldBtn: fairygui.GButton;
        private _noticeBtn: fairygui.GButton;
        private _warShopBtn: fairygui.GButton;
        private _countryAppointBtn: fairygui.GButton;

        private _topTipPanel: WarHomeTipPanel;
        private _gameOverPanel: WarGameOverPanel;
        private _fightPanel: WarFightStatusPanel;
        private _map: MainMap;
        private _mapParent: fairygui.GComponent;
        private _mapBackBtn: fairygui.GButton;
        private _selectCity: fairygui.GComponent;

        private _battlePointText: fairygui.GTextField;
        private _battleIcon: fairygui.GLoader;

        public initUI() {
            super.initUI();
            this.adjust(this.getChild("bg"));
            this._mapParent = this.getChild("map").asCom;
            this._map = this._mapParent.getChild("map").asCom as MainMap;
            this._mapBackBtn = this._mapParent.getChild("backBtn").asButton;
            this._mapBackBtn.visible = false;
            this._mapBackBtn.addClickListener(() => {
                Core.EventCenter.inst.dispatchEventWith(WarMgr.SelectCity, false);
            }, this);
            this._selectCity = this._mapParent.getChild("selectCityPanel").asCom;
            this._selectCity.visible = false;
            
            this._moreCtr = this.getController("more");
            this._closeBtn =  this.getChild("n2").asButton;
            this._cityBtn = this.getChild("cityBtn").asButton;
            this._questBtn = this.getChild("questBtn").asButton;
            this._fightBtn = this.getChild("fightBtn").asButton;
            this._warShopBtn = this.getChild("shopBtn").asButton;
            // this._defenseBtn = this.getChild("defenseBtn").asButton;
            this._topTipPanel = this.getChild("selectCityPanel").asCom as WarHomeTipPanel;
            this._gameOverPanel = this.getChild("n17").asCom as WarGameOverPanel;
            this._gameOverPanel.visible = false;
            this._fightPanel = this.getChild("n14").asCom as WarFightStatusPanel;
            this._fightPanel.visible = false;
            this._functionList = this.getChild("commonFunction").asList;
            this._worldBtn = this._functionList.getChild("worldBtn").asButton;
            this._noticeBtn = this._functionList.getChild("noticeBtn").asButton;
            this._countryAppointBtn = this.getChild("countryAppointBtn").asButton;
            this._battlePointText = this.getChild("battlePoint").asTextField;
            this._battleIcon = this.getChild("battleIcon").asLoader;

            this._cityBtn.addClickListener(this._onMyCity, this);
            this._questBtn.addClickListener(this._onQuest, this);
            this._closeBtn.addClickListener(this._onCloseBtn, this);
            this._worldBtn.addClickListener(this._onWorldBtn, this);
            this._noticeBtn.addClickListener(this._onNoticeBtn, this);
            this._countryAppointBtn.addClickListener(this._onCountryAppointBtn,this);
            this._battleIcon.addClickListener(this._onBattleIcon, this);
            this._fightBtn.addClickListener(this._onFightBtn, this);
            this._warShopBtn.addClickListener(this._onWarShopBtn, this);

            this.getChild("battlePointBg").asLoader.y += window.support.topMargin;
            this.getChild("selectCityPanel").asCom.y += window.support.topMargin;
        }

        public get fightStatusPanel(): WarFightStatusPanel {
            return this._fightPanel;
        }

        public get arrestPanel(): WarGameOverPanel {
            return this._gameOverPanel;
        }

        public get warStatusPanel(): WarHomeTipPanel {
            return this._topTipPanel;
        }

        public get fightBtn(): fairygui.GButton {
            return this._fightBtn;
        }
        public get questBtn(): fairygui.GButton {
            return this._questBtn;
        }
        
        private async _onMyCity() {
            this._map.moveCenter();
            if (MyWarPlayer.inst.cityID && MyWarPlayer.inst.cityID != 0) {
                WarMgr.inst.openMyCityInfo();
            }
        }
        private async _onQuest() {
            if (MyWarPlayer.inst.inStatus(PlayerStatusName.ST_ARREST)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70317));
                return;
            }
            if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING) || WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70318));
                return;
            }
            this._questBtn.getChild("n7").visible = false;
            WarMgr.inst.openMyQuestInfo();
        }
        private async _onWorldBtn() {
            WarMgr.inst.openCityListPanel();
        }
        private async _onNoticeBtn() {
            if (!MyWarPlayer.inst.countryID || MyWarPlayer.inst.countryID == 0) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70374));
                return;
            }
            this._noticeBtn.getChild("n6").visible = false;
            Core.ViewManager.inst.open(ViewName.warNoticePanel);
            // let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_CAMPAIGN_NOTICE, null);
            // if (result.errcode == 0) {
            //     this._noticeBtn.getChild("n6").visible = false;
            //     let reply = pb.CampaignNoticeInfo.decode(result.payload);
            //     Core.ViewManager.inst.open(ViewName.warNoticePanel, reply);
            // }
        }

        private async _onCountryAppointBtn() {
            if (MyWarPlayer.inst.inStatus(PlayerStatusName.ST_ARREST)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70373));
                return;
            }
            let country = CountryMgr.inst.getCountry(MyWarPlayer.inst.countryID);
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_COUNTRY_JOB_PLAYERS, null);
            if (result.errcode == 0) {
                let reply = pb.CampaignPlayerList.decode(result.payload);
                
                country.setCountryPlayers(reply.Players);
            }
            Core.ViewManager.inst.open(ViewName.countryAppointPanel, country);
        }
        private _onBattleIcon() {
            let com = fairygui.UIPackage.createObject(PkgName.cards, ViewName.skillInfo).asCom;
            com.getChild("skillDescTxt").asRichTextField.text = Core.StringUtils.TEXT(70214);
            this._parent.addChild(com);
            let onTouch;
            onTouch = function() {
                com.parent.removeChild(com);
                egret.MainContext.instance.stage.removeEventListener(egret.TouchEvent.TOUCH_END, onTouch, com);
            }
            egret.MainContext.instance.stage.addEventListener(egret.TouchEvent.TOUCH_END, onTouch, com);
            com.center();
            com.y = this._battleIcon.y + this._battleIcon.height;
        }
        private async _onFightBtn() {
            if (MyWarPlayer.inst.inStatus(PlayerStatusName.ST_ARREST)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70319));
                return;
            }
            let locationCityID = MyWarPlayer.inst.locationCityID;
            if (!locationCityID || locationCityID == 0) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70320));
                return;
            }
            if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING) || WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                let city = CityMgr.inst.getCity(locationCityID);
                let ok = await WarMgr.inst.fetchMilitaryOrders(city);
                if (ok) {
                    this._map.moveCenter(city);
                    Core.ViewManager.inst.open(ViewName.questFightPanel, city);
                }
            } else {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70321));
                return;
            }
        }
        private async _onWarShopBtn() {
            let ok = await Equip.EquipMgr.inst.fetchEquip();
            if (ok) {
                Core.ViewManager.inst.open(ViewName.warShopView);
            }
        }
        private async _onCloseBtn() {
            if (WarTeamMgr.inst.myTeam) {
                return;
            }
            //关闭政令监听
            Core.ViewManager.inst.closeView(this);
        }
        public setCloseBtn(bool: boolean) {
            this._closeBtn.visible = bool;
        }

        public get mapView(): MainMap {
            return this._map;
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._noticeBtn.getChild("n6").asCom.getChild("textNum").visible = false;
            this._moreCtr.selectedIndex = 0;
            // await this._map.initCityComs();
            this._map.loadResMap();
            this._fightPanel.closePanel();
            this.setCloseBtn(true);
            // this._map.dayPassTimerStart();
            // this._refreshHomeView();
            //监听政令按钮的变化
            Core.ViewManager.inst.getView(ViewName.newHome).setVisible(false);
            Core.EventCenter.inst.addEventListener(WarMgr.ShowNotifyRedDot, this._showNotifyReDot, this);
            Core.EventCenter.inst.addEventListener(WarMgr.ShowMissionRedDot, this._showMissionReDot, this);
            this.watch();
            // WarMgr.inst.updateState(WarState.ReadyWar, 6000);
        }

        public initMap() {
            this._map.initSize();
            this._map.beginDragDetect();
        }

        public watch() {
            MyWarPlayer.inst.watchProp(MyWarPlayer.PropLocationCity, this._updateCityBtn, this);
            MyWarPlayer.inst.watchProp(MyWarPlayer.PropCity, this._updateQuestBtn, this);
            MyWarPlayer.inst.watchProp(MyWarPlayer.PropCountry, this.refreshHomeView, this);
            MyWarPlayer.inst.watchProp(MyWarPlayer.PropContribution, this._updateContribution, this);
            this._fightPanel.watch();
        }
        public unwatch() {
            MyWarPlayer.inst.unwatchProp(MyWarPlayer.PropLocationCity, this._updateCityBtn, this);
            MyWarPlayer.inst.unwatchProp(MyWarPlayer.PropCity, this._updateQuestBtn, this);
            MyWarPlayer.inst.unwatchProp(MyWarPlayer.PropCountry, this.refreshHomeView, this);
            MyWarPlayer.inst.unwatchProp(MyWarPlayer.PropContribution, this._updateContribution, this);
            this._fightPanel.unwatch();
        }
        private _updateCityBtn() {
            let bool = (MyWarPlayer.inst.locationCityID != 0);
            this._cityBtn.touchable = bool;
            this._cityBtn.grayed = !bool;
            this._fightBtn.touchable = bool;
            this._fightBtn.grayed = !bool;
        }
        private _updateQuestBtn() {
            let bool = false;
            if (MyWarPlayer.inst.cityID == 0) {
                bool = false;
            } else {
                let city = CityMgr.inst.getCity(MyWarPlayer.inst.cityID);
                if (city && city.countryID != 0) {
                    bool = true;
                }
            }
            this._questBtn.touchable = bool;
            this._questBtn.grayed = !bool;
        }
        public updateFightAndQuest() {
            if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING) || WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                this._fightBtn.visible = true;
                this._questBtn.visible = false;
            } else {
                this._fightBtn.visible = false; 
                this._questBtn.visible = true;
            }
        }
        private _updateCountryBtn() {
            this._countryAppointBtn.visible = (MyWarPlayer.inst.countryID != 0);
        }

        private _updateContribution() {
            this._battlePointText.text = `${MyWarPlayer.inst.contribution}`;
        }
        public updateFightTip() {
            if (MyWarPlayer.inst.inStatus(PlayerStatusName.ST_DEFEND)) {
                    this._fightPanel.updateDefendStatus();
                } else if (MyWarPlayer.inst.inStatus(PlayerStatusName.ST_EXPEDITION)) {
                    this._fightPanel.updateExpeditionStatus();
                } else if (MyWarPlayer.inst.inStatus(PlayerStatusName.ST_SUPPORT)) {
                    this._fightPanel.updateSupportStatus();
                }
        }
        public updateHomeTip() {
            if (WarMgr.inst.inStatus(BattleStatusName.ST_NORMAL)) {
                    this._topTipPanel.showTipNormal();
                } else if (WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                    this._topTipPanel.showTipPrePare();
                } else if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING)) {
                    this._topTipPanel.showTipInWar();
                }
        }
        public joinSelectMode(bool: boolean, mode: MapState) {
            this._mapBackBtn.visible = bool;
            this._selectCity.visible = bool;
            let point = null;
            let uiRoot = fairygui.GRoot.inst;
            if (bool) {
                point = this.localToGlobal(this._mapParent.x, this._mapParent.y);
                Core.LayerManager.inst.mainLayer.addChild(this._mapParent);
                let localPoint = Core.LayerManager.inst.mainLayer.globalToLocal(point.x, point.y);
                this._mapParent.x = localPoint.x;
                this._mapParent.y = localPoint.y;
                if (mode == MapState.Transport) {
                    this._selectCity.getChild("txt2").text = Core.StringUtils.TEXT(70322);
                } else if (mode == MapState.SelectMy) {
                    this._selectCity.getChild("txt2").text = Core.StringUtils.TEXT(70323);
                } else if (mode == MapState.SelectEnemy) {
                    this._selectCity.getChild("txt2").text = Core.StringUtils.TEXT(70324);
                } else if (mode == MapState.SurrenderCity) {
                    this._selectCity.getChild("txt2").text = Core.StringUtils.TEXT(70325);
                } else if (mode == MapState.SurrenderCamp) {
                    this._selectCity.getChild("txt2").text = Core.StringUtils.TEXT(70326);
                }
            } else {
                point = Core.LayerManager.inst.mainLayer.localToGlobal(this._mapParent.x, this._mapParent.y);
                this.addChild(this._mapParent);
                this.setChildIndex(this._mapParent, 1);
                let localPoint = this.globalToLocal(point.x, point.y);
                this._mapParent.x = localPoint.x;
                this._mapParent.y = localPoint.y;
            }
        }
        public async refreshHomeView() {
            // if (MyWarPlayer.inst.isCaptive) { //俘虏状态
            //     //显示俘虏操作面板
            //     this._gameOverPanel.showPanel();
            //     //隐藏所有操作面板
            this._topTipPanel.closeTip();  
            this._fightBtn.getChild("n7").visible = false;
            this._fightBtn.getChild("time").visible = false;
            
            if (MyWarPlayer.inst.inStatus(PlayerStatusName.ST_ARREST)) {
                this._gameOverPanel.showPanel();
            } else {
                this._gameOverPanel.closePanel();
                this.updateFightTip();
                this.updateHomeTip();
                
            }
            this._questBtn.getChild("n7").visible = WarMgr.inst.hasCompleteMisson;
            this._noticeBtn.getChild("n6").visible = WarMgr.inst.hasNewNotice;

            this._questBtn.getChild("time").visible = false;
            this.updateFightAndQuest();
            this._updateCityBtn();
            this._updateContribution();
            this._updateCountryBtn();
            this._updateQuestBtn();

        }
        //event 
        private async _refreshMapCity(evt: egret.Event) {
            let cityID = <number>evt.data;
            this._map.refreshCity(cityID);
        }
        private async _showNotifyReDot(evt: egret.Event) {
            this._noticeBtn.getChild("n6").visible = evt.data;
        }
        private async _showMissionReDot() {
            this._questBtn.getChild("n7").visible = true;
        }
        
        

        public async close(...param: any[]) {
            super.close(...param);
            this.unwatch();
            this._map.destroyResMap();
            WarMgr.inst.onDestroy();
            // Core.EventCenter.inst.removeEventListener(WarMgr.RefreshWarHome, this._refreshHomeView, this);
            // Core.EventCenter.inst.removeEventListener(WarMgr.RefreshAllCityCom, this._refreshAllCity, this);
            await Net.rpcPush(pb.MessageID.C2S_LEAVE_CAMPAIGN_SCENE, null);
            Core.ViewManager.inst.getView(ViewName.newHome).setVisible(true);
        }

        public get map(): MainMap {
            return this._map;
        }
        public get warTipPanel(): WarHomeTipPanel {
            return this._topTipPanel;
        }
    }
}
