module Battle {

    export class FightCardView extends UI.CardCom {
        private _battleView: BattleView;
        private _selectGrid: GridView;
        private _hand: Hand;
        private _newbieCountNum: fairygui.GImage;

        private _effectPlayer: EffectPlayer;
        private _nums: Collection.Dictionary<CardNumPos, FightCardNum>;
        private _upMoveing: boolean = false;
        private _downMoveing: boolean = false;
        private _leftMoveing: boolean = false;
        private _rightMoveing: boolean = false;
        private _isDetailOpen: boolean = false;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._battleView = Core.ViewManager.inst.getView(ViewName.battle) as BattleView;
            this._effectPlayer = new EffectPlayer(this);
            this._nums = new Collection.Dictionary<CardNumPos, FightCardNum>();
            this._nums.setValue(CardNumPos.UP, new FightCardNum(this._upNum, CardNumPos.UP));
            this._nums.setValue(CardNumPos.DOWN, new FightCardNum(this._downNum, CardNumPos.DOWN));
            this._nums.setValue(CardNumPos.LEFT, new FightCardNum(this._leftNum, CardNumPos.LEFT));
            this._nums.setValue(CardNumPos.RIGHT, new FightCardNum(this._rightNum, CardNumPos.RIGHT));
            this.addEventListener(fairygui.DragEvent.DRAG_START, this._onDragStart, this);
            this.addEventListener(fairygui.DragEvent.DRAG_MOVING, this._onDragMove, this);
            this.addEventListener(fairygui.DragEvent.DRAG_END, this._onDragEnd, this);
            this.addClickListener(this._onClick, this);
        }

        public playEffect(effectId:string | number, playType:number, visible:boolean=true, targetCount?:number, value?:number): Promise<void> {
            /*
            if (typeof effectId === "string" && effectId.indexOf("blank", 0) >= 0) {
                // 白板特效
                let isAllLockSkill = false;
                for(let skillID of this.cardObj.skillIds) {
                    let skillData = Data.skill.get(skillID);
                    if (skillData.desTra.length > 0) {
                        // 有卡面上的技能
                        isAllLockSkill = true;
                    }
                    let isLock = false;
                    for (let typeInfo of  <Array<Array<number>>>skillData.type) {
                        if (typeInfo[0] == 4) {
                            isLock = true;
                            break;
                        }
                    }

                    if (!isLock) {
                        isAllLockSkill = false;
                        break;
                    }
                }

                if (isAllLockSkill) {
                    // 卡面上的技能全都是锁定技
                    return;
                }
            }
            */
            return this._effectPlayer.playEffect(effectId, playType, visible, targetCount, value);
        }

        public clearEffect() {
            return this._effectPlayer.clearEffect();
        }

        public set hand(h:Hand) {
            this._hand = h;
        }
        public get hand(): Hand {
            return this._hand;
        }

        public set effectPlayer(player: EffectPlayer) {
            this._effectPlayer = player;
        }
        public get effectPlayer():EffectPlayer {
            return this._effectPlayer;
        }

        public set selectGrid(grid:GridView) {
            this._selectGrid = grid;
        }
        public get selectGrid():GridView {
            return this._selectGrid;
        }

        public set isDetailOpen(val:boolean) {
            this._isDetailOpen = val;
        }

        public toBeCopy(cardObj:FightCard) {
            this.cardObj = cardObj;
            this._effectPlayer.clearEffect();
            cardObj.view = this;
        }

        public setNumText() {
            if (!this._hand || this._hand.isShow) {
                let card = <FightCard>this.cardObj;
                if (card.isShowFogUI()) {
                    super.setNumText(false);
                } else {
                    super.setNumText();
                }
            }
        }

        public cacheAsBitmap(flag:boolean) {
            this.displayObject.cacheAsBitmap = flag;
        }

        public refleshSkill() {
            let card = <FightCard>this.cardObj;
            if (card.isShowFogUI()) {
                this.hideSkill();
                return;
            }
            let cardObj = <FightCard>this.cardObj;
            let skillNames = ["", "", "", ""];
            let index = 0;
            for (let skill of cardObj.getEffectiveSkill()) {
                skillNames[index] = skill.name;
                index++;
                if (index >= skillNames.length) {
                    break;
                }
            }
            this.setSkillByName(skillNames[0], skillNames[1], skillNames[2], skillNames[3]);
        }

