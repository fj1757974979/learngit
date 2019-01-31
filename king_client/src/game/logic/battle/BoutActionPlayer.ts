module Battle {

    interface IAction {
        playAction(data:any): Promise<any>
    }

    export class BoutActionPlayer {
        private static _inst: BoutActionPlayer;

        private _playing: Promise<void>;
        private static _actions: Collection.Dictionary<pb.ClientAction.ActionID, IAction>;

        constructor() {
            if (BoutActionPlayer._actions) {
                return;
            }
            BoutActionPlayer._actions = new Collection.Dictionary<pb.ClientAction.ActionID, IAction>();
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.PlayCard, new PlayCardAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.Attack, new AttackAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.TurnOver, new TurnOverAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.Move, new MoveAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.Skill, new SkillAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.TextMovie, new TextMovieAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.Movie, new McMovieAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.ModifyValue, new ModifyValueAction());
            //this._actions.setValue(ActionID.SkillOth, new SkillOthAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.SkillStatusMovie, new SkillStatusMovieAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.Bonus, new BonusAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.BattleEnd, new BattleEndAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.SwitchPos, new SwitchPosAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.HandShow, new HandShowAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.Guanxing, new GuanxingAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.Summon, new SummonAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.Destroy, new DestroyAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.Return, new ReturnAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.AddSkill, new AddSkillAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.DelSkill, new DelSkillAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.Copy, new CopyAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.EnterFog, new EnterFogAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.LeaveFog, new LeaveFogAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.GoldGob, new GoldGobAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.DrawCard, new DrawCardAction());
            BoutActionPlayer._actions.setValue(pb.ClientAction.ActionID.DisCard, new DisCardAction());
        }

        public static get inst(): BoutActionPlayer {
            if (!BoutActionPlayer._inst) {
                BoutActionPlayer._inst = new BoutActionPlayer();
            }
            return BoutActionPlayer._inst;
        }

        public static createInst() {
            BoutActionPlayer._inst = new BoutActionPlayer();
        }

        public getAction(actionId:pb.ClientAction.ActionID): IAction {
            return BoutActionPlayer._actions.getValue(actionId);
        }

        public async waitActionComplete() {
            if (this._playing != null) {
                await this._playing;
            }
        }

        public async playActions(actionDatas:Array<pb.IClientAction>, winUid:Long) {
            if (this._playing != null) {
                await this._playing;
                this._playing = null;
            }

            let battle = BattleMgr.inst.battle;
            if (!battle) {
                console.debug(`playActions no battle`);
                return;
            }

            if (!actionDatas) {
                if (winUid) {
                    try {
                        await BoutActionPlayer._actions.getValue(pb.ClientAction.ActionID.BattleEnd).playAction(null);
                    } catch (e) {
                        console.debug(e);
                    }
                }
                return;
            }

            this._playing = this._playActions(actionDatas, winUid);
            await this._playing;
            this._playing = null;
        }

        private async _playActions(actionDatas:Array<pb.IClientAction>, winUid:Long) {
            let needBattleEndAction = Boolean(winUid);
            let skillStatusMovieBegin = false;
            let playingSkillStatusMovie:Array<Promise<void>>;
            for (let i=0; i<actionDatas.length; i++) {
                let act = actionDatas[i];
                let action = BoutActionPlayer._actions.getValue(act.ID);
                if (action) {
                    try {
                        if (act.ID == pb.ClientAction.ActionID.Bonus && needBattleEndAction) {
                            needBattleEndAction = false;
                            act.Data["winUid"] = winUid;
                        } else if (act.ID != pb.ClientAction.ActionID.SkillStatusMovie) {
                            if (skillStatusMovieBegin) {
                                if (act.ID != pb.ClientAction.ActionID.AddSkill &&
                                    act.ID != pb.ClientAction.ActionID.DelSkill) {
                                    skillStatusMovieBegin = false;
                                    await Promise.all(playingSkillStatusMovie);
                                }
                            }
                        }

                        let p = action.playAction(act.Data);

                        if (act.ID == pb.ClientAction.ActionID.SkillStatusMovie) {
                            if (!skillStatusMovieBegin) {
                                skillStatusMovieBegin = true;
                                playingSkillStatusMovie = [];
                            }
                            playingSkillStatusMovie.push(p);
                        } else {
                            await p;
                        }
                    } catch (e) {
                        console.debug(e);
                    }
                }
            }

            if (needBattleEndAction) {
                try {
                    await BoutActionPlayer._actions.getValue(pb.ClientAction.ActionID.BattleEnd).playAction(winUid);
                } catch (e) {
                    console.debug(e);
                }
            }
        }

        public async playCard(useCardObjId:number, targetGridId:number, needTalk:boolean, isUseCardInFog?:boolean, 
            isUseCardPublicEnemy?:boolean) {

            if (this._playing != null) {
                await this._playing;
                this._playing = null;
            }

            let battle = BattleMgr.inst.battle;
            if (!battle) {
                console.debug(`playCard no battle`);
                return;
            }

            try {
                await BoutActionPlayer._actions.getValue(pb.ClientAction.ActionID.PlayCard).playAction({"useCardObjId":useCardObjId, 
                    "targetGridId":targetGridId, "needTalk":needTalk, "isUseCardInFog":isUseCardInFog, 
                    "isUseCardPublicEnemy":isUseCardPublicEnemy});
            } catch (e) {
                console.debug(e);
            }
        }
    }

    class PlayCardAction implements IAction {
        public async playAction(data:any) {
            let useCardObjId:number = data.useCardObjId;
            let targetGridId:number = data.targetGridId;
            let needTalk: boolean = data.needTalk;
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return;
            }
            let targetCard = battle.getBattleObj(useCardObjId) as FightCard;
            if (!targetCard) {
                return;
            }
            targetCard.isInFog = data.isUseCardInFog;
            targetCard.isPublicEnemy = data.isUseCardPublicEnemy;
            let targetGrid = battle.getGridById(targetGridId);
            await targetCard.playCard(targetGrid, needTalk);
            targetCard.owner.handView.handVisibleLightCircle(false);
            (<Battle.BattleView>Core.ViewManager.inst.getView(ViewName.battle)).stopTimerProgress();
                await fairygui.GTimers.inst.waitTime(350);
        }
    }

    class AttackAction implements IAction {

        private async _blink(attackCard:FightCard, data:any) { 
            if (!data.WinEffect) {
                return;
            }
            await attackCard.view.blink();
            /*
            let battle = BattleMgr.inst.battle;
            let ps = new Array<Promise<void>>();  
            ps.push(p);

            data.WinEffect.forEach(win => {
                let beAttackCard = battle.getBattleObj(win.BeAttacker) as FightCard;
                p = beAttackCard.view.blink();
                ps.push(p);
            })
            await Promise.all(ps);
            */
        }

        private async _attack(attackCard:FightCard, data:pb.AttackAct) {
            if (!data.WinActs) {
                return;
            }

            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return;
            }
            let ps: Array<Promise<void>> = [];
            data.WinActs.forEach(win => {
                let beAttackCard = battle.getBattleObj(win.BeAttacker) as FightCard;
                if (!beAttackCard) {
                    return;
                }
                let moveGrid:GridObj = null;
                let moveEffectId:string = "";
                let movePos = CardNumPos.NONE;
                let moveCard: FightCard;
                if (data.MoveActs != null) {
                    // attack 期间 move
                    let idx = -1;
                    for (let i=0; i<data.MoveActs.length; i++) {
                        let findMoveTarget = false;
                        if (beAttackCard.objId == data.MoveActs[i].Target) {
                            moveCard = beAttackCard;
                            findMoveTarget = true;
                        } else if (attackCard.objId == data.MoveActs[i].Target) {
                            moveCard = attackCard;
                            findMoveTarget = true;
                        }

                        if (findMoveTarget) {
                            idx = i;
                            let gridObjId = data.MoveActs[i].TargetGrid;
                            moveGrid = battle.getBattleObj(gridObjId) as GridObj;
                            moveEffectId = data.MoveActs[i].MovieID;
                            movePos = data.MoveActs[i].MovePos;
                            if (data.MoveActs[i].TargetGrid >= 0) {
                                break;
                            } 
                        }
                    }
                    if (idx >= 0) {
                        data.MoveActs.splice(idx, 1);
                    }
                }

                let isGuide = battle instanceof GuideBattle && (<GuideBattle>battle).canAttactGuide();
                let p = attackCard.attackAndMoveTarget(beAttackCard, win.WinPos, win.LosePos, moveCard, moveGrid, moveEffectId, movePos, 
                    isGuide, data.IsArrow);
                if (p != null) {
                    ps.push(p);
                }
            });

            let p = BoutActionPlayer.inst.getAction(pb.ClientAction.ActionID.Move).playAction(data.MoveActs);
            if (ps.length > 0) {
                await Promise.all(ps);
                await fairygui.GTimers.inst.wait30FpsFrame(5);
            }
            if (p) {
                await p;
            }

            if (data.AfterMoveActs) {
                ps = [];
                let othAction: Array<pb.IClientAction> = [];
                for (let afterMoveData of data.AfterMoveActs) {
                    // 先飘字
                    if (afterMoveData.ID == pb.ClientAction.ActionID.TextMovie) {
                        p = BoutActionPlayer.inst.getAction(pb.ClientAction.ActionID.TextMovie).playAction(afterMoveData.Data);
                        if (p) {
                            ps.push(p);
                        }
                    } else {
                        othAction.push(afterMoveData);
                    }
                }
                if (ps.length > 0) {
                    await Promise.all(ps);
                }

                ps = [];
                othAction.forEach(actData => {
                    p = BoutActionPlayer.inst.getAction(actData.ID).playAction(actData.Data);
                    if (p) {
                        ps.push(p);
                    }
                });
                if (ps.length > 0) {
                    await Promise.all(ps);
                    await fairygui.GTimers.inst.wait30FpsFrame(5);
                }
            }
        }

        public async playAction(payload:any) {
            let data = pb.AttackAct.decode(payload);
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return;
            }
            let attackCard = battle.getBattleObj(data.Attacker) as FightCard;
            if (!attackCard) {
                return;
            }
            //await this._blink(attackCard, data);
            await this._attack(attackCard, data);           
        }

    }

    class MoveAction implements IAction {
        public async playAction(data:any) {
            if (!data) {
                return;
            }

            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return;
            }

            let moveActs = data as Array<pb.MoveAct>;
            let ps: Array<Promise<void>> = [];
            moveActs.forEach(act => {
                let p: Promise<void>;
                let targetCard = battle.getBattleObj(act.Target) as FightCard;
                if (!targetCard) {
                    return;
                }
                let targetGrid = battle.getBattleObj(act.TargetGrid) as GridObj;
                let moveEffectId = act.MovieID as string;
                let movePos = act.MovePos as CardNumPos;
                p = targetCard.moveToGrid(targetGrid, moveEffectId, movePos);
                if (p != null) {
                    ps.push(p);
                }
            })

            if (ps.length > 0) {
                await Promise.all(ps);
            } 
        }
    }

    class TurnOverAction implements IAction {
        public async playAction(payload:any) {
            let data = pb.TurnOverAct.decode(payload);
            if (!data.BeTurners) {
                return;
            }
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return;
            }
            let ps: Array<Promise<void>> = [];
            data.BeTurners.forEach(objId => {
                let card = battle.getBattleObj(objId) as FightCard;
                if (!card) {
                    return;
                }
                let p = card.changeSide();
                ps.push(p);
            });
                
            if (ps.length > 0) {
                await Promise.all(ps);
            }
        }
    }

    class MovieAction {
        public async playMovie(targets:Array<number>, movieID:string|number, ownerObjID:number, playType:number, targetCount:number, 
            value:number) {

            if (!targets) {
                return;
            }
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return;
            }
            let ps: Array<Promise<any>> = [];
            targets.forEach(objId => {
                let target = battle.getBattleObj(objId);
                if (!target) {
                    return;
                }

                let visible:boolean = true;
                if (target instanceof FightCard) {
                    let owner = battle.getBattleObj(ownerObjID);
                    if (owner && owner instanceof FightCard) {
                        let card = owner as FightCard;
                        visible = !card.isShowFogUI();
                    }
                }
                let p = target.playEffect(movieID, playType, visible, targetCount, value);
                if (p != null) {
                    ps.push(p);
                }
            });
            if (ps.length > 0) {
                await Promise.all(ps);
            }
        }
    }

    class McMovieAction extends MovieAction implements IAction {
        public async playAction(payload:any) {
            let data = pb.MovieAct.decode(payload);
            await super.playMovie(data.Targets, data.MovieID, data.OwnerObjID, data.PlayType, 0, 0);
        }
    }

    class TextMovieAction extends MovieAction implements IAction {
        public async playAction(payload:any) {
            let data = pb.TextMovieAct.decode(payload);
            await super.playMovie(data.Targets, data.MovieID, data.OwnerObjID, data.PlayType, data.TargetCount, data.Value);
        }
    }

    class ModifyValueAction implements IAction {
        public async playAction(payload:any) {
            let data = pb.ModifyValueAct.decode(payload);
            if (!data.Targets) {
                return;
            }
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return;
            }
            data.Targets.forEach(objId => {
                let card = battle.getBattleObj(objId) as FightCard;
                if (!card) {
                    return;
                }
                card.modifyValue(data.Value, data.ModifyType);
            });
        }
    }

    class HandShowAction implements IAction {
        public async playAction(payload:any) {
            let data = pb.HandShowAct.decode(payload);
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return;
            }
            let fighter = battle.getFighter(data.Uid as Long);
            fighter.handView.show();
        }
    }

    class SkillAction implements IAction {

        public async playAction(payload:any) {
            let data = pb.SkillAct.decode(payload);
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return;
            }

            let ps = [];
            let ownerCard = battle.getBattleObj(data.Owner) as FightCard;
            if (ownerCard) {
                await ownerCard.triggerSkill(data.SkillID, data.IsEquip);
            }
            
            let p = BoutActionPlayer.inst.getAction(pb.ClientAction.ActionID.Move).playAction(data.MoveActs);
            if (data.Actions == null && data.AfterMoveActs == null) {
                await p;
                return;
            } else {
                ps.push(p);
            }

            if (data.Actions == null) {
                data.Actions = [];
            }
            if (data.AfterMoveActs != null) {
                data.Actions = (<Array<any>>data.Actions).concat(data.AfterMoveActs);
            }

            // 先飘字
            data.Actions.forEach(e => {
                if (e.ID == pb.ClientAction.ActionID.Movie || e.ID == pb.ClientAction.ActionID.TextMovie) {
                    let p = BoutActionPlayer.inst.getAction(e.ID).playAction(e.Data);
                    if (p) {
                        ps.push(p);
                    }
                }
            });

            if (ps.length > 0) {
                await Promise.all(ps);
            }

            for(let e of data.Actions) {
                if (e.ID == pb.ClientAction.ActionID.Movie || e.ID == pb.ClientAction.ActionID.TextMovie) {
                    continue;
                }
                let act = BoutActionPlayer.inst.getAction(e.ID);
                if (act != null) {
                    await act.playAction(e.Data);
                }
            }
        }
    }

    class SkillStatusMovieAction extends MovieAction implements IAction {
        public async playAction(payload:any) {
            let data = pb.MovieAct.decode(payload);
            await super.playMovie(data.Targets, data.MovieID, data.OwnerObjID, data.PlayType, 0, 0);
        }
    }

    class BonusAction implements IAction {

        private async _showBonus(bonusName: string, resChange: Array<any>) {
            let tips = fairygui.UIPackage.createObject(PkgName.battle, "bonus", BonusTips) as BonusTips;
            await tips.show(bonusName, resChange);
        }

        // 红利
        public async playAction(payload:any) {
            let winUid = payload["winUid"];
            let data = pb.BonusAct.decode(payload);
            if (!data) {
                return;
            }
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return;
            }

            let lastPlayEffect = [];
            for (let act of data.Rewards) {
                if (act.Uid != battle.getOwnFighter().uid) {
                    continue;
                }
                let bonusRes = Data.bonus.get(act.BonusID);
                if (!bonusRes) {
                    continue;
                }

                let canPlay = true;
                if (winUid) {
                    for (let i=0; i<bonusRes.function.length; i++) {
                        let cond = bonusRes.function[0];
                        if (cond == "opp==9" || cond == "front==9") {
                            lastPlayEffect.push( {"bonusName":bonusRes.name, "resChange":act.Res} );
                            canPlay = false;
                            break;
                        }
                    }
                } 
                if (canPlay) {
                    await this._showBonus(bonusRes.name, act.Res);
                }
            }

            if (winUid) {
                await BoutActionPlayer.inst.getAction(pb.ClientAction.ActionID.BattleEnd).playAction(winUid);
            }
            for (let data of lastPlayEffect) {
                await this._showBonus(data.bonusName, data.resChange);
            }
        }
    }

    class BattleEndAction implements IAction {

        public async playAction(data:any) {
            let winUid:Long = data;
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return;
            }
            battle.beforeEndBattle(winUid == battle.getOwnFighter().uid);
            let ps: Array<Promise<void>> = [];
            SoundMgr.inst.stopBgMusic();

            let myTotal:number = 0;
            let enemyTotal:number = 0;
            for (let i=0; i<9; i++) {
                let gridObj = battle.getGridById(i);
                if (gridObj && gridObj.inGridCard) {
                    if (gridObj.inGridCard.owner.uid == battle.getOwnFighter().uid) {
                        myTotal ++;
                    } else {
                        enemyTotal ++;
                    }
                }
            }
            let fighters: Array<Fighter>;
            let lastWinCard: FightCardView;
            let lastLoseCard: FightCardView

            if (battle.battleType == BattleType.Guide) {
                fighters = [battle.getOwnFighter(), battle.getEnemyFighter()];
            } else {
                fighters = [battle.getOwnFighter()];
            }

            for(let f of fighters) {
                let isWin = winUid == f.uid;
                let isOwn = f == battle.getOwnFighter();
                let count:number = 0;
                let total: number = isOwn ? myTotal : enemyTotal; 

                for (let i=0; i<9; i++) {
                    let gridObj = battle.getGridById(i);
                    if (gridObj && gridObj.inGridCard && gridObj.inGridCard.owner.uid == f.uid) {
                        count ++;
                        if (isOwn && count == 1) {
                            await fairygui.GTimers.inst.waitTime(450);
                        } else {
                            if (battle.battleType == BattleType.Guide) {
                                await fairygui.GTimers.inst.waitTime(208);
                            } else {
                                await fairygui.GTimers.inst.waitTime(150);
                            }
                        }

                        if (battle.battleType == BattleType.Guide) {
                            gridObj.inGridCard.view.showNewbieCountNum(count, isOwn);
                        }

                        let p = gridObj.inGridCard.view.blink(Core.TextColors.white)
                        ps.push(p);

                        if (battle.battleType == BattleType.Guide) {
                            if (count != total) {
                                fairygui.GTimers.inst.add(207, 1, ()=>{
                                    gridObj.inGridCard.view.hideNewbieCountNum();
                                }, this);
                            } else {
                                if (isWin) {
                                    lastWinCard = gridObj.inGridCard.view;
                                } else {
                                    lastLoseCard = gridObj.inGridCard.view;
                                }
                            }
                        }

                        ps.push( new Promise<void>(resolve => {
                            if (isWin) {
                                SoundMgr.inst.playSoundAsync("count"+ count +"_mp3");
                            } else {
                                SoundMgr.inst.playSoundAsync("count"+ (total - count + 1) +"_mp3");
                            }
                            resolve();
                        }));
                    }
                }

                if (ps.length > 0) {
                    await Promise.all(ps);
                }

                if (battle.battleType == BattleType.Guide) {
                    await fairygui.GTimers.inst.waitTime(120);
                } else {
                    await fairygui.GTimers.inst.waitTime(100);
                }
            }

            if (lastWinCard || lastLoseCard) {
                if (lastWinCard) {
                    let winAni = fairygui.UIPackage.createObject(PkgName.battle, "numResultAni");
                    lastWinCard.addChild(winAni);
                }
                if (lastLoseCard) {
                    let loseAni = fairygui.UIPackage.createObject(PkgName.battle, "numResultAni").asCom;
                    loseAni.getChild("result").asLoader.url = "battle_numLose_png";
                    lastLoseCard.addChild(loseAni);
                }
                await fairygui.GTimers.inst.waitTime(120);
            }

            await fairygui.GTimers.inst.waitTime(80);
        }
    }

    class SwitchPosAction implements IAction {
        public async playAction(payload:any) {
            let data = pb.SwitchPosAct.decode(payload);
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return;
            }
            let target = battle.getBattleObj(data.Target);
            let switchTarget = battle.getBattleObj(data.SwitchTarget);
            if (!target || !switchTarget) {
                return;
            }

            await (<FightCard>target).switchPos(switchTarget as FightCard);            
        }
    }

    class GuanxingAction implements IAction {
        // 观星   
        public async playAction(payload:any) {
            let data = pb.GuanxingAct.decode(payload);
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return
            }

            let canShow = false;
            for(let uid of data.Uids) {
                if (battle.getOwnFighter().uid == uid) {
                    canShow = true;
                    break;
                }
            }
            if (!canShow) {
                return;
            }

            battle.fighter1.handShow(data.SitOneDrawCards);
            battle.fighter2.handShow(data.SitTwoDrawCards);
        }
    }

    class SummonAction implements IAction {
        // 召唤小兵
        public async playAction(payload:any) {
            let data = pb.SummonAct.decode(payload);
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return
            }

            let fighter = battle.getFighter(data.Uid as Long);
            let card = new FightCard(data.Card, fighter);
            card.isInFog = data.IsInFog;
            card.isPublicEnemy = data.IsPublicEnemy;
            battle.addBattleObj(card);
            let gridObj = battle.getBattleObj(data.GridObjID) as GridObj;
            card._moveToGrid(gridObj);
            let [_, p] = gridObj.view.addCard(card, 2);
            if (p) {
                await p;
            }
        }
    }

    class DestroyAction implements IAction {
        public async playAction(payload:any) {
            let data = pb.DestroyAct.decode(payload);
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return
            }

            data.Targets.forEach(objID => {
                let card = battle.getBattleObj(objID) as FightCard;
                if (!card) {
                    return;
                }
                if (card.gridObj) {
                    card.gridObj.view.clear();
                    card.gridObj.inGridCard = null;
                } else {
                    // 手牌
                    card.owner.disHandCard([objID]);
                }
                card.view.clearEffect();
                battle.delBattleObj(objID);
            });
        }
    }

    class ReturnAction implements IAction {
        public async playAction(payload:any) {
            let data = pb.ReturnAct.decode(payload);
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return
            }

            let card = battle.getBattleObj(data.CardObjID) as FightCard;
            if (!card || !card.gridObj) {
                return;
            }

            let fighter = battle.getFighter(data.Uid as Long);
            card.view.clearEffect();
            let index = fighter.returnHandCard(data.Card);
            await card.view.moveToHand(fighter.handView, index);
            card.gridObj.view.clear();
            card.gridObj.inGridCard = null;
            fighter.handView.refresh();
            battle.delBattleObj(data.CardObjID);
        }
    }

    class ModifySkillAction implements IAction {
        public async playAction(payload:any) {
            let data = pb.ModifySkillAct.decode(payload);
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return
            }

            let card = battle.getBattleObj(data.CardObjID) as FightCard;
            if (!card) {
                return;
            }

            this.modifySkill(card, data.SkillID, data.IsEquip);

            if (card.gridObj) {
                card.view.refleshSkill();
            } else {
                // 手牌
                if (card.initOwner.handView.isShow) {
                    card.view.refleshSkill();
                }
            }
        }

        public modifySkill(card:FightCard, skillID:number, isEquip:boolean) {
        } 
    }

    class AddSkillAction extends ModifySkillAction {
        public modifySkill(card:FightCard, skillID:number, _:boolean) {
            card.addSkill(skillID);
        }
    }

    class DelSkillAction extends ModifySkillAction {
        public modifySkill(card:FightCard, skillID:number, isEquip:boolean) {
            card.delSkill(skillID, isEquip);
        }
    }

    class CopyAction implements IAction {
        public async playAction(payload:any) {
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return
            }

            let data = pb.CopyAct.decode(payload);
            let card = battle.getBattleObj(data.Target) as FightCard;
            if (!card) {
                return;
            }
            await card.toBeCopy(data.CopyCard as pb.Card, data.OwnerUid as Long);
        }
    }

    class EnterFogAction implements IAction {
        public async playAction(payload:any) {
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return
            }

            let data = pb.EnterFogAct.decode(payload);
            let card = battle.getBattleObj(data.Target) as FightCard;
            if (!card) {
                return;
            }
            card.enterFog(data.IsPublicEnemy);
        }
    }

    class LeaveFogAction implements IAction {
        public async playAction(payload:any) {
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return
            }

            let data = pb.LeaveFogAct.decode(payload);
            let ps: Array<Promise<void>> = [];
            data.Targets.forEach(objID => {
                let card = battle.getBattleObj(objID) as FightCard;
                if (!card) {
                    return;
                }
                ps.push(card.leaveFog());
            });
            await Promise.all(ps);
        }
    }

    class GoldGobAction implements IAction {
        public async playAction(payload:any) {
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return
            }

            let data = pb.GoldGobAct.decode(payload);
            if (data.Gold == 0) {
                return;
            }
            if (battle.getOwnFighter().uid != data.Uid) {
                return;
            }

            let battleView = (<Battle.BattleView>Core.ViewManager.inst.getView(ViewName.battle))
            await battleView.showGoldGob(data.Gold, data.IsLadder);
        }
    }

    class DrawCardAction implements IAction {
        public async playAction(payload:any) {
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return
            }

            let data = pb.DrawCardAct.decode(payload);
            let fighter = battle.getFighter(data.Uid as Long);
            fighter.kingAddHandCard(data.Cards);
            let drawCards = [];
            let ps = [];
            for (let cardData of data.Cards) {
                let cardObj = battle.getBattleObj(cardData.ObjId) as FightCard;
                drawCards.push(cardObj);
                if (!cardObj.isShadow) {
                    // 没被观星，隐藏
                    cardObj.view.visible = false;
                }
                let visible:boolean = true;
                let owner = battle.getBattleObj(data.OwnerObjID);
                if (owner && owner instanceof FightCard) {
                    let card = owner as FightCard;
                    visible = !card.isShowFogUI();
                }

                let p = cardObj.playEffect(data.MovieID, 1, visible);
                if (p) {
                    ps.push(p);
                }
            }

            if (ps.length > 0) {
                await Promise.all(ps);
            }

            // 显示新补的卡
            drawCards.forEach(cardObj => {
                cardObj.view.visible = true;
                cardObj.view.alpha = 1;
                cardObj.isShadow = false;
            });
        }
    }

    class DisCardAction implements IAction {
        public async playAction(payload:any) {
            let battle = BattleMgr.inst.battle;
            if (!battle) {
                return
            }
            let data = pb.DisCardAct.decode(payload);
            let fighter = battle.getFighter(data.Uid as Long);
            fighter.disHandCard(data.CardObjIDs);
        }
    }     

}
