module War {

    export class PlayerChooseItem extends fairygui.GButton {

        private _typeCtr: fairygui.Controller;
        private _buttonCtr: fairygui.Controller;
        private _headCom: Social.HeadCom;
        private _nameText: fairygui.GTextField;
        private _jobText: fairygui.GRichTextField;
        private _rankTitleText: fairygui.GTextField;
        private _rankImg: fairygui.GLoader;

        private _playerInfo: CampaignPlayer;

        protected constructFromXML(xml: any): void {
            this._typeCtr = this.getController("comType");
            this._buttonCtr = this.getController("button");
            this._headCom = this.getChild("lordHead").asCom as Social.HeadCom;
            this._nameText = this.getChild("nameText").asTextField;
            this._nameText.textParser = Core.StringUtils.parseColorText;
            this._jobText = this.getChild("job").asRichTextField;
            this._jobText.textParser = Core.StringUtils.parseColorText;
            this._jobText.funcParser = Core.StringUtils.parseFuncText;

            this._rankTitleText = this.getChild("rankTitleText").asTextField;
            this._rankImg = this.getChild("rankImg").asLoader;
        }
        public setInfo(info?: CampaignPlayer) {
            this._buttonCtr.selectedIndex = 0;
            if (info) {
                this._playerInfo = info;
                this._typeCtr.selectedIndex = 1;
                this._headCom.setAll(info.headImg, info.headFrame);
                this._nameText.text = info.name;
                this._jobText.text = info.employee.doubleJobName(true);
                this._rankTitleText.text = info.pvpLvTitle;
                this._rankImg.url = info.pvpTeamIcon;
            } else {
                this._playerInfo = null;
                this._typeCtr.selectedIndex = 0;
                this._headCom.setAll("", "");
                this._nameText.text = "";
                this._jobText.text = "";
            }
        }
        public get player() {
            return this._playerInfo;
        }

    }

    export class AppointChooseWnd extends Core.BaseWindow {
        
        private _job: Job;
        private _jobType: JobType;
        private _city: City;
        private _country: Country;
        private _nowPlayer: CampaignPlayer;
        private _newPlayer: CampaignPlayer;
        private _page: number;
        
        private _jobDesc: fairygui.GTextField;
        private _nowHeadCom: Social.HeadCom;
        private _nowNameText: fairygui.GTextField;
        private _newHeadCom: Social.HeadCom;
        private _newNameText: fairygui.GTextField;
        private _playerList: fairygui.GList;
        private _confirmBtn: fairygui.GButton;
        private _hintText: fairygui.GTextField;
        private _closeBtn: fairygui.GButton;

        private _isKingDie: boolean;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;
            this._jobDesc = this.contentPane.getChild("jobText").asTextField;
            this._nowHeadCom = this.contentPane.getChild("nowPlayer").asCom as Social.HeadCom;
            this._nowNameText = this.contentPane.getChild("nowPlayerName").asTextField;
            this._nowNameText.textParser = Core.StringUtils.parseColorText;
            this._newHeadCom = this.contentPane.getChild("newPlayer").asCom as Social.HeadCom;
            this._newNameText = this.contentPane.getChild("newPlayerName").asTextField;
            this._newNameText.textParser = Core.StringUtils.parseColorText;
            this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;
            this._hintText = this.contentPane.getChild("emptyHintText").asTextField;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;

            this._playerList = this.contentPane.getChild("playerList").asList;
            this._playerList.itemClass = PlayerChooseItem;
            this._playerList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickItem, this);
            this._playerList._scrollPane.addEventListener(fairygui.ScrollPane.PULL_UP_RELEASE, this._fetchMember, this);

