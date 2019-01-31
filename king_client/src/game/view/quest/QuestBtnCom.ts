module Quest {
    export class QuestBtnCom extends fairygui.GButton {
        private _inst: QuestBtnCom;

        private _completeBar: UI.MaskProgressBar;
        private _hint: fairygui.GComponent;
        private _boxIcon: fairygui.GLoader;
        private _nextTxt: fairygui.GTextField;
        
        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);

            this._completeBar = this.getChild("boxProgress") as UI.MaskProgressBar;
            this._completeBar.setProgress(0,0); 
            this._boxIcon = this.getChild("treasureIcon").asLoader;
            this._nextTxt = this.getChild("nextTxt").asTextField;
            this._hint = this.getChild("hint").asCom;
            this._hint.getChild("textNum").text = "";
            this._hint.visible = false;

            this.addClickListener(this._onQuest,this);
            Quest.QuestMgr.inst.addEventListener(QuestMgr.UpdateQuestButton,this._updateQuestBtn,this);
            Quest.QuestMgr.inst.addEventListener(QuestMgr.UpdateQuestHint,this._showRedDot,this);
            Quest.QuestMgr.inst.addEventListener(QuestMgr.UpdateTimer,this._updateTimer,this);
        }

        private _updateQuestBtn(evt: egret.Event) {
            this._setQuestBtn();
        }

        private _updateTimer() {            
            this._nextTxt.text = QuestMgr.inst.getQuestTimer;
        }

        private _setQuestBtn() {
            let treasureLab = Data.treasure_config.get(QuestMgr.inst.getTreasureModelID);
            let completeNum = QuestMgr.inst.getCompleteNum;
            let total = QuestMgr.inst.getQuestNum;
            let rewardNum = QuestMgr.inst.getIsRewardNum;
            let isReward = (rewardNum >= total);

            if (QuestMgr.inst.canReward) {
                this.getChild("bottom").asLoader.url = "pvp_functionBottom2_png";
                this._hint.visible = true;
            } else {
                this.getChild("bottom").asLoader.url = "pvp_functionBottom_png";
                this._hint.visible = false;
            }
            this._completeBar.getChild("text").text = `${completeNum}/${total}`;
            
            if (isReward) {
                this._boxIcon.grayed = true;
                this._nextTxt.visible = true;
                this._completeBar.visible = false;
            } else {
                this._boxIcon.grayed = false;
                this._nextTxt.visible = false;
                this._completeBar.visible = true;
            }           
            this._completeBar.setProgress(completeNum,total);
        }

        private _showRedDot() {
            this._hint.visible = true;
        }

        private async _onQuest() {
            await QuestMgr.inst.loadQuest();
            Core.ViewManager.inst.open(ViewName.questView);
            QuestMgr.inst.updateView();
        }
    } 
}