module Level {
	export class ChapterRewardCom extends fairygui.GComponent {

		private _title: fairygui.GTextField;
		private _progressTitle: fairygui.GTextField;
		private _progressBar: fairygui.GLoader;
		private _progressBottom: fairygui.GLoader;
		private _stateCtrl: fairygui.Controller;
		private _tran0: fairygui.Transition;
		private _canOpen: boolean;

		private _chapterId: number;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._title = this.getChild("txt1").asTextField;
			this._progressTitle = this.getChild("boxProgress").asCom.getChild("text").asTextField;
			this._progressBar = this.getChild("boxProgress").asCom.getChild("bar").asLoader;
			this._progressBottom = this.getChild("boxProgress").asCom.getChild("bottom").asLoader;
			this._stateCtrl = this.getController("button");
			this._tran0 = this.getTransition("t0");

			Core.EventCenter.inst.addEventListener(GameEvent.ClearLevelEv, this._onLevelClear, this);
			Player.inst.addEventListener(Player.PvpMaxScoreChangeEvt, this._onPvpMaxScoreChange, this);

		}

		public refresh(chapterId: number) {
			this._chapterId = chapterId;
			let cpt = LevelMgr.inst.getChapter(this._chapterId);
			let levelObjs = cpt.levelObjs;
			let curLevelId = LevelMgr.inst.curLevel;
			let clearNum = 0;
			levelObjs.forEach(levelObj => {
				if (levelObj.state == LevelState.Clear) {
					clearNum ++;
				}
			});
			let unlockPvpLevel = levelObjs[0].unlockPvpLevel;
			let maxScore = Player.inst.getResource(ResType.T_MAX_SCORE);
			let pvpLevel = Pvp.PvpMgr.inst.getPvpLevel(maxScore);
			if (curLevelId < levelObjs[0].id || pvpLevel < unlockPvpLevel) {
				 // 未解锁
				 this._stateCtrl.setSelectedPage("lock");
				if (this._chapterId == 1) {
					this._title.text = Core.StringUtils.format(Core.StringUtils.TEXT(60092), Pvp.Config.inst.getPvpTitle(levelObjs[0].unlockPvpLevel));
				} else {
					this._title.text = Core.StringUtils.format(Core.StringUtils.TEXT(60175), 
							Core.StringUtils.getZhNumber(this._chapterId - 1),
							Pvp.Config.inst.getPvpTitle(levelObjs[0].unlockPvpLevel)
						);
				}
				this._progressBar.width = 0;
				this._progressTitle.text = `0/${levelObjs.length}`;
				this._tran0.stop();
				this._canOpen = false;
			} else if (curLevelId >= levelObjs[0].id && curLevelId <= levelObjs[levelObjs.length-1].id) {
				// 已解锁
				this._stateCtrl.setSelectedPage("unlock");
				let cardId = LevelMgr.inst.getChapterUnlockCardId(this._chapterId);
				if (cardId) {
					let cardResData = CardPool.CardPoolMgr.inst.getCardData(cardId, 1);
					this._title.text = Core.StringUtils.format(Core.StringUtils.TEXT(60089), cardResData.name);
				} else {
					this._title.text = "";
				}
				this._progressBar.width = clearNum / levelObjs.length * this._progressBottom.width;
				this._progressTitle.text = `${clearNum}/${levelObjs.length}`;
				this._tran0.stop();
				this._canOpen = false;
			} else {
				// 已通关
				if (LevelMgr.inst.isChapterTreasureOpen(this._chapterId)) {
					// 已领取
					this._stateCtrl.setSelectedPage("got");
					this._title.text = Core.StringUtils.TEXT(60053);
					this._progressBar.width = this._progressBottom.width;
					this._progressTitle.text = `${clearNum}/${levelObjs.length}`;
					this._tran0.stop();
					this._canOpen = false;
				} else {
					// 可领取
					this._stateCtrl.setSelectedPage("open");
					this._title.text = Core.StringUtils.TEXT(60052);
					this._progressBar.width = this._progressBottom.width;
					this._progressTitle.text = `${clearNum}/${levelObjs.length}`;
					this._tran0.play(null, null, null, -1);
					this._canOpen = true;
				}
			}
		}

		private _onLevelClear(ev:egret.Event) {
            let levelId = <number>ev.data;
            let level = LevelMgr.inst.getLevel(levelId);
            if (level) {
                if(level.chapter == this._chapterId) {
					let old = this._canOpen;
                    this.refresh(this._chapterId);
					if (!old && this._canOpen) {
						LevelMgr.inst.addLevelHintNum();
					}
                }
            }
        }

		private _onPvpMaxScoreChange() {
			this.refresh(this._chapterId);
		}

		public get canOpen(): boolean {
			return this._canOpen;
		}
	}
}