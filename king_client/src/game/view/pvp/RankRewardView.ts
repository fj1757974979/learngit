module Pvp {

	export class RankRewardView extends Core.BaseView {

		private _list: fairygui.GList;
		private _btnClose: fairygui.GButton;
		private _listItems: Collection.Dictionary<number, RankRewardCom>;
		private _pvpLevel: number;
		private _curRewardLevel: number;
		private _rewardPvpLevels: Array<number>;

		private _onClosePlayTreasureAni: boolean;

		public initUI() {
			super.initUI();

			this.adjust(this.getChild("bg"), Core.AdjustType.EXCEPT_MARGIN);
			this.y += window.support.topMargin;
			this._list = this.getChild("resultList").asList;
			this._btnClose = this.getChild("btnClose").asButton;
			this._listItems = new Collection.Dictionary<number, RankRewardCom>();
			this._pvpLevel = Pvp.PvpMgr.inst.getPvpLevel();
			this._curRewardLevel = 0;
			this._rewardPvpLevels = [];
			this._onClosePlayTreasureAni = false;

			this._btnClose.addClickListener(this._onClickClose, this);
			Player.inst.addEventListener(Player.ResUpdateEvt, this._onPlayerResUpdate, this);

			this._initList();
		}

		private _initList() {
			let allLevels = Data.rank.keys;
			for (let i = allLevels.length - 1; i >= 0; i --) {
				let level = allLevels[i];
				let unlockCards = Config.inst.getUnlockCard(level);
				if (unlockCards.length > 0) {
					this._rewardPvpLevels.push(level);
					
					let rewardCom = fairygui.UIPackage.createObject(PkgName.pvp, "rankRewardCard", RankRewardCom).asCom as RankRewardCom;
					rewardCom.initWithPvpLevel(level);
					this._list.addChild(rewardCom);
					this._listItems.setValue(level, rewardCom);
					
				}
			}
			/*
			this._list.setVirtual();
			this._list.itemClass = RankRewardCom;
			this._list.itemRenderer = this._renderList;
			this._list.callbackThisObj = this;
			this._list.numItems = this._rewardPvpLevels.length;
			*/
		}

		/*
		private _renderList(idx:number, item:fairygui.GObject) {
			let pvpLevel = this._rewardPvpLevels[idx];
			let rewardCom = item as RankRewardCom;
			rewardCom.initWithPvpLevel(pvpLevel);	
			//console.debug(`======== render reward com idx = ${idx}`);
			
			if (this._curRewardLevel == pvpLevel) {
				rewardCom.playRankTitleAnimation();
				this._curRewardLevel = 0;
			}
			this._listItems.setValue(pvpLevel, rewardCom);
		}
		*/

		public async open(...param: any[]) {
			super.open(...param);
			this._onClosePlayTreasureAni = param[0];

			// this._initList();

			let pvpLevel = PvpMgr.inst.getPvpLevel();
			let level = Config.inst.getMiniLevelInPvpTeam(Config.inst.getPvpTeam(pvpLevel));
			
			let curCom = this._listItems.getValue(level);
			if (curCom) {
				this._list.touchable = false;
				this._list.scrollToView(this._list.getChildIndex(curCom));
				await curCom.playRankTitleAnimation(this._list);
			} else {
				this._list.scrollToView(this._list.numItems - 1);
			}
			if (Player.inst.hasGetVipExperience) {
				Player.inst.hasGetVipExperience = false;
				let getReward = new Pvp.GetRewardData();
				let giftData = Payment.PayMgr.inst.getProducts();
                let vipData = giftData.getValue("advip") as Payment.GiftProduct;
				let descTxt = Core.StringUtils.TEXT(70191) + "\n\n" + Core.StringUtils.TEXT(60023) + ": " + Core.StringUtils.secToString(Player.inst.vipTime, "hm");
				getReward.addOther(vipData.name, `shop_${vipData.icon}_png`, descTxt);
				Core.ViewManager.inst.open(ViewName.getRewardWnd, getReward);
			}
		}

		public async close(...param: any[]) {
			await super.close(...param);
			
			let pvpLevel = PvpMgr.inst.getPvpLevel();
	
			if (pvpLevel >= 5 && !(egret.localStorage.getItem("showReview") == "true")) {
				egret.localStorage.setItem("showReview","true");
				console.log("OPEN_APP_COMMENT");
				Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.OPEN_APP_COMMENT);
			}
			if (!Core.DeviceUtils.isWXGame() && Player.inst.isNewbieName( Player.inst.name ) && pvpLevel >= 2) {
                Core.ViewManager.inst.open(ViewName.modifyName);
            }
			// this._btnClose.removeClickListener(this._onClickClose, this);
			// Player.inst.removeEventListener(Player.ResUpdateEvt, this._onPlayerResUpdate, this)
			
			// this._list.removeChildren(0, -1, true);
			// this._listItems.forEach((key, com) => {
			// 	com.destroy();
			// 	console.log("destroying ....");
			// });
			// this._listItems.clear();
			// this._rewardPvpLevels = [];
		}

		private async _onClickClose() {
			let nowPage = this.getController("page").selectedIndex;
			await new Promise<void>(resolve => {
				this._list.getChildAt(nowPage).asCom.getTransition("t1").play(() => {
					resolve();
				});
            });
			await new Promise<void>(resolve => {
                this.getTransition("t1").play(() => {
					this._list.getChildAt(nowPage).asCom.getTransition("t1").playReverse();
                    resolve();
                });
            });
			await Core.ViewManager.inst.closeView(this);
			if (this._onClosePlayTreasureAni == true) {
				let homeView = Core.ViewManager.inst.getView(ViewName.match) as Pvp.MatchView;
                await homeView.tryPlayTreasureAddAnimation();
			}
		}

		private _onPlayerResUpdate() {
			let pvpLevel = Pvp.PvpMgr.inst.getPvpLevel();
            if (pvpLevel != this._pvpLevel) {
				let keys = this._listItems.keys();
				for (let key of keys) {
					let rewardCom = this._listItems.getValue(key);
					rewardCom.update();
				}
				this._pvpLevel = pvpLevel;
            }	
		}
	}
}