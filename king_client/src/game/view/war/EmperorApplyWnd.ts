module War {

    export class EmperorApplyItem extends fairygui.GComponent {

        private _headCom: Social.HeadCom;
        private _uID: Long;
        private _nameText: fairygui.GTextField;
        private _goldText: fairygui.GTextField;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._headCom = this.getChild("lordHead").asCom as Social.HeadCom;
            this._nameText = this.getChild("nameText").asTextField;
            this._nameText.textParser = Core.StringUtils.parseColorText;
            this._goldText = this.getChild("goldInput").asTextField;

            this.addClickListener(this._onClick, this);
        }
        public setInfo(playerData: pb.IApplyCreateCountryPlayer) {
            this._uID = <Long>playerData.Player.Uid;
            this._headCom.setAll(playerData.Player.HeadImg, playerData.Player.HeadFrame);
            this._nameText.text = playerData.Player.Name;
            this._goldText.text = playerData.Gold.toString();
        }
        private async _onClick() {
            let playerInfo = await Social.FriendMgr.inst.fetchPlayerInfo(this._uID);
			if (playerInfo) {
			    Core.ViewManager.inst.open(ViewName.friendInfo, <Long>this._uID, playerInfo);
			}
        }
    }

    export class EmperorApplyWnd extends Core.BaseWindow {

        private _cityID: number;
        private _city: City;
        private _time: number;
        private _page: number;
        private _myGold: number;

        private _timerText: fairygui.GTextField;
        private _playerList: fairygui.GList;
        private _goldInput: fairygui.GTextField;
        private _confirmBtn: fairygui.GButton;
        private _closeBtn: fairygui.GButton;
        private _hintText: fairygui.GTextField;
        private _goldMaxCnt: fairygui.GTextField;
        private _goldCnt: fairygui.GSlider;

        private _cityObjWatchers: Core.Watcher[];

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;
            this._cityObjWatchers = [];
            this._timerText = this.contentPane.getChild("treasureTime").asTextField;
            this._playerList = this.contentPane.getChild("playerList").asList;
            this._goldInput = this.contentPane.getChild("goldInput").asTextField;
            this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._hintText = this.contentPane.getChild("emptyHintText").asTextField;
            this._goldMaxCnt = this.contentPane.getChild("goldMaxCnt").asTextField;
            this._goldCnt = this.contentPane.getChild("goldCnt").asSlider;
            this._goldCnt.getChild("title").visible = false;

            this._playerList.itemClass = EmperorApplyItem;
            this._playerList._scrollPane.addEventListener(fairygui.ScrollPane.PULL_UP_RELEASE, this._getApplyPLayers, this);

            this._closeBtn.addClickListener(this._onCloseBtn, this);
            this._confirmBtn.addClickListener(this._onConfirmBtn, this);

            this._goldCnt.addEventListener(fairygui.StateChangeEvent.CHANGED, this._goldInputChange, this);
        }

        public async open(...param: any[]) {
            super.open(...param);
            
            this._cityID = param[0];
            let applyData = param[1] as pb.IApplyCreateCountryData;
            let city = CityMgr.inst.getCity(this._cityID);
            this._city = city;
            this._city.applyPlayers = applyData.Players;
            this._refresh(applyData);
            this._cityObjWatchers.push(Core.Binding.bindHandler(city, [City.PropCountry], this._onCloseBtn, this));
        }
        private async _refresh(applyData: pb.IApplyCreateCountryData) {
            this._time = 0;
            this._page = 0;
            this._goldInput.text = "0";
            this._goldCnt.value = 0;
            if (Player.inst.getResource(ResType.T_GOLD) == 0) {
                this._goldCnt.grayed = true;
                this._goldCnt.touchable = false;
            } else {
                this._goldCnt.grayed = false;
                this._goldCnt.touchable = true;
                this._goldCnt.max = Player.inst.getResource(ResType.T_GOLD);
            }
            if (this._goldCnt.value == 0){
                this._confirmBtn.touchable = false;
                this._confirmBtn.grayed = true;
            }
            this._goldMaxCnt.text = Core.StringUtils.format(Core.StringUtils.TEXT(70257), Player.inst.getResource(ResType.T_GOLD));
            this._playerList.removeChildrenToPool();
            this._time = applyData.RemainTime;
            this._timerStart();
            if (applyData.Players.length > 0) {
                this._hintText.visible = false;
                this._page += 1;
                applyData.Players.forEach((playerData) => {
                    this._addApplyPlayer(playerData);
                });
            } else {
                this._page = -1;
                this._hintText.visible = true;
            }
            this._myGold = applyData.MyApplyMoney;
            if (this._myGold > 0) {
                this._confirmBtn.title = Core.StringUtils.TEXT(70258);
            } else {
                this._confirmBtn.title = Core.StringUtils.TEXT(70259);
            }
            // this._hasApply(applyData.MyApplyMoney > 0);
        }
        private async _addApplyPlayer(applyPlayer: pb.IApplyCreateCountryPlayer) {
            let com = this._playerList.addItemFromPool().asCom as EmperorApplyItem;
            com.setInfo(applyPlayer);
        }
        private async _getApplyPLayers() {
            if (this._page < 0) {
                return;
            }
            let args = {CityID: this._cityID, Page: this._page};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_APPLY_CREATE_COUNTRY_PLAYERS, pb.FetchApplyCreateCountryPlayersArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.ApplyCreateCountryPlayers.decode(result.payload);
                if (reply.Players.length > 0) {
                    this._page += 1;
                    reply.Players.forEach( playerData => {
                        this._addApplyPlayer(playerData);
                    })
                } else {
                    this._page = -1;
                }
            }
        }

        private async _goldInputChange() {
            this._goldInput.text = `${this._goldCnt.value}`;
            if (this._goldCnt.value == 0) {
                this._confirmBtn.touchable = false;
                this._confirmBtn.grayed = true;
            } else {
                this._confirmBtn.touchable = true;
                this._confirmBtn.grayed = false;
            }
            this._goldMaxCnt.text = Core.StringUtils.format(Core.StringUtils.TEXT(70257), Player.inst.getResource(ResType.T_GOLD) - this._goldCnt.value);
        }
        private async _hasApply(bool: boolean) {
            this._goldInput.visible = !bool;
            this._confirmBtn.visible = !bool;
        }

        private async _timerStart() {
            this._timerStop();
            fairygui.GTimers.inst.add(1000, -1, this._remainTimer, this);
        }
        private async _remainTimer() {
            this._timerText.text = Core.StringUtils.secToString(this._time, "hms");
            this._time -= 1;
            if (this._time <= 0) {
                this._timerStop();
            }
        }
        private async _timerStop() {
            fairygui.GTimers.inst.remove(this._remainTimer, this);
        }

        private async _onConfirmBtn() {
            let moneyStr = this._goldInput.text;
            moneyStr = moneyStr.trim();
            let moneyNum = parseInt(moneyStr);
            if (isNaN(moneyNum) || moneyStr.length <= 0 || moneyStr.length != moneyNum.toString().length) {
                return;
            }
            let tipStr = "";
            if (this._myGold > 0) {
                tipStr = Core.StringUtils.format(Core.StringUtils.TEXT(70260), moneyNum);
            } else {
                tipStr = Core.StringUtils.format(Core.StringUtils.TEXT(70261), moneyNum);
            }
            Core.TipsUtils.confirm(tipStr, () => {
                this._onConfirm(moneyNum);
            } , null, this);
        }
        private async _onConfirm(gold: number) {
            if (Player.inst.getResource(ResType.T_GOLD) < gold) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70262));
                return;
            }
            let args = {Gold: gold};
            let result = await Net.rpcCall(pb.MessageID.C2S_CREATE_COUNTRY, pb.CreateCountryArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.ApplyCreateCountryData.decode(result.payload);
                this._city.applyPlayers = reply.Players;
                this._page = 0;
                this._refresh(reply);
            }
        }
        
        private async _onCloseBtn() {
            
            Core.ViewManager.inst.closeView(this);
        }

        public async close(...param: any[]) {
            this._cityObjWatchers.forEach(w => {
                w.unwatch();
            })
            this._cityObjWatchers = [];
            super.close(...param);
        }
    }
}