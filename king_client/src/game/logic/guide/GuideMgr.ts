module Guide {

    class breakGuideSignal {   
    }

    export class GuideTriggerType {
        public static LevelFight = "1";
        public static OpenView = "2";
        public static CloseView = "3";
        public static RefreshCampaignFort = "4";
        public static GuideNextStep = "5";
        public static GuideBattle = "6";
        public static HomeChanged = "HomeChanged";
        public static NewbiePvpBattle = "newbiePvp";
    }

    class BattleTrigger {
        public static BOUT_BEGIN = "1";
        public static BOUT_END = "2";
    }

    export let MAX_GUIDE_GROUP = 9999;

    export function calcGuideGroup(group: number) {
        let ret = Math.floor(group / 10) * 10;
        if (ret == 0) {
            ret = MAX_GUIDE_GROUP;
        }
        return ret;
    }

    function isValideGroupId(grpId: number) {
        return grpId > 0 && grpId != MAX_GUIDE_GROUP
    }

    export let MaxGuideProgress = 5;

    class GuideGroup {
        private _firstGuide: IGuide;
        private _lastGuides: Collection.Set<number>;
        private _groupId: number;
        private _nextGroupId: number;

        public constructor(groupId: number) {
            this._firstGuide = null;
            this._lastGuides = new Collection.Set<number>();
            this._groupId = groupId;
        }

        public get firstGuide(): IGuide {
            return this._firstGuide;
        }

        public set firstGuide(g: IGuide) {
            this._firstGuide = g;
        }

        public get lastGuides(): Collection.Set<number> {
            return this._lastGuides;
        }

        public get nextGroupId(): number {
            return this._nextGroupId;
        }

        public addGuide(g: IGuide) {
            if (!this._firstGuide) {
                this._firstGuide = g;
            }
            let guideId = g.getGuideId();
            let conf = Data.guide.get(guideId)
            let confGrpId = conf.group;
            let groupId = g.getGroupId();
            if (Math.floor(confGrpId / 10) == Math.floor(groupId / 10) &&
                confGrpId - groupId == 1) {
                this._lastGuides.add(g.getGuideId());
            }
            this._nextGroupId = conf.groupDep;
        }
    }

    export class GuideMgr extends egret.EventDispatcher {
        private static _inst: GuideMgr;
        public static GUIDE_COMPLETE_EV = "guideCompleteEv";
        public static GUIDE_BATTLE_LOSE = "guideBattleLose";

        private _finishGuideIds: Collection.Set<number>;
        private _view: GuideView;
        private _curGuideItem: IGuide;
        private _isInGuide: boolean;
        // { TriggerKey: Array<IGuide> }
        private _allGuides: Collection.MultiDictionary<string, IGuide>;

        private _curGuideGroupId: number;
        private _guideGroups: Collection.Dictionary<number, GuideGroup>;

        public static get inst(): GuideMgr {
            if (!GuideMgr._inst) {
                GuideMgr._inst = new GuideMgr();
            }
            return GuideMgr._inst;
        }

        public init(guideIds: Array<number>) {
            this._finishGuideIds = new Collection.Set<number>();
            this._allGuides = new Collection.MultiDictionary<string, IGuide>();
            this._isInGuide = false;
            guideIds.forEach(id => {
                let data = Data.guide.get(id);
                if (!data) {
                    return;
                }
                if (GuideMgr.inst.curGuideGroupId != calcGuideGroup(data.group)) {
                    this._finishGuideIds.add(id);
                }
            });
            this._guideGroups = new Collection.Dictionary<number, GuideGroup>();
        }

        public get isInGuide(): boolean {
            return this._isInGuide;
        }

        public get curGuideGroupId(): number {
            return this._curGuideGroupId;
        }

        public set curGuideGroupId(g: number) {
            this._curGuideGroupId = g;
        }

        public onLogout() {
            this.removeEvent();
            if (this._view) {
                this._view.hide();
                this._view = null;
            }

            this._curGuideItem = null;
            this._isInGuide = false;
            this._curGuideGroupId = 0;
            //this._allGuides = null;
            //GuideMgr._inst = new GuideMgr();
        }

        private _saveCurrentGroupId() {
            Net.rpcPush(pb.MessageID.C2S_RECORD_CUR_GUIDE_GROUP, pb.GuideGroup.encode({"GroupID":this._curGuideGroupId}));
            let key = `${Player.inst.uid}`;
            let data = {};
            data[key] = this._curGuideGroupId;
            egret.localStorage.setItem("guide", JSON.stringify(data));
            console.debug(`forward current group id to ${this._curGuideGroupId}`);
        }

        private _finishGuide(guide:IGuide) {

            if (guide.getViewName() == ViewName.cardDetail) {
                Core.ViewManager.inst.close(ViewName.cardDetail);
            }

            if (guide.isBattleType) {
                return;
            }

            if (this._finishGuideIds.contains(guide.getGuideId())) {
                return;
            }
            this._finishGuideIds.add( guide.getGuideId() );
            //egret.localStorage.setItem(`guide:${Player.inst.uid}`, JSON.stringify(this._finishGuideIds.toArray()));
            Net.rpcPush(pb.MessageID.C2S_FINISH_GUIDE, pb.FinishGuide.encode({"GuideID":guide.getGuideId()}));
            guide.onFinish();

            let guideGrpId = guide.getGroupId();
            let guideId = guide.getGuideId();
            if (isValideGroupId(guideGrpId)) {
                console.debug(`current guide group id: ${guideGrpId}`);
                if (this._curGuideGroupId != guideGrpId) {
                    console.error(`skip guide which is expected to be ignored ${guideId}`);
                } else {
                    let group = this._guideGroups.getValue(this._curGuideGroupId);
                    if (group) {
                        console.debug(`group ${this._curGuideGroupId} last guides: `, JSON.stringify(group.lastGuides));
                        if (group.lastGuides.contains(guideId)) {
                            this._curGuideGroupId = group.nextGroupId;
                            this._saveCurrentGroupId();
                        } else {
                            console.debug(`not last finish in group ${this._curGuideGroupId}, guideId = ${guideId}`);
                        }
                    } else {
                        console.error(`no group obj found ${this._curGuideGroupId}`);
                    }
                }
            }
            this.dispatchEventWith(GameEvent.FinishGuideEv);
        }

        private _checkBattleGuideIsBreak(battle: Battle.Battle, g: IGuide) {
            if (g.isBattleType && battle != Battle.BattleMgr.inst.battle) {
                throw new breakGuideSignal();
            }
        }

        private async _runGuide(g: IGuide) {

            let battle = Battle.BattleMgr.inst.battle;
            let groupId = g.getGroupId();

            if (isValideGroupId(groupId)) {
                if (this._curGuideGroupId == 0) {
                    this._curGuideGroupId = groupId;
                    Net.rpcPush(pb.MessageID.C2S_RECORD_CUR_GUIDE_GROUP, pb.GuideGroup.encode({"GroupID":this._curGuideGroupId}));
                    console.debug(`record current group id ${this._curGuideGroupId}`);
                }
                if (groupId != this._curGuideGroupId) {
                    console.error(`running guide with groupId ${groupId}, but cur: ${this._curGuideGroupId}`);
                    return true;
                }
                console.debug(`running guide with group id ${groupId}, guideId ${g.getGuideId()}`);
            }            
            if (!this._view) {
                this._view = new GuideView();
            }

            while (g) {
                await fairygui.GTimers.inst.waitTime(100);
                this._checkBattleGuideIsBreak(battle, g);
                if (!g.begin(this._view)) {
                    g = g.getNext();
                    continue
                }
                this.dispatchEventWith(GameEvent.BeginGuideEv);
                this._curGuideItem = g;
                this._isInGuide = true;

                if (g instanceof TimeoutGuide) {
                    this._finishGuide(g);
                }

                await new Promise<void>(resolve => {
                    try {
                        this._view.show()
                        g.addOnFinishListener(()=>{
                            if (!this._view) {
                                return;
                            }
                            this._view.hide();
                            this._curGuideItem = null;
                            this._finishGuide(g);
                            resolve();
                        }, this);
                    } catch (e) {
                        console.error("exec guide error: ", e);
                    }
                });

                this._checkBattleGuideIsBreak(battle, g);

                if (!this._view) {
                    return false;
                }
                g = g.getNext();
            }

            return true;
        }

        private async _tryTriggerGuide(triggerKey:string) {
            try {
                if (!this._allGuides) {
                    return;
                }
                let guides = this._allGuides.getValue(triggerKey);
                if (!guides || guides.length <= 0) {
                    return;
                }

                for (let g of guides) {
                    if (!this._allGuides) {
                        return;
                    }
                    if (this._finishGuideIds.contains(g.getGuideId())) {
                        continue;
                    }
                    if (!g.canTrigger()) {
                        continue;
                    }

                    if (!await this._runGuide(g)) {
                        break;
                    }
                }
            } catch (e) {
                console.error(e);
            }
            
            if (this._isInGuide) {
                this._isInGuide = false;
                this.dispatchEventWith(GuideMgr.GUIDE_COMPLETE_EV);
            }
        }

        public isGuideFinish(guideID:number): boolean {
            return this._finishGuideIds.contains(guideID);
        }

        private _genTriggerKey(triggerType:string, viewName:string, ...param:string[]): string {
            switch(triggerType) {
            case GuideTriggerType.LevelFight:
            case GuideTriggerType.GuideBattle:
            case GuideTriggerType.NewbiePvpBattle:
                // 1_levelId_bout_fightTrigger
                return triggerType + "_" + param[0] + "_" + param[1] + "_" + param[2];
            case GuideTriggerType.OpenView:
                // 2_viewName
                return triggerType + "_" + viewName;
            case GuideTriggerType.CloseView:
            case GuideTriggerType.HomeChanged:
                // 3_closeViewName
                return triggerType + "_" + param[0];
            default:
                return triggerType;
            }
        }

        public listenEvent() {
            Core.EventCenter.inst.addEventListener(Core.Event.OpenViewEvt, this._onOpenView, this);
            Core.EventCenter.inst.addEventListener(Core.Event.CloseViewEvt, this._onCloseView, this);
            //App.EventCenter().addEventListener(GameConst.LEVEL_FIGHT_BOUT_BEGIN_EV, this.onLevelFightBoutBegin, this);
            //App.EventCenter().addEventListener(GameConst.LEVEL_FIGHT_BOUT_END_EV, this.onLevelFightBoutEnd, this);
            Core.EventCenter.inst.addEventListener(GameEvent.CampaignSwitchTypeEv, this._onCampaignSwitchType, this);
            Core.EventCenter.inst.addEventListener(GameEvent.BattlePlayCardEv, this.onPlayCard, this);
            Core.EventCenter.inst.addEventListener(GameEvent.OpenHomeEv, this._onHomeChanged, this);
        }

        public removeEvent() {
            Core.EventCenter.inst.removeEventListener(Core.Event.OpenViewEvt, this._onOpenView, this);
            Core.EventCenter.inst.removeEventListener(Core.Event.CloseViewEvt, this._onCloseView, this);
            //App.EventCenter().removeEventListener(GameConst.LEVEL_FIGHT_BOUT_BEGIN_EV, this.onLevelFightBoutBegin, this);
            Core.EventCenter.inst.removeEventListener(GameEvent.CampaignSwitchTypeEv, this._onCampaignSwitchType, this);
            Core.EventCenter.inst.removeEventListener(GameEvent.BattlePlayCardEv, this.onPlayCard, this);
            Core.EventCenter.inst.removeEventListener(GameEvent.OpenHomeEv, this._onHomeChanged, this);
        }

        private _onHomeChanged(ev:egret.Event) {
            let key = this._genTriggerKey(GuideTriggerType.HomeChanged, "", ev.data);
            this._tryTriggerGuide(key);
        }

        private _onOpenView(ev:egret.Event) {
            let key = this._genTriggerKey(GuideTriggerType.OpenView, ev.data);
            this._tryTriggerGuide(key);
        }

        private _onCloseView(ev:egret.Event) {
            let key = this._genTriggerKey(GuideTriggerType.CloseView, "", ev.data);
            this._tryTriggerGuide(key);
        }

        private _onCampaignSwitchType(ev:egret.Event) {
            let key = this._genTriggerKey(GuideTriggerType.RefreshCampaignFort, "");
            this._tryTriggerGuide(key);
        }

        public onLevelBattleBoutBegin(levelId:number, curBout:number) {
            let key = this._genTriggerKey(GuideTriggerType.LevelFight, "", levelId.toString(), curBout.toString(), 
                BattleTrigger.BOUT_BEGIN);
            this._tryTriggerGuide(key);
        }

        public async onLevelBattleBoutEnd(levelId:number, curBout:number) {
            let key = this._genTriggerKey(GuideTriggerType.LevelFight, "", levelId.toString(), curBout.toString(), 
                BattleTrigger.BOUT_END);
            await this._tryTriggerGuide(key);
        }

        public async onGuideBattleBoutBegin(guideBattleID:number, curBout:number) {
            let key = this._genTriggerKey(GuideTriggerType.GuideBattle, "", guideBattleID.toString(), curBout.toString(), 
                BattleTrigger.BOUT_BEGIN);
            await this._tryTriggerGuide(key);
        }

        public async onGuideBattleBoutEnd(guideBattleID:number, curBout:number) {
            let key = this._genTriggerKey(GuideTriggerType.GuideBattle, "", guideBattleID.toString(), curBout.toString(), 
                BattleTrigger.BOUT_END);
            await this._tryTriggerGuide(key);
        }

        public async onNewbiePvpBattleBoutBegin(curBout:number) {
            let key = this._genTriggerKey(GuideTriggerType.NewbiePvpBattle, "", "1", curBout.toString(), 
                BattleTrigger.BOUT_BEGIN);
            await this._tryTriggerGuide(key);
        }

        public async onNewbiePvpBattleBoutEnd(curBout:number) {
            let key = this._genTriggerKey(GuideTriggerType.NewbiePvpBattle, "", "1", curBout.toString(), 
                BattleTrigger.BOUT_END);
            await this._tryTriggerGuide(key);
        }

        public addGuide(data:any) {
            let g: IGuide;
            if (data.timeout > 0) {
                g = new TimeoutGuide(data);
            } else if (data.click) {
                g = new ClickGuide(data);
            } else if (data.dragCard.length >= 2) {
                g = new DragCardGuide(data);
            } else if (data.dragCard.length == 0) {
                g = new TalkGuide(data);
            } 

            if (!g) {
                return
            }

            for (let triggerParam of <Array<Array<string>>>data.triggerOpp) {
                if (triggerParam[0] == GuideTriggerType.GuideNextStep) {
                    this._addGuideNextStep(g, triggerParam);
                } else {
                    let key = this._genTriggerKey(triggerParam[0], data.view, ...triggerParam.slice(1));
                    this._allGuides.setValue(key, g);
                }
            }

            let groupId = g.getGroupId();
            if (!this._guideGroups.containsKey(groupId)) {
                this._guideGroups.setValue(groupId, new GuideGroup(groupId));
            }
            let group = this._guideGroups.getValue(groupId);
            group.addGuide(g);
        }

        private _addGuideNextStep(guide:IGuide, triggerParam:Array<string>) {
            if (!triggerParam) {
                return;
            }
            let rootGuideId = parseInt(triggerParam[1]);
            let rootGuideData = Data.guide.get(rootGuideId);
            if (!rootGuideData) {
                return;
            }

            let rootTriggerParam = rootGuideData.triggerOpp[0] as Array<string>;
            let key = this._genTriggerKey(rootTriggerParam[0][0], rootGuideData.view, ...rootTriggerParam.slice(1));
            let rootGuideArr = this._allGuides.getValue(key);
            if (!rootGuideArr || rootGuideArr.length <= 0) {
                return;
            }

            let rootGuide: IGuide;
            for (let _guide of rootGuideArr) {
                if (_guide.getGuideId() == rootGuideId) {
                    rootGuide = _guide;
                    break;
                }
            }
            if (rootGuide) {
                rootGuide.setNext(guide);
            }
        }

        private onPlayCard(evt:egret.Event) {
            if (this._curGuideItem) {
                let card = evt.data.card as Battle.FightCard;
                let gridIdx = evt.data.gridIdx as number;
                this._curGuideItem.onPlayCard(card, gridIdx);
            }
        }

        public canPlayCard(card:Battle.FightCard, gridIdx:number): boolean {
            if (this._curGuideItem) {
                return this._curGuideItem.canPlayCard(card, gridIdx);
            } else {
                return true;
            }
        }

        public async waitGuideComplete() {
            if (!this._isInGuide) {
                return;
            }
            await new Promise(resolve => {
                try {
                    this.once(GuideMgr.GUIDE_COMPLETE_EV, ()=>{
                        resolve();
                    }, this);
                } catch (e) {
                    console.error("waitGuideComplete error", e);
                }
            })
        }

        public showGuideText(targetObj:fairygui.GObject, text:string): Promise<void> {
            if (!this._view) {
                this._view = new GuideView();
            }
            this._view.setTalkData(targetObj, text, 0, 0, 0, false);
            this._view.show();
            return new Promise<void>(reslove => {
                this._view.once(egret.TouchEvent.TOUCH_TAP, ()=>{
                    this._view.hide();
                    reslove();
                }, this);
            })
        }

        public async beginGuideBattle(camp:Camp): Promise<boolean> {
            let result = await Net.rpcCall(pb.MessageID.C2S_START_TUTORIAL_BATTLE, pb.StartTutorialBattleArg.encode(
                {"CampID":camp},
            ));
            if (result.errcode != 0) {
                return false;
            }

            Player.inst.guideCamp = camp;
            Pvp.PvpMgr.inst.fightCamp = camp;
            let reply = pb.FightDesk.decode(result.payload);
            Battle.BattleMgr.inst.beginBattle(reply, Battle.BattleType.Guide);
            //let homeView = Core.ViewManager.inst.getView(ViewName.newHome) as Home.NewHomeView; 
            //await Core.ViewManager.inst.close(ViewName.team);
            //homeView.openPvpView();
            Pvp.PvpMgr.inst.onEnterPvp();

            if (Core.DeviceUtils.isWXGame()) {
                WXGame.WXGameMgr.inst.onCreateRole();
            }
            return true;
        }

        public async enterGuideHome(callback: (camp: Camp) => void) {
            let guideHomeView = Core.ViewManager.inst.getView(ViewName.guideHome);
            if (!guideHomeView) {
                guideHomeView = fairygui.UIPackage.createObject(PkgName.guide, ViewName.guideHome, GuideHome) as GuideHome;
                Core.ViewManager.inst.register(ViewName.guideHome, guideHomeView);
            }
            await Core.ViewManager.inst.openView(guideHomeView, callback);
        }

        public checkInterruptedGuide() {
            if (Battle.BattleMgr.inst.battle) {
                return;
            }
            if (this._checkGuideBattleSign()) {
                // console.log("有教程战斗失败哦");
                Pvp.PvpMgr.inst.beginMatch();
                return;
            }
            //角色处于指引中
            if (this._curGuideGroupId == 0 && Player.inst.isInGuide()) {
                this._curGuideGroupId = 100;
            }
            if (isValideGroupId(this._curGuideGroupId)) {
                let group = this._guideGroups.getValue(this._curGuideGroupId);
                if (group.firstGuide) {
                    this._runGuide(group.firstGuide);
                    if (this._isInGuide) {
                        this._isInGuide = false;
                        this.dispatchEventWith(GuideMgr.GUIDE_COMPLETE_EV);
                    }
                }
            }
        }
        public saveGuideBattleSign(b: boolean) {
            let key = `${Player.inst.uid}`;
            let saveStr = egret.localStorage.getItem(GuideMgr.GUIDE_BATTLE_LOSE);
            let saveData = {};
            if (saveStr && saveStr != "") {
                saveData = JSON.parse(saveStr);
            } else {
                saveData = {};
            }
            saveData[key] = b;
            saveStr = JSON.stringify(saveData);
            egret.localStorage.setItem(GuideMgr.GUIDE_BATTLE_LOSE, saveStr);
        }
        private _checkGuideBattleSign() {
            if (!Player.inst.isInGuide()) {
                return false;
            }
            let key = `${Player.inst.uid}`;
            let saveStr = egret.localStorage.getItem(GuideMgr.GUIDE_BATTLE_LOSE);
            // console.log(saveStr);
            if (saveStr && saveStr != "") {
                let saveData = JSON.parse(saveStr);
                return saveData[key];
            }
            return false;
        }

        public hideGuide() {
            if (this._curGuideItem) {
                this._curGuideItem = null;
                this._isInGuide = false;
                if (this._view) {
                    this._view.hide();
                }
            }
        }
        /**
         * 停止教程，注销监听
        */
        public stopGuide() {
            this.removeEvent();
            this.hideGuide();
        }
        /**
         * 继续教程，添加监听
         */
        public continueGuide() {
            if (this._isInGuide) {
                return;
            }
            this.listenEvent();
            this.checkInterruptedGuide();
        }
    }

    export function clearGuide() {
        //egret.localStorage.removeItem("guide:" + Player.inst.uid);
        GuideMgr.inst.removeEvent();
        onLogin();
    }

    export async function onLogin() {
        /*
        let strGuideIds = egret.localStorage.getItem("guide:" + Player.inst.uid);
        let guideIds:Array<number>
        if (!strGuideIds) {
            let result =  await Net.rpcCall(MessageID.C2S_FETCH_GUIDE, {});
            if (result.errcode == 0) {
                guideIds = result.reply.GuideIDs;
                if (!guideIds) {
                    guideIds = [];
                }
            } else {
                guideIds = [];
            }
            egret.localStorage.setItem("guide:" + Player.inst.uid, JSON.stringify(guideIds));
        } else {
            guideIds = JSON.parse(strGuideIds);
        }
        */

        let result2 = await Net.rpcCall(pb.MessageID.C2S_FETCH_CUR_GUIDE_GROUP, null);
        if (result2.errcode == 0) {
            GuideMgr.inst.curGuideGroupId = pb.GuideGroup.decode(result2.payload).GroupID;
        }

        let dataStr = egret.localStorage.getItem("guide");
        if (dataStr && dataStr != "") {
            let data = JSON.parse(dataStr);
            let key = `${Player.inst.uid}`;
            if (data[key]) {
                if (data[key] == MAX_GUIDE_GROUP || GuideMgr.inst.curGuideGroupId < data[key]) {
                    GuideMgr.inst.curGuideGroupId = data[key];
                }
            }
        }

        egret.log(`curGuideGroup: ${GuideMgr.inst.curGuideGroupId}`);

        let guideIds:Array<number>
        let result =  await Net.rpcCall(pb.MessageID.C2S_FETCH_GUIDE, null);
        if (result.errcode == 0) {
            guideIds = pb.AllFinishGuide.decode(result.payload).GuideIDs;
            if (!guideIds) {
                guideIds = [];
            }
        } else {
            guideIds = [];
        }

        GuideMgr.inst.listenEvent();
        GuideMgr.inst.init(guideIds);
        Data.guide.keys.forEach(id => {
            let data = Data.guide.get(id);
            if (guideIds.indexOf(id) >= 0 && 
                GuideMgr.inst.curGuideGroupId != calcGuideGroup(data.group)) {
                return;
            }
            GuideMgr.inst.addGuide(data);
        });

        Guide.GuideMgr.inst.checkInterruptedGuide();
    }

    function onLogout() {
        try {
            GuideMgr.inst.onLogout();
        } catch (e) {
            console.error(e);
        }
    }

    export function init() {
        Player.inst.addEventListener(Player.LoginEvt, onLogin, null);
        Player.inst.addEventListener(Player.LogoutEvt, onLogout, null);
    }
}