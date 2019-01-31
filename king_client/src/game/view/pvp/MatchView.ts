module Pvp {

    export class MatchView extends Core.BaseView {

        private _isAppstoreExamine: boolean;
        private _pvpLevelText: fairygui.GTextField;
        private _scoreProgressBar: UI.MaskProgressBar;
        private _renderPoolsExecutor: Core.FrameExecutor;
        //private _guideProgress: UI.MaskProgressBar;
        private _guideGroup: fairygui.GGroup;
        private _guideProgressTxt: fairygui.GTextField;
        private _techBtn: fairygui.GButton;
        private _rankSeasonBtn: fairygui.GComponent;
        private _rankSeasonFaqBtn: fairygui.GComponent;
        private _seasonTimeText: fairygui.GTextField;
        private _huodongEntryBtn: fairygui.GButton;
        private _seasonStarNum: fairygui.GTextField;

        //
        private _moreFunctionList: fairygui.GList;
        private _commonFunctionList: fairygui.GList;

        private _gameCenterBtn: fairygui.GButton;
        private _appStoreShareBtn: fairygui.GButton;
        private _appLikeBtn: fairygui.GButton;
        private _setupBtn: fairygui.GButton;
        private _publicPlatformBtn: fairygui.GButton;
        // private _questionBtn: fairygui.GButton;
        private _inviteBtn: fairygui.GButton;
        private _wechatFriendBtn: fairygui.GButton;
        private _rebornBtn: fairygui.GButton;
        private _rankSeasonCardBtn: fairygui.GButton;
        private _warBtn: fairygui.GButton;

        private _treasure1: Treasure.TreasureItemCom;
        private _treasure2: Treasure.TreasureItemCom;
        private _treasure3: Treasure.TreasureItemCom;
        private _treasure4: Treasure.TreasureItemCom;

        private _treasureAni0: fairygui.Transition;
        private _treasureAni1: fairygui.Transition;
        private _treasureAni2: fairygui.Transition;
        private _treasureAni3: fairygui.Transition;
        private _TreasureAni4: fairygui.Transition;

        private _treasureImg: fairygui.GLoader;

        private _dailyTreasure: Treasure.DailyTreasureItemCom;


        private _pos2Treasure: Collection.Dictionary<number, Treasure.TreasureItemCom>;

        private _pvpRankBanner: UI.PvpRankBannerCom;
        // private _pvpTitleText: fairygui.GTextField;
        private _questBtn: Quest.QuestBtnCom;
        private _mailBtn: fairygui.GButton;

        private _latestTreasurePos: number;

        public initUI() {

            this._isAppstoreExamine = IOS_EXAMINE_VERSION;

            super.initUI();
            // this.adjust(this.getChild("bg"));
            //this._pvpLevelText = this.getChild("pvpLevelText").asTextField;
            //this._scoreProgressBar = this.getChild("scoreProgressBar").asCom as UI.MaskProgressBar;
            this._guideGroup = this.getChild("guide").asGroup;
            //this._guideProgress = this.getChild("guideProgress") as UI.MaskProgressBar;
            this._guideProgressTxt = this.getChild("guideProgressTxt").asTextField;
            this.getChild("btnMatch").asButton.visible = false;
            this.getChild("techBtn").touchable = false;
            let techTimer = new egret.Timer(200,1);
            techTimer.addEventListener(egret.TimerEvent.TIMER_COMPLETE,() => {
                this.getChild("techBtn").touchable = true;
            },this);
            techTimer.start();

            this._questBtn = this.getChild("questBtn").asButton as Quest.QuestBtnCom;
            this._mailBtn = this.getChild("mailBtn").asButton;
            this._mailBtn.addClickListener(this._onMail,this);
            this._mailBtn.getChild("mailHint").visible = false;
            this._rankSeasonBtn = this.getChild("rankSeasonBtn").asCom;
            this._rankSeasonFaqBtn = this.getChild("seasonFaqBtn").asButton;
            this._seasonTimeText = this._rankSeasonBtn.getChild("time").asTextField;
            this._seasonStarNum = this._rankSeasonBtn.getChild("cnt").asTextField;
            this._rankSeasonBtn.addClickListener(this._onSeason, this);
            this._rankSeasonFaqBtn.addClickListener(() => {
                Core.ViewManager.inst.openPopup(ViewName.faqView, Core.StringUtils.TEXT(90004));
            }, this);
            this._rebornBtn = this.getChild("rebornBtn").asButton;
            this._rebornBtn.addClickListener(this._onRebornBtn, this);
            this._rankSeasonCardBtn = this.getChild("rankSeasonCardBtn").asButton;
            this._rankSeasonCardBtn.addClickListener(this._onRankCardBtn, this);
            //
            this._moreFunctionList = this.getChild("moreFunction").asList;
            this._commonFunctionList = this.getChild("commonFunction").asList;
            this._moreFunctionList.foldInvisibleItems = true;
            this._commonFunctionList.foldInvisibleItems = true;

            this._gameCenterBtn = this._moreFunctionList.getChild("gameCenterBtn").asButton;
            this._appLikeBtn = this._moreFunctionList.getChild("appLikeBtn").asButton;
            this._wechatFriendBtn = this._moreFunctionList.getChild("wechatFriendBtn").asButton;
            this._publicPlatformBtn = this._moreFunctionList.getChild("publicPlatformBtn").asButton;

            this._inviteBtn = this._commonFunctionList.getChild("inviteBtn").asButton;
            this._appStoreShareBtn = this._commonFunctionList.getChild("appstoreShareBtn").asButton;
            // this._questionBtn = this._commonFunctionList.getChild("surveyBtn").asButton;
            this._setupBtn = this._commonFunctionList.getChild("setupBtn").asButton;
            this._warBtn = this._commonFunctionList.getChild("warBtn").asButton;
            this._warBtn.addClickListener(() => {
                // Core.ViewManager.inst.open(ViewName.choiceFightCardWnd);
                War.WarMgr.inst.openWarHome();

            }, this);
            this._setupBtn.visible = true;
            this._setupBtn.addClickListener(this._onSetup, this);
            this._inviteBtn.asCom.getChild("rewardHint").visible = false;

            this._appStoreShareBtn.addClickListener(() => {
                // console.log(window.sharePlatform.getShareType());
                if (window.sharePlatform.getShareType() == ShareType.SHARE_FACEBOOK) {
                    Core.ViewManager.inst.open(ViewName.shareFacebookReward);
                } else {
                    Core.ViewManager.inst.open(ViewName.shareReward);
                }
            }, this);

            this.getChild("btnMatch").asButton.addClickListener(this._onMatch, this);

            this.getChild("techBtn").asButton.addClickListener(this._onMatch, this);
            this.getChild("rankListBtn").asCom.addClickListener(this._onRankList, this);
            this.getChild("videoBtn").asButton.addClickListener(this._onWatchVideo, this);
            // this.getChild("videoHallBtn").asButton.addClickListener(this._onVideoHall, this);
            this.getChild("btnMatch").y += window.support.topMargin + Utils.getResolutionDistance()/3;
            this.getChild("techBtn").y += window.support.topMargin + Utils.getResolutionDistance()/3;
            this.getChild("treasures").y += window.support.topMargin + Utils.getResolutionDistance()/2;

            this._treasure1 = (this.getChild("treasures").asCom).getChild("treasure1").asCom as Treasure.TreasureItemCom;
            this._treasure2 = (this.getChild("treasures").asCom).getChild("treasure2").asCom as Treasure.TreasureItemCom;
            this._treasure3 = (this.getChild("treasures").asCom).getChild("treasure3").asCom as Treasure.TreasureItemCom;
            this._treasure4 = (this.getChild("treasures").asCom).getChild("treasure4").asCom as Treasure.TreasureItemCom;

            this._treasureAni0 = (this.getChild("treasures").asCom).getTransition("t0");
            this._treasureAni1 = (this.getChild("treasures").asCom).getTransition("t1");
            this._treasureAni2 = (this.getChild("treasures").asCom).getTransition("t2");
            this._treasureAni3 = (this.getChild("treasures").asCom).getTransition("t3");
            this._TreasureAni4 = (this.getChild("treasures").asCom).getTransition("t4");

            this._treasureImg =  (this.getChild("treasures").asCom).getChild("boxImg").asLoader;

            this._pos2Treasure = new Collection.Dictionary<number, Treasure.TreasureItemCom>();
            this._pos2Treasure.setValue(0, this._treasure1);
            this._treasure1.pos = 0;
            this._pos2Treasure.setValue(1, this._treasure2);
            this._treasure2.pos = 1;
            this._pos2Treasure.setValue(2, this._treasure3);
            this._treasure3.pos = 2;
            this._pos2Treasure.setValue(3, this._treasure4);
            this._treasure4.pos = 3;

            this._treasure1.refresh(null);
            this._treasure2.refresh(null);
            this._treasure3.refresh(null);
            this._treasure4.refresh(null);

            this._latestTreasurePos = -1;

            this._dailyTreasure = this.getChild("dailyTreasure").asCom as Treasure.DailyTreasureItemCom;
            //this._dailyTreasure.visible = false;

            this._pvpRankBanner = this.getChild("pvpRankBanner").asCom as UI.PvpRankBannerCom;
            this._pvpRankBanner.y += window.support.topMargin;


            this._appLikeBtn.visible = false;

            // this._questionBtn.addClickListener(()=> {
            //     Core.ViewManager.inst.open(ViewName.survey);
            // }, this);
            // this._questionBtn.visible = false;

            this._pvpRankBanner.addClickListener(() => {
                SoundMgr.inst.playSoundAsync("click_mp3");
                //Core.ViewManager.inst.open(ViewName.pvpNewBattleEnd, {"WinUid":Player.inst.uid, "scoreModify":2, "TreasureID":""});
                Core.ViewManager.inst.open(ViewName.rankRewardView);
            }, this);

            // this.getChild("publicPlatformBtn").visible = true;
            this._publicPlatformBtn.addClickListener(() => {
                Core.ViewManager.inst.open(ViewName.wechatPlatform);
            }, this);

            this._appLikeBtn.visible = false;
            this._appLikeBtn.addClickListener(() => {
                egret.localStorage.setItem("showReview","true");
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.OPEN_APP_COMMENT);
                this._appLikeBtn.visible = false;
            },this);

            // this._pvpTitleText = this.getChild("pvpTitleText").asTextField;
            // this._pvpTitleText.textParser = Core.StringUtils.parseColorText;
            this._updatePvpInfo();

            if (Core.DeviceUtils.isWXGame()) {
                this._wechatFriendBtn.addClickListener(() => {
                    Core.ViewManager.inst.open(ViewName.wxgameFriendRankView, "friends");
                }, this);
                this._inviteBtn.addClickListener(() => {
                    this._onInvite();
                },this);
            } else if (Core.DeviceUtils.isiOS()) {
                this._gameCenterBtn.addClickListener(() => {
                    Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.SHOW_GAME_CENTER_RANK);
                }, this);
            }
            this._wechatFriendBtn.visible = false;
            this._inviteBtn.visible = false;
            this.getChild("mailBtn").visible = false;
            this._gameCenterBtn.visible = false;
            this._appStoreShareBtn.visible =false;
            this._rankSeasonBtn.visible = false;
            this._rankSeasonFaqBtn.visible = false;
            this._rankSeasonCardBtn.visible = false;
            this._warBtn.visible = false;

            let self = this;
            this.getChild("shopBtn").asButton.addClickListener(() => {
                Core.ViewManager.inst.open(ViewName.shopView);
            }, this);
            if (window.gameGlobal.channel == "lzd_handjoy" || !Player.inst.isNewVersionPlayer()) {
                Core.EventCenter.inst.addEventListener(GameEvent.ShopFreeAvailableEv, () => {
                    self.getChild("shopBtn").asButton.getChild("freeFlag").visible = true;
                }, this);
                Core.EventCenter.inst.addEventListener(GameEvent.ShopFreeUnavailableEv, () => {
                    self.getChild("shopBtn").asButton.getChild("freeFlag").visible = false;
                }, this);
            }

            this.getChild("shopBtn").visible = false;

            Core.EventCenter.inst.addEventListener(Core.Event.AddTreasureEvt, this._onAddTreasureItem, this);
            Core.EventCenter.inst.addEventListener(Core.Event.DelTreasureEvt, this._onDelTreasureItem, this);
            Core.EventCenter.inst.addEventListener(Core.Event.UpdateTreasureEvt, this._onUpdateTreasureItem, this);
            Core.EventCenter.inst.addEventListener(Core.Event.UpdateDailyTreasureEvt, this._onUpdateDailyTreasureItem, this);
            Core.EventCenter.inst.addEventListener(Core.Event.ReConnectEv, this._refreshTreasures, this);
            Core.EventCenter.inst.addEventListener(Core.Event.ReConnectEv, this._refreshQuest, this);
            Core.EventCenter.inst.addEventListener(GameEvent.UpdateSeasonTime, this._setSeasonTime, this);
            Core.EventCenter.inst.addEventListener(GameEvent.SeasonBegin, this._setSeasonBtn, this);
            Core.EventCenter.inst.addEventListener(GameEvent.SeasonEnd, this._closeSeasonBtn, this);
            Core.EventCenter.inst.addEventListener(GameEvent.RankCardUpdate, this._setRankHandCardBtn, this);
            Core.EventCenter.inst.addEventListener(GameEvent.ShowRankCard, this._showRankHandCardBtn, this);

            Player.inst.addEventListener(Player.ResUpdateEvt, this._updatePvpInfo, this);

            Pvp.MailMgr.inst.addEventListener(Pvp.MailMgr.MailRedDot, this._mailRedDot, this);
            Core.EventCenter.inst.addEventListener(Social.InviteDataMgr.UpdateInviteHit, this._inviteDot, this);

            Core.NativeMsgCenter.inst.addListener(Core.NativeMessage.ON_START_MATCH, () => {
                console.log("native onStartMatch");
                self._onMatch();
            }, null);

            this._setGuideProgress();

            if (window.gameGlobal.isMultiLan) {
                this._publicPlatformBtn.visible = false;
                // this._questionBtn.visible = false;
            }

            this._huodongEntryBtn = this.getChild("eventBtn").asButton;
            this._huodongEntryBtn.addClickListener(() => {
                Core.ViewManager.inst.open(ViewName.exchangeHuodongView);
            }, this);
            // this._huodongEntryBtn.visible = false;
        }

        public async open(...param:any[]) {
            super.open(...param);
            let parent = param[0];
            this.addToParent(parent);
            this.height = parent.height;
            this._refreshTreasures();
            this._setSeasonBtn();
        }

        public getHudongEntryCom() {
            return this._huodongEntryBtn;
        }

        public getTreasureCom(pos: number) {
            return this._pos2Treasure.getValue(pos);
        }

        private _onWatchVideo() {
            //PvpMgr.inst.watchVideo();
            Core.ViewManager.inst.open(ViewName.videoRecord);
        }

        private _onRankCardBtn() {
            Season.SeasonMgr.inst.showRankHand();
        }

         private async _refreshQuest() {
            await Quest.QuestMgr.inst.loadQuest(true);
        }

        private async _refreshTreasures() {
            let treasures = await Treasure.TreasureMgr.inst().fetchTreasures(RewardType.REWARD);
            treasures.forEach(item => {
                let pos = item.pos;
                let treasureCom = this._pos2Treasure.getValue(pos);
                treasureCom.refresh(item);
            });

            for (let pos = 0; pos < 4; ++ pos) {
                let treasureCom = this._pos2Treasure.getValue(pos);
                let treasure = treasureCom.treasure;
                if (treasure) {
                    if (!Treasure.TreasureMgr.inst().getTreasure(treasure.id)) {
                        treasureCom.refresh(null);
                    }
                }
            }
            Treasure.TreasureMgr.inst().resCurActivatingTreasure();
        }

        public async close(...param:any[]) {
            super.close(...param);
        }

        private _showComponentsAfterGuide() {
            if (window.gameGlobal.isFbAdvert) {
                Net.rpcPush(pb.MessageID.C2S_GET_FBADVERT_REWARD, null);
                // h5推广链接，发奖
                Core.TipsUtils.alert(Core.StringUtils.TEXT(60251), () => {
                    if (Core.DeviceUtils.isAndroid()) {
                        window.location.href = "https://play.google.com/store/apps/details?id=com.openew.game.lzd.handjoy";
                    } else if (Core.DeviceUtils.isiOS()) {
                        window.location.reload(); // TODO
                    }
                }, this, Core.StringUtils.TEXT(60252));
                return;
            }
            this.getChild("rankListBtn").asCom.visible =true;
            this.getChild("dailyTreasure").asCom.visible = true;
            this.getChild("btnMatch").asButton.visible = true;
            this.getChild("videoBtn").asButton.visible = true;
			//this.getChild("videoHallBtn").asButton.visible = true;
            this.getChild("shopBtn").asButton.visible = true;
            this.getChild("questBtn").asButton.visible = true;
            this._rebornBtn.visible = Home.FunctionMgr.inst.isFeatOpen();
            this._mailBtn.visible = true;
            if (window.gameGlobal.isMultiLan) {
                // overseas edition
                this._wechatFriendBtn.visible = false;
                this._publicPlatformBtn.visible = false;
                this._gameCenterBtn.visible = false;
                this._inviteBtn.visible = false;
                if (window.sharePlatform.getShareType() == ShareType.SHARE_FACEBOOK) {
                    this._appStoreShareBtn.visible = (window.sharePlatform.getShareLink() != "");
                }
            } else {
                if (Core.DeviceUtils.isWXGame()) {
                    this._wechatFriendBtn.visible = true;
                    this._publicPlatformBtn.visible = true;
                    this._inviteBtn.visible = true;
                    this._appStoreShareBtn.visible = true;
                } else if (Core.DeviceUtils.isiOS()) {
                    if (!this._isAppstoreExamine) {
                        // this._publicPlatformBtn.visible = true;
                        // this._gameCenterBtn.visible = true;
                        this._appStoreShareBtn.visible = true;
                        this._appLikeBtn.visible = !(egret.localStorage.getItem("showReview") == "true");
                    }
                    this._gameCenterBtn.visible = true;
                    //this.getChild("gameCenterBtn").asCom.visible = true;
                }
                // this._appStoreShareBtn.visible = true;
                this._setWarBtn();
                this._setSeasonBtn();
                this._setRankHandCardBtn();
            }
            Home.HomeMgr.inst.tryBindOldAccount();
        }

        private _closeSeasonBtn() {
            this._rankSeasonBtn.visible = false;
            this._rankSeasonFaqBtn.visible = false;
            this._rankSeasonCardBtn.visible = false;
        }

        private _setWarBtn() {
            if (Home.FunctionMgr.inst.isWorldWarOpen()) {
                let pvpLev = Pvp.PvpMgr.inst.getPvpLevelByScore(Player.inst.getResource(ResType.T_MAX_SCORE));
                let team = Pvp.Config.inst.getPvpTeam(pvpLev);
                this._warBtn.visible =(team >= 5);
            } else {
                this._warBtn.visible = false;
            }
            // this._warBtn.visible = true;
        }
        private _setSeasonBtn() {
            this._rankSeasonBtn.visible = Season.SeasonMgr.inst.isSeason;
        }
        private _setSeasonTime(evt: egret.Event) {
            this._seasonTimeText.text = `${Core.StringUtils.secToString(evt.data, "dhms")}`;
            this._seasonStarNum.text = `${Player.inst.getResource(ResType.SeasonWinDiff)}`;

        }
        private _setRankHandCardBtn() {
            this._rankSeasonCardBtn.visible = Season.SeasonMgr.inst.isSeasonPvpChooseCard;
        }
        private _showRankHandCardBtn(evt: egret.Event) {
            this._rankSeasonCardBtn.visible = evt.data;
        }

        private _setGuideProgress() {
            let pvpScore = Player.inst.getResource(ResType.T_SCORE);
            if (pvpScore > 0) {
                this._guideGroup.visible = false;
                this._showComponentsAfterGuide();
                return;
            }
            Player.inst.addEventListener(Player.ResUpdateEvt, this._onGuideProgressUpdate, this);
            this._onGuideProgressUpdate();
        }

        private _onSetup() {
            Core.ViewManager.inst.open(ViewName.cmdWnd);
        }

        private _onGuideProgressUpdate() {
            let cur = Player.inst.getResource(ResType.T_GUIDE_PRO);
            if (cur >= Guide.MaxGuideProgress) {
                this._guideGroup.visible = false;
                this._showComponentsAfterGuide();
                Player.inst.removeEventListener(Player.ResUpdateEvt, this._onGuideProgressUpdate, this);
                return;
            }
            //this._guideProgress.setProgress(cur, Guide.MaxGuideProgress);
            this._guideProgressTxt.text = `${cur}/${Guide.MaxGuideProgress}`;
        }

        public hideQuestion() {
            // this._questionBtn.visible = false;
        }

        private async _checkQuestion() {
            if (this._isAppstoreExamine) {
                return;
            }

            // this._questionBtn.visible = Home.FunctionMgr.inst.isSurveyOpen();

            let questionComplete: string = egret.localStorage.getItem("questionComplete3"+ Player.inst.uid);
            if (questionComplete == "true") {
                // this._questionBtn.visible = false;
                return;
            }
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_SURVEY_INFO, null);
            if (result.errcode != 0) {
                return;
            }
            let reply = pb.SurveyInfo.decode(result.payload);
            if (reply.IsReward) {
                egret.localStorage.setItem('questionComplete3'+ Player.inst.uid, "true");
                // this._questionBtn.visible = false;
            } else {
                // this._questionBtn.visible = false;
            }

            if (reply.IsComplete) {
                Home.SurveyView.IsComplete = true;
            }
        }

        private _updatePvpInfo() {
            this._pvpRankBanner.refresh(Player.inst.getResource(ResType.T_SCORE));
            let pvpLevel = PvpMgr.inst.getPvpLevel();
            // this._pvpTitleText.text = Config.inst.getPvpTitle(pvpLevel);
            if (pvpLevel >= 2) {
                this._checkQuestion();
            }
            this._setWarBtn();
            this._setSeasonBtn();
            this._setRankHandCardBtn();
        }

        private _mailRedDot(b: egret.Event) {
            this._mailBtn.getChild("mailHint").visible = b.data as boolean;
        }

        private _inviteDot(b: egret.Event) {
            this._inviteBtn.getChild("rewardHint").visible = b.data as boolean;
        }

        private async _onSeason() {
            // Core.ViewManager.inst.open(ViewName.rankSeasonWnd);
            Season.SeasonMgr.inst.showRankWnd();
        }

        private async _onRebornBtn() {
            let ok = await Equip.EquipMgr.inst.fetchEquip();
            if (ok) {
                Core.ViewManager.inst.open(ViewName.rebornShopView);
            }
        }

        private _onMatch() {

            if (Player.inst.isInGuide()) {
                Guide.GuideMgr.inst.saveGuideBattleSign(true);
            }
            let pvpLevel = PvpMgr.inst.getPvpLevel();
            if(pvpLevel<2) {
                // return;
            }
            let camp = PvpMgr.inst.fightCamp;
            let fightPool = PvpMgr.inst.fightPool;
            // console.log("match", fightPool, PvpMgr.inst);
            if (!fightPool) {
                return;
            }

            if (fightPool.getCardAmout() < 5 && (! Season.SeasonMgr.inst.isSeason)) {
                Core.TipsUtils.showTipsFromCenter(`${Utils.camp2Text(camp)}`+Core.StringUtils.TEXT(60142));
                return;
            }
            PvpMgr.inst.beginMatch();
        }

        private async _onInvite() {
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_WX_INVITE_FRIENDS, null);
            if (result.errcode == 0) {
                let reply = pb.WxInviteFriendsReply.decode(result.payload);
                Core.ViewManager.inst.open(ViewName.inviteRewardWnd, reply);
            }

        }

        private async _onMail() {
            let args = {MinMailID: 0};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_MAIL_LIST, pb.FetchMailListArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.MailList.decode(result.payload);
                Core.ViewManager.inst.open(ViewName.mail, reply);
            }
            //test
            // Core.ViewManager.inst.open(ViewName.questChooseCardWnd);
            // Core.ViewManager.inst.open(ViewName.rankSeasonRandomCard, 3);
            // Season.SeasonMgr.inst.showRankWnd();

        }

        private _onRankList() {
            Core.ViewManager.inst.open(ViewName.rankListWnd);
        }

        private _onEnterDiy() {
            Core.ViewManager.inst.open(ViewName.diy);
            //Core.ViewManager.inst.closeView(this);
        }

        private _onBack() {
            Core.ViewManager.inst.open(ViewName.home);
            Core.ViewManager.inst.closeView(this);
        }

        private _onAddTreasureItem(ev:Treasure.TreasureEvent) {
            let treasure = ev.treasureItem;
            let treasureCom = this._pos2Treasure.getValue(treasure.pos);
            treasureCom.refresh(treasure);
            if (!ev.isInit) {
                this._latestTreasurePos = treasure.pos;
            }
        }

        private _onDelTreasureItem(ev:Treasure.TreasureEvent) {
            let treasure = ev.treasureItem;
            let treasureCom = this._pos2Treasure.getValue(treasure.pos);
            treasureCom.refresh(null);
        }

        private _onUpdateTreasureItem(ev:Treasure.TreasureEvent) {
            let poses = this._pos2Treasure.keys();
            poses.forEach(pos => {
                let treasureCom = this._pos2Treasure.getValue(pos);
                treasureCom.refresh(treasureCom.treasure);
            });
            Treasure.TreasureMgr.inst().resCurActivatingTreasure();
        }

        private _onUpdateDailyTreasureItem(ev:Treasure.TreasureEvent) {
            let dailyTreasure = ev.treasureItem as Treasure.DailyTreasureItem;
            this._dailyTreasure.refresh(dailyTreasure);
            //this._dailyTreasure.visible = true;
        }

        public getLatestAddTreasureCom(): Treasure.TreasureItemCom {
            if (this._latestTreasurePos >= 0) {
                return this._pos2Treasure.getValue(this._latestTreasurePos);
            } else {
                return null;
            }
        }

        public get latestTreasurePos(): number {
            return this._latestTreasurePos;
        }

        public clearLatestAddTreasureCom() {
            this._latestTreasurePos = -1;
        }

        public async tryPlayTreasureAddAnimation() {
            let matchView = <Pvp.MatchView>Core.ViewManager.inst.getView(ViewName.match);
            let treasureCom = matchView.getLatestAddTreasureCom();
            if (treasureCom) {
                let treasure = treasureCom.treasure;
                if (treasure) {
                    let pos = matchView.latestTreasurePos;
                    let ani: fairygui.Transition = null;
                    if (pos == 0) {
                        ani = this._treasureAni0;
                    } else if (pos == 1) {
                        ani = this._treasureAni1;
                    } else if (pos == 2) {
                        ani = this._treasureAni2;
                    } else {
                        ani = this._treasureAni3;
                    }
                    treasureCom.hideContent();
                    treasureCom.touchable = false;
                    let rareType = treasure.getRareType();
                    this._treasureImg.url = `treasure_box${rareType}_png`;
                    await new Promise<void>(resolve => {
                        ani.play(() => {
                            resolve();
                        })
                    });
                    matchView.clearLatestAddTreasureCom();
                    treasureCom.touchable = true;
                    treasureCom.refresh(treasureCom.treasure);
                    await new Promise<void>(resolve => {
                        this._TreasureAni4.play(() => {
                            resolve();
                        })
                    });
                }

            }
        }
    }
}
