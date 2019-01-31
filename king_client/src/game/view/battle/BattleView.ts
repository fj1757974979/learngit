module Battle {

    export class BattleView extends Core.BaseView {
        private _beginBtn: fairygui.GButton;
        private _grids: Array<GridView>;
        private _myHandCom: UI.HandCardGrid;
        private _oppHandCom: UI.HandCardGrid;
        private _surrenderBtn: fairygui.GButton;
        private _gmWinBtn: fairygui.GButton;
        private _enemyTimer: UI.MaskProgressBar;
        private _myTimer: UI.MaskProgressBar;
        private _timerValue: number = 100;
        private _selfOffensiveTrans: fairygui.Transition;
        private _enemyOffensiveTrans: fairygui.Transition;
        private _recordTrans: fairygui.Transition;
        private _offensiveGroup: fairygui.GGroup;
        private _emojiBtn: fairygui.GButton;
        private _switchEmojiBtn: fairygui.GButton;
        private _enemyName: fairygui.GTextField;
        private _enemyCountry: fairygui.GLoader;
        //private _enemyCountryBg: fairygui.GLoader;
        private _recordImage: fairygui.GLoader;
        private _startRecordBtn: fairygui.GButton;
        private _exitPlayBtn: fairygui.GButton;
        private _stopRecordBtn: fairygui.GButton;
        private _myTurnIcon: fairygui.GLoader;
        private _oppTurnIcon: fairygui.GLoader;
        private _myturnTrans: fairygui.Transition;
        private _oppturnTrans: fairygui.Transition;
        private _enemyHead: Social.HeadCom;
        private _levelName: fairygui.GTextField;

        private _myHand: Hand;
        private _oppHand: Hand;
        private _topGrid: GridView;
        private _selfEmojiCom: EmojiCom;
        private _enemyEmojiCom: EmojiCom;
        private _showRecordBtn: Boolean;


        private _disregard: boolean;

        public initUI() {
            super.initUI();
            this.adjust(this.getChild("bg"));

            this._recordImage = this.getChild("img_record").asLoader;

            this._grids = [];
            this._grids.push( this.getChild("grid1") as GridView );
            this._grids.push( this.getChild("grid2") as GridView );
            this._grids.push( this.getChild("grid3") as GridView );
            this._grids.push( this.getChild("grid4") as GridView );
            this._grids.push( this.getChild("grid5") as GridView );
            this._grids.push( this.getChild("grid6") as GridView );
            this._grids.push( this.getChild("grid7") as GridView );
            this._grids.push( this.getChild("grid8") as GridView );
            this._grids.push( this.getChild("grid9") as GridView );
            this._topGrid = this._grids[this._grids.length - 1];
            for (let i=0; i<this._grids.length; i++) {
                this._grids[i].gridId = i;
            }

            let adjustH = Utils.getResolutionDistance();
            this._beginBtn = this.getChild("beginBtn").asButton;
            this._myHandCom =  this.getChild("myHand") as UI.HandCardGrid;
            this._myHandCom.y -= adjustH / 4;
            this._oppHandCom = this.getChild("oppHand") as UI.HandCardGrid;
            this._oppHandCom.y += adjustH / 4;
            this._surrenderBtn = this.getChild("surrenderBtn").asButton;
            this._gmWinBtn = this.getChild("gmWinBtn").asButton;
            this._enemyTimer = this.getChild("enemyProgress") as UI.MaskProgressBar;
            this._myTimer = this.getChild("myProgress") as UI.MaskProgressBar;
            this._selfOffensiveTrans = this.getTransition("self");
            this._enemyOffensiveTrans = this.getTransition("enemy");
            this._recordTrans = this.getTransition("record");
            this._offensiveGroup = this.getChild("offensiveGroup").asGroup;
            this._emojiBtn = this.getChild("emojiBtn").asButton;
            this._switchEmojiBtn = this.getChild("n67").asButton;
            this._enemyName = this.getChild("enemyName").asTextField;
            this._enemyName.textParser = Core.StringUtils.parseColorText;
            this._enemyCountry = this.getChild("enemyCountry").asLoader;
            //this._enemyCountryBg = this.getChild("enemyCountryBg").asLoader;
            this._startRecordBtn = this.getChild("startRecordBtn").asButton;
            this._stopRecordBtn = this.getChild("stopRecordBtn").asButton;
            this._exitPlayBtn = this.getChild("exitPlayBtn").asButton;
            this._myTurnIcon = this.getChild("myTurnCardIcon").asLoader;
            this._oppTurnIcon = this.getChild("oppTurnCardIcon").asLoader;
            this._myturnTrans = this.getTransition("myturn");
            this._oppturnTrans = this.getTransition("oppturn");
            this._enemyHead = this.getChild("enemyHead") as Social.HeadCom;
            this._levelName = this.getChild("levelName").asTextField;

            this._enemyName.y -= Utils.getResolutionDistance() /4/2;
            
            this._levelName.visible = false;
            this._enemyTimer.visible = false;
            this._myTimer.visible = false;
            this._recordImage.visible = false;

            this._beginBtn.addClickListener(this._onLevelReadyDone, this);
            this._surrenderBtn.addClickListener(this._onSurrender, this);
            this._gmWinBtn.addClickListener(BattleMgr.inst.gmWin, BattleMgr.inst);
            this._exitPlayBtn.addClickListener(this._onExit, this);
            this._emojiBtn.addClickListener(this._showEmojiChoiceWnd, this);
            this._switchEmojiBtn.addClickListener(this._onDisregardBtn, this);
            this._startRecordBtn.addClickListener(this.startRecord, this);
            this._stopRecordBtn.addClickListener(this.stopRecord, this);

            // this._showRecordBtn = Core.DeviceUtils.isiOS() && !Core.DeviceUtils.isWXGame();
            this._showRecordBtn = !Core.DeviceUtils.isWXGame();

            if (window.gameGlobal.isMultiLan) {
                this._enemyName.fontSize = 20;
                this._levelName.fontSize = 20;
            }
        }

        public async open(...param:any[]) {
            super.open(...param);
            egret.MainContext.instance.stage.maxTouches = 1;
            let battle = param[0] as Battle;
            this._disregard = false;
            this._beginBtn.visible = false;
            this._offensiveGroup.visible = false;
            this._setCasterSkill(battle);
            //this.getTransition("t2").play(null, null, null, 1, 10);
            this._myHand = new MyHand(this._myHandCom, battle, battle.getOwnFighter());
            this._oppHand = new EnemyHand(this._oppHandCom, battle, battle.getEnemyFighter());
            let enemyFighter = battle.getEnemyFighter();
            if (battle instanceof LevelBattle) {
                this._enemyName.visible = false;
                this._levelName.visible = true;
                this._enemyCountry.url = null;
                this._levelName.text = (battle as LevelBattle).levelName;
                //this._enemyCountryBg.url = "battle_nameWu_png";
            } else if (battle instanceof VideoBattle && enemyFighter.pvpScore == 0) {
                this._enemyName.visible = false;
                this._levelName.visible = true;
                this._enemyCountry.url = null;
                if (Level.LevelMgr.inst.curVideoLevel) {
                    this._levelName.text = Level.LevelMgr.inst.curVideoLevel.name;
                } else {
                    this._levelName.text = "";
                }
                
            } else {
                this._enemyName.visible = true;
                this._levelName.visible = false;
                this._enemyName.text = enemyFighter.name;
                // if (enemyFighter.pvpScore != 0) {
                this._enemyCountry.url = this._campToResUrl(enemyFighter.camp);
                //this._enemyCountryBg.url = this._campToBgResUrl(enemyFighter.camp);
                // } else {
                //     this._enemyCountry.url = null;
                //     this._enemyCountryBg.url = "battle_nameWu_png";
                // }
                
            }
            
            this._grids.forEach(g => {
                g.setup(battle.getGridById(g.gridId));
            });

            let visibleGmWin = false;
            if (window.gameGlobal.debug && 
                (Player.inst.name.indexOf("www") >= 0 || Player.inst.name.indexOf("kcmj") >= 0 || Player.inst.name.indexOf("lsw") >= 0)) {
                visibleGmWin = true;
            }
            this._recordImage.visible = false;

            if (battle.battleType == BattleType.VIDEO) {
                this._surrenderBtn.visible = false;
                this._gmWinBtn.visible = false;
                this._exitPlayBtn.visible = true;
                this._startRecordBtn.visible = this._showRecordBtn && true;
                this._stopRecordBtn.visible = false;
                Core.ViewManager.inst.open(ViewName.videoFunction, battle);
            } else {
                //this._surrenderBtn.visible = true;
                this._gmWinBtn.visible = visibleGmWin;
                this._exitPlayBtn.visible = false;
                this._startRecordBtn.visible = false;
                this._stopRecordBtn.visible = false;
                this._surrenderBtn.visible = true;
                Core.ViewManager.inst.close(ViewName.videoFunction);
            }
            this._myTurnIcon.visible = false;
            this._oppTurnIcon.visible = false;

            this.stopTimerProgress();
            this._emojiBtn.visible = battle.isPvp();
            this._switchEmojiBtn.visible = battle.isPvp();

            let battleType = battle.battleType;
            if (battleType == BattleType.LEVEL || battleType == BattleType.LevelHelp) {
                this._enemyHead.visible = false;
            } else if (battleType == BattleType.VIDEO && enemyFighter.pvpScore == 0) {
                this._enemyHead.visible = false;
            } else {
                let enemyFighter = battle.getEnemyFighter();
                this._enemyHead.setAll(enemyFighter.headIcon, enemyFighter.frameIcon);
            }

            Core.EventCenter.inst.addEventListener(GameEvent.BeginDragGuideEv, this._onBeginDragGuide, this);
        }

        public setRecordMode(flag:boolean) {
            this._recordImage.visible = flag;
            if (flag) {
                this._recordTrans.play(null, null, null, -1);
            }
            this._startRecordBtn.visible = this._showRecordBtn && !flag;
            this._stopRecordBtn.visible = this._showRecordBtn && flag;
        }

        public startRecord() {
            VideoPlayer.inst.startRecord();
        }

        public stopRecord() {
            VideoPlayer.inst.stopRecord();
        }

        private _campToResUrl(camp:Camp): string {
            if (camp == Camp.WEI) {
                return "battle_txtWei_png";
            } else if (camp == Camp.SHU) {
                return "battle_txtShu_png";
            } else if (camp == Camp.WU) {
                return "battle_txtWu_png";
            } else {
                return "";
            }    
        }

        private _campToBgResUrl(camp:Camp): string {
            if (camp == Camp.WEI) {
                return "battle_nameWei_png";
            } else if (camp == Camp.SHU) {
                return "battle_nameShu_png";
            } else if (camp == Camp.WU) {
                return "battle_nameWu_png";
            } else {
                return "";
            }    
        }

        public async close(...param:any[]) {
            super.close(...param);
            egret.MainContext.instance.stage.maxTouches = 2;
            this._myHand.clear();
            this._oppHand.clear();
            this._grids.forEach(g => {
                g.clear();
            });

            this.stopRecord();
            if(Core.ViewManager.inst.isShow(ViewName.matching)) {
                Core.ViewManager.inst.close(ViewName.matching);
            }
            Core.ViewManager.inst.close(ViewName.videoFunction);
            Core.EventCenter.inst.removeEventListener(GameEvent.BeginDragGuideEv, this._onBeginDragGuide, this);
        }


        private _showEmojiChoiceWnd() {
            Core.ViewManager.inst.openPopup(ViewName.emojiChoiceWnd, (emojiId: number) => {
                BattleMgr.inst.sendEmoji(emojiId);
            });
        }
        
        private _onDisregardBtn() {
            let tipStr = "";
            if (this._disregard) {
                tipStr = Core.StringUtils.TEXT(60145);
            } else {
                tipStr = Core.StringUtils.TEXT(60146);
            }
            this._disregard = !this._disregard;
            if(this._enemyEmojiCom) {
                this._enemyEmojiCom.visible = !this._disregard;
            }
            Core.TipsUtils.showTipsFromCenter(tipStr);
        }

        private _onSurrender() {
            let battle = BattleMgr.inst.battle;
            if (!battle || (battle instanceof LevelBattle && battle.curBout <= 0)) {
                BattleMgr.inst.exitLevel();
                return;
            }
            Core.TipsUtils.confirm(Core.StringUtils.TEXT(60129), ()=>{
                BattleMgr.inst.surrender();
            }, null, this);
        }
        
        private async _onExit() {
            BattleMgr.inst.exitVideo();
            let battle = BattleMgr.inst.battle;
            if (!battle.isPvp()) {
                let homeView = <Home.NewHomeView>Core.ViewManager.inst.getView(ViewName.newHome);
                await homeView.openLevelView(true);
            }
        }

        public visibleBeginBtn(visible:boolean,surrender:boolean) {
            this._beginBtn.visible = visible;
            //this._surrenderBtn.visible = surrender;
        }

        private _setCasterSkill(battle:Battle) {
            this.getController("castler").selectedPage = "noCastler";
            let castlerSkill = battle.getOwnFighter().casterSkill;
            let castlerSkillCom: UI.CastlerSkill;
            if (castlerSkill && castlerSkill.length > 0) {
                this.getController("castler").selectedPage = "ownCastler";
                castlerSkillCom = this.getChild("ownCastlerSkill") as UI.CastlerSkill;
            } else {
                castlerSkill = battle.getEnemyFighter().casterSkill;
                if (castlerSkill && castlerSkill.length > 0) {
                    this.getController("castler").selectedPage = "enemyCastler";
                    castlerSkillCom = this.getChild("oppCastlerSkill") as UI.CastlerSkill;
                }
            }

            if (castlerSkillCom) {
                castlerSkillCom.setData(castlerSkill);
            }
        }

        private async _onLevelReadyDone() {
            let ok = await BattleMgr.inst.levelBattleReadyDone();
            if (ok) {
                this._beginBtn.visible = false;
                this._surrenderBtn.visible = true;
            }
        }

        public bringGridToFront(grid:GridView) {
            if (this._topGrid == grid) {
                return;
            }
            this.swapChildren(this._topGrid, grid);
            this._topGrid = grid;
        }

        public switchGridAndHand(grid:GridView) {
            this.swapChildren(grid, this._gmWinBtn);
        }

        private onTimer(max:number, curFighter:Fighter) {
            if (!BattleMgr.inst.battle) {
                fairygui.GTimers.inst.remove(this.onTimer, this);
                return;
            }

            let value = Math.min(1, this._timerValue/max);
            this._myTimer.value = value * 100;
            this._myTimer.getChild("head").x = this._myTimer.width * value - 5;
            this._enemyTimer.value = value * 100;
            this._enemyTimer.getChild("head").x = this._enemyTimer.width * value - 5;

            this._timerValue -= 1;

            if (this._timerValue <= max) {
                if (curFighter == BattleMgr.inst.battle.getOwnFighter()) {
                            this._myTimer.visible = true;
                            this._enemyTimer.visible = false;
                } else {
                            this._myTimer.visible = false;
                            this._enemyTimer.visible = true;
                }
            }

            if (value <= 0) {
                this._myTimer.visible = false;
                this._enemyTimer.visible = false;
            }
        }

        public async boutBegin(curFighter:Fighter) {
            await this._myHand.boutBegin(curFighter);
            await this._oppHand.boutBegin(curFighter);
        }

        public beginBoutTimer(curFighter:Fighter, boutTimeout:number) {
            fairygui.GTimers.inst.remove(this.onTimer, this);
            this._myTimer.visible = false;
            this._enemyTimer.visible = false;

            if (boutTimeout <= 0) {
                return;
            }
            let repeat = boutTimeout * 1000 / 50;
	        this._timerValue = repeat;
            fairygui.GTimers.inst.add(50, repeat, this.onTimer, this, 8 * 1000/50, curFighter);
        }

        public selectGrid(x:number, y:number, w:number, h:number): GridView {
			let localPoint = this.rootToLocal(x, y)
			x = localPoint.x;
			y = localPoint.y;

			for (let i=0; i<this._grids.length; i++) {
				let g = this._grids[i];
				if (g.isInGrid(x, y, w, h)) {
					return g;
				}
			}

			return null;
		}

        public onPlayBoutActions() {
            this._myHand.handDraggable(false);
        }

        public async endBattle(battle:Battle, data:any, isReplay:boolean = false) {
            await Core.ViewManager.inst.open(battle.getEndViewName(), data, battle, isReplay);
        }

        public getNode(nodeName:string): fairygui.GObject {
            let nameArgs = nodeName.split(":");
            if (nameArgs[0] == "fightCard") {
                let card = BattleMgr.inst.battle.getCardByIdx(parseInt(nameArgs[1]));
                if (card) {
                    return card.view;
                } else {
                    return null;
                }
            } else if (nodeName == "myEmptyHand") {
                return this._myHand.getGuideClickNode();
            } else {
                return super.getNode(nodeName);
            }
        }

        public stopTimerProgress() {
            fairygui.GTimers.inst.remove(this.onTimer, this);
            this._myTimer.visible = false;
            this._enemyTimer.visible = false;	    
        }

        public async playOffensiveAni(isMyBout:boolean) {
            this._offensiveGroup.visible = true;
            await new Promise<void>(resolve => {
                let self = this;
                let onComplete = function() {
                    resolve();
                    self._offensiveGroup.visible = false;
                }

                if (isMyBout) {
                    if (this._selfOffensiveTrans.playing) {
                        onComplete();
                        return;
                    }
                    this._selfOffensiveTrans.play(onComplete, this);
                    this.getChild("card1").asLoader.url = "cards_cardLightSelf_png";
                    this.getChild("card2").asLoader.url = "cards_cardLightSelf_png";
                    this.getChild("card3").asLoader.url = "cards_cardLightSelf_png";
                    this.getChild("card4").asLoader.url = "cards_cardLightSelf_png";
                    this.getChild("card5").asLoader.url = "cards_cardLightSelf_png";
                } else {
                    if (this._enemyOffensiveTrans.playing) {
                        onComplete();
                        return;
                    }
                    this._enemyOffensiveTrans.play(onComplete, this);
                    this.getChild("card1").asLoader.url = "cards_cardLightEnemy_png";
                    this.getChild("card2").asLoader.url = "cards_cardLightEnemy_png";
                    this.getChild("card3").asLoader.url = "cards_cardLightEnemy_png";
                    this.getChild("card4").asLoader.url = "cards_cardLightEnemy_png";
                    this.getChild("card5").asLoader.url = "cards_cardLightEnemy_png";
                }
            });
        }

        public async playTurnAni(isMyBout:boolean) {
            await new Promise<void>(resolve => {
                if (isMyBout) {
                    this._oppTurnIcon.visible = false;
                    if (this._myturnTrans.playing) {
                        resolve();
                    } else {
                        this._myturnTrans.play(()=>{
                            resolve();
                        }, this);
                    }
                } else {
                    this._myTurnIcon.visible = false;
                    if (this._oppturnTrans.playing) {
                        resolve();
                    } else {
                        this._oppturnTrans.play(()=>{
                            resolve();
                        }, this);
                    }
                }
            });
        }

        public showSelfEmoji(emojiID:number): boolean {
            
            if (!this._selfEmojiCom) {
                this._selfEmojiCom = fairygui.UIPackage.createObject(PkgName.battle, "emojiSelf", SelfEmojiCom) as SelfEmojiCom;
                this._selfEmojiCom.setParent(this._myHandCom);
                this._selfEmojiCom.setXY(240,0);
            }
            return this._selfEmojiCom.show(emojiID);
        }

        public showEnemyEmoji(emojiID:number) {
            if (this._disregard) {
                return;
            }
            if (!this._enemyEmojiCom) {
                this._enemyEmojiCom = fairygui.UIPackage.createObject(PkgName.battle, "emojiEnemy", EmojiCom) as EmojiCom;
                this._enemyEmojiCom.setParent(this._oppHandCom);
                this._enemyEmojiCom.setXY(240,100);
            }
            this._enemyEmojiCom.visible = true;
            this._enemyEmojiCom.show(emojiID);
        }

        public async showGoldGob(gold:number, isLadder:boolean) {
            let goldGobTips = fairygui.UIPackage.createObject(PkgName.battle, "goldGob", GoldGobTips) as GoldGobTips;
            goldGobTips.x = this.width / 2 - goldGobTips.width / 2;
            goldGobTips.y = this._myHandCom.y;
            this.addChild(goldGobTips);
            await goldGobTips.show(gold, isLadder);
            goldGobTips.removeFromParent();
        }

        private _onBeginDragGuide(evt:egret.Event) {
            let targetCard = evt.data as FightCardView;
            this._myHand.handDraggable(false);
            targetCard.draggable = true;
            this._surrenderBtn.touchable = false;
            this._gmWinBtn.touchable = false;
            Guide.GuideMgr.inst.once(Guide.GuideMgr.GUIDE_COMPLETE_EV, ()=>{
                this._surrenderBtn.touchable = true;
                this._gmWinBtn.touchable = true;
            }, this);
        }
    }

}
