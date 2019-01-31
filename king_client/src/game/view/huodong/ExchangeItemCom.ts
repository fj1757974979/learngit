module Huodong {
	export class ExchangeItemCom extends fairygui.GComponent {

		private _rewardIcon: fairygui.GLoader;
		private _priceText: fairygui.GTextField;
		private _itemIcon: fairygui.GLoader;
		private _exchangeBtn: fairygui.GButton;
		private _exchangeCountText: fairygui.GTextField;
		private _countText: fairygui.GTextField;
		private _ctrl: fairygui.Controller;

		private _hostView: ExchangeView;

		private _conf: any;
		private _exchangeCnt: number;
		private _huodong: ExchangeHuodong;
		private _goodsId: number;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._rewardIcon = this.getChild("rewardIcon1").asLoader;
			this._itemIcon = this.getChild("itemIcon").asLoader;
			this._priceText = this.getChild("processTxt").asTextField;
			this._exchangeBtn = this.getChild("btnReceive").asButton;
			this._exchangeCountText = this.getChild("exchangeCnt").asTextField;
			this._countText = this.getChild("countText").asTextField;
			this._ctrl = this.getController("c1");

			this._exchangeBtn.addClickListener(this._onExchangeBtn, this);
			this._rewardIcon.addClickListener(this._onDetail, this);
		}

		public async setExchangeData(goodsId: number, huodong: ExchangeHuodong, conf: any) {
			this._goodsId = goodsId;
			this._conf = conf;
			this._exchangeCnt = await huodong.getExchangeCnt(goodsId);
			this._huodong = huodong;
			let t = this._conf.type;
			let param = this._conf.rewardId;
			let rewardId = this._conf.rewardId;
			if (t == "skin") {
				let skinId: string = rewardId;
				let conf = CardPool.CardSkinMgr.inst.getSkinConf(skinId);
				param = conf.head;
			} else if (t == "treasure") {
				let treasureType: string = rewardId;
				let treasure = new Treasure.TreasureItem(-1, treasureType);
				param = treasure.getRareType();
			}
			this._rewardIcon.url = Reward.RewardMgr.inst.getRewardIconByStrType(t, param);
			this._itemIcon.url = huodong.getItemIcon();
			this._countText.text = `x${this._conf.cnt}`;
			let price = this._conf.price;
			let has = Player.inst.getResource(ResType.T_EXCHANGE_ITEM);
			this._priceText.text = `${has}/${price}`;
			if (price > has) {
				this._priceText.color = 0xff0000;
				this._ctrl.setSelectedIndex(0);
			} else {
				this._priceText.color = 0x66ff00;
				this._ctrl.setSelectedIndex(1);
			}
			let exchangeTotalCnt = this._conf.exchangeCnt;
			if (exchangeTotalCnt <= 0) {
				// 不限次数
				this._exchangeCountText.visible = false;
			} else {
				this._exchangeCountText.visible = true;
				this._exchangeCountText.text = `${this._exchangeCnt}/${exchangeTotalCnt}`;
				if (this._exchangeCnt >= exchangeTotalCnt) {
					this._ctrl.setSelectedIndex(2);
					this._exchangeCountText.visible = false;
				}
			}

			if (t == "skin") {
				let skinId: string = rewardId;
				let conf = CardPool.CardSkinMgr.inst.getSkinConf(skinId);
				let cardId = parseInt(conf.general);
				if (CardPool.CardSkinMgr.inst.hasSkin(cardId, skinId)) {
					this._ctrl.setSelectedIndex(2);
					this._exchangeCountText.visible = false;
				}
			}
		}

		public set host(h: ExchangeView) {
			this._hostView = h;
		}

		private async _onExchangeBtn() {
			if (this._ctrl.selectedIndex != 1) {
				return;
			}
			Core.TipsUtils.confirm(Core.StringUtils.format("兑换该奖励将消耗{0}个金桶兑换券", this._conf.price), this._onExchange, null, this);
		}

		private async _onExchange() {
			if (this._ctrl.selectedIndex != 1) {
				return;
			}
			let args = {
				Type: <number>this._huodong.type,
				GoodsID: this._goodsId
			};
			let result = await Net.rpcCall(pb.MessageID.C2S_HUODONG_EXCHANGE, pb.HuodongExchangeArg.encode(args));
			if (result.errcode == 0) {
				let reply = pb.HuodongExchangeReply.decode(result.payload);
				if (this._conf.type == "treasure") {
					let reward = new Treasure.TreasureReward();
					reward.setRewardForOpenReply(reply.Treasure);
					Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward, new Treasure.TreasureItem(-1, this._conf.rewardId));
				} else {
					let rewardData = new Pvp.GetRewardData();
					let t = this._conf.type;
					if (t == "gold") {
						rewardData.addGold(parseInt(this._conf.cnt));
					} else if (t == "card") {
						rewardData.addCards(parseInt(this._conf.rewardId), this._conf.cnt);
					} else if (t == "skin") {
						rewardData.addSkins(this._conf.rewardId);
					} else if (t == "headFrame") {
						rewardData.addHeadFrame(parseInt(this._conf.rewardId));
					} else if (t == "jade") {
						rewardData.addJade(this._conf.cnt);
					} else if (t == "bowlder") {
						rewardData.addBowlder(this._conf.cnt);
					}
					Core.ViewManager.inst.open(ViewName.getRewardWnd, rewardData);
				}
				await this._huodong.onExchange(this._goodsId, 1);
				this._hostView.refreshList();
			}
		}

		public refresh() {
			this.setExchangeData(this._goodsId, this._huodong, this._conf);
		}

		private async _onDetail() {
			let conf = this._conf;
			let t = conf.type;
			if (t == "skin") {
				let skinId: string = conf.rewardId;
				let skinConf = CardPool.CardSkinMgr.inst.getSkinConf(skinId);
				let cardId = parseInt(skinConf.general);
				let data = CardPool.CardPoolMgr.inst.getCardData(cardId, 1);
				let card = new CardPool.Card(data);
				Core.ViewManager.inst.open(ViewName.skinView, card, skinId);
			} else if (t == "card") {
				let cardId: number = parseInt(conf.rewardId);
				let data = CardPool.CardPoolMgr.inst.getCardData(cardId, 1);
				let card = new CardPool.Card(data);
				Core.ViewManager.inst.open(ViewName.cardInfoOther, card);
			} else if (t == "treasure") {
				let treasureType: string = conf.rewardId;
				let treasure = new Treasure.DailyTreasureItem(-1, treasureType);
				Core.ViewManager.inst.open(ViewName.treasureReview, treasure);
			}
		}
	}
}