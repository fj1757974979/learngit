module War {

    export class MemberItem extends fairygui.GComponent {
        
        private _headCom: Social.HeadCom;
        private _nameText: fairygui.GTextField;
        private _jobText: fairygui.GRichTextField;
        private _delBtn: fairygui.GButton;
        private _isKickOutText: fairygui.GTextField;
        private _info: CampaignPlayer;
        private _rankText: fairygui.GTextField;
        private _battlePoint: fairygui.GTextField;
        private _rankIcon: fairygui.GLoader;

        private _kickTime: number;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._headCom = this.getChild("lordHead").asCom as Social.HeadCom;
            this._nameText = this.getChild("nameText").asTextField;
            this._nameText.textParser = Core.StringUtils.parseColorText;
            this._jobText = this.getChild("job").asRichTextField;
            this._jobText.textParser = Core.StringUtils.parseColorText;
            this._jobText.funcParser = Core.StringUtils.parseFuncText;
            this._delBtn = this.getChild("deleteBtn").asButton;
            this._isKickOutText = this.getChild("banTime").asTextField;
            this._rankText = this.getChild("rankTitleText").asTextField;
            this._rankIcon = this.getChild("rankImg").asLoader;
            this._battlePoint = this.getChild("battlePoint").asTextField;

            this._headCom.addClickListener(this._onDetail, this);
            this._delBtn.addClickListener(this._onDelBtn, this);
        }
        public setInfo(playerInfo: CampaignPlayer) {
            this._info = playerInfo;
            this._nameText.text = playerInfo.name;
            this._headCom.setAll(playerInfo.headImg, playerInfo.headFrame);
            this._rankText.text = this._info.pvpLvTitle;
            this._rankIcon.url = this._info.pvpTeamIcon;
            if(playerInfo.employee.hasOfficialTitle()) {
                this._jobText.text = playerInfo.employee.doubleJobName(true);
            } else {
                this._jobText.text = playerInfo.employee.doubleJobName(true);
            }
            
            if (this._info.kickOutTime) {
                this._kickTime = this._info.kickOutTime;
            } else {
                this._kickTime = 0;
            }
            this._battlePoint.text =this._info.contribution.toString();
            this.refresh();
        }
        public setDelBtn(bool: boolean) {
            this._delBtn.visible = bool;
            if (this._kickTime > 0) {
                this._delBtn.visible = false;
            }
        }
        public refresh() {
            // this.timerStop();
            if (this._kickTime > 0) {
                this._isKickOutText.visible = true;
                this._isKickOutText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70220), Core.StringUtils.secToString(this._kickTime, "dhm"));
                // fairygui.GTimers.inst.add(1000, -1, this._kickOutTimer, this);
                this._delBtn.visible = false;
            } else {
                this._isKickOutText.visible = false;
            }
            
        }
        // private _kickOutTimer() {
        //     this._kickTime -= 1;
        //     if (this._kickTime < 0) {
        //         this.timerStop();
        //     } else {
        //         this._isKickOutText.text = `${Math.floor(this._kickTime/3600)}:{}`;
        //     }
        // }
        // public timerStop() {
        //     fairygui.GTimers.inst.remove(this._kickOutTimer, this);
        // }

        private async _onDetail() {
            let playerInfo = await Social.FriendMgr.inst.fetchPlayerInfo(<Long>this._info.uID);
			if (playerInfo) {
			    Core.ViewManager.inst.open(ViewName.friendInfo, <Long>this._info.uID, playerInfo);
			}
		}
        private async _onDelBtn() {
            if (WarMgr.inst.checkWarIsOver()) {
                return;
            }
            Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70221), this._info.name), this._onDel, null, this);
        }
        private async _onDel() {
            let args = {Uid: this._info.uID};
            let result = await Net.rpcCall(pb.MessageID.C2S_KICK_OUT_CITY_PLAYER, pb.CampaignTargetPlayer.encode(args));
            if (result.errcode == 0) {
                this._kickTime = 24 * 60 * 60;
                this.refresh();
            }
        }
    }

    export class AllMemberPanel extends Core.BaseWindow {
        private _city: City;
        private _playerList: fairygui.GList;
        private _nowPage: number;
        private _helpList: fairygui.GList;
        private _helpPage: number;
        private _captiveList: fairygui.GList;
        private _captivePage: number;

        private _pageCtr: fairygui.Controller;
        private _closeBtn: fairygui.GButton;
        private _hitText: fairygui.GTextField;
        private _hitText2: fairygui.GTextField;
        private _hitText3: fairygui.GTextField;

        private _bounsBtn: fairygui.GButton;
        private _countryChk: fairygui.GButton;
        private _honorChk: fairygui.GButton;

        public initUI() {
            super.initUI();

            this.center();
            this.modal = true;
            this._hitText = this.contentPane.getChild("emptyHintText").asTextField;
            this._hitText2 = this.contentPane.getChild("emptyHintText2").asTextField;
            this._hitText3 = this.contentPane.getChild("emptyHintText3").asTextField;
            this._pageCtr = this.contentPane.getController("c1");
            this._playerList = this.contentPane.getChild("playerList").asList;
            this._playerList.itemClass = MemberItem;
            this._playerList._scrollPane.addEventListener(fairygui.ScrollPane.PULL_UP_RELEASE, this._updatePlayers, this);
            this._helpList = this.contentPane.getChild("helpList").asList;
            this._helpList.itemClass = MemberItem;
            this._helpList._scrollPane.addEventListener(fairygui.ScrollPane.PULL_UP_RELEASE, this._updateHelps, this);
            this._captiveList = this.contentPane.getChild("captiveList").asList;
            this._captiveList.itemClass = MemberItem;
            this._captiveList._scrollPane.addEventListener(fairygui.ScrollPane.PULL_UP_RELEASE, this._updateCaptives, this);
            
            this._bounsBtn = this.contentPane.getChild("bounsBtn").asButton;
            this._countryChk = this.contentPane.getChild("countryChk").asButton;
            this._honorChk = this.contentPane.getChild("honorChk").asButton;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._closeBtn.addClickListener(this._onCloseBtn, this);
            this._bounsBtn.addClickListener(this._onHelpBtn, this);
            this._countryChk.addClickListener(this._onPlayerBtn, this);
            this._honorChk.addClickListener(this._onCaptiveBtn, this);
        }
        public async open(...param: any[]) {
            super.open(...param);
            this._nowPage = 0;
            this._helpPage = 0;
            this._captivePage = 0;
            this._pageCtr.selectedIndex = 0;
            this._city = param[0];
            let players = param[1] as pb.CampaignPlayerList;
            if (this._playerList.numItems > 0) {
                this._playerList.scrollToView(0);
            }
            this._hitText2.visible = false;
            this._hitText3.visible = false;
            this._playerList.removeChildrenToPool();
            this._helpList.removeChildrenToPool();
            this._captiveList.removeChildrenToPool();
            if (players.Players.length <= 0) {
                this._hitText.visible = true;
            } else {
                this._hitText.visible = false;
                this._addPlayer(players);
            }
            
        }
        private async _addPlayer(players: pb.CampaignPlayerList) {
            if (players.Players.length <= 0) {
                if(this._nowPage == 0) {
                    this._hitText.visible = true;
                }
                this._nowPage = -1;
                return;
            } else {
                this._nowPage += 1;
            }
            players.Players.forEach(_player => {
                let com = this._playerList.addItemFromPool().asCom as MemberItem;
                let campPLayer = new CampaignPlayer(_player);
                com.setInfo(campPLayer);
                //我拥有城市职位并且对方没有国家职位和城市职位
                
                if (MyWarPlayer.inst.employee.canKickMember() && _player.CountryJob == 0 && _player.CityJob == 0 && this._city.cityID == MyWarPlayer.inst.cityID) {
                    com.setDelBtn(true);
                } else {
                    com.setDelBtn(false);
                }
            });
        }
        private async _updatePlayers() {
            if (this._nowPage < 0) {
                return ;
            }
            let players = await WarMgr.inst.fetchCityMember(this._city.cityID, this._nowPage);
            if (players) {
                this._addPlayer(players);
            }
        }
        private async _onPlayerBtn() {
            if (this._nowPage != 0) {
                return;
            }
            this._updatePlayers();
        }
        private async _onHelpBtn() {
            if (this._helpPage != 0) {
                return;
            }
            this._updateHelps();
        }
        private async _updateHelps() {
            if (this._helpPage < 0) {
                return;
            }
            let players = await WarMgr.inst.fetchInCityMember(this._city.cityID, this._helpPage);
            if (players) {
                this._addHelps(players);
            }
        }
        private async _addHelps(players: pb.CampaignPlayerList) {
            if (players.Players.length <= 0) {
                if(this._helpPage == 0) {
                    this._hitText2.visible = true;
                }
                this._helpPage = -1;
                return;
            } else {
                this._helpPage += 1;
            }
            players.Players.forEach(_player => {
                let com = this._helpList.addItemFromPool().asCom as MemberItem;
                let campPLayer = new CampaignPlayer(_player);
                com.setInfo(campPLayer);
                    com.setDelBtn(false);
            });
        }
        private async _onCaptiveBtn() {
        if (this._captivePage != 0) {
                return;
            }
            this._updateCaptives();
        }
        private async _updateCaptives() {
            if (this._captivePage < 0) {
                return;
            }
            let players = await WarMgr.inst.fetchCityCaptives(this._city.cityID, this._captivePage);
            if (players) {
                this._addCaptives(players);
            }
        }
        private async _addCaptives(players: pb.CampaignPlayerList) {
            if (players.Players.length <= 0) {
                if(this._captivePage == 0) {
                    this._hitText3.visible = true;
                }
                this._captivePage = -1;
                return;
            } else {
                this._captivePage += 1;
            }
            players.Players.forEach(_player => {
                let com = this._captiveList.addItemFromPool().asCom as MemberItem;
                let campPLayer = new CampaignPlayer(_player);
                com.setInfo(campPLayer);
                    com.setDelBtn(false);
            });
        }
        private _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }

        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}