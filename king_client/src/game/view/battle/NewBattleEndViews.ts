// TypeScript file
module Battle {
    export class BattleEndBaseView extends Core.BaseView {

        protected _winCom: NewBattleWinCom;
        protected _loseCom: NewBattleLoseCom;

        protected _isClosing: boolean;
        protected _canClose: boolean;
        private _closeTrans: fairygui.Transition;
        private _showBtnTrans: fairygui.Transition;

        protected _battleId: Long;
        protected _battleType: BattleType;
        protected _isWin: boolean;
        protected _guideID: number;

        public initUI() {
            super.initUI();
            this.adjust(this.getChild("bg"));
            this._winCom = this.getChild("win").asCom as NewBattleWinCom;
            this._winCom.visible = false;
            this._loseCom = this.getChild("lose").asCom as NewBattleLoseCom;  
            this._loseCom.visible = false;
            this._isClosing = false;
            this._canClose = false;
            this._closeTrans = this.getTransition("t0");
            this._showBtnTrans = this.getTransition("t1");
            this.getChild("closeBtn").addClickListener(this.onBack, this);
            this.getChild("backBtn").addClickListener(this.onBack,this);     
        }

        public async open(...param: any[]) {
            SoundMgr.inst.stopBgMusic(false);
            //关闭投降界面 wuchao
            Core.TipsUtils.closeConfirmPanel();
            super.open(...param);
            this._battleId = BattleMgr.inst.battle.battleID;
            this._battleType = BattleMgr.inst.battle.battleType;
            let data = param[0];
            let isReplay = param[2] as boolean;
            this.getChild("closeBtn").alpha = 0;
            console.log("isReplay:" + isReplay);
            // console.log(this);
            this.setupReplay(isReplay);
            this._guideID = (<Battle>param[1]).getGuideBattleID();
            if (data.WinUid == (<Battle>param[1]).getOwnFighter().uid) {
                this._winCom.visible = true;
                await this.onWin(data);
            } else {
                this._loseCom.visible = true;
                await this.onLose(data);
                
            }
            this._canClose = true;
            this._showBtnTrans.play();
            let matchView = <Pvp.MatchView>Core.ViewManager.inst.getView(ViewName.match);
            if (!matchView) {
                Core.ViewManager.inst.tryCreateView(ViewName.match);
                matchView = <Pvp.MatchView>Core.ViewManager.inst.getView(ViewName.match);
            }
            let treasureCom = matchView.getLatestAddTreasureCom();
            if (treasureCom) {
                treasureCom.hideContent();
            }
            if(Pvp.PvpMgr.inst.getPvpLevel() < 2 && this._loseCom.visible) {
                this.getChild("closeBtn").asButton.title = Core.StringUtils.TEXT(60068);
            } else {
                this.getChild("closeBtn").asButton.title = Core.StringUtils.TEXT(60044);
            }
            let oldflag = Player.inst.oldFlag;
            let nowflg = Player.inst.getResource(ResType.SeasonWinDiff);
            if (oldflag && oldflag != nowflg) {
                Core.TipsUtils.flagTips(oldflag, nowflg);
                Player.inst.oldFlag = nowflg;
            }
        }
        public setupReplay(isReplay:boolean) {

        }

        protected async playCloseAni() {
            await new Promise<void>(resolve => {
				this._closeTrans.play(() => {
					resolve();
				});
			});
        }

        public async close(...param: any[]) {
            await super.close(...param);
            this._canClose = false;
            this._isClosing = false;
            SoundMgr.inst.playBgMusic("bg_mp3");
			await this.playCloseAni();
            this._winCom.visible = false;
            this._loseCom.visible = false;
            this.alpha = 1;

            let homeView = Core.ViewManager.inst.getView(ViewName.newHome) as Home.NewHomeView;
            if (!homeView) {
                Core.ViewManager.inst.open(ViewName.newHome);
                Quest.QuestMgr.inst.updateQuestBtn();
            }
        }

        protected async onWin(data: any) {
            // to be implemented
        }

        protected async onLose(data: any) {
            // to be implemented
        }
        
