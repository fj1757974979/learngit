module Treasure {

	export class TreasureReward {
		private _gold: number;
		private _jade: number;
		private _bowlder: number;
		private _huodongItems: number;
		private _cardIds: Collection.Dictionary<number, number>;
		private _skinIds: Collection.Dictionary<string, number>;
		private _emojiIds: Collection.Dictionary<number, number>;
		private _headFrames: Collection.Dictionary<string, number>;
		private _shareId: number;

		public constructor() {
			this._cardIds = new Collection.Dictionary<number, number>();
			this._skinIds = new Collection.Dictionary<string, number>();
			this._emojiIds = new Collection.Dictionary<number, number>();
			this._headFrames = new Collection.Dictionary<string, number>();
			this._shareId = 0;
			this._gold = 0;
			this._jade = 0;
			this._bowlder = 0;
		}

		public setRewardForOpenReply(rewardData: pb.IOpenTreasureReply) {
			rewardData.Resources.forEach( resData => {
				this.setRes(resData.Type, resData.Amount);
			})

			rewardData.CardIDs.forEach(cardId => {
				this.addCardId(cardId);
			});
			rewardData.CardSkins.forEach( skinId => {
				this.addSkinId(skinId);
			});	
			rewardData.EmojiTeams.forEach(emojiTeamId => {
				this.addEmojiTeamId(emojiTeamId);
			});
			rewardData.Headframes.forEach(headFrame => {
				this.addHeadFrame(headFrame);
			});
			this.shareId = rewardData.ShareHid;

			// 测试用
			// this.bowlder = 183;
			// this.huodongItems = 1;
			// Player.inst.addResource(ResType.T_BOWLDER, this.bowlder);
			// Player.inst.addResource(ResType.T_EXCHANGE_ITEM, this.huodongItems);			
		}
		public setRes(type: ResType, num: number) {
			switch (type) {
				case ResType.T_GOLD:
					return this.gold = num;
				case ResType.T_JADE:
					return this.jade = num;;
				case ResType.T_BOWLDER:
					return this.bowlder = num;
				case ResType.T_EXCHANGE_ITEM:
					return this.huodongItems = num;
				default:
					return null;
			}
		}

		public getRes(type: ResType) {
			switch (type) {
				case ResType.T_GOLD:
					return this.gold;
				case ResType.T_JADE:
					return this.jade;
				case ResType.T_BOWLDER:
					return this.bowlder;
				case ResType.T_EXCHANGE_ITEM:
					return this.huodongItems;
				default:
					return null;
			}
		}

		public get gold() {
			return this._gold;
		}

		public set gold(g: number) {
			this._gold = g;
		}

		public get jade() {
			return this._jade;
		}

		public set jade(j: number) {
			this._jade = j;
		}

		public get bowlder(): number {
			return this._bowlder;
		}

		public set bowlder(b: number) {
			this._bowlder = b;
		}

		public get huodongItems(): number {
			return this._huodongItems;
		}

		public set huodongItems(h: number) {
			this._huodongItems = h;
		}

		public get cardIds() {
			return this._cardIds;
		}

		public get skinIds() {
			return this._skinIds;
		}

		public get emojiIds() {
			return this._emojiIds;
		}

		public get headFrames() {
			return this._headFrames;
		}

		public addCardId(cardId: number) {
			if (this._cardIds.containsKey(cardId)) {
				let count = this._cardIds.getValue(cardId)
				this._cardIds.setValue(cardId, count + 1);
			} else {
				this._cardIds.setValue(cardId, 1);
			}
		}
		
		public addSkinId(skinId: string) {
			if (this._skinIds.containsKey(skinId)) {
				let count = this._skinIds.getValue(skinId);
				this._skinIds.setValue(skinId, count +1);
			} else {
				this._skinIds.setValue(skinId, 1);
			}
		}

		public addEmojiTeamId(emojiTeamId: number) {
			if (this._emojiIds.containsKey(emojiTeamId)) {
				let count = this._emojiIds.getValue(emojiTeamId);
				this._emojiIds.setValue(emojiTeamId, count +1);
			} else {
				this._emojiIds.setValue(emojiTeamId, 1);
			}
		}

		public addHeadFrame(headFrame: string) {
			if (this._headFrames.containsKey(headFrame)) {
				let count = this._headFrames.getValue(headFrame);
				this._headFrames.setValue(headFrame, count +1);
			} else {
				this._headFrames.setValue(headFrame, 1);
			}
		}

		public addAllCardByAmount(amount: number) {
			let cardIds = this._cardIds.keys();
			cardIds.forEach(cardId => {
				let num = this._cardIds.getValue(cardId);
				num += amount;
				this._cardIds.setValue(cardId, num);
			});
		}

		public get shareId(): number {
			return this._shareId;
		}

		public set shareId(sid: number) {
			this._shareId = sid;
		}

		public static genRewardItemComsByTreasure(treasure: TreasureItem): Array<TreasureRewardItemCom> {
			let ret = [];

			let goldMinCnt = treasure.getMinGoldCnt();
			if (goldMinCnt > 0) {
				let com = fairygui.UIPackage.createObject(PkgName.treasure, "rewardItem", TreasureRewardItemCom).asCom as Treasure.TreasureRewardItemCom;
				com.setRewardInfo(Reward.RewardType.T_GOLD, goldMinCnt, treasure.getMaxGoldCnt());
				ret.push(com);
			}

			let jadeMinCnt = treasure.getMinJadeCnt();
			if (jadeMinCnt > 0) {
				let com = fairygui.UIPackage.createObject(PkgName.treasure, "rewardItem", TreasureRewardItemCom).asCom as Treasure.TreasureRewardItemCom;
				com.setRewardInfo(Reward.RewardType.T_JADE, jadeMinCnt, treasure.getMaxJadeCnt());
				ret.push(com);
			}

			let bowlderCnt = treasure.getMinBowlderCnt();
			if (bowlderCnt > 0) {
				let com = fairygui.UIPackage.createObject(PkgName.treasure, "rewardItem", TreasureRewardItemCom).asCom as Treasure.TreasureRewardItemCom;
				com.setRewardInfo(Reward.RewardType.T_BOWLDER, bowlderCnt, treasure.getMaxBowlderCnt());
				ret.push(com);
			}
			
			let cardNum = treasure.getCardNum();
			if (cardNum > 0) {
				let com = fairygui.UIPackage.createObject(PkgName.treasure, "rewardItem", TreasureRewardItemCom).asCom as Treasure.TreasureRewardItemCom;
				com.setRewardInfo(Reward.RewardType.T_COMMON_CARD, cardNum);
				ret.push(com);
			}

			let skinNum = treasure.getSkinNum();
			if (skinNum > 0) {
				let com = fairygui.UIPackage.createObject(PkgName.treasure, "rewardItem", TreasureRewardItemCom).asCom as Treasure.TreasureRewardItemCom;
				com.setRewardInfo(Reward.RewardType.T_COMMON_SKIN, skinNum);
				ret.push(com);
			}

			let frameNum = treasure.getHeadFrameNum();
			if (frameNum > 0) {
				let com = fairygui.UIPackage.createObject(PkgName.treasure, "rewardItem", TreasureRewardItemCom).asCom as Treasure.TreasureRewardItemCom;
				com.setRewardInfo(Reward.RewardType.T_COMMON_HEAD_FRAME, frameNum);
				ret.push(com);
			}
			
			let emojiNum = treasure.getEmojiNum();
			if (emojiNum > 0) {
				let com = fairygui.UIPackage.createObject(PkgName.treasure, "rewardItem", TreasureRewardItemCom).asCom as Treasure.TreasureRewardItemCom;
				com.setRewardInfo(Reward.RewardType.T_COMMON_EMOJI, emojiNum);
				ret.push(com);
			}

			return ret;
		}
	}
}