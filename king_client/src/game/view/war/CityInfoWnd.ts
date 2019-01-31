module War {

    export class CityInfoWnd extends BaseCityInfoWnd {

        private _moreBtn: fairygui.GButton;
        private _enterBtn: fairygui.GButton;
        private _applyBtn: fairygui.GButton;
        // private _fightBtn: fairygui.GButton;
        private _appointBtn: fairygui.GButton;
        private _moveBtn: fairygui.GButton;

        private _applyTimeText: fairygui.GTextField;

        private _page: number;

        public initUI() {
            super.initUI();

            this._applyTimeText = this.contentPane.getChild("time").asTextField;

            this._playerList = this.contentPane.getChild("playList").asList;
            // this._playerList.itemClass = WarPlayerItem;
            this._playerList._scrollPane.addEventListener(fairygui.ScrollPane.PULL_UP_RELEASE, this._getApplyPLayers, this);

            this._applyBtn = this.contentPane.getChild("applyBtn").asButton;
            this._moreBtn = this.contentPane.getChild("moreBtn").asButton;
            this._enterBtn = this.contentPane.getChild("enterBtn").asButton;
            this._appointBtn = this.contentPane.getChild("appointBtn").asButton;
            this._moveBtn = this.contentPane.getChild("moveBtn").asButton;

            this._moreBtn.addClickListener(this._onMore, this);
            this._enterBtn.addClickListener(this._onEnter, this);
            this._applyBtn.addClickListener(this._onApplyBtn, this);
            this._moveBtn.addClickListener(this._onEnter, this);
            this._appointBtn.addClickListener(this._onAppointBtn, this);
        }
              
        public async open(...param: any[]) {
            super.open(...param);
            let city = CityMgr.inst.getCity(param[0])
            this._city = city;
            
            this._setCityDetails();
            this.watch();
            Core.EventCenter.inst.addEventListener(WarMgr.RefreshCityInfo, this._setCityBaseInfo, this);
        }
        private async _setCityDetails() {
            super.setCityBaseInfo();
            this._setCityBaseInfo();
            this._updatePlayer();          
        }
        //加入
        private _updateEnterBtn() {
            if (WarMgr.inst.inStatus(BattleStatusName.ST_NORMAL)) {
                this._enterBtn.grayed = false;
                this._enterBtn.visible = false;
                if (this._city.cityID == MyWarPlayer.inst.cityID) {
                    this._enterBtn.visible = false;
                } else if (MyWarPlayer.inst.cityID == 0 || MyWarPlayer.inst.countryID == 0) {
                    this._enterBtn.visible = true;
                } else {
                    this._enterBtn.visible = false;
                }
            } else {
                if (MyWarPlayer.inst.countryID == 0) {
                    this._enterBtn.visible = true;
                    this._enterBtn.grayed = true;
                } else {
                    this._enterBtn.visible = false;
                }
            }
        }
        //迁移
        private _updateMoveBtn() {
            this._moveBtn.visible = false;
            if (WarMgr.inst.inStatus(BattleStatusName.ST_NORMAL)) {
                if (this._city.cityID != MyWarPlayer.inst.cityID && MyWarPlayer.inst.countryID != 0 && this._city.countryID == MyWarPlayer.inst.countryID) {
                    this._moveBtn.visible = true;
                }
            }
        }
        //内政
        private _updateMoreBtn() {
            this._moreBtn.visible = false;
            this._moreBtn.grayed = true;

            if (MyWarPlayer.inst.isMyCity(this._city.cityID) && this._city.countryID != 0) {
                this._moreBtn.visible = true;
                if (MyWarPlayer.inst.employee.hasSameJob(Job.Prefect)) {
                    this._moreBtn.grayed = false;
                }
            }
        }
        //任免
        private _updateAppointBtn() {
            this._appointBtn.visible = true;
            if (MyWarPlayer.inst.isMyCity(this._city.cityID) && this._city.countryID != 0) {
                // this._appointBtn.visible = true;
                this._appointBtn.grayed = false;
                this._appointBtn.touchable = true;
            } else if (MyWarPlayer.inst.isMyCountryCity(this._city.cityID) && MyWarPlayer.inst.employee.hasSameJob(Job.YourMajesty)) {
                // this._appointBtn.visible = true;
                this._appointBtn.grayed = false;
                this._appointBtn.touchable = true;
            } else if (MyWarPlayer.inst.isMyCountryCity(this._city.cityID)) {
                this._appointBtn.grayed = true;
                this._appointBtn.touchable = false;
            } else {
                this._appointBtn.visible = false;
                 this._appointBtn.grayed = true;
            }
        }
        //军事
        private _updateFightBtn() {
            // this._fightBtn.visible = false;
            // this._fightBtn.grayed = true;
            // if (MyWarPlayer.inst.isMyCity(this._city.cityID) && this._city.countryID != 0) {
            //     this._fightBtn.visible = true;
            //     if (this._city.inStatus(CityStatusName.ST_FALLEN)) {
            //         this._fightBtn.grayed = true;
            //     } else if (MyWarPlayer.inst.employee.hasSameJob(Job.Prefect)) {
            //         this._fightBtn.grayed = (WarMgr.inst.inStatus(BattleStatusName.ST_NORMAL));
            //     }                        
            // } else if (MyWarPlayer.inst.isMyCountryCity(this._city.cityID) && MyWarPlayer.inst.employee.hasSameJob(Job.YourMajesty)) {
            //     this._fightBtn.grayed = true;
            //     this._fightBtn.visible = true;
            // }
        }
        //竞选
        private _updateAppFightBtn() {
            this._applyBtn.visible = false;
            this._applyTimeText.visible = false;
            this._createTimerStop();
            if (MyWarPlayer.inst.isMyCity(this._city.cityID) && this._city.countryID == 0) {
                this._applyBtn.visible = true;
                this._applyTimeText.visible = true;
                if (this._city.createTime > 0) {
                    this._createTimerStart();
                }
            }
        }
        //一些按钮的显示
        private async _setCityBaseInfo() {
            //奴隶状态
            if (MyWarPlayer.inst.inStatus(PlayerStatusName.ST_ARREST)) {
                this._moreBtn.visible = false;
                this._enterBtn.visible = false;
                this._applyBtn.visible = false;
                // this._fightBtn.visible = false;
                this._appointBtn.visible = false;
                this._moveBtn.visible = false;
            } else {
                this._updateEnterBtn();
                this._updateMoreBtn();
                this._updateAppFightBtn();
                this._updateFightBtn();
                this._updateMoveBtn();
                this._updateAppointBtn();
            }
        }
        private async _updatePlayer() {
            let players = [];
            for (let i = this._playerList.numItems - 1; i >= 0; i--) {
                this._playerList.removeChildAt(i);
            }
            if (this._city.countryID == 0) {
                players = this._city.applyPlayers;
                this.contentPane.getChild("emptyHint").visible = true;
                if (players.length > 0) {
                    this.contentPane.getChild("emptyHint").visible = false;
                    this._page = 0;
                } else {
                    this._page = -1;
                }
                this._addPlayer(players, true);
                
            } else {
                this._page = -1;
                
                players = this._city.players;
                if (players.length > 0) {
                    this.contentPane.getChild("emptyHint").visible = false;
                    this._addPlayer(players, false);
                } else {
                    this.contentPane.getChild("emptyHint").visible = true;
                }
            }
        }
        private _addPlayer(players: any[], noCountry: boolean) {
            if (noCountry) {
                for(let i = 0; i < players.length; i++) {
                    let com = fairygui.UIPackage.createObject(PkgName.war, "emperorApplyItem") as EmperorApplyItem;
                    com.setInfo(players[i]);
                    this._playerList.addChild(com);
                }
            } else {
                for(let i = 0; i < players.length; i++) {
                    let com = fairygui.UIPackage.createObject(PkgName.war, "playerItem") as WarPlayerItem;
                    com.setInfo(players[i]);
                    this._playerList.addChild(com);
                }
            }
            
        }
        private async _getApplyPLayers() {
            if (this._page < 0) {
                return;
            }
            let args = {CityID: this._city.cityID, Page: this._page};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_APPLY_CREATE_COUNTRY_PLAYERS, pb.FetchApplyCreateCountryPlayersArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.ApplyCreateCountryPlayers.decode(result.payload);
                if (reply.Players.length > 0) {
                    this._page += 1;
                    this._addPlayer(reply.Players, true);
                } else {
                    this._page = -1;
                }
            }
        }
        
        private async _onApplyBtn() {
            if (WarMgr.inst.checkWarIsOver()) {
                return;
            }
            if (this._city.countryID == 0 && MyWarPlayer.inst.isMyCity(this._city.cityID) && WarMgr.inst.inStatus(BattleStatusName.ST_NORMAL)) {
                WarMgr.inst.openEmperorApply(this._city.cityID);
            }
        }
        private async _onAppointBtn() {
            Core.ViewManager.inst.open(ViewName.cityAppointPanel, this._city.cityID);
        }
         private async _onMore() {
             if (WarMgr.inst.checkWarIsOver()) {
                return;
            }
            //  if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING) || WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
            //      Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format("战争期间无法内政"));
            //      return;
            //  }
            if (this._city.inStatus(CityStatusName.ST_FALLEN)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format("此城刚陷落不久，不宜发布指令"));
                return;
            }
            if (MyWarPlayer.inst.employee.hasSameJob(Job.Prefect) && MyWarPlayer.inst.isMyCity(this._city.cityID)) {
                Core.ViewManager.inst.open(ViewName.cityManagePanel, this._city.cityID);
            } else {
                Core.TipsUtils.showTipsFromCenter("只有本城太守才能发布指令");
                return;
            }
        }
        private _createTimerStart() {
            fairygui.GTimers.inst.add(1000, -1, this._updateCreateTime, this);
        }
        private _updateCreateTime() {
            this._city.createTime -= 1;
            if (this._city.createTime <= 0) {
                this._createTimerStop();
                this._setCityDetails();
            } else {
                this._applyTimeText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70238), Core.StringUtils.secToString(this._city.createTime, "hms"));
            }
        }
        private _createTimerStop() {
            fairygui.GTimers.inst.remove(this._updateCreateTime, this);
        }
        // private async 
        private async _onEnter() {
            if (WarMgr.inst.checkWarIsOver()) {
                return;
            }
            if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING) || WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70239)));
                return;
            }
            if (MyWarPlayer.inst.cityID == 0) {
                Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70240), this._city.cityName) , () => {
                    this._joinCity();
                }, null, this);
            } else {
                if (MyWarPlayer.inst.countryID == 0) {
                    Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70241), this._city.cityName) , () => {
                        this._moveCity(0);
                    }, null, this);
                } else {
                    let fromCity = CityMgr.inst.getCity(MyWarPlayer.inst.cityID);
                    let path = CityMgr.inst.getShortestPathBetweenCityForTransport(fromCity, this._city);
                    let day = Road.countCityPathDistance(path);
                    let money = day * Data.parameter.get("transfer_cost").para_value[0];
                    if (MyWarPlayer.inst.employee.hasCityOfficialTitle()) {
                        Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70242), money, this._city.cityName, Utils.job2Text(MyWarPlayer.inst.employee.cityJob.type, true)) , () => {
                            this._moveCity(money);
                        }, null, this);
                    } else {
                        Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70243), money, this._city.cityName) , () => {
                            this._moveCity(money);
                        }, null, this);
                    }
                }
            }
        }
        private async _joinCity() {
            if (WarMgr.inst.checkWarIsOver()) {
                return;
            }
            let ok = await WarMgr.inst.joinCity(this._city.cityID);
            if (ok) {
                MyWarPlayer.inst.countryID = this._city.countryID;
                MyWarPlayer.inst.cityID = this._city.cityID;
                this._setCityDetails();
                WarMgr.inst.warView.updateHomeTip();
                Core.EventCenter.inst.dispatchEventWith(WarMgr.RefreshCityInfo);
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70244), this._city.cityName));
            }
        }
        private async _moveCity(gold: number) {
            if (gold) {
                if (Player.inst.getResource(ResType.T_GOLD) < gold) {
                    Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70245)));
                    return;
                }
            }
            let ok = await WarMgr.inst.moveCity(this._city.cityID, gold);
            if (ok) {
                MyWarPlayer.inst.countryID = this._city.countryID;
                MyWarPlayer.inst.cityID = this._city.cityID;
                this._setCityDetails();
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70244), this._city.cityName));
            }
        }
        public async close(...param: any[]) {
            super.close(...param);
            this._createTimerStop();
            this.unwatch();
            Core.EventCenter.inst.removeEventListener(WarMgr.RefreshCityInfo, this._setCityBaseInfo, this);
        }
        public watch() {
            this.watchCityInfo();
            this.watchCountryInfo();
            this._city.watchProp(City.PropApplyPlayer, this._updatePlayer, this);
            this._city.watchProp(City.PropPlayers, this._updatePlayer, this);
            this._city.watchProp(City.PropCountry, this._setCityBaseInfo, this);
        }
        public unwatch() {
            this.unwatchCityInfo();
            this.unwatchCountryInfo();
            this._city.unwatchProp(City.PropApplyPlayer, this._updatePlayer, this);
            this._city.unwatchProp(City.PropPlayers, this._updatePlayer, this);
            this._city.unwatchProp(City.PropCountry, this._setCityBaseInfo, this);
        }
    }
}
