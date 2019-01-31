module Quest {
    export class QuestTipItem extends fairygui.GComponent {

        private _questObj: QuestData;

        private _questBar: UI.MaskProgressBar;
        private _questTitle: fairygui.GTextField;
        private _questText: fairygui.GTextField;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);

            this._questBar = this.getChild("boxProgress") as UI.MaskProgressBar;
            this._questText  = this.getChild("text").asTextField;
            this._questTitle = this.getChild("title").asTextField;

        }

        public setQuest(questObj: QuestData) {
            this._questObj = questObj;
            let missionLab = Data.quest_config.get(questObj.getMissionID);
            if (questObj.getCurCnt >= missionLab.process) {
                this._questBar.getChild("text").text = Core.StringUtils.TEXT(60052);
                this._questBar.getChild("text").asTextField.color = 0x66ff00;
                this._questBar.getChild("bar").asLoader.url = "common_barGreen_png";
            } else {
                this._questBar.getChild("text").text = questObj.getCurCnt + "/" + missionLab.process;
                this._questBar.getChild("text").asTextField.color = 0xffffff;
                this._questBar.getChild("bar").asLoader.url = "common_barYellow_png";
            }
            this._questBar.setProgress(questObj.getCurCnt,missionLab.process);
            this.getChild("text").text = missionLab.text;
            this.getChild("title").text = missionLab.title;
            this.getTransition("entry").play();
        }

        public get getID() {
            return this._questObj.getID;
        }
    }
}