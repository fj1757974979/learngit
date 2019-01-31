module Quest {

    export class QuestView extends Core.BaseWindow {

        private _closeBtn: fairygui.GButton;
        private _questList: fairygui.GList;
        private _boxQuest: fairygui.GButton;
        private _nextTxt: fairygui.GTextField;
        private _dailyTreasure: fairygui.GTextField;
        private _dailyGold: fairygui.GTextField;

        private _boxBar: UI.MaskProgressBar;

        private _questItemList: Collection.Dictionary<number,QuestItem>;

        private _treasure: Treasure.DailyTreasureItem;
        private _treasureLab: any;

        public initUI() {

            super.initUI();

            this.center();
            this.modal = true;

            this._closeBtn = this.getChild("closeBtn").asButton;
            this._questList = this.getChild("questList").asList;
            this._boxQuest = this.getChild("questBox").asButton;
            this._dailyTreasure = this.getChild("dailyTreasure").asTextField;
            this._dailyGold = this.getChild("dailyGold").asTextField;

            this._boxBar = this._boxQuest.getChild("boxProgress") as UI.MaskProgressBar;
            this._nextTxt = this._boxQuest.getChild("nextTxt").asTextField;


            this._closeBtn.addClickListener(this._onClose,this);
            this._boxQuest.addClickListener(this._onBox,this);

            this._questList.removeChildrenToPool();
            this._questItemList = new Collection.Dictionary<number,QuestItem>();

            QuestMgr.inst.addEventListener(QuestMgr.UpdateTreasure,this._updateView,this);
            QuestMgr.inst.addEventListener(QuestMgr.UpdateQuest,this._updateQuest,this);
            QuestMgr.inst.addEventListener(QuestMgr.HideRefresh,this._hideRefresh,this);
            QuestMgr.inst.addEventListener(QuestMgr.UpdateQuestList,this._updateQuestList,this);
            // QuestMgr.inst.addEventListener(QuestMgr.UpdateTimer,this._updateTimer,this);

            // Player.inst.addEventListener(Player.ResUpdateEvt, this._onResUpdate, this);
        }

        private _updateTimer() {
            this._nextTxt.text = QuestMgr.inst.getQuestTimer;
        }

        private _updateView() {
            this._treasureLab = Data.treasure_config.get(QuestMgr.inst.getTreasureModelID);

            let _curCnt = QuestMgr.inst.getCurCnt;
            let total = this._treasureLab.quest_unlockCnt;
            this._boxBar.setProgress(_curCnt,total);
            this._boxBar.getChild("text").text = `${_curCnt}/${total}`;
            this._boxQuest.getChild("txt1").text = Core.StringUtils.format(Core.StringUtils.TEXT(60218), total);
            this._boxQuest.getChild("boxName").text = this._treasureLab.title;

            let treasure1 = new Treasure.TreasureItem(-1, QuestMgr.inst.getTreasureModelID);
            this._treasure = treasure1 as Treasure.DailyTreasureItem;
            this._boxQuest.getChild("boxIcon").asLoader.url = treasure1.image;
            if (_curCnt >= total) {
                this._boxQuest.getChild("boxIconBg").asLoader.visible = true;
            } else {
                this._boxQuest.getChild("boxIconBg").asLoader.visible = false;
            }
        }

        //更新整个任务列表
        private async _updateQuestList() {
            let questList = QuestMgr.inst.getQuestList;
            this._questList.removeChildrenToPool();
            this._questItemList = new Collection.Dictionary<number,QuestItem>();
            let arrayQuest = new Array<QuestData>();

            questList.forEach((_index,_questdata) => {
                arrayQuest.push(_questdata);
            });

            for(let i = 0; i < arrayQuest.length; i ++) {
                await this._setQuest(arrayQuest[i]);
            }
        }
        //更新某个任务
        private async _updateQuest(evt: egret.Event) {
            let questData = evt.data as QuestData;
            this._setQuest(questData);
        }
        private async _setQuest(questData: QuestData) {
            if (!this._questItemList.containsKey(questData.getID)) {
                let questItem = this._questList.addItemFromPool() as QuestItem;
                this._questItemList.setValue(questData.getID,questItem);
                // questItem.setQuest(questData);
            }
            await this._questItemList.getValue(questData.getID).setQuest(questData);
            await this._questItemList.getValue(questData.getID).playTrans();
        }


        private _hideRefresh() {
            this._questItemList.forEach((_,questItem) => {
                questItem.hideRefreshBtn();
            })
        }

        private _onBox() {
            if (QuestMgr.inst.getCurCnt < this._treasureLab.quest_unlockCnt) {
            //查看宝箱内容
            Core.ViewManager.inst.open(ViewName.dailyTreasureInfo, this);
            return;
            }
            QuestMgr.inst.getTreasureReward();
        }

        public async open(...param:any[]) {
            super.open(...param);
            this._onResUpdate();
        }

        public async colse(...param:any[]) {
            super.close(...param);
        }

        private _onClose() {
            Core.ViewManager.inst.closeView(this);
        }

        public get treasure(): Treasure.DailyTreasureItem {
			return this._treasure;
		}

        private _onResUpdate() {
            let maxTreasure = 24;
            if (Player.inst.hasPrivilege(Priv.REWARD_ADD_TREASURE)) {
                maxTreasure += 2;
            }
            this._dailyGold.text = Core.StringUtils.format(Core.StringUtils.TEXT(70123), Player.inst.getResource(ResType.PvpTreasureCnt), maxTreasure);
            this._dailyTreasure.text = Core.StringUtils.format(Core.StringUtils.TEXT(70122), Player.inst.getResource(ResType.PvpGoldCnt), 24);
        }
    }
}
