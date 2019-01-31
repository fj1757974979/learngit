module Pvp {

    export class RankHand extends fairygui.GComponent {

        private _cardList: Array<UI.CardCom>;
        
        constructFromXML(xml: any): void {
            this._cardList = [null, null, null, null, null];
        }
        
        public addCard(cardObj: UI.ICardObj) {
            for (let i = 0; i < this._cardList.length; i++) {
                let card = null;
                if (this._cardList[i] == null) {
                    let grid = this.getChild(`grid${i + 1}`).asCom;
                    card = fairygui.UIPackage.createObject(PkgName.cards, "cardItem", CardPool.CardItem) as CardPool.CardItem;
                    card.setData(cardObj, true);
                    card.setRankSeasonMode();
                    card.x = grid.x;
                    card.y = grid.y-5;
                    card.addClickListener(() => {
                        Core.ViewManager.inst.open(ViewName.cardInfo, card.cardObj);
                    }, this);
                    this.addChild(card);
                    this._cardList[i] = card;
                    break;
                } else if(!this._cardList[i].visible) {
                    card.setData(cardObj, true);
                    card.setRankSeasonMode();
                    this._cardList[i].visible = true;
                    break;
                }
            }
        }

        private _setCard(card: UI.CardCom, cardObj: UI.ICardObj) {
            card.cardObj = cardObj;
            card.setName();
            card.setOwnBackground();
            card.setOwnFront();
            card.setCardImg();
            card.setEquip();
            card.setSkill();
            card.setNumOffsetText();
            card.setNumText(true);
        }
        
        public delCard(card: UI.ICardObj) {
            for (let i = 0; i < this._cardList.length; i++) {
                if (this._cardList[i] != null && this._cardList[i].cardObj == card) {
                    // this._cardList[i].cardObj = null;
                    // this._cardList[i].visible = false;
                    this.removeChild(this._cardList[i]);
                    this._cardList[i] = null;
                    break;
                }
            }
        }
        public async delAllCard() {
            for (let i = 0; i < this._cardList.length; i++) {
                let card = this._cardList[i];
                if (card != null) {
                    this.delCard(card.cardObj);
                }
            }
        }

        public get cardIds():number[] {
            let ids = new Array<number>();
            for (let i = 0; i < this._cardList.length; i++) {
                let card = this._cardList[i];
                if (card != null && card.cardObj != null) {
                    ids.push(card.cardObj.cardId);
                }
            }
            return ids;
        }
    }

    export class RankFirstWnd extends Core.BaseWindow {

        private _closeBtn: fairygui.GButton;
        private _btnWei: fairygui.GButton;
        private _btnShu: fairygui.GButton;
        private _btnWu: fairygui.GButton;
        private _btnNext: fairygui.GButton;
        private _campCtr: fairygui.Controller;

        private _cardList: fairygui.GList;
        private _curCards: number[];
        private _touchBegin: boolean;

        private _rankHand: RankHand;

        private _refreshFreeBtn: fairygui.GButton;
        private _refreshBtn: fairygui.GButton;
        private _fightBtn: fairygui.GButton;

        public initUI() {
            super.initUI();
            this.modal = true;
            this.center();
            this.adjust(this.contentPane.getChild("background"));
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._closeBtn.addClickListener(() => {
                Core.ViewManager.inst.closeView(this);
            }, this);
            this._campCtr = this.contentPane.getController("c2");
            this._btnWei = this.contentPane.getChild("btnWei").asButton;
            this._btnShu = this.contentPane.getChild("btnShu").asButton;
            this._btnWu = this.contentPane.getChild("btnWu").asButton;

            this._btnNext = this.contentPane.getChild("nextBtn").asButton;
            this._btnNext.addClickListener(this._onNext, this);
            this._fightBtn = this.contentPane.getChild("fightBtn").asButton;
            this._fightBtn.addClickListener(this._onFight, this);
            this._refreshBtn = this.contentPane.getChild("refreshBtn").asButton;
            this._refreshFreeBtn = this.contentPane.getChild("refreshFreeBtn").asButton;
            this._refreshBtn.addClickListener(this._onRefreshBtn, this);
            this._refreshFreeBtn.addClickListener(this._onRefreshBtn, this);
            
            this._cardList = this.contentPane.getChild("cardList").asList;
            this._cardList.itemClass = CardPool.CardItem;
            this._cardList.addEventListener(fairygui.ItemEvent.CLICK, this._onListCard, this);

            this._rankHand = this.contentPane.getChild("handCard").asCom as RankHand;
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._curCards = [];
            this._rankHand.delAllCard();
            let cards = param[0] as pb.SeasonPvpChooseCardData;
            if (cards) {
                this.contentPane.getController("c1").selectedIndex = 1;
                this._refreshCardList(cards);
            } else {
                this.contentPane.getController("c1").selectedIndex = 0;
                this._campCtr.selectedIndex = param[1] - 1;
            }
        }

        private _refreshCardList(cardData: pb.SeasonPvpChooseCardData) { 
            
            if (cardData.FreeRefreshCnt > 0) {
                this._refreshFreeBtn.visible =true;
                this._refreshBtn.visible = false;
            } else if (cardData.JadeRefreshCnt > 0) {
                this._refreshFreeBtn.visible =false;
                this._refreshBtn.visible = true;
                this._refreshBtn.grayed = false;
                this._refreshBtn.touchable = true;
                if (Player.inst.hasEnoughBowlder(10)) {
                    this._refreshBtn.titleColor = 0xffffff00;
                } else {
                    this._refreshBtn.titleColor = 0xffff0000;
                }
            } else {
                this._refreshFreeBtn.visible =false;
                this._refreshBtn.visible = true;
                this._refreshBtn.grayed = true;
                this._refreshBtn.touchable = false;
            }

            let cardIds = cardData.CardIDs;
            this._cardList.removeChildrenToPool();
            cardIds.forEach(_cardId => {
                let cardCom = this._cardList.addItemFromPool() as CardPool.CardItem;
                let card = CardPool.CardPoolMgr.inst.getCollectCard(_cardId);
                cardCom.setData(card, true);

                cardCom.setRankSeasonMode();
                
                cardCom.getController("select").selectedIndex = 0;
                cardCom.addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onTouchCard, this);
            });
        }

        private _onListCard(evt: fairygui.ItemEvent) {
            
            let com = evt.itemObject as CardPool.CardItem;
            this._touchBegin = false;
            let cardId = com.cardObj.cardId;
            let index = this._curCards.indexOf(cardId);
            if(index == -1) {
                if (this._curCards.length >= 5) {
                    return;
                }
                com.getController("select").selectedIndex = 1;
                this._curCards.push(cardId);
                this._rankHand.addCard(com.cardObj);
            } else {
                com.getController("select").selectedIndex = 0;
                this._curCards.splice(index, 1);
                this._rankHand.delCard(com.cardObj);
            }
        }
        private _onTouchCard(evt: egret.TouchEvent) {
            let com = evt.target as CardPool.CardItem;
            this._touchBegin = true;
            let x = fairygui.GRoot.mouseX;
            let y = fairygui.GRoot.mouseY;
            fairygui.GTimers.inst.callDelay(600, ()=>{
                if (Math.abs(fairygui.GRoot.mouseX - x) > 15 || Math.abs(fairygui.GRoot.mouseY - y) > 20) {
                    return;
                }
                if (this._touchBegin) {
                    this._touchBegin = false;
                    Core.ViewManager.inst.open(ViewName.cardInfo, com.cardObj);
                }
            }, this);
        }

        private async _onNext() {
            let args = {Camp: this._campCtr.selectedIndex + 1};
            let result = await Net.rpcCall(pb.MessageID.C2S_SEASON_PVP_CHOOSE_CAMP, pb.SeasonPvpChooseCampArg.encode(args));
            if(result.errcode == 0) {
                let reply = pb.SeasonPvpChooseCardData.decode(result.payload);
                this._refreshCardList(reply);
                this.contentPane.getController("c1").selectedIndex = 1;
            }
        }
        private async _onRefreshBtn() {
            Core.TipsUtils.confirm(Core.StringUtils.TEXT(70182),() => {
                this._onRefresh();
            }, null);
        }
        private async _onRefresh() {
            
            let result = await Net.rpcCall(pb.MessageID.C2S_REFRESH_SEASON_PVP_CHOOSE_CARD, null);
            if (result.errcode == 0) {
                let reply = pb.SeasonPvpChooseCardData.decode(result.payload);
                this._refreshCardList(reply);
                this._rankHand.delAllCard();
                this._curCards = [];
            }
        }

        private async _onFight() {
            let cardIds = this._rankHand.cardIds;
            if (cardIds.length != 5) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60142));
                return;
            }
            let result = await Net.rpcCall(pb.MessageID.C2S_SEASON_PVP_CHOOSE_CARD, pb.SeasonPvpChooseCardArg.encode({CardIDs: cardIds}));
            if (result.errcode == 0) {
                Core.EventCenter.inst.dispatchEventWith(GameEvent.ShowRankCard, false, true);
                this.contentPane.getController("c1").selectedIndex = 0;
                Core.ViewManager.inst.closeView(this);
                PvpMgr.inst.beginMatch();
            }
        }

        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}