            this._closeBtn.addClickListener(this._onCloseBtn, this);
            this._confirmBtn.addClickListener(this._onConfirmBtn, this);


        }
        private async _onCloseBtn() {
            this._isKingDie = false;
            Core.ViewManager.inst.closeView(this);
        }
        private async _onClickItem(evt: fairygui.ItemEvent) {
            this._setConfirmBtn(true);
            let com = evt.itemObject.asCom as PlayerChooseItem;
            this._newPlayer = com.player;
            if (this._newPlayer) {
                this._newHeadCom.setAll(this._newPlayer.headImg, this._newPlayer.headFrame);
                this._newNameText.text = this._newPlayer.name;
                if (this._nowPlayer && this._newPlayer.uID == this._nowPlayer.uID) {
                    this._setConfirmBtn(false);
                } else {
                    this._setConfirmBtn(this._newPlayer.employee.canAppointToJob(this._job));
                }
            } else {
                this._newHeadCom.setAll("", "");
                this._newNameText.text = "";
            }
            
        }
        private async _onConfirmBtn() {
            let type = Utils.job2Type(this._job);
            if (this._isKingDie) {
                this._isKingDie = false;
                Core.EventCenter.inst.dispatchEventWith(WarMgr.KingDie, false, this._newPlayer.uID);
                Core.ViewManager.inst.closeView(this);
                return;
            }
            if (this._newPlayer) {
                //任命
                let oldUid = null;
                if (this._nowPlayer) {
                    oldUid = this._nowPlayer.uID;
                } else {
                    oldUid = 0;
                }
                if (type == JobType.CityJob) {
                   let ok = await WarMgr.inst.appointJob(this._newPlayer.uID, this._job, oldUid);
                   if (ok) {
                       await this._newPlayer.employee.setCityJob(this._job);
                       this._city.updatePlayer(this._newPlayer ,oldUid);
                       Core.EventCenter.inst.dispatchEventWith(WarMgr.RefreshAppoint);
                       this._onCloseBtn();
                   }
                } else if (type == JobType.CountryJob) {
                    if (this._newPlayer.employee.hasSameJob(Job.YourMajesty)) {
                        Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70222));
                        return;
                    }
                   let ok = await WarMgr.inst.appointJob(this._newPlayer.uID, this._job, oldUid);
                   if (ok) {
                       await this._newPlayer.employee.setCountryJob(this._job);
                       this._country.updatePlayer(this._newPlayer ,oldUid);
                       Core.EventCenter.inst.dispatchEventWith(WarMgr.RefreshAppoint);
                       this._onCloseBtn();
                   }
                }
            } else {
                //罢免
                if (type == JobType.CityJob) {
                    let ok = await WarMgr.inst.recallJob(this._nowPlayer.uID, this._job);
                    if (ok) {
                        this._city.removePlayer(this._nowPlayer.uID);
                        Core.EventCenter.inst.dispatchEventWith(WarMgr.RefreshAppoint);
                        this._onCloseBtn();
                    }
                } else if (type == JobType.CountryJob) {
                    if (this._nowPlayer.employee.hasSameJob(Job.YourMajesty)) {
                        Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70222));
                        return;
                    }
                    let ok = await WarMgr.inst.recallJob(this._nowPlayer.uID, this._job);
                    if (ok) {
                        this._country.removePlayer(this._nowPlayer.uID);
                        Core.EventCenter.inst.dispatchEventWith(WarMgr.RefreshAppoint);
                        this._onCloseBtn();
                    }
                }
                
            }
        }
        private _setConfirmBtn(bool: boolean) {
            this._confirmBtn.touchable = bool;
            this._confirmBtn.grayed = !bool;
        }
        public async open(...param: any[]) {
            super.open(...param);
            
            this._job = param[1];
            this._jobType = Utils.job2Type(this._job);
            this._jobDesc.text = Utils.job2descText(this._job);
            if (this._jobType == JobType.CityJob) {
                this._city = CityMgr.inst.getCity(param[0]);
                this._country = CountryMgr.inst.getCountryForCityID(param[0]);
            } else if (this._jobType == JobType.CountryJob) {
                this._country = CountryMgr.inst.getCountry(param[0]);
            }
            this._nowPlayer = param[3];
            // if (this._job == Job.YourMajesty) {
            //     this._nowPlayer = new pb.CampaignPlayer();
            //     this._nowPlayer.CityJob = MyWarPlayer.inst.cityJob;
            //     this._nowPlayer.CountryJob = MyWarPlayer.inst.countryJob;
            //     this._nowPlayer.HeadFrame = Player.inst.frameID;
            //     this._nowPlayer.HeadImg = Player.inst.avatarUrl;
            //     this._nowPlayer.Uid = Player.inst.uid;
            // }
            this._newHeadCom.setAll("", "");
            this._newNameText.text = "";
            this._page = 0;
            this._playerList.removeChildrenToPool();
            this._hintText.visible = true;
            this._setConfirmBtn(false);
            this._refresh();
            this._addPlayers(param[2]);
        }

        public async setKingDie(bool: boolean) {
            this._isKingDie = bool;
        }
        private async _refresh() {
            //获取官职描述（暂时空）
            if (this._nowPlayer) {
                this._nowHeadCom.setAll(this._nowPlayer.headImg, this._nowPlayer.headFrame);
                this._nowNameText.text = this._nowPlayer.name;
                //设置罢免
                if (this._job != Job.YourMajesty) {
                    let com = this._playerList.addItemFromPool().asButton as PlayerChooseItem;
                    com.setInfo();
                }
            } else {
                this._nowHeadCom.setAll("", "");
                this._nowNameText.text = "";
            }
        }
        private async _addPlayers(players: pb.CampaignPlayerList) {
            if (players.Players.length <= 0) {
                this._page = -1;
                return;
            } else {
                 this._page += 1;
            }
            this._hintText.visible = false;
            players.Players.forEach(info => {
                let campPlayer = new CampaignPlayer(info);
                let com = this._playerList.addItemFromPool().asButton as PlayerChooseItem;
                com.setInfo(campPlayer);
            })
        }
        private async _fetchMember() {
            if (this._page < 0) {
                return;
            }
            let playerList = null;
            if (this._jobType == JobType.CityJob) {
                playerList = await WarMgr.inst.fetchCityMember(this._city.cityID, this._page);
            } else if (this._jobType == JobType.CountryJob) {
                playerList = await WarMgr.inst.fetchCountryMember(this._country.countryID, this._page);
            }
            if (playerList) {
                this._addPlayers(playerList);
            }
        } 
        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}