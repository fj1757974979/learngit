module Quest {

    export enum MissionType {
        WatchVideo = 9,
        WxShare = 6,
    }

    export class QuestMgr extends egret.EventDispatcher {
        private static _inst: QuestMgr;

        // private _treasureModelID: string;
        // private _curCnt: number;
        private _canRefresh: boolean;
        // private _isReward: boolean;
        private _nextRemainTime: number;
        private _treasure: pb.MissionTreasure;

        private _questList: Collection.Dictionary<number,QuestData>;

        public static UpdateQuestButton = "UpdateQuestButton";
        public static UpdateQuestHint = "UpdateQuestHint";
        public static UpdateTreasure = "UpdateQuestView";
        public static UpdateTimer = "UpdateTimer";
        public static UpdateQuestList = "UpdateQuestList";
        public static UpdateQuest = "UpdateQuest";
        public static HideRefresh = "HideRefresh";
        public static ShowTip = "ShowTip";

        constructor() {
            super();
        }

        public static get inst(): QuestMgr {
            if (!QuestMgr._inst) {
                QuestMgr._inst = new QuestMgr();
            }
            return QuestMgr._inst;
        }

         public async loadQuest(force: boolean = false) {
             if (this._questList && !force) {
                 return;
             }
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_MISSION_INFO, null);
            if (result.errcode != 0) {
                console.log("quest have errcode");
                return;
            }
            let reply = pb.MissionInfo.decode(result.payload);

            this.setQuestList(reply);
            //更新主界面显示
            this.updateQuestBtn();
        }

        public updateView() {
            this.updateTreasure();
            this.updateQuestList();
        }

        public setTreasureData(treasure:any) {

            this._treasure = treasure;
            fairygui.GTimers.inst.remove(this._updateTimer, this);
            fairygui.GTimers.inst.add(1000,this._nextRemainTime,this._updateTimer,this);

            this.updateTreasure();
        }
        public setQuestList(reply: any) {
            //更新数据
            this._nextRemainTime = reply.RefreshRemainTime;
            this.setTreasureData(reply.Treasure);
            this._canRefresh = reply.CanRefresh;


            this._questList = new Collection.Dictionary<number,QuestData>();
            reply.Missions.forEach( _miss => {
                let questData = new QuestData(_miss);
                this._questList.setValue(questData.getID,questData);
            });
        }
        public setQuest(questData:any) {
            questData = questData as QuestData;
            this._questList.setValue(questData.getID,questData);
            this.dispatchEventWith(QuestMgr.UpdateQuest,false,questData);

            let showView = Core.ViewManager.inst.isShow(ViewName.questView);
            if (!showView) {
                //当不在任务界面的时候显示任务进度提示
                Core.ViewManager.inst.open(ViewName.questTipView);
                QuestMgr.inst.dispatchEventWith(QuestMgr.ShowTip,false,questData);
            }
        }
        public async showRedDot() {
            this.dispatchEventWith(QuestMgr.UpdateQuestHint,false);
        }
        public async updateQuestBtn() {
            this.dispatchEventWith(QuestMgr.UpdateQuestButton,false);
            this._questList.forEach((_index,_questData) => {
                if(_questData.getCurCnt >= Data.quest_config.get(_questData.getMissionID).process && !_questData.getIsReward) {
                    this.showRedDot();
                }
            });
        }

        private async _updateTimer() {
            this._nextRemainTime -= 1;
            QuestMgr.inst.dispatchEventWith(QuestMgr.UpdateTimer,false);
        }

        public async updateTreasure() {
            this.dispatchEventWith(QuestMgr.UpdateTreasure,false);
        }
        public async updateQuestList() {
            this.dispatchEventWith(QuestMgr.UpdateQuestList,false);
        }

        public async refreshQuest(missID: number) {
            if (!this._canRefresh) {
                return;
            }
            let result = await Net.rpcCall(pb.MessageID.C2S_REFRESH_MISSION,pb.TargetMission.encode({"ID":missID}));
            if (result.errcode != 0) {
                return;
            }

            let reply = pb.Mission.decode(result.payload)
            let questData = new QuestData(reply);
            this._canRefresh = false;
            this._questList.setValue(questData.getID,questData);
            this.dispatchEventWith(QuestMgr.UpdateQuest,false,questData);
            this.dispatchEventWith(QuestMgr.HideRefresh,false,null);

        }
        public async getQuestReward(missID: number) {
            let quest = this._questList.getValue(missID);
            if (quest.getCurCnt < Data.quest_config.get(quest.getMissionID).process) {
                return false;
            }
            let result = await Net.rpcCall(pb.MessageID.C2S_GET_MISSION_REWARD,pb.TargetMission.encode({"ID":missID}));
            if (result.errcode != 0) {
                console.log(result.errcode);
                return false;
            }
            let reward = pb.MissionReward.decode(result.payload);
            //获得奖励 只用提示
            let args = new Pvp.GetRewardData();
            args.jade = reward.Jade;
            args.gold = reward.Gold;
            args.bowlder = reward.Bowlder;
            Core.ViewManager.inst.open(ViewName.getRewardWnd, args);

            quest.setIsReward = true;
            this.dispatchEventWith(QuestMgr.UpdateQuest,false,quest);
            this.updateQuestBtn();
            this.updateTreasure();

            return true;
        }
        public async getTreasureReward() {
            let treasureLab = Data.treasure_config.get(QuestMgr.inst.getTreasureModelID);

            let result = await Net.rpcCall(pb.MessageID.C2S_OPEN_MISSION_TREASURE,null);
            if(result.errcode != 0) {
                return;
            }
            let reply = pb.OpenMissionTreasureReply.decode(result.payload);
            let treasureReward = reply.TreasureReward;

            let reward = new Treasure.TreasureReward();
            let treasureItem = new Treasure.TreasureItem(-1,this._treasure.TreasureModelID);
            reward.setRewardForOpenReply(reply.TreasureReward);

            Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward,treasureItem);

            this.setTreasureData(reply.NextTreasure);
            this.updateQuestBtn();
            this.updateTreasure();
        }

        public onWatchVideo() {
            if (!this._questList) {
                return;
            }

            let hasWatchVideoMission = false;
            this._questList.forEach((_:number, qdata:QuestData) => {
                if (qdata.type == MissionType.WatchVideo && !qdata.isComplete()) {
                    hasWatchVideoMission = true;
                }
            });

            if (hasWatchVideoMission) {
                Net.rpcPush(pb.MessageID.C2S_WATCH_OUT_VIDEO, null);
            }
        }

        public onWxShare() {
            if (!this._questList) {
                return;
            }

            let hasWxShareMission = false;
            this._questList.forEach((_:number, qdata:QuestData) => {
                if (qdata.type == MissionType.WxShare && !qdata.isComplete()) {
                    hasWxShareMission = true;
                }
            });

            if (hasWxShareMission) {
                Net.rpcPush(pb.MessageID.C2S_WXGAME_SHARE, null);
            }
        }

        get getCurCnt() {
            return this._treasure.CurCnt;
        }
        get getCompleteNum() {
            let completeNum = 0;
            this._questList.forEach((_index,_questData) => {
                if(_questData.isComplete()) {
                    completeNum += 1;
                }
            });
            return completeNum;
        }
        get getIsRewardNum() {
            let isRewardNum = 0;
            this._questList.forEach((_index,_questData) => {
                if(_questData.getIsReward) {
                    isRewardNum += 1;
                }
            });
            return isRewardNum;
        }

        get canReward() {
             this._questList.forEach((_index,_questData) => {
                if(_questData.getIsReward) {
                    return true;
                }
            });
            let _data = Data.treasure_config.get(this.getTreasureModelID);
            if(this._treasure.CurCnt >= _data.quest_unlockCnt) {
                return true;
            }
            return false;
        }

        get getCanRefresh() {
            return this._canRefresh;
        }
        get getQuestNum() {
            return this._questList.size();
        }
        get getTreasureModelID() {
            return this._treasure.TreasureModelID;
        }
        get getQuestList() {
            return this._questList;
        }
        get getQuestTimer() {
            let timerLab = `${Core.StringUtils.secToString(this._nextRemainTime, "hm")}`;
            return timerLab;
        }
        // get getIsReward() {
            // return this._treasure.IsReward;
        // }
    }

    export function init() {
        let registerView = Core.ViewManager.inst.registerConstructor.bind(Core.ViewManager.inst);
        let createObject = fairygui.UIPackage.createObject;
        registerView(ViewName.questView, () => {
            return createObject(PkgName.pvp,ViewName.questView,QuestView);
        });

        registerView(ViewName.questView, () => {
            return createObject(PkgName.pvp,ViewName.questView,QuestView);
        });

        registerView(ViewName.questTipView,() => {
            return createObject(PkgName.pvp,ViewName.questTipView,QuestTipView);
        });

        //pvp 包内的 getResourceAni 组件
        
        registerView("questGetView", () => {
            return createObject(PkgName.pvp, ViewName.resourceGetView, Shop.GetResAniWnd);
        });

        initRpc();
    }
}
