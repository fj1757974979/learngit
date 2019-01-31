module War {

    export class CityManageFightItem extends fairygui.GComponent {
        private _bg: fairygui.GLoader;
        private _titleText: fairygui.GTextField;
        private _budgetText: fairygui.GTextField;
        private _stopBtn: fairygui.GButton;

        private _mission: pb.IMilitaryOrder;
        protected constructFromXML(xml: any): void {
            this._bg = this.getChild("bg").asLoader;
            this._titleText = this.getChild("title").asTextField;
            this._budgetText = this.getChild("Budget").asTextField;
            this._stopBtn = this.getChild("stopBtn").asButton;

            this._stopBtn.addClickListener(this._onStopBtn, this);
        }
        public setFightInfo(missInfo: pb.IMilitaryOrder) {
            // this._titleText.text = missInfo.TargetCity
            this._mission = missInfo;
            this._budgetText.text = `${missInfo.MaxAmount - missInfo.Amount}/${missInfo.MaxAmount}`;
            if (missInfo.Type == pb.MilitaryOrderType.DefCityMT) {
                this._bg.url = "war_defenseBg_png";
                this._titleText.text = Core.StringUtils.TEXT(70246);
            } else if (missInfo.Type == pb.MilitaryOrderType.ExpeditionMT) {
                this._bg.url = "war_attackBg_png";
                this._titleText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70247), CityMgr.inst.getCity(missInfo.TargetCity).cityName);
            } else if (missInfo.Type == pb.MilitaryOrderType.SupportMT) {
                this._bg.url = "war_moveBg_png";
                this._titleText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70248), CityMgr.inst.getCity(missInfo.TargetCity).cityName);
            }
        }
        private _onStopBtn() {
            Core.TipsUtils.confirm(Core.StringUtils.TEXT(70249), () => {
                this._onStop();
            } , null, this);
        }
        private async _onStop() {
            let args = {Type: this._mission.Type, TargetCity: this._mission.TargetCity};
            let result = await Net.rpcCall(pb.MessageID.C2S_CANCEL_MILITARY_ORDER, pb.TargetMilitaryOrder.encode(args));
            if (result.errcode == 0) {
                let reply = pb.CancelMilitaryOrderReply.decode(result.payload);
                let city = CityMgr.inst.getCity(MyWarPlayer.inst.cityID);
                if (city) {
                    city.forage = reply.Forage;
                }
                this.visible = false;
            }
        }
    }

    export class CityManageFightCom extends fairygui.GComponent {

        private _city: City;

        private _fightBtn: fairygui.GButton;
        private _defenceBtn: fairygui.GButton;
        private _expeditionBtn: fairygui.GButton;
        private _emptyHint: fairygui.GTextField;
        private _fightList: fairygui.GList;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);

            this._fightList = this.getChild("list").asList;
            this._fightList.itemClass = CityManageFightItem;
            this._fightList.foldInvisibleItems = true;

            this._fightBtn = this.getChild("attackBtn").asButton;
            this._defenceBtn = this.getChild("defenseBtn").asButton;
            this._expeditionBtn = this.getChild("moveBtn").asButton;
            this._emptyHint = this.getChild("emptyHint").asTextField;

            this._fightBtn.addClickListener(this._onFightBtn, this);
            this._defenceBtn.addClickListener(this._onDefenceBtn, this);
            this._expeditionBtn.addClickListener(this._onExpeditionBtn, this);

        }
        public async openFightWnd(city: City) {
            this._city = city;
            this.refreshList();
        }

        public async watch() {
            this._city.watchProp(City.PropMilitaryOrderInfo, this.refreshList, this);
        }
        public async unWatch() {
            this._city.unwatchProp(City.PropMilitaryOrderInfo, this.refreshList, this);
        }

        public refreshList() {
            this._fightList.removeChildrenToPool();
            let miss = this._city.militaryOrderInfo;
            this._emptyHint.visible = (miss.length <= 0);
            miss.forEach( _miss => {
                if (_miss.Amount >= 0) {
                    let com = this._fightList.addItemFromPool().asCom as CityManageFightItem;
                    com.visible = true;
                    com.setFightInfo(_miss);
                }
            })
        }

        private _onFightBtn() {
            Core.ViewManager.inst.open(ViewName.questAttackReleaseWnd, this._city);
        }
        private _onDefenceBtn() {
            Core.ViewManager.inst.open(ViewName.questDefenseReleaseWnd, this._city);
        }
        private _onExpeditionBtn() {
            Core.ViewManager.inst.open(ViewName.questMoveReleaseWnd, this._city);
        }
    }
}