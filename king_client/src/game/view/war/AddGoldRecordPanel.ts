module War {

    export class AddGoldRecordItem extends fairygui.GComponent {

        private _nameText: fairygui.GTextField;
        private _jobText: fairygui.GRichTextField;
        private _headCom: Social.HeadCom;
        private _timeText: fairygui.GTextField;
        private _goldCntText: fairygui.GTextField;
        private _player: CampaignPlayer;
        
        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._nameText = this.getChild("nameText").asTextField;
            this._nameText.textParser = Core.StringUtils.parseColorText;
            this._headCom = this.getChild("lordHead").asCom as Social.HeadCom;
            this._timeText = this.getChild("time").asTextField;
            this._goldCntText = this.getChild("goldCnt").asTextField;
            this._jobText = this.getChild("job").asRichTextField;
            this._jobText.textParser = Core.StringUtils.parseColorText;
            this._jobText.funcParser = Core.StringUtils.parseFuncText;

            this._headCom.addClickListener(this._onClick, this);
        }

         public setInfo(info: any) {
             this._player = new CampaignPlayer(info.Player);
             this._nameText.text = this._player.name;
             this._headCom.setAll(this._player.headImg, this._player.headFrame);
             this._goldCntText.text = info.Gold.toString();
             this._timeText.text = Core.StringUtils.secToString(Math.floor(Date.now()/1000) - info.Time, "dhm");
             this._jobText.text = this._player.employee.doubleJobName(true);
         }
         private async _onClick() {
             let playerInfo = await Social.FriendMgr.inst.fetchPlayerInfo(<Long>this._player.uID);
			    if (playerInfo) {
			    Core.ViewManager.inst.open(ViewName.friendInfo, <Long>this._player.uID, playerInfo);
			}
         }


    }

    export class AddGoldRecordPanel extends Core.BaseWindow {

        private _playerList: fairygui.GList;
        private _closeBtn: fairygui.GButton;
        private _emptyHintText: fairygui.GTextField;
        private _records: any[];
        private _page: number;
        private _cityID: number;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;

            this._emptyHintText = this.contentPane.getChild("emptyHintText").asTextField;
            this._playerList = this.contentPane.getChild("playerList").asList;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;

            this._playerList.itemClass = AddGoldRecordItem;
            this._playerList._scrollPane.addEventListener(fairygui.ScrollPane.PULL_UP_RELEASE, this._getMorePlayer, this);
            this._closeBtn.addClickListener(this._onClose, this);
        }
        public async open(...param: any[]) {
            super.open();
            this._cityID = param[0];
            let record = param[1] as pb.CityCapitalInjectionHistory;
            this._emptyHintText.visible = record.Records.length == 0;
            this._page = 0;
            this._playerList.removeChildrenToPool();
            this._refreshList(record.Records);
        }
        private async _refreshList(players: any[]) {
            if (players.length <= 0) {
                this._page = -1;
            }  else {
                this._page += 1;
            }
            players.forEach(_info => {
                let com = this._playerList.addItemFromPool().asCom as AddGoldRecordItem;
                com.setInfo(_info);
            })
        }
        private async _getMorePlayer() {
            if (this._page < 0) {
                return;
            }
            let args = {CityID: this._cityID, Page: this._page};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_CITY_CAPITAL_INJECTION_HISTORY, pb.FetchCityCapitalInjectionArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.CityCapitalInjectionHistory.decode(result.payload);
                this._refreshList(reply.Records);
            }
        }
        private async _onClose() {
            Core.ViewManager.inst.closeView(this);
        }
        public async close(...param: any[]) {
            super.close();
        }
    }
}