        protected calcResModify(resType: ResType, data: any) {
            if (data.scoreModify) {
                // for test
                return data.scoreModify;
            }
            let changeRes = <Array<any>>data.ChangeRes;
            let scoreModify = 0;
            for (let info of changeRes) {
                if (info.Old.Type == resType) {
                    scoreModify = info.New.Amount - info.Old.Amount;
                    break;
                }
            }
            return scoreModify;
        }

        protected async onBack() {
            if (this._isClosing || !this._canClose) {
                return false;
            }
            this._isClosing = true;
            //强制在指引第一关胜利后关闭教程，弹出分享
            if (this._guideID && this._guideID == 1 && this._isWin) {
            // if (this._isWin) {
                if (window.sharePlatform.getShareLink() != "" && window.sharePlatform.getShareType() != ShareType.SHARE_FACEBOOK) {
                    Guide.GuideMgr.inst.stopGuide();
                    Core.ViewManager.inst.open(ViewName.shareReward);
                }
            }
            await Core.ViewManager.inst.close(ViewName.battle);
            await Core.ViewManager.inst.closeView(this);
            //BattleMgr.inst.exitVideo();
            return true;
        }
    }

    export class PvpNewBattleEnd extends BattleEndBaseView {

        private _scoreModify: number;
        private _cardIds: Array<number>;

        protected _loseAdvertBtn: fairygui.GButton;
        protected _loseShareBtn: fairygui.GButton;
        protected _winShareBtn: fairygui.GButton;
        protected _closeBtn: fairygui.GButton;
        protected _backBtn: fairygui.GButton;

        private _upTreasureResolve: (value?: void | PromiseLike<void>) => void;

        public initUI() {
            super.initUI();

            this._loseAdvertBtn = this.getChild("loseAdvertBtn").asButton;
            this._loseShareBtn = this.getChild("loseShareBtn").asButton;
            this._winShareBtn = this.getChild("winShareBtn").asButton;
            this._closeBtn = this.getChild("closeBtn").asButton;
            this._backBtn = this.getChild("backBtn").asButton;


            this._winShareBtn.addClickListener(() => {
                if (Core.DeviceUtils.isWXGame()) {

                    WXGame.WXShareMgr.inst.wechatShareBattleVideo(this._battleId,null,null);
                }
            }, this);

            this._loseShareBtn.addClickListener(() => {
                if (Core.DeviceUtils.isWXGame()) {
                    WXGame.WXShareMgr.inst.wechatSharePreventLoseStar();
                }
            }, this);

            this._loseAdvertBtn.addClickListener(async () => {
                if (adsPlatform.isAdsOpen()) {
                    let ret = await adsPlatform.isAdsReady();
					if (!ret.success) {
						Core.TipsUtils.showTipsFromCenter(ret.reason);
						return;
					}
					let res = await adsPlatform.showRewardAds();
					if (res) {
                        let result = await Net.rpcCall(pb.MessageID.C2S_BATTLE_LOSE_READ_ADS, null);
                        if (result.errcode == 0) {
                            let reply = pb.BattleLoseReadAdsReply.decode(result.payload);
                            if (reply.AddStar > 0) {
                                this.onBeHelpToPreventLoseStar(reply.AddStar);
                            }
                        }
					}
				}
            }, this);
        }
        protected async onWin(res: any) {
            this._isWin = true;
            let data = <pb.BattleResult>res;
            // if (Core.DeviceUtils.isWXGame()) {
            //     this._winShareBtn.visible = data.CanShare;
            //     // this._winShareBtn.visible = true;
            //     this._closeBtn.visible = !data.CanShare;
            //     this._backBtn.visible = data.CanShare;
            // } else {
                this._closeBtn.visible = true;
                this._backBtn.visible = false;
            //}
            this._loseShareBtn.visible = false;
            this._loseAdvertBtn.visible = false;
            this._winCom.setPvpMode();
            let gold = this.calcResModify(ResType.T_GOLD, data);
            this._winCom.initGold(gold);
            let scoreModify = this.calcResModify(ResType.T_SCORE, data);
            this._scoreModify = scoreModify;
            this._cardIds = [];
            (<pb.BattleResult>data).UpPvpLevelRewardCards.forEach(cardId => {
                this._cardIds.push(cardId);
            });
            if (scoreModify >= 0) {
                if (scoreModify > 1) {
                    Core.TipsUtils.privTips(Priv.BATTLE_ADD_STAR);
                }
                let oldScore = Player.inst.getResource(ResType.T_SCORE) - scoreModify;
                this._winCom.initCurRankBanner(oldScore);
                this._winCom.initBox(data.TreasureID, data.NoTreasureReason);
                await this._winCom.playWinAnimation();
                if (scoreModify > 0) {
                    await this._winCom.onWin(scoreModify);
                }
            }
            if (data.UpRareTreasureModelID && data.UpRareTreasureModelID != "") {
                if (Core.DeviceUtils.isWXGame()) {
                //     Core.ViewManager.inst.open(ViewName.advertUpTreasureWnd, data.TreasureID, data.UpRareTreasureModelID, async (b: boolean, jade: boolean) => {
                    
                //     });
                    Core.EventCenter.inst.addEventListener(GameEvent.UpTreasureRareEv, this._onShareUpTreasure, this);
                }
                // } else if (adsPlatform.isAdsOpen()) {
                    await new Promise<void>(resolve => {
                        this._upTreasureResolve = resolve;
                        Core.ViewManager.inst.open(ViewName.advertUpTreasureWnd, data.TreasureID, data.UpRareTreasureModelID, async (b: boolean, jade: boolean) => {
                            if (b) {
                                let args = {
                                    IsConsumeJade: jade
                                }
                                let result = await Net.rpcCall(pb.MessageID.C2S_WATCH_UP_TREASURE_RARE_ADS, pb.WatchUpTreasureRareAdsArg.encode(args));
                                if (result.errcode == 0) {
                                    let reply = pb.Treasure.decode(result.payload);
                                    this._winCom.initBox(reply.ModelID, data.NoTreasureReason);
                                    let treasure = Treasure.TreasureMgr.inst().getTreasure(reply.ID);
                                    treasure.type = reply.ModelID;
                                    treasure.fireUpdateEvent();
                                }
                            }
                            this._upTreasureResolve = null;
                            resolve();
                        });
                    });
                // }
            }
        }

