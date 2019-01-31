module Battle {

	export class NewBattleLoseCom extends fairygui.GComponent {

		private _curRankBanner: UI.PvpRankBannerCom;
		private _newRankBanner: UI.PvpRankBannerCom;

		private _loseTrans: fairygui.Transition;
		private _rankdownTrans: fairygui.Transition;
		private _rankupTrans: fairygui.Transition;

		private _cantDecStarHintText: fairygui.GTextField;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._curRankBanner = this.getChild("oldRankBanner").asCom as UI.PvpRankBannerCom;
			this._newRankBanner = this.getChild("newRankBanner").asCom as UI.PvpRankBannerCom;

			this._loseTrans = this.getTransition("t0");
			this._rankdownTrans = this.getTransition("t1");
			this._rankupTrans = this.getTransition("t2");

			this._cantDecStarHintText = this.getChild("cantDecStarText").asTextField;
			if (!LanguageMgr.inst.isChineseLocale()) {
				this.getChild("loseText2").asLoader.y = 330;
			}
		}

	    public async playLoseAnimation() {
		    SoundMgr.inst.playSoundAsync("lose_mp3");
			await new Promise<void>(resolve => {
				this._loseTrans.play(() => {
					resolve();
				});
			});
		}

		public async playRankdownAnimation() {
			await new Promise<void>(resolve => {
				this._rankdownTrans.play(() => {
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
			this._curRankBanner.show();
			this._newRankBanner.show();
			this._cantDecStarHintText.visible = false;
		}

		public setLevelMode() {
			this._curRankBanner.hide();
			this._newRankBanner.hide();
			this._cantDecStarHintText.visible = false;
		}
		
		public setFriendMode() {
			this._curRankBanner.hide();
			this._newRankBanner.hide();
			this._cantDecStarHintText.visible = false;
		}

		public initCurRankBanner(score: number) {
			this._curRankBanner.show();
			this._curRankBanner.refresh(score);
		}

		public noScoreDecLose() {
			this._cantDecStarHintText.visible = true;
		}

		public async onPreventLoseStar(scoreModify: number) {
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

		public async onLose(scoreModify: number) {
			let newScore = Player.inst.getResource(ResType.T_SCORE);
			let newPvpLevel = Pvp.PvpMgr.inst.getPvpLevel(newScore);
			let newPvpStar = Pvp.PvpMgr.inst.getPvpStarCnt(newScore);
			let oldScore = newScore + scoreModify;
			let oldPvpLevel = Pvp.PvpMgr.inst.getPvpLevel(oldScore);
			let oldPvpStar = Pvp.PvpMgr.inst.getPvpStarCnt(oldScore);
			this._cantDecStarHintText.visible = false;

			console.debug(`score ${oldScore}=>${newScore}, level ${oldPvpLevel}=>${newPvpLevel}, star ${oldPvpStar}=>${newPvpStar}`);

			this.initCurRankBanner(oldScore);

			let newPvpMaxStar = Pvp.Config.inst.getPvpMaxStar(newPvpLevel);
			
			if (newPvpLevel < oldPvpLevel) {
				for (let i = oldPvpStar; i > 0; i --) {
					await this._curRankBanner.curBannerCom.playStarDownAnimation(i);
				}
				let rest = scoreModify - oldPvpStar;
				this._newRankBanner.refresh(newScore);
				this._newRankBanner.curBannerCom.refresh(newPvpLevel, newPvpMaxStar);
				this._newRankBanner.show();
				await this.playRankdownAnimation();
				for (let i = newPvpMaxStar; i > newPvpMaxStar - rest; i --) {
					await this._newRankBanner.curBannerCom.playStarDownAnimation(i);
				}
			} else {
				for (let i = oldPvpStar; i > oldPvpStar - scoreModify; i --) {
					await this._curRankBanner.curBannerCom.playStarDownAnimation(i);
				}
			}
		}
	}
}
