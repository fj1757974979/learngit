module Level {

    export class LevelMgr {
        private static _inst: LevelMgr;

        private _levelDict: Collection.Dictionary<number, Level>;  // {levelId: Level}
        private _chapterDict: Collection.Dictionary<number, Chapter>; // {chapterId: Chapter}
        private _chapters: Array<Chapter>;
        private _curLevel: number;
        private _cardUnlockLevels: Collection.Dictionary<number, number>; // {cardId: levelId}
        private _chapterUnlockCard: Collection.Dictionary<number, number>; // {chapterId: cardId}
        private _chapterTreasureOpened: Collection.Dictionary<number, boolean>;
        private _curVideoLevelId: Level;

        private readonly _STORE_KEY: string = "levelHints";
        private _chapterTreasureCanOpenHintData: any;

        constructor() {
            this.initData();
            //Core.EventCenter.inst.addEventListener(GameEvent.LoadConfigDoneEv, this.initData, this);
        }

        public initData() {
            this._levelDict = new Collection.Dictionary<number, Level>();
            this._chapterDict = new Collection.Dictionary<number, Chapter>();
            this._chapters = [];
            this._cardUnlockLevels = new Collection.Dictionary<number, number>();
            this._chapterUnlockCard = new Collection.Dictionary<number, number>();
            this._chapterTreasureOpened = new Collection.Dictionary<number, boolean>();
            Data.level.keys.forEach(levelId => {
                //console.log(`${levelId} ${typeof levelId}`);
                let levelData = Data.level.get(levelId);
                let cpt = this._chapterDict.getValue(levelData.chapter[0]);
                //console.log(levelData);
                if (!cpt) {
                    cpt = new Chapter(levelData.chapter);
                    this._chapterDict.setValue(levelData.chapter[0], cpt);
                    this._chapters.push(cpt);
                    this._chapterTreasureOpened.setValue(cpt.id, false);
                }
                let levelObj = new Level(levelData, cpt.id);
                cpt.addLevel(levelObj);
                this._levelDict.setValue(levelId, levelObj);

                let cardId = levelData.generalUnlock;
                if (cardId > 0) {
                    this._cardUnlockLevels.setValue(cardId, levelId);
                    this._chapterUnlockCard.setValue(cpt.id, cardId);
                }
            });
            this._chapters.sort((a:Chapter, b:Chapter):number => {
                return a.id - b.id;
            });
        }

        public loadLevelHintData() {
            let localDataStr = egret.localStorage.getItem(this._STORE_KEY);
            
            if (!localDataStr || localDataStr == "") {
                localDataStr = "{}";
            }
            this._chapterTreasureCanOpenHintData = JSON.parse(localDataStr);
            let uid = `${Player.inst.uid}`;
            if (!this._chapterTreasureCanOpenHintData[uid]) {
                this._chapterTreasureCanOpenHintData[uid] = 0;
                this._saveLevelHintData();
            }
        }

        public _saveLevelHintData() {
            let dataStr = JSON.stringify(this._chapterTreasureCanOpenHintData);
            egret.localStorage.setItem(this._STORE_KEY, dataStr);
        }

        public getTotalLevelHintNum(): number {
            let uid = `${Player.inst.uid}`;
            return this._chapterTreasureCanOpenHintData[uid];
        }

        public addLevelHintNum() {
            let uid = `${Player.inst.uid}`;
            let cnt = this._chapterTreasureCanOpenHintData[uid] + 1;
            this._chapterTreasureCanOpenHintData[uid] = cnt;
            this._saveLevelHintData();
            Core.EventCenter.inst.dispatchEventWith(Core.Event.LevelHintNumChangeEv, false);
        }

        public subLevelHintNum() {
            let uid = `${Player.inst.uid}`;
            let cnt = Math.max(0, this._chapterTreasureCanOpenHintData[uid] - 1);
            this._chapterTreasureCanOpenHintData[uid] = cnt;
            this._saveLevelHintData();
            Core.EventCenter.inst.dispatchEventWith(Core.Event.LevelHintNumChangeEv, false);
        }

        public static get inst(): LevelMgr {
            if (!LevelMgr._inst) {
                LevelMgr._inst = new LevelMgr();
            }
            return LevelMgr._inst;
        }

        public getLevel(levelId:number): Level {
            return this._levelDict.getValue(levelId);
        }


        public getChapter(chapterId:number): Chapter {
            return this._chapterDict.getValue(chapterId);
        }

        public getChapterNum(): number {
            return this._chapters.length;
        }

        // 可以打，但还没打的当前关卡
        public get curLevel(): number {
            return this._curLevel;
        }

        public get curLevelName():string {
            return this.getLevel(this._curLevel).name;
        }
        public set curVideoLevel(level: Level) {
            this._curVideoLevelId = level;
        }
        public get curVideoLevel():Level {
            return this._curVideoLevelId;
        }

        public getCardIdUnlockLevelId(cardId: number): number {
            let levelId = this._cardUnlockLevels.getValue(cardId);
            if (!levelId) {
                return 0;
            } else {
                return levelId;
            }
        }

        public getChapterUnlockCardId(chapterId: number): number {
            return this._chapterUnlockCard.getValue(chapterId);
        }

        public isClear() {
            return this._chapters[ this._chapters.length-1 ].isClear();
        }

        public async fetchLevelData(isSync:boolean):Promise<boolean> {
            let reply = await Net.rpcCall(pb.MessageID.C2S_FETCH_LEVEL_INFO, null, isSync, isSync);
            if (reply.errcode != 0) {
                return false;
            }
            let result = pb.LevelInfo.decode(reply.payload)

            result.OpenedTreasureChapters.forEach(chpId => {
                this._chapterTreasureOpened.setValue(chpId, true);
            });

            let curLevel = result.CurLevel;
            for (let levelID = 1; levelID < curLevel; levelID++) {
                let levelObj = this.getLevel(levelID);
                if (!levelObj) {
                    continue;
                }
                levelObj.state = LevelState.Clear;
            }

            let oldLevel = this._curLevel;
            this._curLevel = curLevel;
            if (oldLevel && curLevel > oldLevel) {
                Core.EventCenter.inst.dispatchEventWith(GameEvent.ClearLevelEv, false, oldLevel);
            }

            this._levelDict.forEach((levelId, levelObj) => {
                levelObj.help = false;
            });

            result.AskHelpLevels.forEach(levelId => {
                let levelObj = this.getLevel(levelId);
                if (levelObj) {
                    levelObj.help = true;
                }
            });

            let levelObj = this.getLevel(curLevel);
            if (!levelObj) {
                return true;
            }
            levelObj.state = LevelState.UnLock;
            return true;
        }

        public isChapterTreasureOpen(chapterId: number): boolean {
            return this._chapterTreasureOpened.getValue(chapterId);
        }

        public onChapterTreasureOpen(chapterId: number) {
            this._chapterTreasureOpened.setValue(chapterId, true);
        }

        public async onEnterLevel() {
            let ok = await this.fetchLevelData(true);
            if (!ok) {
                return;
            }
            Core.ViewManager.inst.open(ViewName.level, this._chapters);
        }

        public async refreshLevelView() {
            let view = (<Level.LevelView>Core.ViewManager.inst.getView(ViewName.level));
            if (view) {
                await this.onEnterLevel();
                view.refresh();
            }
        }

        public async beginLevelBattle(levelObj:Level) {
            if (levelObj.state == LevelState.Lock) {
                return;
            }

            let result = await Net.rpcCall(pb.MessageID.C2S_BEGIN_LEVEL_BATTLE, pb.BeginLevelBattle.encode({"LevelId":levelObj.id}));
            if (result.errcode != 0) {
                return;
            }

            Battle.BattleMgr.inst.beginBattle(pb.LevelBattle.decode(result.payload), Battle.BattleType.LEVEL, levelObj.id);
            Core.ViewManager.inst.close(ViewName.level);
        }
    }

    function onLogout() {
        try {
            LevelMgr.inst.initData();
        } catch (e) {
            console.error(e);
        }
    }

    function onLogin() {
        LevelMgr.inst.loadLevelHintData();
    }

    function rpc_ChapterUnlock(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.ChapterUnlock.decode(payload);
        let chapterObj = LevelMgr.inst.getChapter(arg.Chapter);
        if (!chapterObj || chapterObj.state != ChapterState.Lock) {
            return;
        }

        chapterObj.state = ChapterState.UnLock;
        let battle = Battle.BattleMgr.inst.battle;
        let tips = Core.StringUtils.format(Core.StringUtils.TEXT(60248), Core.StringUtils.getZhNumber(arg.Chapter));
        if (battle) {
            battle.addDelayTips(tips);
        } else {
            Core.TipsUtils.alert(tips);
        }
    }

    function rpc_LevelBeHelp(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.LevelBeHelpArg.decode(payload);
        let levelObj = LevelMgr.inst.getLevel(arg.LevelID);
        if (levelObj) {
            Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(60198), arg.HelperName, levelObj.name));
        }
        // console.log(`rpc_LevelBeHelp ${arg.HelperName}, ${arg.LevelID}`);
        LevelMgr.inst.refreshLevelView();
    }

    export function init() {
        Player.inst.addEventListener(Player.LoginEvt, onLogin, null);
        Player.inst.addEventListener(Player.LogoutEvt, onLogout, null);
        Net.registerRpcHandler(pb.MessageID.S2C_CHAPTER_UNLOCK, rpc_ChapterUnlock);
        Net.registerRpcHandler(pb.MessageID.S2C_LEVEL_BE_HELP, rpc_LevelBeHelp);


        let registerView = Core.ViewManager.inst.registerView.bind(Core.ViewManager.inst);
        let createObj = fairygui.UIPackage.createObject;
        registerView(ViewName.level, () => {
            return createObj(PkgName.level, ViewName.level, LevelView);
        });

        registerView( ViewName.levelTreasureInfo, () => {
            let chapterTreasureInfoWnd = new ChapterTreasureInfoWnd();
            chapterTreasureInfoWnd.contentPane = createObj(PkgName.level, ViewName.levelTreasureInfo).asCom;
            return chapterTreasureInfoWnd;
        });
        
        registerView(ViewName.levelHelpWnd, () => {
            let levelHelpWnd = new LevelHelpWnd();
            levelHelpWnd.contentPane = createObj(PkgName.level, ViewName.levelHelpWnd).asCom;
            return levelHelpWnd;
        });
        
        registerView(ViewName.levelVideo, () => {
            return createObj(PkgName.level, ViewName.levelVideo, LevelVideoView);
        });
    }

}