        public async leaveFog() {
            let p = RES.getResAsync("effect_sanwu_mc_json");
            await RES.getResAsync("effect_sanwu_tex_png");
            await p;
            this.setFrontSkin();
            let leaveFogEffect = Core.MCFactory.inst.getMovieClip("sanwu", "sanwu");
            if (leaveFogEffect) {
                this.addChild(leaveFogEffect);
                leaveFogEffect.x = this.width / 2;
                leaveFogEffect.y = this.height / 2;
                
                let p = new Promise<void>(resolve => {
                    leaveFogEffect.once(egret.MovieClipEvent.COMPLETE, ()=> {
                        leaveFogEffect.removeFromParent();
                        leaveFogEffect.scaleX = 1;
                        leaveFogEffect.scaleY = 1;
                        Core.MCFactory.inst.revertMovieClip(leaveFogEffect);
                        resolve();
                    }, this);
                })

                leaveFogEffect.gotoAndPlay(1, 1);
                await p;
            }
        }

        public async setFrontSkin() {
            let cardObj = <FightCard>this.cardObj;
            if (cardObj.side == Side.OWN) {
                this.setOwnFront();
                this.setOwnBackground();
            } else {
                this.setOppFront();
                this.setOppBackground();
            }
            this.setEquip();
            this.setCardImg();
            this.setName();
            this.setNumText();
            //this.setSkill();
            this.refleshSkill();
            this.touchable = true;

            let fogEffect = this.getChild("fogEffect") as Core.EMovieClip;
            if (cardObj.isInFog) {
                if (!fogEffect) {
                    let self = this;
                    RES.getResAsync("effect_dawu_mc_json").then(()=>{
                        RES.getResAsync("effect_dawu_tex_png").then(()=>{
                            if (!cardObj.isInFog) {
                                return;
                            }
                            fogEffect = Core.MCFactory.inst.getMovieClip("dawu", "dawu");
                            if (fogEffect) {
                                fogEffect.name = "fogEffect";
                                self.addChild(fogEffect);
                                fogEffect.x = self.width / 2;
                                fogEffect.y = self.height / 2;
                                fogEffect.gotoAndPlay(1, -1);
                            }
                        });
                    });
                }
            } else if (fogEffect) {
                this.removeChild(fogEffect);
                Core.MCFactory.inst.revertMovieClip(fogEffect);
            }

            if (cardObj.initEffects) {
                let initEffects = cardObj.initEffects;
                cardObj.clearInitEffects();
                egret.callLater(()=>{
                    if (!BattleMgr.inst.battle) {
                        return;
                    }
                    initEffects.forEach(effect => {
                        let visible = true;
                        let owner = BattleMgr.inst.battle.getBattleObj(effect.OwnerObjID);
                        if (owner && owner instanceof FightCard) {
                            let card = owner as FightCard;
                            visible = !cardObj.isShowFogUI();
                        }
                        let textEffectID = parseInt(effect.MovieID);
                        if (isNaN(textEffectID)) {
                            // mc effect
                            this.playEffect(effect.MovieID, effect.PlayType, visible);
                        } else {
                            // text effect
                            this.playEffect(textEffectID, effect.PlayType, visible);
                        }
                    });
                }, this);
            }
        }

        public setName() {
            let card = <FightCard>this.cardObj;
            if (card.isShowFogUI()) {
                super.hideName();
            } else {
                super.setName();
            }
        }

        private _onClick() {
            if (this.packageItem.name == "smallCard" && this._isDetailOpen) {
                this._isDetailOpen = false;
                return;
            }
            this._isDetailOpen = true;
            Core.ViewManager.inst.open(ViewName.cardDetail, this.cardObj);
        }

        private _onDragStart() {
            if (this._hand) {
                this._hand.handTouchable(false);
                this._hand.bringCardToFront(this);
            }
        }

