module War {
    export class QuestFightItem extends fairygui.GComponent {
        private _city: City;
        private _mission: pb.IMilitaryOrder;

        private _bg: fairygui.GLoader;
        private _titleText: fairygui.GTextField;
        private _text: fairygui.GTextField;
        private _foodText: fairygui.GTextField;
        private _confirmBtn: fairygui.GButton;
        private _backBtn: fairygui.GButton;
        private _isLocationCtr: fairygui.Controller;
        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._bg = this.getChild("bg").asLoader;
            this._titleText = this.getChild("title").asTextField;
            this._text = this.getChild("text").asTextField;
            this._foodText = this.getChild("foodCnt").asTextField;
            this._confirmBtn = this.getChild("n20").asButton;
            this._backBtn = this.getChild("backBtn").asButton;
            this._isLocationCtr = this.getController("islocation");
            this._confirmBtn.addClickListener(this._onConfirmBtn, this);
            this._backBtn.addClickListener(this._onBackBtn, this);
        }

        public setLocation() {
            this._isLocationCtr.selectedIndex = 1;
            this._confirmBtn.visible = false;
            let city = CityMgr.inst.getCity(MyWarPlayer.inst.locationCityID);
            let mycity = CityMgr.inst.getCity(MyWarPlayer.inst.cityID);
            this._titleText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70271), mycity.cityName);
            this._text.text = Core.StringUtils.format(Core.StringUtils.TEXT(70272), city.cityName ,mycity.cityName);
            this._backBtn.title = Core.StringUtils.format(Core.StringUtils.TEXT(70273));
            
        }
        public setMission(miss: pb.IMilitaryOrder, isNomral: boolean, locationCity: City) {
            this._isLocationCtr.selectedIndex = 0;
            this._confirmBtn.visible = isNomral;
            this._mission = miss;
            this._city = locationCity;
            this._foodText.text = this._mission.Forage.toString();
            let city = CityMgr.inst.getCity(this._mission.TargetCity);
            if (this._mission.Type == pb.MilitaryOrderType.DefCityMT) {
                let city = CityMgr.inst.getCity(MyWarPlayer.inst.locationCityID);
                this._bg.url = "war_defenseBg_png";
                this._titleText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70274), city.cityName);
                this._text.text = Core.StringUtils.format(Core.StringUtils.TEXT(70275), city.cityName);
            } else if (this._mission.Type == pb.MilitaryOrderType.ExpeditionMT) {
                this._bg.url = "war_attackBg_png";
                this._titleText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70276), city.cityName);
                this._text.text = Core.StringUtils.format(Core.StringUtils.TEXT(70277), city.cityName);
            } else if (this._mission.Type == pb.MilitaryOrderType.SupportMT) {
                this._bg.url = "war_moveBg_png";
                this._titleText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70278), city.cityName);
                this._text.text = Core.StringUtils.format(Core.StringUtils.TEXT(70279), city.cityName);
                this._foodText.visible = false;
                this.getChild("foodIcon").asLoader.visible = false;
            }
            
        }
        private _onBackBtn() {
            Core.TipsUtils.confirm(Core.StringUtils.TEXT(70280), () => {
                this._onBack();
            }, null, this);
        }
        private async _onBack() {
            //撤军
            let result = await Net.rpcCall(pb.MessageID.C2S_CAMPAIGN_BACK_CITY, null);
            if (result.errcode == 0) {
                Core.ViewManager.inst.close(ViewName.questFightPanel);
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70281)));
            }
        }

        private _onConfirmBtn() {
            if (this._mission.Type != pb.MilitaryOrderType.SupportMT && WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70282)));
                return;
            }
            if (this._mission.Type != pb.MilitaryOrderType.DefCityMT && this._city.inStatus(CityStatusName.ST_ATTACKED)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70283)));
                return;
            }
            if (MyWarPlayer.inst.cityID != MyWarPlayer.inst.locationCityID) {
                Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70284)), ()=> {
                    this._onConfirm();
                }, null, this);
            } else {
                Core.ViewManager.inst.open(ViewName.choiceFightCardWnd, this._mission);
            }
            
        }
        private async _onConfirm() {
            if (this._mission.Type != pb.MilitaryOrderType.DefCityMT && this._city.inStatus(CityStatusName.ST_ATTACKED)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70283)));
                return;
            }
            //驻扎状态直接接受军令
            let ok = await WarMgr.inst.acceptMilitaryOrder(this._mission.Type, MyWarPlayer.inst.supportCards, this._mission.TargetCity);
            if (ok) {
                Core.ViewManager.inst.close(ViewName.questFightPanel);
            }
        }
    }

    export class QuestFightPanel extends Core.BaseWindow {

        private _city: City;

        private _questList: fairygui.GList;
        private _closeBtn: fairygui.GButton;
        private _emptyHint: fairygui.GTextField;

        public initUI() {
            super.initUI();
            this.modal = true;
            this.center();
            
            this._questList = this.contentPane.getChild("questList").asList;
            this._questList.itemClass = QuestFightItem;
            
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._closeBtn.addClickListener(this._onCloseBtn, this);

            this._emptyHint = this.contentPane.getChild("emptyHint").asTextField;
        }
        public async open(...param: any[]) {
            super.open(...param);
            this._city = param[0];
            this._emptyHint.visible = (this._city.militaryOrderInfo.length <= 0);
            this._refreshList();
            this._watch();
        }
        private _watch() {
            this._city.watchProp(City.PropMilitaryOrderInfo, this._refreshList, this);
        }

        private _unwatch() {
            this._city.unwatchProp(City.PropMilitaryOrderInfo, this._refreshList, this);
        }

        private async _refreshList() {
            this._questList.removeChildrenToPool();
            //非Nomral状态无法接任务
            let isNomral = MyWarPlayer.inst.inStatus(PlayerStatusName.ST_NORMAL);
            //所在城市与所属城市不同且状态在Nomral说明处于驻扎状态
            if (MyWarPlayer.inst.cityID != MyWarPlayer.inst.locationCityID && isNomral) {
                let com = this._questList.addItemFromPool().asCom as QuestFightItem;
                com.setLocation();
            }
            let quests = this._city.militaryOrderInfo;
            quests.forEach( _quest => {
                if (_quest.Amount > 0) {
                    let com = this._questList.addItemFromPool().asCom as QuestFightItem;
                    com.setMission(_quest, isNomral, this._city);
                }
            })
        }
        private _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }
        public async close(...param: any[]) {
            super.close(...param);
            this._unwatch();
        }
    }
}