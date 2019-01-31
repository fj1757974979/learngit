module Treasure {
	
	export class TreasureItemCom extends fairygui.GComponent {
		private _readyOpenBg: fairygui.GLoader;
		private _canOpenBg: fairygui.GLoader;
		private _treasureImg: fairygui.GLoader;
		private _nameText: fairygui.GTextField;
		private _openBtn: fairygui.GButton;
		private _openTimeText: fairygui.GTextField;
		private _boxWnd: fairygui.GLoader;
		private _jadeIcon: fairygui.GLoader;
		private _jadeText: fairygui.GTextField;
		private _jadeCnt: fairygui.GTextField;
		private _jadeBg: fairygui.GLoader;

		private _treasure: TreasureItem;

		private _clickTrans: fairygui.Transition;
		private _activateTrans: fairygui.Transition;
		private _pos: number;

		private _openFlag: boolean = false;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			this._readyOpenBg = this.getChild("readyOpenBg").asLoader;
			this._canOpenBg = this.getChild("canOpenBg").asLoader;
			this._treasureImg = this.getChild("teasureImg").asLoader;
			this._nameText = this.getChild("nameText").asTextField;
			this._openBtn = this.getChild("openBtn").asButton;
			this._openTimeText = this.getChild("openTimeText").asTextField;
			this._boxWnd = this.getChild("boxWnd").asLoader;
			this._jadeIcon = this.getChild("jadeIcon").asLoader;
			this._jadeText = this.getChild("jadeText").asTextField;
			this._jadeCnt = this.getChild("jadeCnt").asTextField;
			this._jadeBg = this.getChild("jadeBg").asLoader;

			if (!LanguageMgr.inst.isChineseLocale()) {
				this._openTimeText.fontSize = 12;
			}

			this._clickTrans = this.getTransition("t3");
			this._activateTrans = this.getTransition("t4");

			this.addClickListener(this._onClick, this);
			this.addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onTouchBegin, this);
			Core.EventCenter.inst.addEventListener(Core.Event.ReLoginEv, this._onRelogin, this);

			this._treasure = null;
		}

		private _onRelogin() {
			fairygui.GTimers.inst.remove(this._execCountDown, this);
		}

		public get pos(): number {
			return this._pos;
		}

		public set pos(p: number) {
			this._pos = p;
		}

		public hideContent() {
			this._readyOpenBg.visible = false;
			this._canOpenBg.visible = false;
			this._treasureImg.visible = false;
			this._nameText.visible = false;
			this._openBtn.visible = false;
			this._openTimeText.visible = false;
		}

		public get treasure() {
			return this._treasure;
		}

		public refresh(treasure: TreasureItem) {
			this._treasure = treasure;
			this._resetUI();
			this._jadeCnt.visible = false;
			this._jadeIcon.visible = false;
			this._jadeText.visible = false;
			this._jadeBg.visible = false;
			if (treasure) {
				this._nameText.text = this._treasure.getName();
				this._nameText.visible = true;
				if (treasure.isActivating()) {
					// if (platform.canMakePay()) {
						this._jadeCnt.visible = true;
						this._jadeIcon.visible = true;
						this._jadeText.visible = true;
						this._jadeIcon.url = treasure.getAccResIcon();
						if (Player.inst.getAccTreasureCnt() > 0) {
							this._jadeText.text = Core.StringUtils.TEXT(60025);
						} else {
							this._jadeText.text = Core.StringUtils.TEXT(60062);
						}
						this._jadeBg.visible = true;
					// }
					this._startCountDown();
				} else if (treasure.canOpen()) {
					Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.REMOVE_NOTIFY);
					fairygui.GTimers.inst.remove(this._execCountDown, this);
					this._canOpenMode();
				} else {
					this._canActivateMode();
				}
				let rareType = this._treasure.getRareType();
				this._treasureImg.visible = true;
				this._treasureImg.url = `treasure_box${rareType}_png`;
				this._canOpenBg.url = `treasure_box${rareType}CanOpen_png`;
			} else {
				this._nameText.visible = false;
				fairygui.GTimers.inst.remove(this._execCountDown, this);
			}
		}

		private _resetUI() {
			this._readyOpenBg.visible = false;
			this._canOpenBg.visible = false;
			this._treasureImg.url = "treasure_box0_png";
			this._openBtn.visible = false;
			this._openTimeText.visible = false;
			this._boxWnd.url = "treasure_boxFrame_png";
		}

		private _canOpenMode() {
			// this._readyOpenBg.visible = true;
			this._boxWnd.url = "treasure_boxFrame2_png";
			this._openBtn.visible = true;
		}

		private _canActivateMode() {
			this._canOpenBg.visible = true;
			this._openTimeText.visible = true;
			if (TreasureMgr.inst().curActivatingTreasure) {
				this._openTimeText.text = Core.StringUtils.TEXT(60063);
			} else {
				this._openTimeText.text = Core.StringUtils.TEXT(60064);
			}
		}

		private _execCountDown() {
			this._openTimeText.visible = true;
			let openTime = this._treasure.openTime;
			openTime -= 1;
			if (openTime <= 0) {
				fairygui.GTimers.inst.remove(this._execCountDown, this);
				this._treasure.openTime = 0;
				this.refresh(this._treasure);
				this._treasure.fireUpdateEvent();
				TreasureMgr.inst().onTreasureCountDownDone(this._treasure);
			} else {
				this._treasure.openTime = openTime;
				this._setCountDownTime(openTime);
			}
		}

		private _setCountDownTime(sec: number) {
			if (this._treasure) {
				this._openTimeText.text = Core.StringUtils.secToString(sec, "hm");
				let jadeCnt = 0;
				if (Player.inst.getAccTreasureCnt() > 0) {
					if (Player.inst.isVip) {
						this._jadeCnt.text = Core.StringUtils.TEXT(70114);
						this._jadeCnt.color = 0xffffff;
					} else {
						jadeCnt = 3;
						this._jadeCnt.text = `${jadeCnt}`;
						if (!Player.inst.hasEnoughResToSkipAdvert()) {
							this._jadeCnt.color = 0xff0000;
						} else {
							this._jadeCnt.color = 0xffffff;
						}
					}
				} else {
					jadeCnt = this._treasure.getAccResCnt();
					this._jadeCnt.text = `${jadeCnt}`;
					if (!this._treasure.hasEnoughResToAcc(jadeCnt)) {
						this._jadeCnt.color = 0xff0000;
					} else {
						this._jadeCnt.color = 0xffffff;
					}
				}
			}
		}

		private _startCountDown() {
			Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.REMOVE_NOTIFY);
			fairygui.GTimers.inst.remove(this._execCountDown, this);
			this._execCountDown();
			this._treasure.lastUpdateTime = Math.floor(new Date().getTime()/1000);
			fairygui.GTimers.inst.add(1000, this._treasure.openTime, this._execCountDown, this);

			Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.CREATE_NOTIFY, {
					"time":this._treasure.openTime,
					"message":Core.StringUtils.TEXT(60176)
				});
		}

		private async _onClick() {
			if (Player.inst.isInGuide()) {
				if (this._openFlag) {
					console.error("opening!");
					return;
				}
				let treasureInfoWnd = <TreasureInfoWnd>Core.ViewManager.inst.getView(ViewName.treasureInfo);
				if (treasureInfoWnd && treasureInfoWnd.isShow()) {
					console.error("treasure info wnd opened");
					return;
				}
			}
			this._openFlag = true;
			if (this._treasure) { // && !this._activateTrans.playing) {
				let treasure = this._treasure;
				console.log(treasure.canOpen());
				if (treasure.canOpen()) {
					// 获奖
					console.debug("TreasureItemCom _onClick open");
					let reward = await TreasureMgr.inst().openTreasure(treasure.id);
					// egret.log(JSON.stringify(reward));
					if (!reward) {
						console.debug(`openTreasure fail, id=${treasure.id}, t=${treasure.type}`);
						this._openFlag = false;
						return;
					}
					console.debug("TreasureItemCom _onClick get reward done");
					Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward, treasure, () => {
						TreasureMgr.inst().popTreasure(treasure.id);
					});
				} else {
					// 查看
					console.debug("TreasureItemCom _onClick info");
					await Core.ViewManager.inst.open(ViewName.treasureInfo, this);
				}
			}
			this._openFlag = false;
		}

		private _onTouchBegin() {
			if (this._treasure) {
				this._clickTrans.play();
			}
		}

		public async playActivateAnimation() {
			await new Promise<void>(revolve => {
				this._activateTrans.play(()=>{
					revolve();
				}, this);
			});
		}
	}
}