        private _onDragMove() {
            if (!BattleMgr.inst.battle.isMyBout()) {
                let s = Math.sqrt( Math.pow(this.x - this.inHandPoint.x, 2) + Math.pow(this.y - this.inHandPoint.y, 2) );
                if (s > 110) {
                    Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60162));
                    this.stopDrag();
                    if (this._selectGrid) {
                        this._selectGrid.selected = false;
                        this._selectGrid = null;
                    }
                    this._onDragEnd();
                    return;
                }
            }

            let gPoint = this.parent.localToRoot(this.x, this.y, null, false);
            let selectGrid = this._battleView.selectGrid(gPoint.x, gPoint.y, this.width, this.height); 

            if (selectGrid == null || selectGrid.inGridCard) {
                if (this._selectGrid != null) {
                    this._selectGrid.selected = false;
                    this._selectGrid = null;
                }
            } else if (this._selectGrid != null && this._selectGrid.gridId != selectGrid.gridId) {
                this._selectGrid.selected = false;
                selectGrid.selected = true;
                this._selectGrid = selectGrid;
            } else {
                selectGrid.selected = true;
                this._selectGrid = selectGrid;
            }
        }

        private async _onDragEnd() {
            if (this._selectGrid != null && BattleMgr.inst.battle) {
                let ok = await BattleMgr.inst.battle.playCard((<FightCard>this.cardObj).objId, this._selectGrid.gridId);
                if (ok) {
                    this._hand.handTouchable(true);
                    return;
                } else {
                    this._selectGrid.selected = false;
                    this._selectGrid = null;
                }
            }

            this._hand.handTouchable(true);
            let tox = this.inHandPoint.x;
            let toy = this.inHandPoint.y;
            let v = 2.4;
            let distance = Math.sqrt( Math.pow(tox - this.x, 2) + Math.pow(toy - this.y, 2) )
            egret.Tween.get( this ).to( {x:tox, y:toy}, distance / v);
        }

        private async _addToGrid(grid:GridView, needTalk:boolean) {
        //SoundMgr.inst.playSoundAsync("playcard_mp3");
            let cardObj = this.cardObj;
            let [middleCard, p] = grid.addCard(<FightCard>this.cardObj);
            this._effectPlayer.switchParent(middleCard);
            middleCard.effectPlayer = this._effectPlayer;
            this._effectPlayer = null;
            this.cardObj = null;
            this._selectGrid = null;
            this._hand.refresh();
            if (p) {
                await p;
            }

            let fightCardObj = cardObj as FightCard;
            fairygui.GTimers.inst.callDelay(160, function(sound) {
                SoundMgr.inst.playSoundAsync("playcard_mp3");
                //let sound = this.cardObj.sound;
                if (needTalk && sound && !VideoPlayer.inst.isPlaying && 
                    !fightCardObj.isShowFogUI()) {
                        
                    SoundMgr.inst.playSoundAsync(`${sound}_mp3`);
                } 
            }, this, cardObj.sound);
            middleCard.displayObject.cacheAsBitmap = true;
        }

        public async moveAndAddToGrid(grid:GridView, needTalk:boolean) {
            if (grid.inGridCard) {
                return;
            }

            this.stopDrag();
            this._hand.handTouchable(true);
            if (this._selectGrid) {
                if (this._selectGrid != grid) {
                    this._selectGrid.selected = false;
                    this._selectGrid = grid;
                    grid.selected = true;
                }
                this._addToGrid(grid, needTalk);
                return;
            }

            // grid中心
            //let toGx = grid.x + grid.width / 2 - this.width / 2;
            //let toGy = grid.y + grid.height / 2 - this.height / 2;
            let gPoint = grid.localToGlobal(grid.width / 2 - this.width / 2, grid.height / 2 - this.height / 2)
            let moveLpoint = this.parent.globalToLocal(gPoint.x, gPoint.y);
            await new Promise<void>(resolve => {
                egret.Tween.get( this ).to( {x:moveLpoint.x, y:moveLpoint.y}, 200).call(()=>{
                    this._addToGrid(grid, needTalk);
                    resolve();
                }, null);
            })
        }

        public async moveToHand(handView:Hand, index:number) {
            let battleView = Core.ViewManager.inst.getView(ViewName.battle) as BattleView;
            let cardGrid = this.parent as GridView;
            //battleView.bringGridToFront(cardGrid);
            let grid = handView.getGridByIndex(index);
            let scale = grid.width / this.width;
            //let gPoint = grid.localToGlobal(grid.width / 2 - this.width / 2, grid.height / 2 - this.height / 2)
            let gPoint = grid.localToGlobal(grid.width / 2, grid.height / 2);
            let moveLpoint = this.parent.globalToLocal(gPoint.x, gPoint.y);
            battleView.switchGridAndHand(cardGrid);
            await new Promise<void>(resolve => {
                egret.Tween.get( this ).to( {x:moveLpoint.x, y:moveLpoint.y, scaleX:scale, scaleY:scale}, 200).call(()=>{
                    battleView.switchGridAndHand(cardGrid);
                    resolve();
                }, null);
            })
        }

        public async blink(color:number=Core.TextColors.red) {
            let mask = new fairygui.GGraph();
            mask.width = this.width;
            mask.height = this.height;
            mask.drawRect(0, color, 0, color, 0.8, [7]);
            this.addChild(mask);

            await new Promise<void>(resolve => {
                egret.Tween.get(mask).to({alpha:0.4}, 110).wait(35).call(()=>{
                    this.removeChild(mask);
                }, null).wait(263).call(()=>{
                    resolve();
                }, this);
            })

            //await fairygui.GTimers.inst.wait30FpsFrame(8);
        }

        public showNewbieCountNum(num:number, isOwnCard:boolean) {
            if (!this._newbieCountNum) {
                this._newbieCountNum = new fairygui.GImage();
            }
            let numUrl = `battle_r${num}_png`;
            if (isOwnCard) {
                numUrl = `battle_b${num}_png`;
            }

            this.addChild(this._newbieCountNum);
            RES.getResAsync(numUrl).then(data => {
                if (this._newbieCountNum.parent) {
                    this._newbieCountNum.texture = data;
                    this._newbieCountNum.width = this.initWidth;
                    this._newbieCountNum.height = this.initHeight;
                    this._newbieCountNum.setPivot(0.5, 0.5, true);
                    this._newbieCountNum.setScale(0.8, 0.8);
                    this._newbieCountNum.x = this.width / 2;
                    this._newbieCountNum.y = this.height / 2;
                }
            });
        }

        public hideNewbieCountNum() {
            if (this._newbieCountNum) {
                this._newbieCountNum.removeFromParent();
                this._newbieCountNum = null;
            }
        }

        private async _playEffectOnTarget(target:fairygui.GObject, effectID:string) {
            let p = RES.getResAsync(`effect_${effectID}_mc_json`);
            await RES.getResAsync(`effect_${effectID}_tex_png`);
            await p;

            let effect: Core.EMovieClip = Core.MCFactory.inst.getMovieClip(effectID, effectID);
            if (!effect) {
                console.error("can't play effect ", effectID);
                return;
            }
            effect.x = target.x + target.width / 2 - effect.width / 2;
            effect.y = target.y + target.height / 2 - effect.height / 2;
            this.addChild(effect);
            await new Promise<void>(resolve => {
                effect.once(egret.MovieClipEvent.COMPLETE, ()=>{
                    Core.MCFactory.inst.revertMovieClip(effect);
                    effect = null;
                    resolve();
                }, this);

                effect.gotoAndPlay(1, 1);
            })
        }

        public async equipBlink() {
            await this._playEffectOnTarget(this._equipBtn, "eqshanbai");
        }

        public async skillBlink(skillName:string) {
            let skillTextCom: fairygui.GTextField;
            let skillTextComs = [this._skill1Text, this._skill2Text, this._skill3Text, this._skill4Text];
            for (let com of skillTextComs) {
                if (com.text == skillName) {
                    skillTextCom = com;
                    break;
                }
            }

            if (!skillTextCom) {
                return;
            }

            await this._playEffectOnTarget(skillTextCom, "jinengshanbai");
        }

        public async beAttackNumBlink(losePos:CardNumPos, isGuide:boolean) {
            let num = this._nums.getValue(losePos);
            if (!num || num.isMoving) {
                return;
            }
            await num.blink(isGuide, false);
        }

        public async beAttackNumStopBlink(losePos:CardNumPos) {
            let num = this._nums.getValue(losePos);
            if (!num || num.isMoving) {
                return;
            }
            num.stopBlink();
        }

        public async attackAndMoveTarget(loseCard:FightCardView, winPos:CardNumPos, losePos:CardNumPos, 
            moveCardView?:FightCardView, moveGrid?:GridView, moveEffectId?:string, movePos?:CardNumPos, 
            isGuide?:boolean, isArrow?:boolean) {

            let winNum = this._nums.getValue(winPos);
            let p1:Promise<void>;
            if (!winNum.isMoving) {
                p1 = winNum.blink(isGuide, true);
            }
            await loseCard.beAttackNumBlink(losePos, isGuide);
            if (p1) {
                await p1;
            }

            if (isGuide) {
                await Guide.GuideMgr.inst.showGuideText(loseCard, Core.StringUtils.TEXT(60236));
                winNum.stopBlink();
                loseCard.beAttackNumStopBlink(losePos);
            }

            let weapon = this.cardObj.weapon;
            if (isArrow && weapon != "arrow") {
                // 箭矢攻击，如果是相隔敌军，用剪的攻击动画
                let loseCardGrid = (<FightCard>loseCard.cardObj).gridObj;
                let myCardGrid = (<FightCard>this.cardObj).gridObj;
                if (loseCardGrid && myCardGrid) {
                    if (Math.floor(loseCardGrid.id / 3) == Math.floor(myCardGrid.id / 3)) {
                        // 同一行
                        if (Math.abs(loseCardGrid.id - myCardGrid.id) > 1) {
                            weapon = "arrow";
                        }
                    } else if (loseCardGrid.id % 3 == myCardGrid.id % 3) {
                        // 同一列
                        if (Math.abs(loseCardGrid.id - myCardGrid.id) > 3) {
                            weapon = "arrow";
                        }
                    }
                }
            }

            if (weapon != "") {
                let p = RES.getResAsync(`effect_${weapon}_mc_json`);
                try {
                    await RES.getResAsync(`effect_${weapon}_tex_png`);
                    await p;
                } catch(e) {
                    console.error("load weapon ", e)
                }
            }

            let self = this;
            let battleView = Core.ViewManager.inst.getView(ViewName.battle) as BattleView;
            battleView.bringGridToFront(this.parent as GridView);
            await winNum.attack(async function(){
                let p = loseCard.beAttackAndMove(winPos, losePos, weapon, (<FightCard>self.cardObj).weaponRedFrame, (<FightCard>self.cardObj).weaponSound);
                if (moveCardView && movePos != CardNumPos.NONE) {
                    await moveCardView.moveToGrid(moveGrid, moveEffectId, movePos);
                }
                await p;
                self = null;
            }, this);
        }

        public beAttackAndMove(winPos:CardNumPos, losePos:CardNumPos, weaponEff:string, weaponRedFrame:number, sound:string): Promise<any> {

            let ps: Promise<void>[] = [];
            let loseNum = this._nums.getValue(losePos);
            ps.push(loseNum.beAttack(winPos));

            if (winPos != CardNumPos.NONE) {
                let mc1: Core.EMovieClip = Core.MCFactory.inst.getMovieClip(weaponEff, weaponEff);
                if (mc1 != null) {
                    mc1.addFrameEvent(weaponRedFrame, "blinkRed");
                    let gPoint = this.localToRoot(0, 0, null, false);
                    mc1.x = gPoint.x;
                    mc1.y = gPoint.y;
                    if (winPos == CardNumPos.DOWN) {
                        mc1.rotation = 180;
                    } else if (winPos == CardNumPos.LEFT) {
                        mc1.rotation = -90;
                    } else if (winPos == CardNumPos.RIGHT) {
                        mc1.rotation = 90;
                    }
                    fairygui.GRoot.inst.addChild(mc1);
                    
                    ps.push( new Promise<void>(resolve => {
                        mc1.once(egret.MovieClipEvent.COMPLETE, ()=>{
                            if (mc1) {
                                mc1.rotation = 0;
                                Core.MCFactory.inst.revertMovieClip(mc1);
                                mc1 = null;
                            }
                            resolve();
                        }, this);
                    }) );

                    ps.push( new Promise<void>(resolve=>{
                        mc1.once(egret.MovieClipEvent.FRAME_LABEL, ()=>{
                            egret.Tween.get(this).to({rotation:5}, 25).to({rotation:-5}, 50).to({rotation:0}, 25);
                            this.blink(Core.TextColors.red).then(()=>{
                                resolve();
                            });
                        }, this);
                    }) );

                    mc1.gotoAndPlay(1, 1);

		            SoundMgr.inst.playSoundAsync((<FightCard>this.cardObj).weaponSound);
                }
            }

            return Promise.all(ps);
        }

        public moveToGrid(targetGrid: GridView, effectId:string, pos:CardNumPos) :Promise<any> {
            let ps: Promise<void>[] = [];
            if (targetGrid != null) {
                ps.push(targetGrid.cardMoveIn(this));
            }

            let mc1: Core.EMovieClip = Core.MCFactory.inst.getMovieClip(effectId, effectId);
            if (mc1 != null) {
                let gPoint = this.localToRoot(0, 0, null, false);
                mc1.x = gPoint.x;
                mc1.y = gPoint.y;
                if (pos == CardNumPos.DOWN) {
                    mc1.rotation = 180;
                } else if (pos == CardNumPos.LEFT) {
                    mc1.rotation = -90;
                } else if (pos == CardNumPos.RIGHT) {
                    mc1.rotation = 90;
                }
                fairygui.GRoot.inst.addChild(mc1);
                
                let p2 = new Promise<void>(resolve => {
                    mc1.once(egret.MovieClipEvent.COMPLETE, ()=>{
                        if (mc1) {
                            mc1.rotation = 0;
                            Core.MCFactory.inst.revertMovieClip(mc1);
                            mc1 = null;
                        }
                        resolve();
                    }, this);
                    mc1.gotoAndPlay(1, 1);
                });
                ps.push(p2);

		        SoundMgr.inst.playSoundAsync(`${effectId}_mp3`);
            }

            return Promise.all(ps);
        }

        public changeSide(): Promise<void> {
            fairygui.GTimers.inst.callDelay(100, function() {
	            SoundMgr.inst.playSoundAsync("turn_mp3");
            }, null);
            return new Promise<void>(resolve => {
                let cardObj = this.cardObj as FightCard;
                if (!cardObj.gridObj) {
                    // 手牌
                    this.setPivot(0.5, 0.5);
                }

                egret.Tween.get(this).to({skewY:-112}, 132).call(()=>{
                    let hitTrans = this.getTransition("hit");
                    if (hitTrans) {
                        hitTrans.play();
                    }

                    if (cardObj.gridObj) {
                        this.displayObject.cacheAsBitmap = false;
                    }

                    if (!cardObj.gridObj) {
                        // 手牌
                        let battle = BattleMgr.inst.battle;
                        if (!battle) {
                            resolve();
                            return;
                        }
                        battle.getFighter(cardObj.initOwner.uid).handView.updateCardSkin(this);
                        //cardObj.owner.handView.updateCardSkin(this);
                    } else {
                        if (cardObj.side == Side.OWN) {
                            this.setOwnFront();
                            this.setOwnBackground();
                        } else {
                            this.setOppFront();
                            this.setOppBackground();
                        }
                    }
                    
                    fairygui.GTimers.inst.callDelay(500, function() {
                        if (cardObj.gridObj) {
                            if (this.parent) {
                                this.displayObject.cacheAsBitmap = true;
                            }
                        }
                    }, this, null);
                }, this).to({skewY:-166}, 66).wait(28).call(()=>{
                    this.skewY = 0;
                    if (!cardObj.gridObj) {
                        // 手牌
                        this.setPivot(0, 0);
                    }
                    resolve();
                }, this);
            });
        }

        public watch() {

        }

        public unwatch() {

        }
    }

}
