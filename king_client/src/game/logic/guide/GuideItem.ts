module Guide {

    export interface IGuide {
        isBattleType:boolean
        getGuideId(): number
        getGroupId(): number
        begin(guideView:GuideView): boolean
        addOnFinishListener(func:Function, thisArg:any)
        canPlayCard(card:Battle.FightCard, gridId:number): boolean
        onPlayCard(card:Battle.FightCard, gridId:number)
        canTrigger():boolean
        getNext(): IGuide
        setNext(guide: IGuide)
        getViewName():string;
        onBegin()
        onFinish()
    }

    interface ICondition {
        check(): boolean
    }

    class ConditionType {
        public static PASS_LEVEL = "1";
        public static PASS_CAMPAIGN = "2";
        public static ViewShow = "3";
        public static CardUnhealthy = "4";
        public static GuideBattlePro = "GuideBattlePro";
        public static GuideCamp = "guideCamp";
        public static GuideFinish = "GuideFinish";
    }

    class PassLevelCondition implements ICondition {
        private _levelId: number

        constructor(data:Array<string>) {
            this._levelId = parseInt(data[1]);
        }

        public check(): boolean {
            let levelObj = Level.LevelMgr.inst.getLevel(this._levelId);
            if (levelObj && levelObj.state == Level.LevelState.Clear) {
                return true;
            } else {
                return false;
            }
        }
    }

    class PassCampaignCondition implements ICondition {
        private _type: number;
        private _level: number

        constructor(data:Array<string>) {
            this._type = parseInt(data[1]);
            this._level = parseInt(data[2]);
        }

        public check(): boolean {
            //if ( Campign.CampignMgr.inst.isPassLevel(this._type, this._level) ) {
            //    return true;
            //} else {
                return false;
            //}
        }
    }

    class CardUnhealthyCondition implements ICondition {
        public check(): boolean {
            return false;
            /*
            if (Player.inst.getResource(ResType.T_BAN) <= 0) {
                return false;
            }

            let campaignType = (<Campign.AttackCastleView>Core.ViewManager.inst.getView(ViewName.attackCastle)).type;
            if (campaignType && campaignType.isFig && !campaignType.isClear) {
                for (let cardId of campaignType.fightCards) {
                    let cardObj = CardPool.CardPoolMgr.inst.getCollectCard(cardId);
                    if (cardObj && (cardObj.state == CardPool.CardState.Dead || cardObj.energy <= cardObj.maxEnergy / 2)) {
                        return true;
                    }
                }
            }
            return false;
            */
        }
    }

    class ViewShowCondition implements ICondition {
        private _viewName: string;

        constructor(data:Array<string>) {
            this._viewName = data[1];
        }

        public check(): boolean {
            let _view = Core.ViewManager.inst.getView(this._viewName);
            return _view && _view.isShow();
        }
    }

    class GuideBattleProCondition implements ICondition {
        private _pro: number

        constructor(data:Array<string>) {
            this._pro = parseInt(data[1]);
        }

        public check(): boolean {
            return Player.inst.getResource(ResType.T_GUIDE_PRO) >= this._pro;
        }
    }

    class GuideCampCondition implements ICondition {
        private _camp: Camp;

        constructor(data:Array<string>) {
            this._camp = parseInt(data[1]);
        }

        public check(): boolean {
            return Player.inst.guideCamp == this._camp;
        }
    }

    class GuideFinishCondition implements ICondition {
        private _guideID: number;

        constructor(data:Array<string>) {
            this._guideID = parseInt(data[1]);
        }

        public check(): boolean {
            return GuideMgr.inst.isGuideFinish(this._guideID);
        }
    }

    function newConditions(condDatas:Array< Array<string> >) {
        let conditions: Array<ICondition> = [];
        for (let data of condDatas) {
            let condType = data[0];
            switch(condType) {
            case ConditionType.PASS_LEVEL:
                conditions.push( new PassLevelCondition(data) );
                break;
            case ConditionType.PASS_CAMPAIGN:
                conditions.push( new PassCampaignCondition(data) );
                break;
            case ConditionType.ViewShow:
                conditions.push( new ViewShowCondition(data) );
                break;
            case ConditionType.CardUnhealthy:
                conditions.push( new CardUnhealthyCondition() );
                break;
            case ConditionType.GuideBattlePro:
                conditions.push( new GuideBattleProCondition(data) );
                break;
            case ConditionType.GuideCamp:
                conditions.push( new GuideCampCondition(data) );
                break;
            case ConditionType.GuideFinish:
                conditions.push( new GuideFinishCondition(data) );
            default:
                break;
            }
        }
        return conditions;
    }

    class BaseGuide {
        private _finishCallback:Function;
        private _thisArg: any;
        private _guideId: number
        private _viewName: string;
        private _conditions: Array< ICondition >;
        private _next: IGuide;
        private _isBattle:boolean;
        private _isBanGuide:boolean;

        constructor(guideId: number, viewName: string, triggerOpp:Array< Array<string> >, condition: Array< Array<string> >) {
            this._guideId = guideId;
            this._viewName = viewName;
            this._conditions = newConditions(condition);
            this._isBattle = false;
            this._isBanGuide = false;
            for (let triggerParam of triggerOpp) {
                if (triggerParam[0] == GuideTriggerType.LevelFight || triggerParam[0] == GuideTriggerType.GuideBattle) {
                    this._isBattle = true;
                    break;
                }

                if (triggerParam[0] == GuideTriggerType.RefreshCampaignFort) {
                    this._isBanGuide = true;
                    break;
                }
            }
        }

        public onBegin() {
            TD.onGuideBegin(this.getGuideId());
        }

        public onFinish() {
            TD.onGuideFinish(this.getGuideId());
        }

        public getNext(): IGuide {
            return this._next;
        }

        public setNext(guide: IGuide) {
            if (this.isBattleType) {
                guide.isBattleType = true;
            }
            if (this._next) {
                this._next.setNext(guide);
            } else {
                this._next = guide;
            }
        }

        public getGuideId(): number {
            return this._guideId
        }

        public getGroupId(): number {
            let conf = Data.guide.get(this.getGuideId());
            return calcGuideGroup(conf.group);
        }

        public addOnFinishListener(func:Function, thisArg:any) {
            this._finishCallback = func;
            this._thisArg = thisArg;
        }

        protected finish() {
            if (this._finishCallback) {
                let func = this._finishCallback;
                this._finishCallback = null;
                func.apply(this._thisArg);
            }
        }

        public getViewName():string {
            return this._viewName;
        }
        
        protected getView(): Core.IBaseView {
            let view = Core.ViewManager.inst.getView(this._viewName);
            if (view && view.isShow()) {
                // shit
                if (this._isBanGuide && Core.LayerManager.inst.getTopView() !== view) {
                    return null;
                }
                return view;
            } else {
                return null;
            }
        }

        public canTrigger():boolean {
            if (this._isBattle && !Battle.BattleMgr.inst.battle) {
                return false;
            }
            if (!this.getView()) {
                return false;
            }
            if (!this._conditions || this._conditions.length <= 0) {
                return true;
            }

            for(let cond of this._conditions) {
                if (!cond.check()) {
                    return false;
                }
            }

            return true;
        }

        public canPlayCard(card:Battle.FightCard, gridId:number): boolean {
            return false;
        }

        public onPlayCard(card:Battle.FightCard, gridId:number) {
        }

        public get isBattleType():boolean {
            return this._isBattle;
        }

        public set isBattleType(val:boolean) {
            this._isBattle = val;
        }
    }

    export class TalkGuide extends BaseGuide implements IGuide {
        private _talkTargetName: string;
        protected _texts: Array<string>;
        protected _x:number;
        protected _y:number;
        protected _width:number;

        constructor(data:any) {
            super(data.__id__, data.view, data.triggerOpp, data.condition);
            this._talkTargetName = data.whoTalk;
            this._texts = data.text;
            if (data.textPoint && data.textPoint.length == 3) {
                this._x = data.textPoint[0];
                this._y = data.textPoint[1];
                this._width = data.textPoint[2];
            }
        }

        public begin(guideView:GuideView) {
            let view = this.getView();
            if (!view) {
                return false;
            }
            let target:fairygui.GObject;
            if (this._talkTargetName && this._talkTargetName != "") {
                target = view.getNode(this._talkTargetName);
                if (!target) {
                    return false;
                }
            }

            if (!this._texts || this._texts.length <= 0) {
                return false;
            }

            this.onBegin();

            this.showTalk(guideView, target, 0);
            return true;
        }

        protected showTalk(guideView:GuideView, target:fairygui.GObject, textIdx:number) {
            guideView.setTalkData(target, this._texts[textIdx], this._x, this._y, this._width);
            guideView.once(egret.TouchEvent.TOUCH_TAP, ()=>{
                if (textIdx >= this._texts.length - 1) {
                    this.finish();
                } else {
                    textIdx++;
                    this.showTalk(guideView, target, textIdx);
                }
            }, this);
        }
    }

    export class DragCardGuide extends BaseGuide implements IGuide {
        private _cardIdx: number;
        private _gridIdx: number;
        private _card: Battle.FightCard;

        private _talkTargetName: string;
        private _texts: Array<string>;
        private _x:number;
        private _y:number;
        private _width:number;

        constructor(data:any) {
            super(data.__id__, data.view, data.triggerOpp, data.condition);
            this._cardIdx = data.dragCard[0];
            this._gridIdx = data.dragCard[1];

            this._talkTargetName = data.whoTalk;
            this._texts = data.text;
            if (data.textPoint && data.textPoint.length == 3) {
                this._x = data.textPoint[0];
                this._y = data.textPoint[1];
                this._width = data.textPoint[2];
            }
        }

        public begin(guideView:GuideView): boolean {
            let battle = Battle.BattleMgr.inst.battle;
            if (!battle) {
                return false;
            }
            let targetCard = battle.getCardByIdx(this._cardIdx);
            let grid = battle.getGridById(this._gridIdx);
            if (!targetCard || !grid || grid.inGridCard || !targetCard.view || !grid.view) {
                return false;
            }

            this.onBegin();

            let battleView = Core.ViewManager.inst.getView(ViewName.battle);
            let textTarget:fairygui.GObject;
            if (this._talkTargetName && this._talkTargetName != "") {
                textTarget = battleView.getNode(this._talkTargetName);
            }

            let text: string;
            if (this._texts && this._texts.length > 0) {
                text = this._texts[0];
            }

            this._card = targetCard;
            guideView.setDragCardData(targetCard.view, grid.view, textTarget, text, this._x, this._y, this._width);
            Core.EventCenter.inst.dispatchEventWith(GameEvent.BeginDragGuideEv, false, targetCard.view);
            return true;
        }
                                                                                                                                                                                                          
        public canPlayCard(card:Battle.FightCard, gridIdx:number): boolean {
            if (card == this._card && gridIdx == this._gridIdx) {
                return true;
            }
            return false;
        }

        public onPlayCard(card:Battle.FightCard, gridIdx:number) {
            if (card == this._card && gridIdx == this._gridIdx) {
                this.finish();
            }
        }
    }

    export class ClickGuide extends BaseGuide implements IGuide {
        private _nodeName: string;
        private _clickNode:fairygui.GObject;
        private _texts: Array<string>;
        private _x:number;
        private _y:number;
        private _width:number;

        constructor(data:any) {
            super(data.__id__, data.view, data.triggerOpp, data.condition);
            this._nodeName = data.click;
            if (data.text && data.text != "") {
                this._texts = data.text;
            }
            if (data.textPoint && data.textPoint.length == 3) {
                this._x = data.textPoint[0];
                this._y = data.textPoint[1];
                this._width = data.textPoint[2];
            }
        }

        public begin(guideView:GuideView): boolean {
            let view = this.getView();
            if (!view) {
                return false
            }
            this._clickNode = view.getNode(this._nodeName);
            if (!this._clickNode) {
                return false;
            }

            this.onBegin();

            let self = this;
            let textIdx = 0;
            let _showClickTalk = function() {
                let text = "";
                if (self._texts && textIdx <= self._texts.length - 1) {
                    text = self._texts[textIdx];
                }
                guideView.setClickData(self._clickNode, text, self._x, self._y, self._width);
                guideView.addTargetClickListener(()=>{
                    if (!self._texts || textIdx >= self._texts.length - 1) {
                        self._clickNode.dispatchEventWith(egret.TouchEvent.TOUCH_BEGIN);
                        fairygui.GRoot.inst.nativeStage.dispatchEventWith(egret.TouchEvent.TOUCH_END);
                        self._clickNode.dispatchEventWith(egret.TouchEvent.TOUCH_TAP);
                        self.finish();
                    } else {
                        _showClickTalk();
                    }
                }, self);
            }
            _showClickTalk();
            return true;
        }
    }

    export class TimeoutGuide extends TalkGuide implements IGuide {
        private _timeout: number

        constructor(data:any) {
            super(data);
            this._timeout = data.timeout;
        }

        protected showTalk(guideView:GuideView, target:fairygui.GObject, textIdx:number) {
            guideView.setTalkData(target, this._texts[textIdx], this._x, this._y, this._width);
            fairygui.GTimers.inst.add(this._timeout, 1, ()=>{
                this.finish();
            }, this);
        }
    }

}
