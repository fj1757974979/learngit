module War {

    export class WarQuest {
        public static warMsType2reward(type: WarMsType) {
            switch(type) {
                case WarMsType.Irrigation:
                    return Data.parameter.get("task_target_irrigation").para_value[0];
                case WarMsType.Trade:
                    return Data.parameter.get("task_target_trade").para_value[0];
                case WarMsType.Build:
                    return Data.parameter.get("task_target_build").para_value[0];
                default:
                return 0;
            }
        }
        //政令奖励战功系数
        public static warMsType2contribution(type: WarMsType) {
            switch(type) {
                case WarMsType.Irrigation:
                    return Data.parameter.get("irrigation_vic").para_value[0];
                case WarMsType.Trade:
                    return Data.parameter.get("trade_vic").para_value[0];
                case WarMsType.Build:
                    return Data.parameter.get("build_vic").para_value[0];
                case WarMsType.Transport:
                    return Data.parameter.get("transport_vic").para_value[0];
                default:
                return 0;
            }
        }

        public static warMsPower2text(type: WarMsType) {
            switch(type) {
                case WarMsType.Irrigation:
                    return Core.StringUtils.TEXT(70327);
                case WarMsType.Trade:
                    return Core.StringUtils.TEXT(70328);
                case WarMsType.Build:
                    return Core.StringUtils.TEXT(70329);
                default:
                return "";
            }
        }
    }

    export class WarQuestItem extends fairygui.GButton {
        private _titleText: fairygui.GTextField;
        private _suggestText: fairygui.GTextField;
        private _descText: fairygui.GTextField;
        private _rewardCnt1Text: fairygui.GTextField;
        private _rewardCnt2Text: fairygui.GTextField;
        private _rewardCnt3Text: fairygui.GTextField;
        private _rewardIcon1: fairygui.GLoader;
        private _rewardIcon2: fairygui.GLoader;
        private _rewardIcon3: fairygui.GLoader;
        private _bg: fairygui.GLoader;
        // private _acceptBtn: fairygui.GButton;
        private _type: WarMsType;
        private _toCity: number;
        private _mission: pb.ICampaignMission;
        private _hasCurQuest: boolean;
        protected constructFromXML(xml: any): void {
            this._titleText = this.getChild("title").asTextField;
            this._suggestText = this.getChild("suggest").asTextField;
            this._descText = this.getChild("text").asTextField;
            this._rewardCnt1Text = this.getChild("rewardCnt1").asTextField;
            this._rewardCnt2Text = this.getChild("rewardCnt2").asTextField;
            this._rewardCnt3Text = this.getChild("rewardCnt3").asTextField;
            this._rewardIcon1 = this.getChild("rewardIcon1").asLoader;
            this._rewardIcon2 = this.getChild("rewardIcon2").asLoader;
            this._rewardIcon3 = this.getChild("rewardIcon3").asLoader;
            this._bg = this.getChild("bg").asLoader;
            this.addClickListener(this._onAcceptBtn, this);
            // this._acceptBtn = this.getChild("acceptBtn").asButton;
            // this._acceptBtn.addClickListener(this._onAcceptBtn, this);
        }
        public async setInfo(info: pb.ICampaignMission, hasQuest: boolean) {
            this._mission = info;
            let c = <number>info.Type;
            this._type = <WarMsType>c;
            this._suggestText.text = WarQuest.warMsPower2text(this._type);
            this._descText.text = `${Utils.warMsDesc2text(this._type)}`
            this._rewardIcon3.url = Utils.warMsType2Url(this._type).toString();
            this._bg.url = Utils.warMsBgType2Url(this._type).toString();
            if (this._type == WarMsType.Transport) {
                // let roadDis = this._mission.TransportMaxTime / Data.parameter.get("transport_time").para_value[0];
                // let contNum = roadDis * WarQuest.warMsType2contribution(this._type);
                this._titleText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70232),Utils.warTranType2text(info.TransportType),CityMgr.inst.getCity(info.TransportTargetCity).cityName);
                //this._descText.text = `时间：${Core.StringUtils.secToString(info.TransportMaxTime, "hm")}`;
                this._setReward2(true);
                this._setReward3(false);
            } else if (this._type == WarMsType.Dispatch) {
                this._titleText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70233), CityMgr.inst.getCity(info.TransportTargetCity).cityName);
                this._setReward2(false);
                this._setReward3(false);
            } else {
                this._titleText.text = Utils.warMsType2text(this._type);
                //this._descText.text = `时间：${Core.StringUtils.secToString(Utils.warMsType2time(this._type), "hm")}`;   
                this._setReward2(true);
                this._setReward3(true);
            }
            this._rewardCnt1Text.text = info.GoldReward.toString();
            this._hasCurQuest = hasQuest;
            // this._acceptBtn.visible = !hasQuest;
        }
        private _setReward2(bool: boolean){
            this._rewardCnt2Text.visible = bool;
            this._rewardIcon2.visible = bool;
            if (bool) {
                this._rewardCnt2Text.text = `${this._mission.Contribution}`;
            }
        }

        private _setReward3(bool: boolean) {
            this._rewardCnt3Text.visible = bool;
            this._rewardIcon3.visible = bool;
            if (bool) {
                this._rewardCnt3Text.text = `+${WarQuest.warMsType2reward(this._type)}`;
            }
        }
        private async _onAcceptBtn() {
            if (WarMgr.inst.checkWarIsOver()) {
                return;
            }
            // let args = {Type: this._type, }
            // let result = await Net.rpcCall(pb.MessageID.C2S_ACCEPT_CAMPAIGN_MISSION, pb.AcceptCampaignMissionArg.encode(args));
            if (this._hasCurQuest) {
                Core.TipsUtils.showTipsFromCenter("当前尚有任务在执行中");
                return;
            }
            if (MyWarPlayer.inst.isKickOut) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70330));
                return;
            }
            if (this._type == WarMsType.Dispatch) {
                let jobDesc = "";
                if (MyWarPlayer.inst.employee.hasCityOfficialTitle()) {
                    jobDesc = Core.StringUtils.format(Core.StringUtils.TEXT(70331), MyWarPlayer.inst.employee.cityJob.name);
                }
                Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70332), CityMgr.inst.getCity(MyWarPlayer.inst.cityID).cityName, CityMgr.inst.getCity(this._mission.TransportTargetCity).cityName, jobDesc),
                    () => {
                        this._onAcceptMove();
                    },null, this)
            } else {
                Core.ViewManager.inst.open(ViewName.questChooseCardWnd, this._mission);
            }
        }
        private async _onAcceptMove() {
            let args = {Type: this._mission.Type, Cards: null, TransportTargetCity: this._mission.TransportTargetCity};
            let result = await Net.rpcCall(pb.MessageID.C2S_ACCEPT_CAMPAIGN_MISSION, pb.AcceptCampaignMissionArg.encode(args));
            if (result.errcode == 0) {
                if (this._mission.GoldReward > 0 || this._mission.Contribution > 0) {
                    let getRewardData = new Pvp.GetRewardData();
                    getRewardData.gold = this._mission.GoldReward;
                    getRewardData.contribution = this._mission.Contribution;
                    Core.ViewManager.inst.open(ViewName.getRewardWnd, getRewardData);
                }
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70333), CityMgr.inst.getCity(this._mission.TransportTargetCity).cityName));
                Core.ViewManager.inst.close(ViewName.warQuestPanel);
            }
        }
    }

    export class CurQuestCom extends fairygui.GComponent {
        private _statusCtr: fairygui.Controller;
        private _timeBar: UI.MaskProgressBar;
        private _titleText: fairygui.GTextField;
        private _timeText: fairygui.GTextField;
        private _card1Com: WarCardHeadCom;
        private _card2Com: WarCardHeadCom;
        private _card3Com: WarCardHeadCom;
        private _card4Com: WarCardHeadCom;
        private _card5Com: WarCardHeadCom;
        private _cardList: WarCardHeadCom[];
        private _completeBtn: fairygui.GButton;
        private _cancelBtn: fairygui.GButton;
        private _rewardCnt1Text: fairygui.GTextField;
        private _rewardCnt2Text: fairygui.GTextField;
        private _rewardCnt3Text: fairygui.GTextField;
        private _rewardIcon1: fairygui.GLoader;
        private _rewardIcon2: fairygui.GLoader; 
        private _rewardIcon3: fairygui.GLoader; 
        private _callBack: any;
        private _remainTime: number;
        private _maxTime: number;

        private _type: WarMsType; 
        private _gold: number;
        private _contribution: number;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._statusCtr = this.getController("status");
            this._timeBar = this.getChild("boxProgress").asCom as UI.MaskProgressBar;
            this._titleText = this.getChild("title").asTextField;
            this._timeText = this.getChild("time").asTextField;
            this._card1Com = this.getChild("card1").asCom as WarCardHeadCom;
            this._card2Com = this.getChild("card2").asCom as WarCardHeadCom;
            this._card3Com = this.getChild("card3").asCom as WarCardHeadCom;
            this._card4Com = this.getChild("card4").asCom as WarCardHeadCom;
            this._card5Com = this.getChild("card5").asCom as WarCardHeadCom;
            this._cardList = [this._card1Com, this._card2Com, this._card3Com, this._card4Com, this._card5Com];
            this._rewardCnt1Text = this.getChild("rewardCnt1").asTextField;
            this._rewardIcon1 = this.getChild("rewardIcon1").asLoader;
            this._rewardCnt2Text = this.getChild("rewardCnt2").asTextField;
            this._rewardIcon2 = this.getChild("rewardIcon2").asLoader;
            this._rewardCnt3Text = this.getChild("rewardCnt3").asTextField;
            this._rewardIcon3 = this.getChild("rewardIcon3").asLoader;
            this._cancelBtn = this.getChild("cancelBtn").asButton;
            this._completeBtn = this.getChild("completeBtn").asButton;

            this._cancelBtn.addClickListener(this._onCancelBtn, this);
            this._completeBtn.addClickListener(this._onGetRewardBtn, this);
        }

        public async setInfo(questInfo: pb.IExecutingCampaignMission) {
            if (questInfo) {
                this._statusCtr.selectedIndex = 0;
                this.visible = true;
                this._maxTime = questInfo.MaxTime;
                this._remainTime = questInfo.RemainTime;
                this._gold = questInfo.GoldReward;
                this._contribution = questInfo.Contribution;
                this._setType(questInfo.Type);
                
                this._setCard(questInfo.Cards);
                this._questTimerStart();
            } else {
                this.visible = false;
                this._statusCtr.selectedIndex = 0;
            }
        }
        public setCallBack(callBack: any) {
            this._callBack = callBack;
        }
        private _questComplete(bool: boolean) {
            this._completeBtn.visible = bool;
            this._cancelBtn.visible = !bool;
            if (bool) {
                this._timeText.text = Core.StringUtils.TEXT(70334);
                this._timeBar.setProgress(this._maxTime, this._maxTime);
            }
        }
        public async getNewMission(mission: pb.ICampaignMission, remainTime: number, cards:number[]) {
            this._statusCtr.selectedIndex = 0;
            this.visible = true;
            this._remainTime = remainTime;
            this._maxTime = remainTime;
            this._gold = mission.GoldReward;
            this._contribution = mission.Contribution;
            this._setType(mission.Type);
            
            this._questTimerStart();
            this._setCard(cards);
        }
        private _setType(type: any) {
            this._type = <WarMsType>type;
            this._rewardCnt1Text.text = this._gold.toString();
            if (this._type == WarMsType.Transport) {
                this._titleText.text = `${Utils.warMsType2text(this._type)}`;
                this._setReward2(true);
                this._setReward3(false);
                // let roadDis = this._maxTime / Data.parameter.get("transport_time").para_value[0];
                // let contNum = roadDis * WarQuest.warMsType2contribution(this._type);
            } else if (this._type == WarMsType.Dispatch) {
                this._titleText.text = `${Utils.warMsType2text(this._type)}`;
                this._setReward2(false);
                this._setReward3(false);
            } else {
                this._titleText.text = Utils.warMsType2text(this._type);
                this._setReward2(true);
                this._setReward3(true);
            }            
        }
        private _setReward2(bool: boolean) {
            this._rewardCnt2Text.visible = bool;
            this._rewardIcon2.visible = bool;
            if (bool) {
                this._rewardCnt2Text.text = `${this._contribution}`;
            }
        }
        private _setReward3(bool: boolean) {
            this._rewardCnt3Text.visible = bool;
            this._rewardIcon3.visible = bool;
            if (bool) {
                this._rewardCnt3Text.text = `+${WarQuest.warMsType2reward(this._type)}`;
                this._rewardIcon3.url = Utils.warMsType2Url(this._type).toString();
            }
        }
        private _setCard(cards: number[]) {
            for (let i = 0; i < this._cardList.length; i++) {
                if (i < cards.length) {
                    this._cardList[i].visible = true;
                    this._cardList[i].setInfo(cards[i]);
                } else {
                    this._cardList[i].visible = false;
                }
            }
        }
        private async _onGetRewardBtn() {
            let result = await Net.rpcCall(pb.MessageID.C2S_GET_CAMPAIGN_MISSION_REWARD, null);
            if (result.errcode == 0) {
                //获得奖励
                this._statusCtr.selectedIndex = 0;
                this.visible = false;
                if (this._callBack) {
                    this._callBack();
                }
                if (this._gold > 0 || this._contribution > 0) {
                    let getRewardData = new Pvp.GetRewardData();
                    getRewardData.gold = this._gold;
                    getRewardData.contribution = this._contribution;
                    Core.ViewManager.inst.open(ViewName.getRewardWnd, getRewardData);
                }
                
            }
        }
        private _questTimerStart() {
            if (this._remainTime > 0) {
                this._timeText.text = Core.StringUtils.secToString(this._remainTime, "hms");
                this._timeBar.setProgress(this._maxTime - this._remainTime, this._maxTime);
                this.questTimerStop();
                this._questComplete(false);
                fairygui.GTimers.inst.add(1000, -1, this._questTimer, this);
            } else {
                this._questComplete(true);
                this.questTimerStop();
            }            
        }
        private _questTimer() {
            if (this._remainTime <= 0) {
                this.questTimerStop();
                this._questComplete(true);
            } else {
                this._timeText.text = Core.StringUtils.secToString(this._remainTime, "hms");
                this._timeBar.setProgress(this._maxTime - this._remainTime, this._maxTime);
            }
            this._remainTime -= 1;
        }
        public questTimerStop() {
            fairygui.GTimers.inst.remove(this._questTimer, this);
        }
        private async _onCancelBtn() {
            Core.TipsUtils.confirm(Core.StringUtils.TEXT(70335) , this._onCancel, null, this);
        }
        private async _onCancel() {
            let result = await Net.rpcCall(pb.MessageID.C2S_CANCEL_CAMPAIGN_MISSION, null);
            if (result.errcode == 0) {
                let reply = pb.CampaignMissionInfo.decode(result.payload);
                this._statusCtr.selectedIndex = 0;
                this.visible = false;
                this.questTimerStop();
                if (this._callBack) {
                    this._callBack();
                }
                let view = Core.ViewManager.inst.getView(ViewName.warQuestPanel) as WarQuestWnd;
                view.refesh(reply.Missions);
            }
        }
    }
    
    export class WarQuestWnd extends Core.BaseWindow {

        private _cityID: number;
        private _curQuestCom: CurQuestCom;
        private _questList: fairygui.GList;
        private _emptyHint: fairygui.GTextField;
        private _closeBtn: fairygui.GButton;
        private _hasquest: boolean;
        private _missions: pb.ICampaignMission[];
        private _missionComs: WarQuestItem[];

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;
            
            this._questList = this.contentPane.getChild("questList").asList;
            this._questList.foldInvisibleItems = true;

            this._curQuestCom = fairygui.UIPackage.createObject(PkgName.war, "questStatus").asCom as CurQuestCom;
            this._curQuestCom.setCallBack(() => {this._cancelBtn()});
            this._questList.addChild(this._curQuestCom);
            this._closeBtn =  this.contentPane.getChild("closeBtn").asButton;
            this._emptyHint = this.contentPane.getChild("emptyHint").asTextField;
            
            this._closeBtn.addClickListener(this._onClose, this);
        }

        private async _onClose() {
            this._curQuestCom.questTimerStop();
            Core.ViewManager.inst.closeView(this);
        }
        
        public async open(...param: any[]) {
            super.open(...param);

            this._cityID = param[0];
            let missionInfo = param[1] as pb.CampaignMissionInfo;
            this._curQuestCom.setInfo(missionInfo.ExecutingMission);
            if (missionInfo.ExecutingMission) {
                this._hasquest = true;
            } else {
                this._hasquest = false;
            }
            this._missions = missionInfo.Missions;
            this._emptyHint.visible = (this._missions.length <= 0);
            this.refesh();
        }
        public refesh(missions?: pb.ICampaignMission[]) {
            if (missions) {
                this._missions = missions;
            }
            // if (this._questList.numItems > 1) {
            //     for (let i = this._questList.numItems - 1; i > 0; i--) {
            //         this._questList.removeChildAt(i);
            //     }
            // }
            this._questList.removeChildren(1, -1, true);
            let arr: Array<pb.CampaignMission> = [];
            this._missions.forEach (mission => {
                arr.push(<pb.CampaignMission>mission);
            });
            arr = arr.sort((m1: pb.CampaignMission, m2: pb.CampaignMission) => {
                if (m1.GoldReward > m2.GoldReward) {
                    return -1;
                } else if (m1.GoldReward < m2.GoldReward) {
                    return 1;
                } else {
                    if (m1.Type > m2.Type) {
                        return -1;
                    } else {
                        return 1;
                    }
                }
            });
            arr.forEach(mission => {
                let com = fairygui.UIPackage.createObject(PkgName.war, "questItem").asCom as WarQuestItem;
                com.setInfo(mission, this._hasquest);
                this._questList.addChild(com);
            });
        }
        public async getNewMission(mission: pb.ICampaignMission, remainTime: number, cards:number[]) {
            this._curQuestCom.getNewMission(mission, remainTime, cards);
            this._hasquest = true;
            // this.refesh(this._missions);
        }
        // public async refeshCurMission(newMission: pb.IExecutingCampaignMission) {
        //     this._curQuestCom.setInfo(newMission);
        // }
        private async _cancelBtn() {
            this._hasquest = false;
            this.refesh();
        }

        public async close(...param: any[]) {
            super.close(...param);
            this._curQuestCom.questTimerStop();
            this._questList.removeChildren(1, -1, true);
        }
    }
}