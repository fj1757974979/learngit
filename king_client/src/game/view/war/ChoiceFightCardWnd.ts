module War {

    export class WarChoiceFightCardItem extends fairygui.GComponent {

        private _card: CardPool.Card;
        private _cardObj: UI.CardCom;
        private _seletCtr: fairygui.Controller;
        private _teamCtr: fairygui.Controller;
        private _disableCtr: fairygui.Controller;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._cardObj = this.getChild("card").asCom as UI.CardCom;
            this._teamCtr = this.getController("team");
            this._seletCtr = this.getController("select");
            this._disableCtr = this.getController("disable");
        }
        public async setInfo(cardID: number) {
            this._card = CardPool.CardPoolMgr.inst.getCollectCard(cardID);
            this._cardObj.displayObject.cacheAsBitmap = false;
            this._cardObj.cardObj = this._card;
            this._cardObj.setNumText();
            this._cardObj.setName();
            this._cardObj.setSkill();
            this._cardObj.setCardImg();
            this._cardObj.setEquip();
            this._cardObj.setNumText();
            this._cardObj.setNumOffsetText();
            this._cardObj.setOwnFront();
            this._cardObj.setDeskBackground();
            this._cardObj.touchable = false;
            this._cardObj.displayObject.cacheAsBitmap = true;
        }

        public async setChoose(bool: boolean) {
            if (bool) {
                this._seletCtr.selectedIndex = 1;
            } else {
                this._seletCtr.selectedIndex = 0;
            }
        }
        public async setClick(bool: boolean) {
             this.touchable = bool;
             if (bool) {
                 this._disableCtr.selectedIndex = 0;
             } else {
                 this._disableCtr.selectedIndex = 1;
             }
         }
         public setInTeam(bool: boolean) {
             if (bool) {
                 this._teamCtr.selectedIndex = 1;
             } else {
                 this._teamCtr.selectedIndex = 0;
             }
         }
         public watch() {
             this._cardObj.watch();
         }
         public unwatch() {
             this._cardObj.unwatch();
         }
         public get cardID(): number {
             return this._card.cardId;
         }
         public get cardCamp(): Camp {
             return this._card.camp;
         }
         public get cardObj() {
             return this._card;
         }
         
    }
    let _SAVE_CAMP: string = "camp";
    let _SAVE_CARDS: string = "cards";
    export class ChoiceFightCardWnd extends Core.BaseWindow {

        private _SAVE_KEY: string = "warcards";
        

        private _weiList: fairygui.GList;
        private _shuList: fairygui.GList;
        private _wuList: fairygui.GList;
        private _campLists: Collection.Dictionary<Camp, fairygui.GList>;
        private _campCtr: fairygui.Controller;

        private _weiTapBtn: fairygui.GButton;
        private _shuTapBtn: fairygui.GButton;
        private _wuTapBtn: fairygui.GButton;
        private _confirmBtn: fairygui.GButton;
        private _questType: pb.CampaignMsType;
        private _closeBtn: fairygui.GButton;
        private _allCards: Collection.Dictionary<Camp, Array<CardPool.Card>>;
        // private _allCards: Array<CardPool.Card>;

        private _curCamp: Camp;

        private _allChooseCardDic: Collection.Dictionary<Camp, Array<number>>;
        private _weiChooseCards: Array<number>;
        private _shuChooseCards: Array<number>;
        private _wuChooseCards: Array<number>;

        private _mission: pb.IMilitaryOrder;
        private _saveData: any;

        public initUI() {
            super.initUI();
            this.modal = true;
            this.center();
            this.adjust(this.contentPane.getChild("bg"), Core.AdjustType.EXCEPT_MARGIN);
            this.contentPane.y += window.support.topMargin;

            this._campCtr = this.contentPane.getController("country");

            this._campLists = new Collection.Dictionary<Camp, fairygui.GList>();
            this._weiList = this.contentPane.getChild("weiCardList").asList;
            this._weiList.itemClass = WarChoiceFightCardItem;
            this._weiList.callbackThisObj = this;
            this._weiList.itemRenderer = this._renderCards;
            this._weiList.setVirtual();
            this._weiList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickCard, this);
            this._shuList = this.contentPane.getChild("shuCardList").asList;
            this._shuList.itemClass = WarChoiceFightCardItem;
            this._shuList.callbackThisObj = this;
            this._shuList.itemRenderer = this._renderCards;
            this._shuList.setVirtual();
            this._shuList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickCard, this);
            this._wuList = this.contentPane.getChild("wuCardList").asList;
            this._wuList.itemClass = WarChoiceFightCardItem;
            this._wuList.callbackThisObj = this;
            this._wuList.itemRenderer = this._renderCards;
            this._wuList.setVirtual();
            this._wuList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickCard, this);
            this._campLists.setValue(Camp.WEI, this._weiList);
            this._campLists.setValue(Camp.SHU, this._shuList);
            this._campLists.setValue(Camp.WU, this._wuList);

            this._weiTapBtn = this.contentPane.getChild("weiTapBtn").asButton;
            this._shuTapBtn = this.contentPane.getChild("shuTapBtn").asButton;
            this._wuTapBtn = this.contentPane.getChild("wuTapBtn").asButton;
            this._weiTapBtn.getChild("cardNumHint").visible = false;
            this._shuTapBtn.getChild("cardNumHint").visible = false;
            this._wuTapBtn.getChild("cardNumHint").visible = false;
            this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;
            this._closeBtn = this.contentPane.getChild("backBtn").asButton;
            
            this._confirmBtn.addClickListener(this._onConfirmBtn, this);
            this._closeBtn.addClickListener(this._onCloseBtn, this);
            this._weiTapBtn.addClickListener(this._onSelectCamp, this);
            this._shuTapBtn.addClickListener(this._onSelectCamp, this);
            this._wuTapBtn.addClickListener(this._onSelectCamp, this);
            
        }
        //获取卡信息
        private async _updateCardDic() {
            this._allCards = new Collection.Dictionary<Camp, Array<CardPool.Card>>();
            let heros = CardPool.CardPoolMgr.inst.getHasCollectCardsByCamp(Camp.HEROS);
            let collectedCard = CardPool.CardPoolMgr.inst.getHasCollectCardsByCamp(Camp.WEI);
            collectedCard = collectedCard.concat(heros);
            this._allCards.setValue(Camp.WEI, collectedCard);
            collectedCard = CardPool.CardPoolMgr.inst.getHasCollectCardsByCamp(Camp.SHU);
            collectedCard = collectedCard.concat(heros);
            this._allCards.setValue(Camp.SHU, collectedCard);
            collectedCard = CardPool.CardPoolMgr.inst.getHasCollectCardsByCamp(Camp.WU);
            collectedCard = collectedCard.concat(heros);
            this._allCards.setValue(Camp.WU, collectedCard);
            // this._allCards = this._allCards.concat(collectedCard);
            this._allCards.forEach((_camp, cards) => {
                cards = cards.sort((card1: CardPool.Card, card2: CardPool.Card) => {
                    if ((!card1.isInCampaignMission && !card2.isInCampaignMission) ||
                        (card1.isInCampaignMission && card2.isInCampaignMission)) {
                        if (card1.camp < card2.camp) {
                            return -1;
                        } else if (card1.camp > card2.camp) {
                            return 1;
                        } else {
                            if (card1.cardId < card2.cardId) {
                                return -1;
                            } else {
                                return 1;
                            }
                        }
                    } else {
                        if (card1.isInCampaignMission) {
                            return 1;
                        } else {
                            return -1;
                        }
                    }
                });
            })
        }

        private _renderCards(idx: number, item:fairygui.GObject) {
            let curCards = this._allChooseCardDic.getValue(this._curCamp);
            let campCards = this._allCards.getValue(this._curCamp);
            let card = campCards[idx];
            let com = <WarChoiceFightCardItem>item;
            com.addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onTouchItem, this);
            com.unwatch();
            com.setInfo(card.cardId);
            com.watch();
            
            if (card.isInCampaignMission) {
                com.setInTeam(true);
                com.setClick(false);
                com.setChoose(false);
                let index = curCards.indexOf(card.cardId);
                if (index >= 0) {
                    curCards.splice(index, 1);
                } 
            } else {
                com.setInTeam(false);
                com.setClick(true);
                if (curCards.indexOf(card.cardId) != -1) {
                    com.setChoose(true);
                } else {
                    com.setChoose(false);
                }
                if (curCards.length == 5) {
                    if (curCards.indexOf(card.cardId) != -1) {
                        com.setChoose(true);
                        com.setClick(true);
                    } else {
                        com.setChoose(false);
                        // com.setClick(false);
                    }
                } else {
                    com.setClick(true);
                }
            }
        }
        private _checkCards() {
            let cards = this._allChooseCardDic.getValue(this._curCamp);
            if (cards && cards.length > 0) {
                for(let i = cards.length - 1; i >= 0; i--) {
                    let card = CardPool.CardPoolMgr.inst.getCollectCard(cards[i]);
                    if (card.isInCampaignMission) {
                        cards.splice(i, 1);
                    } else if (card.amount <= 0 && card.level <= 1) {
                        cards.splice(i, 1);
                    }
                }
                this._allChooseCardDic.setValue(this._curCamp, cards);
            }
        }
        private _clearAllList() {
            this._campLists.forEach((_camp, _list) => {
                _list.numItems = 0;
            })
        }
        public async open(...param: any[]) {
            super.open(...param);

            this._weiChooseCards = new Array<number>();
            this._shuChooseCards = new Array<number>();
            this._wuChooseCards = new Array<number>();
            this._allChooseCardDic = new Collection.Dictionary<Camp, Array<number>>();
            this._allChooseCardDic.setValue(Camp.WEI, this._weiChooseCards);
            this._allChooseCardDic.setValue(Camp.SHU, this._shuChooseCards);
            this._allChooseCardDic.setValue(Camp.WU, this._wuChooseCards);
            this._clearAllList();
            this._mission = param[0] as pb.IMilitaryOrder;
            await this._updateCardDic();

            let key = `${Player.inst.uid}`;
            let saveData = egret.localStorage.getItem(this._SAVE_KEY);
            if (saveData && saveData != "") {
                // console.log(saveData);
                this._saveData = JSON.parse(saveData);
                if (!this._saveData[key]) {
                    // this._saveData = {};
                    this._saveData[key] = {};
                    this._saveData[key][_SAVE_CAMP] = "";
                    this._saveData[key][_SAVE_CARDS] = "";
                    this._curCamp = Camp.WEI;
                } else {
                    this._curCamp = JSON.parse(this._saveData[key][_SAVE_CAMP]);
                    // console.log(this._curCamp, JSON.parse(this._saveData[key][_SAVE_CARDS]));
                    this._allChooseCardDic.setValue(this._curCamp, JSON.parse(this._saveData[key][_SAVE_CARDS]));
                    this._campCtr.selectedIndex = this._curCamp - 1;
                    this._checkCards();
                }
            } else {
                this._saveData = {};
                this._saveData[key] = {};
                this._saveData[key][_SAVE_CAMP] = "";
                this._saveData[key][_SAVE_CARDS] = "";
                this._curCamp = Camp.WEI;
            }
            
            this._onSelectCamp();
        }
        private _onSelectCamp() {
            this._campLists.getValue(this._curCamp).numItems = 0;
            if (this._campCtr.selectedPage == "wei") {
                this._curCamp = Camp.WEI;
            } else if (this._campCtr.selectedPage == "shu") {
                this._curCamp = Camp.SHU;
            } else if (this._campCtr.selectedPage == "wu") {
                this._curCamp = Camp.WU;
            }
            this._campLists.getValue(this._curCamp).numItems = this._allCards.getValue(this._curCamp).length;
            this._campLists.getValue(this._curCamp).refreshVirtualList();
        }
        private _onTouchItem(evt: egret.TouchEvent) {
            let item = evt.target as WarChoiceFightCardItem;
            item["$touchBegin"] = true;
            let x = fairygui.GRoot.mouseX;
            let y = fairygui.GRoot.mouseY;
            fairygui.GTimers.inst.callDelay(600, ()=>{
                if (Math.abs(fairygui.GRoot.mouseX - x) > 15 || Math.abs(fairygui.GRoot.mouseY - y) > 20) {
                    return;
                }
                if (item["$touchBegin"]) {
                    Core.ViewManager.inst.open(ViewName.cardInfo, item.cardObj.collectCard);
                }
            }, this);
        }
        private async _onClickCard(evt: fairygui.ItemEvent) {
            let curCards = this._allChooseCardDic.getValue(this._curCamp);
            let item = evt.itemObject as WarChoiceFightCardItem;
            item["$touchBegin"] = null;
            if (Core.ViewManager.inst.getView(ViewName.cardInfo) && Core.ViewManager.inst.getView(ViewName.cardInfo).isShow()) {
                return;
            }
            let index = curCards.indexOf(item.cardID);
            if (index != -1) {
                curCards.splice(index, 1);
                item.setChoose(false);
            } else {
                if (curCards.length == 5) {
                    return ;
                }
                curCards.push(item.cardID);
                item.setChoose(true);
            }
            this._campLists.getValue(this._curCamp).refreshVirtualList();
        }
        private async _refreshCamp() {
            // this._curCamp = Camp.HEROS;
            // this._chooseCards.forEach( cardID => {
            //     let card = CardPool.CardPoolMgr.inst.getCollectCard(cardID);
            //     if (card.camp != Camp.HEROS) {
            //         this._curCamp = card.camp;
            //     }
            // })
            // this._cardList.refreshVirtualList();
            // this._cardList.numItems = this._allCards.length;
        }
        private async _onConfirmBtn() {
            let curCards = this._allChooseCardDic.getValue(this._curCamp);
            if (curCards.length < 5) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60142));
                return;
            }
            let ok = await WarMgr.inst.acceptMilitaryOrder(this._mission.Type, curCards, this._mission.TargetCity);
            if (ok) {
                let key = `${Player.inst.uid}`;
                this._saveData[key][_SAVE_CAMP] = JSON.stringify(this._curCamp);
                this._saveData[key][_SAVE_CARDS] = JSON.stringify(curCards);
                let dataStr = JSON.stringify(this._saveData);
                egret.localStorage.setItem(this._SAVE_KEY, dataStr);
                Core.ViewManager.inst.close(ViewName.questFightPanel);
                Core.ViewManager.inst.closeView(this);
            }
        }
        private _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }

        public async close(...param: any[]) {
            super.close(...param);
            // this._cardList.numItems = 0;
            this._clearAllList();
            this._allCards.clear();
        }
    }
}