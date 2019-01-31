module Battle {

	export class NewBattleWinCom extends fairygui.GComponent {

		private _curRankBanner: UI.PvpRankBannerCom;
		private _newRankBanner: UI.PvpRankBannerCom;
		private _boxImg: fairygui.GLoader;
		private _boxNameText: fairygui.GTextField;
		private _boxHintText: fairygui.GTextField;
		private _cantGetBoxText: fairygui.GTextField;
		private _goldCom: Treasure.GoldRewardCom;
		private _rewardBg: fairygui.GLoader;
		private _levelWin: fairygui.GLoader;

		private _winTrans: fairygui.Transition;
		private _rankupTrans: fairygui.Transition;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._curRankBanner = this.getChild("oldRankBanner").asCom as UI.PvpRankBannerCom;
			this._newRankBanner = this.getChild("newRankBanner").asCom as UI.PvpRankBannerCom;
			this._goldCom = this.getChild("gold").asCom as Treasure.GoldRewardCom;
			this._goldCom.setNoGoldHint("");
			this._boxImg = this.getChild("boxImg").asLoader;
			this._rewardBg = this.getChild("rewardBg").asLoader;
			this._boxNameText = this.getChild("boxName").asTextField;
			this._boxHintText = this.getChild("boxHintText").asTextField;
			this._cantGetBoxText = this.getChild("cantGetBoxText").asTextField;
			this._levelWin = this.getChild("levelWin").asLoader;

			this._winTrans = this.getTransition("t0");
			this._rankupTrans = this.getTransition("t1");
		}

	    public async playWinAnimation() {
			SoundMgr.inst.playSoundAsync("win_mp3");
			await new Promise<void>(resolve => {
				this._winTrans.play(() => {
					resolve();
				});
			});
		}

		public async playRankupAnimation() {
			await new Promise<void>(resolve => {
				this._rankupTrans.play(() => {
					resolve();
				});
			});
		}

		public setPvpMode() {
			this._boxImg.visible = true;
			this._boxHintText.visible = true;
			this._cantGetBoxText.visible = true;
			this._goldCom.visible = true;
			this._rewardBg.visible = true;
			this._levelWin.visible = false;
			this._curRankBanner.show();
			this._newRankBanner.hide();
		}

		public setLevelMode() {
			this._boxImg.visible = false;
			this._boxHintText.visible = false;
			this._cantGetBoxText.visible = false;
			this._goldCom.visible = false;
			this._boxNameText.visible = false;
			this._rewardBg.visible = false;
			this._levelWin.visible = true;
			this._curRankBanner.hide();
			this._newRankBanner.hide();
		}

		public setFriendMode() {
			this._boxImg.visible = false;
			this._boxHintText.visible = false;
			this._cantGetBoxText.visible = false;
			this._goldCom.visible = false;
			this._boxNameText.visible = false;
			this._rewardBg.visible = false;
			this._levelWin.visible = true;
			this._curRankBanner.hide();
			this._newRankBanner.hide();
		}

		public initBox(type: string, noBoxReason: pb.NoTreasureReasonEnum) {
			if (type == "") {
				this._boxImg.visible = false;
				this._boxNameText.visible = false;
				this._boxHintText.visible = false;
				this._cantGetBoxText.visible = true;
				if (noBoxReason == pb.NoTreasureReasonEnum.AmountLimit) {
					this._cantGetBoxText.text = Core.StringUtils.TEXT(60244);
				} else if (noBoxReason == pb.NoTreasureReasonEnum.NoPos) {
					this._cantGetBoxText.text = Core.StringUtils.TEXT(60234);
				} else {
					this._cantGetBoxText.text = Core.StringUtils.TEXT(60234);
				}
			} else {
				let config = Data.treasure_config.get(type);
				let rareType = config.rare;
				this._boxImg.url = `treasure_box${rareType}_png`;
				this._boxImg.visible = true;
				this._boxNameText.text = config.title;
				this._boxNameText.visible = true;
				this._boxHintText.visible = true;
				this._boxHintText.alpha = 1;
				this._cantGetBoxText.visible = false;
			}
		}

		public initGold(cnt: number) {
			if (cnt > 0) {
				this._goldCom.count = cnt;
			} else {
				this._goldCom.setNoGoldHint(Core.StringUtils.TEXT(60182));
			}
		}

		public initCurRankBanner(score: number) {
			this._curRankBanner.show();
			this._curRankBanner.refresh(score);
		}

		public async onWin(scoreModify: number) {
			let newScore = Player.inst.getResource(ResType.T_SCORE);
			let newPvpLevel = Pvp.PvpMgr.inst.getPvpLevel(newScore);
			let newPvpStar = Pvp.PvpMgr.inst.getPvpStarCnt(newScore);
			let oldScore = newScore - scoreModify;
			let oldPvpLevel = Pvp.PvpMgr.inst.getPvpLevel(oldScore);
			let oldPvpStar = Pvp.PvpMgr.inst.getPvpStarCnt(oldScore);

			//console.debug(`onWin lv ${oldPvpLevel}->${newPvpLevel}, score ${oldScore}->${newScore}, star ${oldPvpStar}->${newPvpStar}`);

			this.initCurRankBanner(oldScore);
			
			let oldLevelMaxStar = Pvp.Config.inst.getPvpMaxStar(oldPvpLevel);
			if (newPvpLevel > oldPvpLevel) {
				for (let i = oldPvpStar + 1; i <= oldLevelMaxStar; i ++) {
					await this._curRankBanner.curBannerCom.playStarUpAnimation(i);
				}
				let rest = scoreModify - oldLevelMaxStar + oldPvpStar;
				this._newRankBanner.refresh(newScore);
				this._newRankBanner.curBannerCom.refresh(newPvpLevel, 0);
				this._newRankBanner.show();
				await this.playRankupAnimation();
				for (let i = 1; i <= rest; i ++) {
					await this._newRankBanner.curBannerCom.playStarUpAnimation(i);
				}
			} else {
				for (let i = oldPvpStar + 1; i<= newPvpStar; i ++) {
					await this._curRankBanner.curBannerCom.playStarUpAnimation(i);
				}
			}
		}
	}
}
