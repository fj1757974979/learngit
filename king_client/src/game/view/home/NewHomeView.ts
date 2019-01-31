module Home {

    enum HomeViewIdx {
        TEAM = 1,
        BATTLE = 2,
        CARDPOOL = 3,
        LEVEL = 4
    }

    export class NewHomeView extends Core.BaseView {
        private _cardPoolBtn: fairygui.GButton;
        private _matchBtn: fairygui.GButton;
        private _levelBtn: fairygui.GButton;
        private _teamBtn: fairygui.GButton;
        private _socialBtn: fairygui.GButton;
        private _listCtrl: fairygui.Controller;
        private _homeList: fairygui.GList;
        private _cardPoolCom: fairygui.GComponent;
        private _matchCom: fairygui.GComponent;
        private _levelCom: fairygui.GComponent;
        private _teamCom: fairygui.GComponent;
        private _socialCom: fairygui.GComponent;
        private _goldText: fairygui.GTextField;
        private _jadeText: fairygui.GTextField;
        private _bowlderText: fairygui.GTextField;
        private _nameText: fairygui.GTextField;
        private _selfInfo: fairygui.GLoader;
        private _headIcon: Social.HeadCom;

        private _treasureAni0: fairygui.Transition;
        private _treasureAni1: fairygui.Transition;
        private _treasureAni2: fairygui.Transition;
        private _treasureAni3: fairygui.Transition;

        private _treasureImg: fairygui.GLoader;

        private _guideTransMask: fairygui.GGraph;

        private _levelOpen: boolean;
        private _teamOpen: boolean;
        private _pvpOpen: boolean;
        private _cardpoolOpen: boolean;
        private _socialOpen: boolean;
        private _inScroll: number = 0;

        private _inviteBattleCom: Social.InviteBattleHintCom;
        private _viewNames: string[] = [ViewName.team,
                                        ViewName.cardpool,
                                        ViewName.match,
                                        ViewName.social,
                                        ViewName.level];

        public initUI() {
            super.initUI();
            this.adjust(this.getChild("bg"));

            this.getChild("topBg").height += window.support.topMargin;
            //this.getChild("topBg").y -= window.support.topMargin;
            this.getChild("bottomBg").height += window.support.bottomMargin;
            //this.getChild("bottomBg").y -= window.support.bottomMargin;

            this._cardPoolBtn = this.getChild("cardPoolBtn").asButton;
            this._matchBtn = this.getChild("matchBtn").asButton;
            this._levelBtn = this.getChild("levelBtn").asButton;
            this._teamBtn = this.getChild("teamBtn").asButton;
            this._socialBtn = this.getChild("societyBtn").asButton;

            let self = this;
            this._cardPoolBtn.addClickListener(() => {
                self.openCardPoolView();
                self._onScrollEnd();
            }, this);
            this._matchBtn.addClickListener(() => {
                self.openPvpView();
                self._onScrollEnd();
            }, this);
            this._levelBtn.addClickListener(() => {
                self.openLevelView();
                self._onScrollEnd();
            }, this);
            this._teamBtn.addClickListener(() => {
                self.openTeamView();
                self._onScrollEnd();
            }, this);
            this._socialBtn.addClickListener(() => {
                self.openSocialView();
                self._onScrollEnd();
            }, this);

            this._listCtrl = this.getController("homeListCtrl");
            this._homeList = this.getChild("baseList").asList;
            // 调整上下边距
            //this._homeList.y += window.support.topMargin/2;
            
            this._homeList.height = Math.floor(this._homeList.height + Utils.getResolutionDistance());
            //this._homeList.height -= (window.support.topMargin + window.support.bottomMargin);

            this._cardPoolCom = this._homeList.getChild("cards").asCom;
            this._cardPoolCom.height = this._homeList.height;
            this._matchCom = this._homeList.getChild("pvp").asCom;
            this._matchCom.height = this._homeList.height;
            this._levelCom = this._homeList.getChild("level").asCom;
            this._levelCom.height = this._homeList.height;
            this._teamCom = this._homeList.getChild("team").asCom;
            this._teamCom.height = this._homeList.height;
            this._socialCom = this._homeList.getChild("society").asCom;
            this._socialCom.height = this._homeList.height;

            this._goldText = this.getChild("goldText").asTextField;
            this._jadeText = this.getChild("jadeText").asTextField;
            this._bowlderText = this.getChild("bowlderText").asTextField;
            this._nameText = this.getChild("nameText").asTextField;
            this._nameText.textParser = Core.StringUtils.parseColorText;
            this._headIcon = this.getChild("head").asCom as Social.HeadCom;

            this._treasureAni0 = this.getTransition("t0");
            this._treasureAni1 = this.getTransition("t1");
            this._treasureAni2 = this.getTransition("t2");
            this._treasureAni3 = this.getTransition("t3");

            this._treasureImg = this.getChild("boxImg").asLoader;

            this._headIcon.addClickListener(this._onDetail, this);

            this._listCtrl.addAction(SoundMgr.inst.playSoundAction("page_mp3", true));
            this._listCtrl.addEventListener(fairygui.StateChangeEvent.CHANGED, this._onListChanged, this);
            this._homeList.scrollPane.addEventListener(fairygui.ScrollPane.SCROLL, this._onListDrag, this);
            this._homeList.scrollPane.addEventListener(fairygui.ScrollPane.SCROLL_END, this._onScrollEnd, this);

            Player.inst.addEventListener(Player.ResUpdateEvt, this._onResUpdate, this);
            Player.inst.addEventListener(Player.LoginEvt, () => {
                this._levelOpen = false;
                this._pvpOpen = false;
                this._teamOpen = false;
                this._cardpoolOpen = false;
                this._socialOpen = false;
            }, this);
            this._nameText.text = Player.inst.name;
            Core.EventCenter.inst.addEventListener(GameEvent.ModifyNameEv, (evt: egret.Event) => {
                this._nameText.text = evt.data;
            }, this);
            this._headIcon.setHead(Player.inst.avatarUrl);
            this._headIcon.setFrame(Player.inst.frameUrl);
            Core.EventCenter.inst.addEventListener(GameEvent.ModifyAvatarEv, (evt: egret.Event) => {
                this._headIcon.setHead(evt.data);
            }, this);
            Core.EventCenter.inst.addEventListener(GameEvent.ModifyFrameEv, (evt: egret.Event) => {
                this._headIcon.setFrame(Player.inst.frameUrl);
            }, this);

            if (Core.DeviceUtils.isWXGame()) {
                (<CardPool.AvatarNumHintCom>this.getChild("avatarNumHint").asCom).visible = false;
            } else {
                (<CardPool.AvatarNumHintCom>this.getChild("avatarNumHint").asCom).visible = true;
                (<CardPool.AvatarNumHintCom>this.getChild("avatarNumHint").asCom).observerAvatarNum();
            }
            (<CardPool.CardNumHintCom>this._cardPoolBtn.getChild("cardNumHint").asCom).observeCampCardNum();
            (<Level.LevelNumHintCom>this._levelBtn.getChild("levelNumHint").asCom).observeLevelNum();
            (<Social.SocialHintCom>this._socialBtn.getChild("socialNumHint").asCom).observerSocialHintNum();

            this._pvpOpen = false;
            this._levelOpen = false;
            this._cardpoolOpen = false;
            this._teamOpen = false;
            this._inScroll = 0;
            this._onResUpdate();
            this._homeList.selectedIndex = 2;
            //this._listCtrl.setSelectedIndex(2, false);

            this._inviteBattleCom = this.getChild("inviteBattleHint").asCom as Social.InviteBattleHintCom;
            this._inviteBattleCom.visible = false;

            Core.EventCenter.inst.addEventListener(GameEvent.BeInviteBattleEv, (evt: egret.Event) => {
                this._inviteBattleCom.visible = true;
                let data = <Array<any>>evt.data;
                this._inviteBattleCom.setInfo(<Long>data[0], <string>data[1]);
            }, this);

            this.getChild("bowlderText").visible = Home.hasBowlderRes();
            this.getChild("bowlderIcon").visible = Home.hasBowlderRes();

            //this.openTeamView();

            this._handleGuideIssues();
            
        }

        private _onSetup() {
            Core.ViewManager.inst.open(ViewName.cmdWnd);
        }

        public async open(...param: any[]) {
            super.open(...param);
            if (this._levelOpen || this._cardpoolOpen || this._teamOpen || this._pvpOpen || this._socialOpen) {
                return;
            }
            this._homeList.scrollToView(2);
            await this.openPvpView();
            await Pvp.PvpMgr.inst.onEnterPvp();

            fairygui.GTimers.inst.callDelay(1000, async ()=> {
                await this.openCardPoolView();
                // await this.openLevelView();
                await this.openSocialView();
                // await this.openTeamView();
            }, this);
        }

        public async close(...param: any[]) {
            super.close(...param);
            this._levelOpen = false;
            this._teamOpen = false;
            this._pvpOpen = false;
            this._cardpoolOpen = false;
            this._socialOpen = false;
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
                }

            }
        }

        private _tryTriggerGuide(viewName: string) {
            fairygui.GTimers.inst.callLater(() => {
                Core.EventCenter.inst.dispatchEventWith(GameEvent.OpenHomeEv, false, viewName);
            }, this);
        }

        public async openPvpView() {
            if (!this._pvpOpen) {
                this._pvpOpen = true;
                console.log("open pvp view");
                await Core.ViewManager.inst.open(ViewName.match, this._matchCom);
            }
            
            if (this.getCurView() == ViewName.match) {
                this._tryTriggerGuide(ViewName.match);
            }
        }

        public async openTeamView() {
            if (!this._teamOpen) {
                this._teamOpen = true;
                let arr = await Pvp.PvpMgr.inst.onEnterPvp();
                // console.log(`${arr}`);
                await Core.ViewManager.inst.open(ViewName.team);
                let view = (<Pvp.TeamView>Core.ViewManager.inst.getView(ViewName.team))
                view.refresh(arr[0], arr[1]);
                view.addToParent(this._teamCom);
                view.height = this._homeList.height;
            }
            
            if (this.getCurView() == ViewName.team) {
                this._tryTriggerGuide(ViewName.team);
            }
        }

        public async openCardPoolView() {
            if (!this._cardpoolOpen) {
                this._cardpoolOpen = true;
                await CardPool.CardPoolMgr.inst.onEnterCardPool();
                let view = (<CardPool.CardPoolView>Core.ViewManager.inst.getView(ViewName.cardpool))
                view.addToParent(this._cardPoolCom);
                view.height = this._homeList.height;
            }
            
            if (!this._teamOpen) {
                await this.openTeamView();
            }

            if (this.getCurView() == ViewName.cardpool) {
                this._tryTriggerGuide(ViewName.cardpool);
            }
        }

        public async openLevelView(force: boolean = false) {
            if (!this._levelOpen || force) {
                this._levelOpen = true;
                await Level.LevelMgr.inst.onEnterLevel();
                await Core.ViewManager.inst.open(ViewName.level);
                let view = (<Level.LevelView>Core.ViewManager.inst.getView(ViewName.level));
                view.addToParent(this._levelCom);
                view.height = this._homeList.height;
            }
            
            if (this.getCurView() == ViewName.level) {
                this._tryTriggerGuide(ViewName.level);
            }
        }

        public async openSocialView() {
            if (!this._socialOpen) {
                this._socialOpen = true;
                await Core.ViewManager.inst.open(ViewName.social);
                let socialView = <Social.SocialView>Core.ViewManager.inst.getView(ViewName.social);
                if (this.getCurView() == ViewName.social) {
                    socialView.refresh();
                }
                socialView.visible = true;
                socialView.addToParent(this._socialCom);
            }
            
            if (!this._levelOpen) {
                await this.openLevelView();
            }
        }

        public hideOtherView() {
            for (let i = 0; i<this._viewNames.length; i++) {
                let name:string = this._viewNames[i];
                let show:boolean = (name == this.getCurView());
                let view = Core.ViewManager.inst.getView(name);
                if (view) view.setVisible(show);
            }

        }

        public showAllView() {
            for (let i = 0; i<this._viewNames.length; i++) {
                let name:string = this._viewNames[i];
                let view = Core.ViewManager.inst.getView(name);
                if (view) view.setVisible(true);
            }
        }

        public getCurView(): string {
            let curIdx = this._listCtrl.selectedIndex;
            return this._viewNames[curIdx] || "";
        }

        private _onListChanged() {
            Core.EventCenter.inst.dispatchEventWith(Core.Event.HomeListChangedEvt, false, this.getCurView());
            if (this._inScroll < 3)
                this.hideOtherView();
        }

        private _onScrollEnd() {
            //console.log("on drag end");
            this.hideOtherView();
            this._inScroll = 0;
        }

        private async _onListDrag() {
            //console.log("on list drag");
            if (this._inScroll >= 3) return;
            this._inScroll ++;
            if (this._inScroll >= 3) {
                this.showAllView();
                let curIdx = this._listCtrl.selectedIndex;
                if (curIdx == 1) {
                    if (!this._cardpoolOpen) {
                        await this.openCardPoolView();
                        this.showAllView();
                    }
                } else if (curIdx == 2) {
                    if (!this._levelOpen) {
                        await this.openLevelView();
                        this.showAllView();
                    }
                }
            }
        }

        private async _onDetail() {
            await Social.SocialMgr.inst.openSelfInfoView();
        }

        private _onResUpdate() {
            this._goldText.text = `${Player.inst.getResource(ResType.T_GOLD)}`;
            this._jadeText.text = `${Player.inst.getResource(ResType.T_JADE)}`;
            this._bowlderText.text = `${Player.inst.getResource(ResType.T_BOWLDER)}`;
        }

        private _handleGuideIssues() {
            Guide.GuideMgr.inst.addEventListener(GameEvent.BeginGuideEv, () => {
                this.showTransMask(false);
            }, this);

            Guide.GuideMgr.inst.addEventListener(GameEvent.FinishGuideEv, () => {
                this.showTransMask(true);
            }, this);
        }

        private _guideMaskTimeout() {
            Core.MaskUtils.hideTransMask();
        }

        private _genGuideMask() {
            if (!this._guideTransMask) {
                let transMask = new fairygui.GGraph();
                transMask.graphics.clear();
                transMask.graphics.beginFill(0x000000, 0.3);
                transMask.graphics.drawRect(0, 0, fairygui.GRoot.inst.width, fairygui.GRoot.inst.height);
                transMask.graphics.endFill();
                transMask.width = fairygui.GRoot.inst.getDesignStageWidth();
                transMask.height = fairygui.GRoot.inst.getDesignStageHeight();
                transMask.x = fairygui.GRoot.inst.width / 2 - transMask.width / 2;
                transMask.y = fairygui.GRoot.inst.height / 2 - transMask.height / 2;
                
                transMask.touchable = true;     
                transMask.visible = true;
                this._guideTransMask = transMask;
            }
        }

        public showTransMask(b: boolean) {
            if (Guide.GuideMgr.inst.curGuideGroupId >= Guide.MAX_GUIDE_GROUP) {
                Core.MaskUtils.hideTransMask();
                return;
            }
            // if (this.getCurView() == ViewName.match) {
                if (b) {
                    if (Guide.GuideMgr.inst.curGuideGroupId == 240) {
                        // 新手指引强撸
                        return;
                    }
                    Core.MaskUtils.showTransMask();
                    fairygui.GTimers.inst.remove(this._guideMaskTimeout, this);
                    fairygui.GTimers.inst.add(5 * 1000, 1, this._guideMaskTimeout, this);
                } else {
                    Core.MaskUtils.hideTransMask();
                }
            // }
            /*
            this._genGuideMask();
            if (Guide.GuideMgr.inst.curGuideGroupId >= Guide.MAX_GUIDE_GROUP) {
                if (this._guideTransMask.parent) {
                    this._guideTransMask.parent.removeChild(this._guideTransMask);
                }
                return;
            }
            if (b) {
                if (this._guideTransMask.parent) {
                    return;
                }
                this.addChild(this._guideTransMask);
                fairygui.GTimers.inst.remove(this._guideMaskTimeout, this);
                fairygui.GTimers.inst.add(5 * 1000, 1, this._guideMaskTimeout, this);
            } else {
                if (this._guideTransMask.parent) {
                    this._guideTransMask.parent.removeChild(this._guideTransMask);
                }
            }
            */
        }
    }
}