        private _onShareUpTreasure(ev: egret.Event) {
            let data = <pb.Treasure>ev.data;

            this._winCom.initBox(data.ModelID, pb.NoTreasureReasonEnum.Unknow);
            let treasure = Treasure.TreasureMgr.inst().getTreasure(data.ID);
            if (treasure) {
                treasure.type = data.ModelID;
                treasure.fireUpdateEvent();
            }

            if (this._upTreasureResolve) {
                this._upTreasureResolve();
                this._upTreasureResolve = null;
            }
        }

        public async onBeHelpToPreventLoseStar(addStar: number) {
            let oldScore = Player.inst.getResource(ResType.T_SCORE) - addStar;
            if (addStar > 0) {
                this._loseAdvertBtn.visible = false;
                this._loseShareBtn.visible = false;
                this._backBtn.visible = false;
                this._closeBtn.visible = true;
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60164));
                this._loseCom.initCurRankBanner(oldScore);
                await this._loseCom.onPreventLoseStar(addStar);
            }
        }

        protected async onLose(data: any) {
            this._isWin = false;
            let scoreModify = this.calcResModify(ResType.T_SCORE, data);
            if (Player.inst.getResource(ResType.T_NO_SUB_STAR_CNT) > 0 && scoreModify < 0) {
                if (adsPlatform.isAdsOpen()) {
                    this._loseAdvertBtn.visible = false;
                    this._loseShareBtn.visible = false;
                    this._closeBtn.visible = true;
                    this._backBtn.visible = false;
                } else if (Core.DeviceUtils.isWXGame()) {
                    this._loseAdvertBtn.visible = false;
                    this._loseShareBtn.visible = false;
                    this._closeBtn.visible = true;
                    this._backBtn.visible = false;
                } else {
                    this._loseAdvertBtn.visible = false;
                    this._loseShareBtn.visible = false;
                    this._closeBtn.visible = true;
                    this._backBtn.visible = false;
                }
            } else {
                this._loseAdvertBtn.visible = false;
                this._loseShareBtn.visible = false;
                this._closeBtn.visible = true;
                this._backBtn.visible = false;
            }
            this._winShareBtn.visible = false;
            
            this._loseCom.setPvpMode();
            
            this._scoreModify = scoreModify;
            if (scoreModify <= 0) {
                let oldScore = Player.inst.getResource(ResType.T_SCORE) - scoreModify;
                this._loseCom.initCurRankBanner(oldScore);
                await this._loseCom.playLoseAnimation();
                if (scoreModify < 0) {
                    await this._loseCom.onLose(-scoreModify);
                } else if (data.NoSubStarReason == pb.BattleResult.NoSubStarReasonEnum.NoSubStarPriv) {
                    Core.TipsUtils.privTips(Priv.BATTLE_NOT_SUB_STAR);
                } else if (data.NoSubStarReason == pb.BattleResult.NoSubStarReasonEnum.Normal) {
                    this._loseCom.noScoreDecLose();
                } else if (Pvp.PvpMgr.inst.getPvpLevel() >= 2) {
                    this._loseCom.noScoreDecLose();
                }
            }

            Core.EventCenter.inst.removeEventListener(GameEvent.UpTreasureRareEv, this._onShareUpTreasure, this);
        }

        protected async onBack() {
            if (!await super.onBack()) {
                return false;
            }
            let needPlayAni = true;
            let scoreModify = this._scoreModify;
            if (scoreModify > 0) {
                let curScore = Player.inst.getResource(ResType.T_SCORE);
                let oldScore = curScore - scoreModify;
                let curPvpLevel = Pvp.PvpMgr.inst.getPvpLevel(curScore);
                let oldPvpLevel = Pvp.PvpMgr.inst.getPvpLevel(oldScore);
                if (curPvpLevel > oldPvpLevel) {
                    let unlockCard = Pvp.Config.inst.getUnlockCard(curPvpLevel);
                    if (unlockCard.length > 0) {
                        if (this._cardIds.length > 0) {
                            await Core.ViewManager.inst.open(ViewName.rankUpRewardTips, true, this._cardIds);
                            needPlayAni = false;
                        }                        
                    }
                }
            } else {
                if (Core.DeviceUtils.isWXGame()) {
                    WXGame.WXShareMgr.inst.cancelPreventLoseStar();
                }
            }
            
            if (needPlayAni) {
                let matchView = Core.ViewManager.inst.getView(ViewName.match) as Pvp.MatchView;
                await matchView.tryPlayTreasureAddAnimation();
            }
            

            if (!this._isWin) {
                if (Player.inst.isInGuide()) {
                    Pvp.PvpMgr.inst.beginMatch();
                }
            }

            return true;
        }
    }

    export class LevelNewBattleEnd extends BattleEndBaseView {
        private _rewardList: fairygui.GList;
        protected _saveVideoBtn: fairygui.GButton;
        protected _shareFacebookBtn: fairygui.GButton;

        public initUI() {
            super.initUI();
            this._rewardList = this._winCom.getChild("rewardList").asList;

            this._saveVideoBtn = this.getChild("saveVideoBtn").asButton;
            this._shareFacebookBtn = this.getChild("shareFacebookBtn").asButton;

            this._saveVideoBtn.addClickListener(() => {
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.SAVE_TO_PHOTO);
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60201));
                this.onBack();
                //this._saveVideoBtn.visible = false;
            }, this);

            this._shareFacebookBtn.addClickListener(() => {
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.SHARE_VIDEO);
            }, this);

            this._shareFacebookBtn.visible = false;
            this._shareFacebookBtn.enabled = false;
        }

        public setupReplay(isReplay:boolean) {
            let hasVideo = (isReplay && window.support.record && VideoPlayer.inst.recordStartSuccess);
            this._saveVideoBtn.visible = hasVideo;
            this._saveVideoBtn.enabled = hasVideo;
            if (hasVideo) {
                this.getChild("closeBtn").setXY(280,675);
            } else {
                this.getChild("closeBtn").setXY(165,675);
            }
            if (window.sharePlatform.getShareType() == ShareType.SHARE_FACEBOOK) {
                this._shareFacebookBtn.visible = hasVideo;
                this._shareFacebookBtn.enabled = hasVideo;
            } else {
                this._shareFacebookBtn.visible = false;
                this._shareFacebookBtn.enabled = false;
            }
        }

        protected async onWin(data: any) {
            this._isWin = true;
            this._winCom.setLevelMode();
            this._rewardList.visible = true;
            let goldModify = this.calcResModify(ResType.T_GOLD, data);
            if (goldModify > 0) {
                let goldCom = fairygui.UIPackage.createObject(PkgName.treasure, "goldCnt", Treasure.GoldRewardCom).asCom as Treasure.GoldRewardCom;
			    goldCom.count = goldModify;
                this._rewardList.addChild(goldCom);
            }

            if (data.ChangeCards) {
                data.ChangeCards.forEach(changeCard => {
                    if (!changeCard.New) {
                        return;
                    }
                    let collectCard = CardPool.CardPoolMgr.inst.getCollectCard(changeCard.New.CardId);
                    if (!collectCard) {
                        return;
                    }
                    let cardCom = fairygui.UIPackage.createObject(PkgName.cards, "middleCard", UI.CardCom) as UI.CardCom;
                    cardCom.cardObj = collectCard;
                    cardCom.setOwnBackground();
                    cardCom.setOwnFront();
                    cardCom.setName();
                    cardCom.setSkill();
                    cardCom.setNumText();
                    cardCom.setNumOffsetText();
                    cardCom.setCardImg();
                    cardCom.setEquip();
                    this._rewardList.addChild(cardCom);
                });
            }

            await this._winCom.playWinAnimation();
        }

        protected async onLose(data: any) {
            this._isWin = false;
            this._loseCom.setLevelMode();
            this._rewardList.visible = false;
            await this._loseCom.playLoseAnimation();
        }

        private async _doBack() {
            this._saveVideoBtn.enabled = false;
            this._shareFacebookBtn.enabled = false;
            this._isClosing = true;
            this._rewardList.removeChildren();
            let homeView = <Home.NewHomeView>Core.ViewManager.inst.getView(ViewName.newHome);
            await homeView.openLevelView(true);

            await Core.ViewManager.inst.close(ViewName.battle);
            await Core.ViewManager.inst.closeView(this);
        }

        protected async onBack() {
            if (this._isClosing || !this._canClose) {
                return false;
            }
            if (this._battleType == BattleType.LevelHelp &&
                Core.DeviceUtils.isWXGame() && this._isWin) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60233));
            }
            if (this._battleType == BattleType.LevelHelp &&
                Core.DeviceUtils.isWXGame() && !this._isWin) {
                let options = WXGame.WXGameMgr.inst.lastHandledOption;
                if (options && parseInt(options.query.act) == WXGame.WXShareType.SHARE_LEVEL_HELP) {
                    Core.TipsUtils.confirm(Core.StringUtils.TEXT(60240), async () => {
                        await this._doBack();
                        let uid: Long = Core.StringUtils.stringToLong(<string>options.query.uid);
                        let levelId: number = parseInt(options.query.levelId);
                        let args = {
                            HelpUid: uid,
                            LevelID: levelId
                        };
                        let result = await Net.rpcCall(pb.MessageID.C2S_LEVEL_HELP_OTHER, pb.LevelHelpArg.encode(args));
                        if (result.errcode == 0) {
                            Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60093));
                        }
                    }, async () => {
                        await this._doBack();
                    }, null, Core.StringUtils.TEXT(60028), Core.StringUtils.TEXT(60019));
                } else {
                    await this._doBack();
                }
            } else {
                await this._doBack();
            }
            return true;
        }

    }
    export class FriendBattleEnd extends BattleEndBaseView {

        protected async onWin(data: any) {
            this._winCom.setFriendMode();
            await this._winCom.playWinAnimation();
        }

        protected async onLose(data: any) {
            this._loseCom.setPvpMode();
            await this._loseCom.playLoseAnimation();
        }

        protected async onBack() {
            if (!await super.onBack()) {
                return false;
            }
            return true;
        }

        protected async playCloseAni() {
            if (this._battleType == BattleType.Campaign) {
                // await super.playCloseAni();
                await Core.ViewManager.inst.open(ViewName.enterWarAni);
            } else {
                await super.playCloseAni();
            }
        }
    }
}