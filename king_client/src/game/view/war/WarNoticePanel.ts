module War {

    export class NoticeData {
        private _id: number;
        private _type: number;
        private _time: number;
        // private _canOp: boolean;
        private _mailDesc: any;
        private _mailData: any;
        public constructor(notice: pb.CampaignNotice) {
            this._id = notice.ID;
            this._type = notice.Type;
            this._time = notice.Time;
            // this._canOp = notice.IsOp;
            this._mailDesc = Data.war_mail_config.get(this._type);
            this._mailData = notice.Args;
        }
        public get title() {
            return this._mailDesc.title;
        }
        public get content() {
            switch (this._type) {
                case pb.CampaignNoticeType.NewCountryNt:    //建国
                {
                    let _mailData = pb.NewCountryNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.PlayerName, CityMgr.inst.getCity(_mailData.CityID).cityName, _mailData.CountryName);
                }
                case pb.CampaignNoticeType.AppointJobNt: {  //任命
                    let _mailData =pb.AppointJobNtArg.decode(this._mailData);
                    if (_mailData.Job > 3) {
                        let city = CityMgr.inst.getCity(_mailData.CityID);
                        return Core.StringUtils.format(this._mailDesc.content, _mailData.PlayerName, _mailData.TargetPlayerName, city.cityName + Utils.job2Text(_mailData.Job, true));
                    } else {
                        return Core.StringUtils.format(this._mailDesc.content, _mailData.PlayerName, _mailData.TargetPlayerName, Utils.job2Text(_mailData.Job, true));
                    }
                    
                }
                case pb.CampaignNoticeType.RecallJobNt: {   //罢免
                    let _mailData =pb.RecallJobNtArg.decode(this._mailData);
                    if (_mailData.Job > 3) {
                        let cityId = _mailData.CityID;
                        let city = CityMgr.inst.getCity(cityId);
                        return Core.StringUtils.format(this._mailDesc.content, city.cityName, Utils.job2Text(_mailData.Job, true));
                    } else {
                        return Core.StringUtils.format(this._mailDesc.content, "", Utils.job2Text(_mailData.Job, true));
                    }
                    
                }
                case pb.CampaignNoticeType.AutocephalyNt: { //独立
                    let _mailData =pb.AutocephalyNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, Utils.job2Text(_mailData.Job, true), _mailData.PlayerName, _mailData.CountryName, _mailData.NewCountryName);
                }
                case pb.CampaignNoticeType.KickOutNt: {     //驱逐
                    let _mailData =pb.KickOutNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, Utils.job2Text(_mailData.Job, true), _mailData.PlayerName, CityMgr.inst.getCity(_mailData.CityID).cityName);
                }
                case pb.CampaignNoticeType.YourMajestyChangeNt: {   //换主公
                    let _mailData =pb.YourMajestyChangeNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.YourMajestyName, _mailData.NewYourMajestyName);
                }
                case pb.CampaignNoticeType.ResignNt: {     //辞官
                    let _mailData =pb.ResignNtArg.decode(this._mailData);
                    if (_mailData.Job > 3) {
                        let cityId = _mailData.CityID;
                        let city = CityMgr.inst.getCity(cityId);
                        return Core.StringUtils.format(this._mailDesc.content, city.cityName, Utils.job2Text(_mailData.Job, true), _mailData.PlayerName);
                    } else {
                        return Core.StringUtils.format(this._mailDesc.content, "", Utils.job2Text(_mailData.Job, true), _mailData.PlayerName);
                    }
                    
                }
                case pb.CampaignNoticeType.ClearMissionNt: {    //完成所有任务
                    return Core.StringUtils.format(this._mailDesc.content);
                }
                case pb.CampaignNoticeType.BeOccupyNt: {    //城被占领
                    let _mailData =pb.BeOccupyNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.CountryName, CityMgr.inst.getCity(_mailData.BeOccupyCityID).cityName, _mailData.CaptiveAmount);
                }
                case pb.CampaignNoticeType.DestoryCountryNt: {  //势力灭亡
                    let _mailData =pb.DestoryCountryNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.BeDestoryCountryName, _mailData.CountryName);
                }
                case pb.CampaignNoticeType.UnifiedWordNt: {  //统一世界
                    let _mailData =pb.UnifiedWordNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.CountryName, _mailData.YourMajestyName);
                }
                case pb.CampaignNoticeType.AutocephalyVoteNt: {  //独立投票
                    let _mailData =pb.AutocephalyVoteNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, Utils.job2Text(_mailData.Job, true), _mailData.PlayerName, _mailData.CountryName, _mailData.CountryName);
                }
                case pb.CampaignNoticeType.CapitalInjectionNt: { //注资
                    let _mailData = pb.CapitalInjectionNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, Utils.job2Text(_mailData.Job, true), _mailData.PlayerName, _mailData.Gold);
                }
                case pb.CampaignNoticeType.ProductionNt: { //丰收
                    let _mailData = pb.ProductionNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.Forage, _mailData.Gold);
                }
                case pb.CampaignNoticeType.SalaryNt: { //发俸禄
                    let _mailData = pb.SalaryNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content,  _mailData.Gold);
                }
                case pb.CampaignNoticeType.TransportNt: { //运输
                    let _mailData = pb.TransportNtArg.decode(this._mailData);
                    console.log(this._mailDesc.content);
                    return Core.StringUtils.format(this._mailDesc.content, CityMgr.inst.getCity(_mailData.FromCity).cityName, CityMgr.inst.getCity(_mailData.TargetCity).cityName, _mailData.Amount, Utils.warTranType2text(_mailData.TransportType));
                }
                case pb.CampaignNoticeType.OccupyNt: {
                    let _mailData = pb.OccupyNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, CityMgr.inst.getCity(_mailData.OccupyCityID).cityName, _mailData.CaptiveAmount);
                }
                case pb.CampaignNoticeType.SurrenderNt: {
                    let _mailData = pb.SurrenderNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.PlayerName);
                }
                case pb.CampaignNoticeType.BetrayNt: {
                    let _mailData = pb.BetrayNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.PlayerName);
                }
                case pb.CampaignNoticeType.EscapedNt: {
                    let _mailData = pb.EscapedNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.PlayerName);
                }
                case pb.CampaignNoticeType.EscapedReturnNt: {
                    let _mailData = pb.EscapedReturnNtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.PlayerName);
                }
                case pb.CampaignNoticeType.AutoDefOrderNt: {    //自动防守
                    let _mailData = pb.TargetCity.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, CityMgr.inst.getCity(_mailData.CityID).cityName);
                }
                case pb.CampaignNoticeType.SurrenderCity1Nt: {  // 献城（原势力所有人）
                    let _mailData = pb.SurrenderCity1NtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.PlayerName, CityMgr.inst.getCity(_mailData.CityID).cityName, _mailData.TargetCountryName);
                }
                case pb.CampaignNoticeType.SurrenderCity2Nt: {  // 献城（目标势力原来所有人）
                    let _mailData = pb.SurrenderCity2NtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.PlayerName, CityMgr.inst.getCity(_mailData.CityID).cityName);
                }
                case pb.CampaignNoticeType.SurrenderCity3Nt: {  // 献城（城内其他成员）
                    let _mailData = pb.SurrenderCity1NtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.PlayerName, CityMgr.inst.getCity(_mailData.CityID).cityName, _mailData.TargetCountryName);
                }
                case pb.CampaignNoticeType.SurrenderCountry1Nt: {  // 主公投降（原势力其他成员）
                    let _mailData = pb.SurrenderCountry1NtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.PlayerName, _mailData.TargetCountryName);
                }
                case pb.CampaignNoticeType.SurrenderCountry2Nt: {  // 主公投降（目标势力原来所有人）
                    let _mailData = pb.SurrenderCountry1NtArg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.PlayerName, _mailData.TargetCountryName);
                }
                case pb.CampaignNoticeType.AutocephalyNt2: {    //独立2
                    let _mailData = pb.AutocephalyNt2Arg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, CityMgr.inst.getCity(_mailData.CityID).cityName, Utils.job2Text(_mailData.Job, true), _mailData.PlayerName, _mailData.OldCountryName, _mailData.NewCountryName);
                }
                case pb.CampaignNoticeType.AutocephalyNt3: {    //独立3
                    let _mailData = pb.AutocephalyNt3Arg.decode(this._mailData);
                    return Core.StringUtils.format(this._mailDesc.content, _mailData.PlayerName, CityMgr.inst.getCity(_mailData.CityID).cityName, _mailData.NewCountryName);
                }
            default :
                    return "";
                    
            }
        }
        public get time() {
            return this._time;
        }
    }

    export class BaseWarNoticeItem extends fairygui.GComponent {
        protected _headCom: Social.HeadCom;
        protected _timeText: fairygui.GTextField;
        protected _nameText: fairygui.GTextField;
        protected _titleText: fairygui.GTextField;
        protected _notice: NoticeData;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._headCom = this.getChild("head").asCom as Social.HeadCom;
            this._timeText = this.getChild("time").asTextField;
            this._nameText = this.getChild("name").asTextField;
            this._titleText = this.getChild("title").asTextField;
            this._titleText.textParser = Core.StringUtils.parseColorText;
        }

        public setNotice(notice: pb.CampaignNotice) {
            this._notice = new NoticeData(notice);
            this._nameText.text = this._notice.title;
            this._titleText.text = this._notice.content;
            this._timeText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60051), Core.StringUtils.secToString(Math.floor(Date.now()/1000 - this._notice.time), "dhm"));            
        }
    } 
    export class WarNoticeItem extends BaseWarNoticeItem {
        private _remainTimeText: fairygui.GTextField = null;
        private _agreeBtn: fairygui.GButton = null;
        private _refuseBtn: fairygui.GButton = null;
        private _headIcon: fairygui.GImage;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._remainTimeText = this.getChild("remainTime").asTextField;
            this._remainTimeText.visible = false;
            this._agreeBtn = this.getChild("agreeBtn").asButton;
            this._agreeBtn.addClickListener(this._onAgreeBtn, this);
            this._refuseBtn = this.getChild("refuseBtn").asButton;
            this._refuseBtn.addClickListener(this._onRefuseBtn, this);
            this._headIcon = this.getChild("head").asCom.getChild("headIcon").asImage;
            Utils.setImageUrlPicture(this._headIcon, "society_headicon1_png");
        }

        public setNotice(notice: pb.CampaignNotice) {
            super.setNotice(notice);
            // if (true) {
            this._remainTimeText.visible = false;
            this._agreeBtn.visible = false;
            this._refuseBtn.visible = false;
            this.height = 119;
            // }
        }

        private _onAgreeBtn() {
            // this._headCom
            // TODO
        }
        private _onRefuseBtn() {
            // TODO
        }
    }

    export class WarNoticePanel extends Core.BaseWindow {

        private _closeBtn: fairygui.GButton;
        private _warChatCom: Social.WorldChatWndCom;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;

            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._warChatCom = this.contentPane.getChild("chatCom").asCom as Social.WorldChatWndCom;
			this._warChatCom.setChannel(Social.ChatChannel.CampaignCountry);

            this._closeBtn.addClickListener(() => {
                Core.ViewManager.inst.closeView(this);
            }, this);

            Core.EventCenter.inst.addEventListener(GameEvent.ChannelChatEv, this._onChannelChat, this);
        }

        private async _onChannelChat(evt: egret.Event) {
			if (evt.data.channel == pb.ChatChannel.CampaignCountry) {
				let chatlet = <Social.PrivateChatlet>evt.data.chatlet;
				this._warChatCom.addChatlet(chatlet);
			}
		}


        public async open(...param: any[]) {
            super.open(...param);
            let ok = await this._warChatCom.onChosen(true);
            if (ok) {
                await this._warChatCom.refresh();
            }
        }

        public async close(...param: any[]) {
            super.close(...param);
            Core.EventCenter.inst.dispatchEventWith(WarMgr.ShowNotifyRedDot, false, false);
        }
    }

    export class WarNoticePanel_deprecated extends Core.BaseWindow {
        private _noticeList: fairygui.GList;
        private _nowPage: number;
        private _closeBtn: fairygui.GButton;
        private _hintText: fairygui.GTextField;

        private _warNoticeItemList: Array<WarNoticeItem>;

        private _notices: Array<pb.CampaignNotice>;

        public initUI() {
            super.initUI();

            this.center();
            this.modal = true;
            // this.adjust(this.getChild("n1"));
            // this.getChild("n1").asLoader.addClickListener()
            this._warNoticeItemList = new Array<WarNoticeItem>();

            this._noticeList = this.contentPane.getChild("chatletList").asList;
            this._noticeList.itemClass = WarNoticeItem;
            this._noticeList.itemRenderer = this._renderNotices;
            this._noticeList.callbackThisObj = this;
            this._noticeList.setVirtual();
            // this.cityList._scrollPane.addEventListener(fairygui.ScrollPane.PULL_UP_RELEASE, this._updatePlayers, this);
            this._hintText = this.contentPane.getChild("emptyHintText").asTextField;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._closeBtn.addClickListener(this._onCloseBtn,this);

            this._notices = [];
            // this.getChild("n1").asLoader.addClickListener(this._onCloseBtn, this);
        }
        public async open(...param: any[]) {
            super.open(...param);
            
            // this._noticeList.removeChildrenToPool();
            let notices = param[0] as pb.CampaignNoticeInfo;
            this._clearList();
            notices.Notices.forEach(notice => {
                this._notices.push(<pb.CampaignNotice>notice);
                // if (notice.IsOp) {
                //     this._addFuncNotice(notice);
                // } else {
                //     this._addNotice(notice);
                // }
            });
            this._noticeList.numItems = this._notices.length;
            this._hintText.visible = (this._notices.length == 0);
        }

        private _renderNotices(idx:number, item:fairygui.GObject) {
            let data = this._notices[this._notices.length - 1 - idx];
			let com = item as WarNoticeItem;
			com.setNotice(data);

            // if (idx == this._notices.length - 1) {
            //     this._noticeList.scrollToView(this._noticeList.getChildIndex(com));
            // }
        }

        private _clearList() {
            this._noticeList.numItems = 0;
            this._notices = [];
            // this._warNoticeItemList.forEach(com => {
            //     com.visible = false;
            // })
        }
        // private _addFuncNotice(notice: pb.ICampaignNotice) {
        //     for (let i = 0; i < this._warNoticeFuncItemList.length; i++) {
        //         let com = this._warNoticeFuncItemList[i];
        //         if (com.visible == false) {
        //             com.visible = true;
        //             com.setNotice(notice);
        //             return;
        //         }
        //     }
        //     let com = fairygui.UIPackage.createObject(PkgName.war, "noticeFunctionItem").asCom as WarNoticeFuncItem;
        //     this._warNoticeFuncItemList.push(com);
        //     this._noticeList.addChild(com);
        //     com.setNotice(notice);
        //     com.visible = true;

        // }
        // private _addNotice(notice: pb.ICampaignNotice) {
        //     for (let i = 0; i < this._warNoticeItemList.length; i++) {
        //         let com = this._warNoticeItemList[i];
        //         if (com.visible == false) {
        //             com.visible = true;
        //             com.setNotice(notice);
        //             return;
        //         }
        //     }
        //     let com = fairygui.UIPackage.createObject(PkgName.war, "noticeItem").asCom as WarNoticeItem;
        //     this._warNoticeItemList.push(com);
        //     this._noticeList.addChild(com);
        //     com.setNotice(notice);
        //     com.visible = true;
        // }
        private _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }
        public async close(...param: any[]) {
            super.close(...param);
            this._clearList();
        }
    }
}