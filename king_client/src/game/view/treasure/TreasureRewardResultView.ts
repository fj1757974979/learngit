module Treasure {

	export class TreasureRewardResultView extends Core.BaseView{

		private _resultList: fairygui.GList;
		private _confirmBtn: fairygui.GButton;
		private _shareBtn: fairygui.GButton;

		private _reward: TreasureReward;
		private _treasure: TreasureItem;

		private _boxEff0: fairygui.GLoader;
		private _boxEff4: fairygui.GLoader;

		private _niceCardName: string;
		private _finishCallback: () => void;

		public initUI() {
			super.initUI();

			this.adjust(this.getChild("bg"));

			this._resultList = this.getChild("resultList").asList;
			this._confirmBtn = this.getChild("btnOk").asButton;
			this._shareBtn = this.getChild("shareBtn").asButton;

			this._boxEff0 = this.getChild("box0").asLoader;
			this._boxEff4 = this.getChild("box4").asLoader;
			
			this._confirmBtn.addClickListener(this._onClickClose, this);

			if (Core.DeviceUtils.isWXGame()) {
				this._shareBtn.addClickListener(() => {
					WXGame.WXShareMgr.inst.wechatShowOffTreasure(this._niceCardName);
				}, this);
			}

			this._finishCallback = null;
		}

		public async open(...param:any[]) {
			super.open(...param);
			this._reward = param[0];
			this._treasure = param[1];
			this._finishCallback = param[2];

			let rareType = this._treasure.getRareType();
			this._boxEff0.url = `treasure_${rareType}0_png`;
			this._boxEff4.url = `treasure_${rareType}4_png`;
			await fairygui.GTimers.inst.waitTime(500);
			let index = 0;
			let gold = this._reward.gold;
			if (gold > 0) {
				let goldCom = fairygui.UIPackage.createObject(PkgName.treasure, "goldCnt", GoldRewardCom).asCom as GoldRewardCom;
				goldCom.count = gold;
				this._resultList.addChild(goldCom);
				
				await goldCom.playTrans();
			}

			let jade = this._reward.jade;
			if (jade > 0) {
				let jadeCom = fairygui.UIPackage.createObject(PkgName.treasure, "jadeCnt", JadeRewardCom).asCom as JadeRewardCom;
				jadeCom.count = jade;
				this._resultList.addChild(jadeCom);
				await jadeCom.playTrans();
			}
			let bowlder = this._reward.bowlder;
			if (bowlder > 0) {
				let bowlderCom = fairygui.UIPackage.createObject(PkgName.treasure, "bowlderCnt", BowlderRewardCom).asCom as BowlderRewardCom;
				bowlderCom.count = bowlder;
				this._resultList.addChild(bowlderCom);
				await bowlderCom.playTrans();
			}

			let huodongItem = this._reward.huodongItems;
			if (huodongItem > 0) {
				let huodongItemCom = fairygui.UIPackage.createObject(PkgName.treasure, "itemCnt", HuodongItemRewardCom).asCom as HuodongItemRewardCom;
				huodongItemCom.count = huodongItem;
				this._resultList.addChild(huodongItemCom);
				await huodongItemCom.playTrans();
			}
			
			let cardIds = this._reward.cardIds.keys();
			let hasNiceCard = false;
			for (let cardId of cardIds) {
				let cardCount = this._reward.cardIds.getValue(cardId);
				let cardObj = CardPool.CardPoolMgr.inst.getCollectCard(cardId);
				if (!cardObj) {
					cardObj = new CardPool.Card(CardPool.CardPoolMgr.inst.getCardData(cardId, 1));
					cardObj.amount = cardCount;
				}
				let cardCom = fairygui.UIPackage.createObject(PkgName.treasure, "cardCnt", CardRewardCom).asCom as CardRewardCom;
				cardCom.count = cardCount
				cardCom.setCardObj(cardObj);
				cardCom.enableClick(true);
				this._resultList.addChild(cardCom);
				this._resultList.scrollToView(this._resultList.getChildIndex(cardCom), true);
				await cardCom.playTrans();
				if (cardObj.rare >= CardQuality.NORMAL) {
					hasNiceCard = true;
					let data = CardPool.CardPoolMgr.inst.getCardData(cardId, 1);
					this._niceCardName = data.name;
				}
			}

			let skinIds = this._reward.skinIds.keys();
			for (let skinId of skinIds) {
				let skinObj = fairygui.UIPackage.createObject(PkgName.treasure, "skinCnt").asCom;
				let cardCom = skinObj.getChild("card").asCom;
				
				Utils.setImageUrlPicture(cardCom.getChild("cardImg").asImage, `skin_m_${skinId}_png`);
				cardCom.getChild("nameText").asTextField.text = CardPool.CardSkinMgr.inst.getSkinConf(skinId).name;
				skinObj.getChild("title").asTextField.text = `x${this._reward.skinIds.getValue(skinId)}`;
				skinObj.addClickListener(() => {
					let card = CardPool.CardPoolMgr.inst.getCollectCard(CardPool.CardSkinMgr.inst.getSkinConf(skinId).general);
					Core.ViewManager.inst.open(ViewName.skinView, card, skinId);
				}, this);
				this._resultList.addChild(skinObj);
			}

			let emojiTeamIds = this._reward.emojiIds.keys();
			for (let emojiTeamId of emojiTeamIds) {
				let emojiObj = fairygui.UIPackage.createObject(PkgName.treasure, "emojiCnt").asCom;
				emojiObj.getChild("emoji").asCom.getChild("headFrame").asLoader.url = Reward.RewardMgr.inst.getRewardIcon(Reward.RewardType.T_EMOJI, null, emojiTeamId);
				emojiObj.getChild("title").asTextField.text = `x${this._reward.emojiIds.getValue(emojiTeamId)}`;
				// TODO click
				this._resultList.addChild(emojiObj);
			}

			let headFrameIds = this._reward.headFrames.keys();
			for (let headFrameId of headFrameIds) {
				let headFrameObj = fairygui.UIPackage.createObject(PkgName.treasure, "headFrameCnt").asCom;
				headFrameObj.getChild("headFrame").asLoader.url = Reward.RewardMgr.inst.getRewardIcon(Reward.RewardType.T_HEAD_FRAME, null, headFrameId);
				headFrameObj.getChild("title").asTextField.text = `x${this._reward.headFrames.getValue(headFrameId)}`;
				// TODO click
				this._resultList.addChild(headFrameObj);
			}

			if (hasNiceCard && Core.DeviceUtils.isWXGame()) {
				this._shareBtn.visible = true;
				this._confirmBtn.setXY(255,705);
				this._confirmBtn.visible = true;
			} else {
				this._shareBtn.visible = false;
				this._confirmBtn.setXY(165,705);
				this._confirmBtn.visible = true;
			}
			// console.log("reward result: ", this._reward);
			// if (this._reward.shareId > 0 && Core.DeviceUtils.isWXGame()) {
			// 	Core.ViewManager.inst.open(ViewName.shareRewardTreasure, this._reward.shareId);
			// }
			//Core.ViewManager.inst.getView(ViewName.home).setVisible(true);
		}

		public async close(...param:any[]) {
			super.close(...param);
			this._resultList.removeChildren();

			if (this._finishCallback) {
				try {
					this._finishCallback();
				} catch (e) {
					egret.log(e);
				}
				this._finishCallback = null;
			}
		}

		public _onClickClose() {
			Core.ViewManager.inst.closeView(this);

			let pvpLevel = Pvp.PvpMgr.inst.getPvpLevel();
			if (pvpLevel >= 5 && !(egret.localStorage.getItem("showReview") == "true")) {
				egret.localStorage.setItem("showReview","true");
				// console.log("OPEN_APP_COMMENT");
				Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.OPEN_APP_COMMENT);
			}
		}
	}
}