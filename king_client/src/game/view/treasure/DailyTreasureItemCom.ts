module Treasure {

	export class DailyTreasureItemCom extends fairygui.GComponent {

		private _starProgressBar: UI.MaskProgressBar;;
		private _treasureImg: fairygui.GLoader;
		private _nextTimeText: fairygui.GTextField;
		private _starImg: fairygui.GLoader;
		private _starImg2: fairygui.GLoader;
		private _boxWnd: fairygui.GLoader;
		private _tran0: fairygui.Transition;

		private _treasure: DailyTreasureItem;

		private _clickTrans: fairygui.Transition;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._starProgressBar = this.getChild("starProgress") as UI.MaskProgressBar;
			this._starProgressBar.setProgress(0,0);
			this._treasureImg = this.getChild("treasureIcon").asLoader;
			this._nextTimeText = this.getChild("nextTxt").asTextField;
			this._starImg = this.getChild("starIcon").asLoader;
			this._starImg2 = this.getChild("starIcon2").asLoader;
			this._boxWnd = this.getChild("boxWnd").asLoader;
			this._tran0 = this.getTransition("t0");
			this._clickTrans = this.getTransition("t1");

			this._nextTimeText.text = "";

			this.addClickListener(this._onClick, this);
			this.addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onTouchBegin, this);
		}

		public refresh(dailyTreasure: DailyTreasureItem) {
			this._treasure = dailyTreasure;
			if (this._treasure.isOpen) {
				// 等待刷新新宝箱
				let rareType = this._treasure.getRareType();
				this._starProgressBar.visible = false;
				this._treasureImg.url = "treasure_box0_png";
				//this._treasureImg.url = `treasure_box${rareType}_png`;
				//this._treasureImg.grayed = true;
				this._nextTimeText.visible = true;
				this._starImg.visible = false;
				this._starImg2.visible = false;
				this._boxWnd.url = "pvp_functionBottom_png";
				fairygui.GTimers.inst.add(1000, this._treasure.nextTime, this._execCountDown, this);
				this._tran0.stop();
			} else if (this._treasure.canOpen()) {
				// 可以开启
				fairygui.GTimers.inst.remove(this._execCountDown, this);
				let rareType = this._treasure.getRareType();
				this._starProgressBar.visible = false;
				this._treasureImg.url = `treasure_box${rareType}_png`;
				this._treasureImg.grayed = false;
				this._nextTimeText.visible = true;
				this._nextTimeText.text = Core.StringUtils.TEXT(60052);
				this._starImg.visible = false;
				this._starImg2.visible = false;
				this._boxWnd.url = "pvp_functionBottom2_png";
				this._setProgress();
				this._tran0.play(null, null, null, -1);
			} else {
				// 进度中
				fairygui.GTimers.inst.remove(this._execCountDown, this);
				let rareType = this._treasure.getRareType();
				this._starProgressBar.visible = true;
				this._treasureImg.url = `treasure_box${rareType}_png`;
				this._treasureImg.grayed = false;
				this._nextTimeText.visible = false;
				this._starImg.visible = true;
				this._starImg2.visible = true;
				this._boxWnd.url = "pvp_functionBottom_png";
				this._setProgress();
				this._tran0.stop();
			}
		}

		private _setProgress() {
			let total = this._treasure.totalStarCount;
			let rest = this._treasure.openStarCount;
			let has = total - rest;
			this._starProgressBar.getChild("text").asTextField.text = `${has}/${total}`;
			this._starProgressBar.setProgress(has,total);
		}

		private _execCountDown() {
			let nextTime = this._treasure.nextTime;
			if (nextTime > 0) {
				this._treasure.nextTime = nextTime - 1;
				this._nextTimeText.text = `${Core.StringUtils.secToString(nextTime, "hm")}`;
			}
		}

		private async _onClick() {
			if (this._treasure && !this._treasure.isOpen) {
				if (this._treasure.canOpen()) {
					let openCallback = async () => {
						// 开启
						let reward = await TreasureMgr.inst().openTreasure(this._treasure.id);
						if (!reward) {
							console.debug(`openTreasure fail, id=${this._treasure.id}, t=${this._treasure.type}`);
							return;
						}
						console.debug("TreasureItemCom _onClick get reward done");
						TreasureMgr.inst().popTreasure(this._treasure.id);
						// new Treasure.TreasureItem(-1, "");
						Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward, this._treasure);
					}
					Core.ViewManager.inst.open(ViewName.dailyTreasureDouble, this._treasure, openCallback);
				} else {
					// 查看
					Core.ViewManager.inst.open(ViewName.dailyTreasureInfo, this);
				}
			} else {
				let hint = Core.StringUtils.format(Core.StringUtils.TEXT(60160), Core.StringUtils.secToString(this._treasure.nextTime, "hm"));
				SoundMgr.inst.playSoundAsync("click_mp3");
			}
		}

		private _onTouchBegin() {
			if (this._boxWnd) {
				this._clickTrans.play();
			}
		}
		
		public get treasure(): DailyTreasureItem {
			return this._treasure;
		}
	}
}