module Level {

    export class ChapterItem extends fairygui.GComponent {
        private _chapterNameTxt: fairygui.GTextField;
        private _levelList: fairygui.GList;
        private _rewardCom: ChapterRewardCom;
        private _chapterId: number;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._chapterNameTxt = this.getChild("chapterNameTxt").asTextField;
            this._levelList = this.getChild("levelList").asList;
            this._rewardCom = this.getChild("reward").asCom as ChapterRewardCom;

            this._rewardCom.y += (fairygui.GRoot.inst.getDesignStageHeight() - 800) * 0.1;

            this._rewardCom.addClickListener(this._onClickReward, this);
            this._levelList.removeItemCallback = this._onLevelItemRemove;
        }

        public canOpenTreasure(): boolean {
            return this._rewardCom.canOpen;
        }

        private _onLevelItemRemove(lvItem:fairygui.GObject) {
            lvItem.displayObject.cacheAsBitmap = false;
        }

        private async _onClickReward() {
            let cpt = LevelMgr.inst.getChapter(this._chapterId);
			let levelObjs = cpt.levelObjs;
			let levelObj = levelObjs[levelObjs.length - 1];
			let boxId = Data.level.get(levelObj.id).reward_box;
			if (this._rewardCom.canOpen) {
				let reply = await Net.rpcCall(pb.MessageID.C2S_OPEN_LEVEL_TREASURE, pb.OpenLevelTreasureArg.encode({"ChapterID": this._chapterId}));
				if (reply.errcode == 0) {
					LevelMgr.inst.onChapterTreasureOpen(this._chapterId);
					this._rewardCom.refresh(this._chapterId);
					let result = pb.OpenTreasureReply.decode(reply.payload);
					let reward = new Treasure.TreasureReward();
                    reward.setRewardForOpenReply(result);
					Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward, new Treasure.TreasureItem(-1, boxId));
                    LevelMgr.inst.subLevelHintNum();
				}
			} else {
				let cardId = Data.treasure_config.get(boxId).reward[0];
				let gold = Data.treasure_config.get(boxId).goldMin;
				//let y = (this._rewardCom.y + this._rewardCom.height);// / fairygui.GRoot.contentScaleFactor;
				Core.ViewManager.inst.open(ViewName.levelTreasureInfo, cardId, gold, this._rewardCom);
			}
        }

        public setName(chapterId:number, name:string) {
            this._chapterId = chapterId;
            this._rewardCom.refresh(this._chapterId);
            this._chapterNameTxt.text = Core.StringUtils.format(Core.StringUtils.TEXT(60087), Core.StringUtils.getZhNumber(chapterId), name);
        }

        public setLevels(levelObjs:Array<Level>) {
            this._levelList.removeChildren(0, -1, true);
            for (let i=0; i<levelObjs.length; i++) {
                let lvObj = levelObjs[i];
                let levelItem = this._levelList.addItem() as LevelItem;
                levelItem.setData(i, lvObj);
            }
        }

        public clearLevel() {
            this._levelList.removeChildren(0, -1, true);
        }
    }

}