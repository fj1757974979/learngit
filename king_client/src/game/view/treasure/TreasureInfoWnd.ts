module Treasure {

	export class TreasureInfoWnd extends Core.BaseWindow {

		private _openTimeText: fairygui.GTextField;
		private _nameText: fairygui.GTextField;
		private _rareCardNumText: fairygui.GTextField;
		private _anotherOpenText: fairygui.GTextField;
		private _skipHintText: fairygui.GTextField;
		private _openBtn: fairygui.GButton;
		private _effBox0: fairygui.GLoader;
		private _effBox1: fairygui.GLoader;
		private _openTrans0: fairygui.Transition;
		private _openTrans1: fairygui.Transition;
		private _openTrans2: fairygui.Transition;
		private _openTrans3: fairygui.Transition;
		private _rewardList: fairygui.GList;

		private _shareBtn: fairygui.GButton;
		private _advertBtn: fairygui.GButton;
		private _jadeBtn: fairygui.GButton;
		private _naviBtn: fairygui.GButton;
		private _jadeSkipBtn: fairygui.GButton;

		private _countdown: number;

		private _isClickOpening: boolean;

		private _treasureCom: TreasureItemCom;

		public initUI() {
			super.initUI();
			this._openTimeText = this.contentPane.getChild("treasureTime").asTextField;
			this._rareCardNumText = this.contentPane.getChild("txt1").asTextField;
			this._anotherOpenText = this.contentPane.getChild("txt2").asTextField;
			this._nameText = this.contentPane.getChild("treasureName").asTextField;
			this._skipHintText = this.contentPane.getChild("skipText").asTextField;
			this._openBtn = this.contentPane.getChild("btnOpen").asButton;
			this._effBox0 = this.contentPane.getChild("box0").asLoader;
			this._effBox1 = this.contentPane.getChild("box1").asLoader;
			this._openTrans0 = this.contentPane.getTransition("t0");
			this._openTrans1 = this.contentPane.getTransition("t1");
			this._openTrans2 = this.contentPane.getTransition("t2");
			this._openTrans3 = this.contentPane.getTransition("t3");

			this._rewardList = this.contentPane.getChild("rewardList").asList;

			this._shareBtn = this.contentPane.getChild("shareBtn").asButton;
			// this._shareBtn.addClickListener(this._onShare, this);
			this._shareBtn.visible = false;

			this._advertBtn = this.contentPane.getChild("advertBtn").asButton;
			this._advertBtn.addClickListener(this._onAdvert, this);
			this._advertBtn.visible = false;

			this._jadeBtn = this.contentPane.getChild("jadeBtn").asButton;
			this._jadeBtn.addClickListener(this._onJade, this);
			this._jadeBtn.visible = false;

			this._naviBtn = this.contentPane.getChild("naviBtn").asButton;
			this._naviBtn.addClickListener(this._onNaviToCurTreasure, this);
			this._naviBtn.visible = false;

			this._jadeSkipBtn = this.contentPane.getChild("jadeSkipBtn").asButton;
			this._jadeSkipBtn.addClickListener(this._onJadeSkipAdvert, this);
			this._jadeSkipBtn.visible = false;

			this.modal = true;
			this.center();
			this._isClickOpening = false;
			this.adjust(this.contentPane.getChild("closeBg"));
			this.contentPane.getChild("closeBtn").addClickListener(this._onClose, this);
		}

		public async open(...param: any[]) {
			super.open(...param);
			this._treasureCom = param[0] as TreasureItemCom;

			let pos = this._treasureCom.pos;
			this._openTimeText.text = "";

			this._jadeBtn.icon = this._treasureCom.treasure.getAccResIcon();
			this._refresh();
			let animation: fairygui.Transition = null;
			if (pos == 0) {
				animation = this._openTrans0;
			} else if (pos == 1) {
				animation = this._openTrans1;
			} else if (pos == 2) {
				animation = this._openTrans2;
			} else {
				animation = this._openTrans3;
			}
			this._openBtn.touchable = (Pvp.PvpMgr.inst.getPvpLevel() >= 2)

			await new Promise<void>(resolve => {
				animation.play(()=>{
					resolve();
				}, this);
			})
			this._openBtn.touchable = true;
			
			this._openBtn.addClickListener(this._onClickOpen, this);
			if (adsPlatform.isAdsOpen()) {
				Player.inst.addEventListener(Player.ResUpdateEvt, this._refreshAdvertCnt, this);
			}
			Core.EventCenter.inst.addEventListener(Core.Event.UpdateTreasureEvt, this._onUpdateTreasureItem, this);
			this.contentPane.getChild("closeBg").addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
		}

		private async _onWatchAdsFinish() {
			let treasure = this._treasureCom.treasure;
			let args = {
				TreasureID: treasure.id,
				IsConsumeJade: false
			};
			let result = await Net.rpcCall(pb.MessageID.C2S_TREASURE_READ_ADS, pb.TargetTreasure.encode(args));
			if (result.errcode == 0) {
				let reply = pb.TreasureReadAdsReply.decode(result.payload);
				treasure.openTime = reply.RemainTime;
				if (treasure.openTime <= 0) {
					let reward = await TreasureMgr.inst().openTreasure(treasure.id);
					if (!reward) {
						return;
					}
					TreasureMgr.inst().onTreasureCountDownDone(treasure);
					TreasureMgr.inst().popTreasure(treasure.id);
					Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward, treasure, () => {
						Core.ViewManager.inst.close(ViewName.treasureInfo);
					});
					Core.ViewManager.inst.closeView(this);
				} else {
					this._refresh();
					this._refreshAdvertCnt();
					treasure.fireUpdateEvent();
				}
			}
		}

		private _onShare() {
			if (Player.inst.isVip) {
				this._onJadeSkipAdvert();
				return;
			}
			if (Core.DeviceUtils.isWXGame()) {
				WXGame.WXShareMgr.inst.wechatShareTreasure(this._treasureCom.treasure.id);
				// WXGame.WXGameMgr.inst.registerOnShowCallback(() => {
				// 	setTimeout(async () => {
				// 		Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60242));
				// 		await this._onWatchAdsFinish();
				// 	}, WXGame.WXShareMgr.inst.shareDelayOpTime);
				// });
			}
		}

		private _refreshAdvertCnt() {
			this._advertBtn.getChild("title1").asTextField.text = Core.StringUtils.TEXT(60023)+`${Player.inst.getAdvertCnt()}`+Core.StringUtils.TEXT(60011);
		}

		private async _onAdvert() {
			if (Player.inst.isVip) {
				this._onJadeSkipAdvert();
				return;
			}
			if (adsPlatform.isAdsOpen()) {
				if (Player.inst.getAccTreasureCnt() <= 0) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60235));
					return;
				}
				let ret = await adsPlatform.isAdsReady();
				if (!ret.success || Player.inst.getAdvertCnt() <= 0) {
					if (Core.DeviceUtils.isWXGame()) {
						Core.TipsUtils.showTipsFromCenter(ret.reason);
						if (Core.DeviceUtils.isWXGame()) {
							Core.TipsUtils.confirm(Core.StringUtils.TEXT(60246), () => {
								this._onShare();
							}, null, this, Core.StringUtils.TEXT(60072), Core.StringUtils.TEXT(60020));
						}
					} else {
						Core.TipsUtils.showTipsFromCenter(ret.reason);
					}
					return;
				}
				let res = await adsPlatform.showRewardAds();
				if (res) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60224));
					await this._onWatchAdsFinish();
				}
			}
		}

		private async _onJadeSkipAdvert() {
			if (Player.inst.getAccTreasureCnt() <= 0) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60215));
				return;
			}

			if (!Player.inst.hasEnoughResToSkipAdvert() && !Player.inst.isVip) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60085));
				return;
			}

			let treasure = this._treasureCom.treasure;
			let args = {
				TreasureID: treasure.id,
				IsConsumeJade: true
			};
			let result = await Net.rpcCall(pb.MessageID.C2S_TREASURE_READ_ADS, pb.TreasureReadAdsArg.encode(args));
			if (result.errcode == 0) {
				let reply = pb.TreasureReadAdsReply.decode(result.payload);
				treasure.openTime = reply.RemainTime;
				if (treasure.openTime <= 0) {
					let reward = await TreasureMgr.inst().openTreasure(treasure.id);
					if (!reward) {
						return;
					}
					TreasureMgr.inst().onTreasureCountDownDone(treasure);
					TreasureMgr.inst().popTreasure(treasure.id);
					Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward, treasure, () => {
						Core.ViewManager.inst.close(ViewName.treasureInfo);
					});
					Core.ViewManager.inst.closeView(this);
				} else {
					this._refresh();
					this._refreshAdvertCnt();
					treasure.fireUpdateEvent();
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60178));
				}
			}
		}

		private async _onJade() {
			let treasure = this._treasureCom.treasure;

			if (!await treasure.askSubAccRes(treasure.getAccResCnt(), true)) {
				return;
			}

			let id = treasure.id;
			let args = {
				TreasureID: id
			};
			let result = await Net.rpcCall(pb.MessageID.C2S_JADE_ACC_TREASURE, pb.TargetTreasure.encode(args));
			if (result.errcode == 0) {
				treasure.openTime = 0;
				let reward = await TreasureMgr.inst().openTreasure(id);
				if (!reward) {
					return;
				}
				TreasureMgr.inst().onTreasureCountDownDone(treasure);
				TreasureMgr.inst().popTreasure(id);
				await Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward, treasure, () => {
					Core.ViewManager.inst.close(ViewName.treasureInfo);
				});
				Core.ViewManager.inst.closeView(this);
			}
		}

		private async _onNaviToCurTreasure() {
			if (this._treasureCom.treasure.isActivating()) {
				return;
			}
			let treasure = TreasureMgr.inst().curActivatingTreasure;
			if (treasure) {
				let pos = treasure.pos;
				let matchView = <Pvp.MatchView>Core.ViewManager.inst.getView(ViewName.match);
				let treasureCom = matchView.getTreasureCom(pos);
				await Core.ViewManager.inst.closeView(this);
				await Core.ViewManager.inst.open(ViewName.treasureInfo, treasureCom);
			}
		}

		public async close(...param:any[]) {
            await super.close(...param);
			this._openTrans0.stop();
			this._openTrans1.stop();
			this._openTrans2.stop();
			this._openTrans3.stop();
			this._openTimeText.text = "";
			this.contentPane.getChild("closeBg").removeEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
			this._openBtn.removeClickListener(this._onClickOpen, this);
			if (adsPlatform.isAdsOpen()) {
				Player.inst.removeEventListener(Player.ResUpdateEvt, this._refreshAdvertCnt, this);
			}
			Core.EventCenter.inst.removeEventListener(Core.Event.UpdateTreasureEvt, this._onUpdateTreasureItem, this);
        }

		private _onUpdateTreasureItem(ev:Treasure.TreasureEvent) {
			if (ev.treasureItem == this._treasureCom.treasure) {
				this._refresh();
			}
		}

		private _onClose(evt:egret.TouchEvent) {
			Core.ViewManager.inst.closeView(this);
		}

		private async _onClickOpen() {
			if (this._isClickOpening) {
				return;
			}
			this._isClickOpening = true;
			let openTime = this._treasureCom.treasure.getOpenNeedTime();
			if (openTime <= 5) {
				await Core.ViewManager.inst.closeView(this);
			}
			this._treasureCom.playActivateAnimation();
			await TreasureMgr.inst().activateTreasure(this._treasureCom.treasure.id);
			this._treasureCom.treasure.fireUpdateEvent();
			if (openTime > 5) {
				this._refresh();
			}
			this._isClickOpening = false;
		}

		private _refresh() {
			if (!this._treasureCom.treasure) {
				console.debug("=== can't get treasure item");
				return;
			}
			this._rewardList.removeChildren(0, -1, true);

			let rewardComs = Treasure.TreasureReward.genRewardItemComsByTreasure(this._treasureCom.treasure);
			rewardComs.forEach(com => {
				this._rewardList.addChild(com);
			});

			this._rewardList.height = Math.ceil(rewardComs.length / 2) * 50;

			// this._goldText.text = `x${Math.floor(this._treasureCom.treasure.getMinGoldCnt() * goldRate)} ~ ${Math.floor(this._treasureCom.treasure.getMaxGoldCnt() * goldRate)}`;
			// this._cardText.text = `x${this._treasureCom.treasure.getCardNum() + cardNum}`;
			this._nameText.text = `${this._treasureCom.treasure.getName()}`;

			let rareCardNum = this._treasureCom.treasure.getRareCardNum();
			if (rareCardNum <= 0) {
				this._rareCardNumText.visible = false;
			} else {
				this._rareCardNumText.visible = true;
				this._rareCardNumText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60130), rareCardNum);
			}

			if (TreasureMgr.inst().curActivatingTreasure) {
				if (this._treasureCom.treasure.isActivating()) {
					this._anotherOpenText.visible = false;
					this._naviBtn.visible = false;
				} else {
					this._anotherOpenText.visible = true;
					this._naviBtn.visible = true;
				}
				this._openBtn.enabled = false;
			} else {
				this._anotherOpenText.visible = false;
				this._naviBtn.visible = false;
				this._openBtn.enabled = true;
			}

			this._openBtn.visible = true;
			this._advertBtn.visible = false;
			this._jadeBtn.visible = false;
			this._jadeSkipBtn.visible = false;
			this._skipHintText.visible = false;

			let treasure = this._treasureCom.treasure
			if (treasure.isActivating()) {
				this._startCountDown();
				this._openBtn.visible = false;
				let advertCnt = Player.inst.getAdvertCnt(); // 可看的广告次数
				let accCnt = Player.inst.getAccTreasureCnt(); // 可加速次数
				if (accCnt > 0) {
					this._jadeBtn.visible = false;
					this._jadeSkipBtn.visible = true;
					if (Player.inst.hasEnoughResToSkipAdvert() || Player.inst.isVip) {
						this._jadeSkipBtn.titleColor = 0xffff00;
						if (Player.inst.isVip) {
							this._jadeSkipBtn.text = Core.StringUtils.TEXT(70114);
						} else {
							this._jadeSkipBtn.text = "3";
						}
					} else {
						this._jadeSkipBtn.titleColor = 0xff0000;
					}
					this._skipHintText.visible = true;
					let maxCnt = Player.inst.getMaxAccTreasureCnt();
					if (Player.inst.hasPrivilege(Priv.TREASURE_ADD_ACC_CNT)) {
						maxCnt += 2;
					}
					this._skipHintText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60159), accCnt, maxCnt);
					if (adsPlatform.isAdsOpen()) {
						this._advertBtn.visible = true;
						this._jadeSkipBtn.x = 30;
					} else {
						this._advertBtn.visible = false;
						this._jadeSkipBtn.x = 125;
					}
				} else {
					this._advertBtn.visible = false;
					this._jadeSkipBtn.visible = false;
					this._jadeBtn.visible = true;
					this._skipHintText.visible = false;
				}
			} else if (treasure.canOpen()) {
				console.debug("--- treasure can open!");
				Core.ViewManager.inst.closeView(this);
			} else {
				fairygui.GTimers.inst.remove(this._execCountDown, this);
				let openTime = treasure.getOpenNeedTime();
				let times = 1;
				if (Player.inst.hasPrivilege(Priv.TREASURE_SUB_TIME)) {
					times -= 0.1;
				}
				this._openTimeText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60107), Core.StringUtils.secToString(openTime * times, "hm"));
			}

			let rareType = treasure.getRareType();
			this._effBox0.url = `treasure_${rareType}0_png`;
			this._effBox1.url = `treasure_${rareType}1_png`;
		}

		private _execCountDown() {
			this._openTimeText.visible = true;
			this._countdown -= 1;
			if (this._countdown <= 0) {
				fairygui.GTimers.inst.remove(this._execCountDown, this);
				this._refresh();
			} else {
				this._setCountDownTime(this._countdown);
			}
		}

		private _startCountDown() {
			fairygui.GTimers.inst.remove(this._execCountDown, this);
			this._countdown = this._treasureCom.treasure.openTime;
			this._setCountDownTime(this._countdown);
			if (this._countdown > 0) {
				fairygui.GTimers.inst.add(1000, this._countdown, this._execCountDown, this);
			}
		}

		private _setCountDownTime(sec: number) {
			if (this._treasureCom && this._treasureCom.treasure) {
				this._openTimeText.text = Core.StringUtils.secToString(sec, "hm");
				let jadeCnt = this._treasureCom.treasure.getAccResCnt(sec);
				this._jadeBtn.title = `${jadeCnt}`;
				if (!this._treasureCom.treasure.hasEnoughResToAcc(jadeCnt)) {
					this._jadeBtn.getChild("title").asTextField.color = 0xff0000;
				} else {
					this._jadeBtn.getChild("title").asTextField.color = 0xffffff;
				}
			}
		}
	}
}
