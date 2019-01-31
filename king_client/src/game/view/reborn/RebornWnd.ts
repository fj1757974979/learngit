module Reborn {
    

    export class RebornWnd extends Core.BaseWindow {

        private _btnClose: fairygui.GButton;
        private _rebornBtn: fairygui.GButton;
        private _rebornList: fairygui.GList;
        private _cardList: fairygui.GList;
        private _treasureIcon: fairygui.GLoader;
        private _data1: fairygui.GComponent;
        private _data2: fairygui.GComponent;
        private _data3: fairygui.GComponent;
        private _data4: fairygui.GComponent;

        private _page: number;
        private _team: number;
        private _treasure: Treasure.DailyTreasureItem;
        private _treasureData: any;

        public initUI() {
            super.initUI();

            this.adjust(this.contentPane.getChild("bg"));

            this._rebornList = this.contentPane.getChild("n27").asList;
            this._data1 = this._rebornList.getChild("data1").asCom;
            // this._data2 = this._rebornList.getChild("data2").asCom;
            this._data3 = this._rebornList.getChild("data3").asCom;
            this._data4 = this._rebornList.getChild("data4").asCom;
            this._rebornList._scrollPane.addEventListener(fairygui.ScrollPane.SCROLL_END, this._scrollUpdate, this);

            this._cardList = this._data4.getChild("cardList").asList;
            this._treasureIcon = this._data3.getChild("treasureIcon").asLoader;
            this._rebornBtn = this._data4.getChild("rebornBtn").asButton;

            this._btnClose = this.contentPane.getChild("btnClose").asButton;

            this._rebornBtn.addClickListener(this._onRebornBtn, this);
            this._btnClose.addClickListener(this._onClose, this);
            this._treasureIcon.addClickListener(this._onBox, this);
            this._treasureIcon.touchable = true;
            
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._rebornList._scrollPane.scrollTop();
            this._team = RebornMgr.inst.team;
            this._page = 0;
            this._rebornList.getChildAt(0).asCom.getTransition("enter").play();
            this._refresh();
            this._refreshCard();
        }

        private _refresh() {
            let rebornCards = RebornMgr.inst.rebornCards;
            let honorKeys = Data.card_caculation.keys;
            for (let i = 0; i < honorKeys.length; i++) {
                let com = this._data3.getChild(`rare${honorKeys[i]}`).asCom;
                let rareCom = com.getChild("cardRare").asCom as UI.CardRareCom;
                rareCom.setRare(honorKeys[i]);
                com.getChild("cardCnt").asTextField.text = `${rebornCards.getValue(honorKeys[i])}(x${Data.card_caculation.get(honorKeys[i]).honor})`;
                com.getChild("honorCnt").asTextField.text = (rebornCards.getValue(honorKeys[i]) * Data.card_caculation.get(honorKeys[i]).honor).toString();
            }
            let goldCom = this._data3.getChild(`goldCom`).asCom;
            goldCom.getChild("title").asTextField.text = RebornMgr.inst.upLevGold.toString();
            goldCom.getChild("fameCnt").asTextField.text = RebornMgr.inst.upLevGod2Fame.toString();

            let allCom = this._data3.getChild(`allCom`).asCom;
            //allCom.getChild("title").asTextField.text = Core.StringUtils.format(Core.StringUtils.TEXT(70170), RebornMgr.inst.rebornDay);
            allCom.getChild("fameCnt").asTextField.text = RebornMgr.inst.reborn2Fame.toString();
            
            this._data3.getChild("cnt2").asTextField.text = RebornMgr.inst.rebornFeats.toString();
            this._data3.getChild("cnt3").asTextField.text = RebornMgr.inst.fames.toString();

            let treasureId = Data.reborn_treausre.get(RebornMgr.inst.canRebornTeam).treasure;
            this._treasureData = Data.treasure_config.get(treasureId);
            this._treasureIcon.url = `treasure_box${this._treasureData.rare}_png`;

            this._data3.getChild("cnt1").asTextField.text = this._treasureData.title;

            let treasure1 = new Treasure.TreasureItem(-1, treasureId);
            this._treasure = treasure1 as Treasure.DailyTreasureItem;

        }
        private _refreshCard() {
            this._cardList.removeChildrenToPool();
            let cardIds = RebornMgr.inst.rebornHeros;
            cardIds.forEach(_cardId => {
                let cardData = CardPool.CardPoolMgr.inst.getCardData(_cardId, 2);
                if (cardData) {
                    let card = this._cardList.addItemFromPool() as UI.CardCom;
                    let cardObj = new CardPool.Card(cardData);
                    card.cardObj = cardObj;
                    card.setName();
                    card.setOwnBackground();
                    card.setOwnFront();
                    card.setCardImg();
                    card.setSkill();
                    card.setNumOffsetText();
                    card.setNumText(true);
                    card.addClickListener(() => {
                        Core.ViewManager.inst.open(ViewName.cardInfoOther, card.cardObj);
                    }, this);
                }
            })
            let cardIds2 = RebornMgr.inst.rebornHeros2;
            cardIds2.forEach(_cardId => {
                let cardData = CardPool.CardPoolMgr.inst.getCardData(_cardId, 1);
                if (cardData) {
                    let card = this._cardList.addItemFromPool() as UI.CardCom;
                    let cardObj = new CardPool.Card(cardData);
                    card.cardObj = cardObj;
                    card.setName();
                    card.setOwnBackground();
                    card.setOwnFront();
                    card.setCardImg();
                    card.setSkill();
                    card.setNumOffsetText();
                    card.setNumText(true);
                    card.addClickListener(() => {
                        Core.ViewManager.inst.open(ViewName.cardInfoOther, card.cardObj);
                    }, this);
                }
            })
        }

        private async _onRebornBtn() {
            if (this._team < RebornMgr.inst.canRebornTeam) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70148));
                return;
            }
            if (RebornMgr.inst.remainDay > 0) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70166), RebornMgr.inst.remainDay));
                return;
            }
            if (RebornMgr.inst.rebornCnt >= 6) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70376));
                return;
            }
            Core.TipsUtils.confirm(Core.StringUtils.TEXT(70150), this._reborn,null,this);
        }
        private async _reborn() {
            let ok = await RebornMgr.inst.onReborn();
            if (ok) {
                this._onClose();
            }
        }

        private async _onBox() {
            Core.ViewManager.inst.open(ViewName.dailyTreasureInfo, this);
        }

        private async _scrollUpdate(evt: fairygui.ItemEvent) {
            let ctrPage = this.contentPane.getController("page").selectedIndex;
            if (this._page != ctrPage) {
                this._page = ctrPage;
                this._rebornList.getChildAt(ctrPage).asCom.getTransition("enter").play();
            }
        }


        private _onClose() {
            Core.ViewManager.inst.closeView(this);
        }

        public async close(...param: any[]) {
            super.close(...param);
        }

        public get treasure(): Treasure.DailyTreasureItem {
			return this._treasure;
		}
    }
}