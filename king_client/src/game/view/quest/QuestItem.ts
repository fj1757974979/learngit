module Quest {
    export class QuestItem extends fairygui.GComponent {
        private _questObj: QuestData;

        private _questBar: UI.MaskProgressBar;
        private _questName: fairygui.GTextField;
        private _rewardNum: fairygui.GTextField;
        private _refreshBtn: fairygui.GButton;
        private _rewardIcon: fairygui.GLoader;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);

            this._refreshBtn = this.getChild("refreshBtn").asButton;
            // this._questBtn = this.getChild("questBtn").asButton;

            this._questBar = this.getChild("boxProgress") as UI.MaskProgressBar;
            this._rewardNum = this.getChild("rewardCnt2").asTextField;
            this._rewardIcon = this.getChild("rewardIcon1").asLoader;

            //view init
            this._refreshBtn.visible = false;

            this.addClickListener(this._completeQuest,this);
            this._refreshBtn.addClickListener(this._refreshQuest,this);            
        }

        private _completeQuest() {
                // 发送获取奖励
               let _play = QuestMgr.inst.getQuestReward(this._questObj.getID);
               _play.then(res =>{
                    if(res) {
                   this.getTransition("t0").play();
                    }
                });               
        }

        private _refreshQuest() {
            Core.TipsUtils.confirm(Core.StringUtils.TEXT(60245), ()=> {
                QuestMgr.inst.refreshQuest(this._questObj.getID);
            }, null, this);
        }

        private _getMissionIcon(missionLab: any) {
            if (window.gameGlobal.channel == "lzd_handjoy") {
                return Reward.RewardMgr.inst.getRewardIcon(Reward.RewardType.T_BOWLDER);
            } else {
                return Reward.RewardMgr.inst.getRewardIcon(Reward.RewardType.T_JADE);
            }
        }

        private _getMissionRewardNum(missionLab: any) {
            if (window.gameGlobal.channel == "lzd_handjoy") {
                return missionLab.bowlder;
            } else {
                return missionLab.jade;
            }
        }

        public setQuest(questObj: QuestData) {
            this._questObj = questObj;

            let missionLab = Data.quest_config.get(questObj.getMissionID);
            this._questBar.setProgress(questObj.getCurCnt,missionLab.process);
            if (questObj.getCurCnt >= missionLab.process) {
                this._refreshBtn.visible = false;
                this._questBar.getChild("text").text = Core.StringUtils.TEXT(60052);
                this._questBar.getChild("text").asTextField.color = 0x66ff00;
                this._questBar.getChild("bar").asLoader.url = "common_barGreen_png"; 
            } else {
                this._questBar.getChild("text").text = questObj.getCurCnt + "/" + missionLab.process;
                this._questBar.getChild("text").asTextField.color = 0xffffff;
                this._questBar.getChild("bar").asLoader.url = "common_barYellow_png"; 
                this._refreshBtn.visible = QuestMgr.inst.getCanRefresh;
            }
            this._rewardIcon.url = this._getMissionIcon(missionLab);
            this.getChild("text").text = missionLab.text;
            this.getChild("title").text = missionLab.title;
            this.getChild("rewardCnt2").text = this._getMissionRewardNum(missionLab);
            if (questObj.getIsReward) {
                this.getController("c1").selectedIndex = 1;
                this._refreshBtn.visible = false;
                this._questBar.getChild("bar").asLoader.url = "common_barGrey_png"; 
                this.touchable = false;
            } else {
                this.touchable = true;
                this.getController("c1").selectedIndex = 0;
                //任务完成禁止切换
            }
        }

        public async playTrans() {
            await new Promise<void>(resolve => {
                this.getTransition("t1").play(() => {
                    resolve();
                });
            });
        }

        public hideRefreshBtn() {
            this._refreshBtn.visible = false;
        }

    }
}