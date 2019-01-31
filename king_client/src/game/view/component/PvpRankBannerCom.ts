module UI {

	export class StarCom extends fairygui.GComponent {

		private _upTrans: fairygui.Transition;
		private _downTrans: fairygui.Transition;

		private _starImg: fairygui.GLoader;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._upTrans = this.getTransition("win");
			this._downTrans = this.getTransition("lose");
			this._starImg = this.getChild("star").asLoader;
		}

		public async playStarUp() {
			await new Promise<void>(resolve => {
				this._upTrans.play(() => {
					resolve();
				}, this);
			});
		}

		public async playStarDown() {
			await new Promise<void>(resolve => {
				this._downTrans.play(() => {
					resolve();
				}, this);
			});
		}

		public show() {
			this.visible = true;
			this.alpha = 1;
			this._starImg.visible = true;
			this._starImg.alpha = 1;
		}

		public hide() {
			this.visible = false;
			this.alpha = 0;
			this._starImg.visible = false;
			this._starImg.alpha = 0
		}
	}

	export class BannerCom extends fairygui.GComponent {
		protected _starCnt: number;
		protected _rankIcon: fairygui.GLoader;
		//private _rankLvIcon: fairygui.GLoader;
		protected _stars: Collection.Dictionary<number, StarCom>;
		private _pvpTitleText: fairygui.GTextField;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._stars = new Collection.Dictionary<number, StarCom>();
			this.initStars();
			this.initRankUI();
		}

		protected initStars() {
			if (this.packageItem.name == "pvpRankBanner0") {
				this._starCnt = 0;
			} else if (this.packageItem.name == "pvpRankBanner1") {
				this._starCnt = 1;
			} else if (this.packageItem.name == "pvpRankBanner2") {
				this._starCnt = 2;
			} else if (this.packageItem.name == "pvpRankBanner3") {
				this._starCnt = 3;
			} else if (this.packageItem.name == "pvpRankBanner4") {
				this._starCnt = 4;
			} else {
				this._starCnt = 5;
			}

			for (let i = 1; i <= this._starCnt; i ++) {
				let starCom = this.getChild(`star${i}`).asCom as StarCom;
				starCom.hide();
				this._stars.setValue(i, starCom);
			}
		}

		protected initRankUI() {
			this._rankIcon = this.getChild("rankIcon").asLoader;
			//this._rankLvIcon = this.getChild("rankLvIcon").asLoader;
			this._pvpTitleText = this.getChild("pvpTitleText").asTextField;
		}

		public get starCnt(): number {
			return this.starCnt;
		}

		public refresh(pvpLevel: number, pvpStar: number) {
			// if (pvpLevel == 1) {
			// 	this._rankLvIcon.visible = false;
			// } else {
			// 	this._rankLvIcon.visible = true;
			// 	let rankLv = Pvp.Config.inst.getPvpRankLv(pvpLevel);
			// 	if (pvpLevel <= 10) {
			// 		this._rankLvIcon.url = `common_ranklv${rankLv - 2}_png`;
			// 	} else {
			// 		this._rankLvIcon.url = `common_ranklv${rankLv}_png`;
			// 	}
			// }
			let team = Pvp.Config.inst.getPvpTeam(pvpLevel);
			this._rankIcon.url = `common_rank${team}_png`;
			this._pvpTitleText.text = Pvp.Config.inst.getPvpTitle(pvpLevel);
			let tmpIdx = 1;
			for (let i = 1; i <= pvpStar; i ++, tmpIdx ++) {
				let starCom = this._stars.getValue(i);
				if (starCom) {
					starCom.show();
				}
			}
			for (let i = tmpIdx; i <= this._starCnt; i ++) {
				this._stars.getValue(i).hide();
			}
		}

		public async playStarUpAnimation(starIdx: number) {
			let starCom = this._stars.getValue(starIdx);
			if (starCom) {
				starCom.show();
				await starCom.playStarUp();
			}
		}

		public async playStarDownAnimation(starIdx: number) {
			let starCom = this._stars.getValue(starIdx);
			if (starCom) {
				starCom.show();
				await starCom.playStarDown();
				starCom.hide();
			}
		}

		public show() {
			this.visible = true;
			this.alpha = 1;
		}

		public hide() {
			this.visible = false;
			this.alpha = 0;
		}
	}

	export class MaxBannerCom extends BannerCom {
		
		private _starCntText: fairygui.GTextField;
		private _curStarCnt: number;
		private _pvpTitle: fairygui.GTextField;

		protected initStars() {
			let starCom = this.getChild(`star1`).asCom as StarCom;
			this._stars.setValue(1, starCom);
			this._starCnt = 1;
			this._starCntText = this.getChild("starText").asTextField;
		}

		protected initRankUI() {
			this._pvpTitle = this.getChild("pvpTitleText").asTextField;
		}

		public refresh(pvpLevel: number, pvpStar: number) {
			this._curStarCnt = pvpStar;
			this._starCntText.text = `${pvpStar}`;
			this._pvpTitle.text = Core.StringUtils.TEXT(60018);
		}

		public async playStarUpAnimation(starIdx: number) {
			await super.playStarUpAnimation(1);
			this.refresh(0, this._curStarCnt + 1);
		}

		public async playStarDownAnimation(starIdx: number) {
			await super.playStarDownAnimation(1);
			this.refresh(0, this._curStarCnt - 1);
		}
	}

	export class PvpRankBannerCom extends fairygui.GComponent {

		private _starCntToBannerCom: Collection.Dictionary<number, BannerCom>;
		private _maxBannerCom: MaxBannerCom;
		private _curBannerCom: BannerCom;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			this._starCntToBannerCom = new Collection.Dictionary<number, BannerCom>();
			for (let i = 0; i <= 5; i ++) {
				let bannerCom = this.getChild(`star${i}`).asCom as BannerCom
				this._starCntToBannerCom.setValue(i, bannerCom);
				bannerCom.hide();
			}
			this._maxBannerCom = this.getChild("starMax").asCom as MaxBannerCom;
			this._maxBannerCom.hide();

			this._curBannerCom = null;
		}

		public refresh(pvpScore: number) {
			//console.debug(`PvpRankBannerCom refresh ${pvpScore}`);
			if (this._curBannerCom) {
				this._curBannerCom.hide();
			}
			let level = Pvp.PvpMgr.inst.getPvpLevel(pvpScore);
			if (level >= Pvp.Config.inst.getMaxPvpLevel()) {
				this._curBannerCom = this._maxBannerCom;
			} else {
				let maxStar = Pvp.Config.inst.getPvpMaxStar(level);
				this._curBannerCom = this._starCntToBannerCom.getValue(maxStar);
			}
			if (this._curBannerCom) {
				this._curBannerCom.show();
				this._curBannerCom.refresh(level, Pvp.PvpMgr.inst.getPvpStarCnt(pvpScore));
			}
		}

		public get curBannerCom() {
			return this._curBannerCom;
		}

		public show() {
			this.visible = true;
			this.alpha = 1;
		}

		public hide() {
			this.visible = false;
			this.alpha = 0;
		}
	}
}