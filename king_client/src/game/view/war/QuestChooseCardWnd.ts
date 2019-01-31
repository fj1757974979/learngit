module War {

    export class QuestChooseCardWnd extends Core.BaseWindow {

        private _cardList: fairygui.GList;
        private _confirmBtn: fairygui.GButton;
        private _questType: pb.CampaignMsType;
        private _closeBtn: fairygui.GButton;
        private _timeText: fairygui.GTextField;
        private _allCards: Array<CardPool.Card>;
        // private _campCardDic: Collection.Dictionary<Camp, Array<CardPool.Card>>;
        private _maxTime: number;
        private _curCamp: Camp;
        private _chooseCards: Array<number>;
        private _maxPower: number;
        private _mission: pb.ICampaignMission;
        private _type: WarMsType;
        private _power: fairygui.GTextField;

        public initUI() {
            super.initUI();
            this.modal = true;
            this.center();

            this._timeText = this.contentPane.getChild("time").asTextField;
            this._power = this.contentPane.getChild("power").asTextField;
            this._cardList = this.contentPane.getChild("headList").asList;
            this._cardList.itemClass = WarCardHeadCom;
            this._cardList.callbackThisObj = this;
            this._cardList.itemRenderer = this._renderCards;
            this._cardList.setVirtual();
            this._cardList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickHead, this);
            this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._confirmBtn.addClickListener(this._onConfirmBtn, this);
            this._closeBtn.addClickListener(this._onCloseBtn, this);
        }

        private _updateHeadList() {
            
            //TODO 根据特殊属性排序
            // let newCards = new Array<CardPool.Card>();
            // this._campCardDic.forEach( (camp, cards) => {
            //     if (this._curCamp == Camp.HEROS) {
            //         newCards = newCards.concat(cards);
            //     } else if (this._curCamp == camp || camp == Camp.HEROS) {
            //         newCards = newCards.concat(cards);
            //     }
            // })
            
            // this._addListItems(this._allCards);
        }
        // private async _addListItems(cards: CardPool.Card[]) {
        //     this._cardList.removeChildrenToPool();
        //     cards.forEach( card => {
        //         if (card.amount > 0 || card.level > 1) {
        //             let com = this._cardList.addItemFromPool() as WarCardHeadCom;
        //             com.setInfo(card.cardId, this._type);
        //             if (Pvp.PvpMgr.inst.isCardInTeam(card.cardId)) {
        //                 com.setInTeam(true);
        //             } else {
        //                 com.setInTeam(false);
        //                 if (this._chooseCards.indexOf(card.cardId) != -1) {
        //                     com.setChoose(true);
        //                 } else {
        //                     com.setChoose(false);
        //                 }
        //                 if (this._chooseCards.length == 5) {
        //                     if (this._chooseCards.indexOf(card.cardId) != -1) {
        //                         com.setChoose(true);
        //                         com.setClick(true);
        //                     } else {
        //                         com.setChoose(false);
        //                         com.setClick(false);
        //                     }
        //                 } else if (this._curCamp != Camp.HEROS) {
        //                     if (card.camp == this._curCamp || card.camp == Camp.HEROS) {
        //                         com.setClick(true);
        //                     } else {
        //                         com.setClick(false);
        //                     }
        //                 }
        //             }
        //         }
        //     })
            
        // }
        private _updateList() {
            // this._cardList.removeChildrenToPool();
            this._cardList.numItems = 0;
            // this._campCardDic = new Collection.Dictionary<Camp, Array<CardPool.Card>>();
            this._allCards = new Array<CardPool.Card>();
            
            let collectedCard = CardPool.CardPoolMgr.inst.getHasCollectCardsByCamp(Camp.WEI);
            // this._campCardDic.setValue(Camp.WEI, collectedCard);
            this._allCards = this._allCards.concat(collectedCard);
            collectedCard = CardPool.CardPoolMgr.inst.getHasCollectCardsByCamp(Camp.SHU);
            // this._campCardDic.setValue(Camp.SHU, collectedCard);
            this._allCards = this._allCards.concat(collectedCard);
            collectedCard = CardPool.CardPoolMgr.inst.getHasCollectCardsByCamp(Camp.WU);
            // this._campCardDic.setValue(Camp.WU, collectedCard);
            this._allCards = this._allCards.concat(collectedCard);
            collectedCard = CardPool.CardPoolMgr.inst.getHasCollectCardsByCamp(Camp.HEROS);
            // this._campCardDic.setValue(Camp.HEROS, collectedCard);
            this._allCards = this._allCards.concat(collectedCard);
            this._allCards.sort((cardA, cardB) => {
                let pA = cardA.getPower(this._type);
                let pB = cardB.getPower(this._type);
                return pB - pA;
            })
            // this._addListItems(this._allCards);
            this._cardList.numItems = this._allCards.length;
        }

        private _renderCards(idx: number, item:fairygui.GObject) {
            let card = this._allCards[idx];
            let com = <WarCardHeadCom>item;
            com.setInfo(card.cardId, this._type);
            //竞标赛中禁止选择
            if (Pvp.PvpMgr.inst.isCardInSeason(card.cardId)) {
                com.setInTeam(2);
                com.setClick(false);
                com.setChoose(false);
                return;
            }
            if (Pvp.PvpMgr.inst.isCardInTeam(card.cardId)) {
                com.setInTeam(1);
            } else {
                com.setInTeam(0);
            }
            if (this._chooseCards.indexOf(card.cardId) != -1) {
                com.setChoose(true);
            } else {
                    com.setChoose(false);
            }
            if (this._chooseCards.length == 5) {
                if (this._chooseCards.indexOf(card.cardId) != -1) {
                    com.setChoose(true);
                    com.setClick(true);
                } else {
                    com.setChoose(false);
                    com.setClick(false);
                }
            } else if (this._curCamp != Camp.HEROS) {
                if (card.camp == this._curCamp || card.camp == Camp.HEROS) {
                    com.setClick(true);
                } else {
                    com.setClick(false);
                }
            }
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._chooseCards = new Array<number>();
            this._mission = param[0] as pb.ICampaignMission;
            this._curCamp = Camp.HEROS;
            this._maxPower = 0;
            let a = <number>this._mission.Type;
            this._type = <WarMsType>a;
            this._timeText.visible = true;
            if (this._type == WarMsType.Transport) {
                this._maxTime = this._mission.TransportMaxTime;
                this._timeText.text = `${Core.StringUtils.secToString(this._mission.TransportMaxTime, "hm")}`; 
                this._power.text = Core.StringUtils.TEXT(70269);              
            } else {
                this._maxTime = Utils.warMsType2time(this._type);
                //this._timeText.text = `${Core.StringUtils.secToString(Utils.warMsType2time(this._type), "hm")}`;
                this._timeText.text = Core.StringUtils.TEXT(70270);
                this._power.text = WarQuest.warMsPower2text(this._type).toString();
            }
            this._updateList();
            this._updateHeadList();
        }

        private async _onClickHead(evt: fairygui.ItemEvent) {
            let com = evt.itemObject as WarCardHeadCom;
            let index = this._chooseCards.indexOf(com.cardID);
            if (index != -1) {
                this._chooseCards.splice(index, 1);
                com.setChoose(false);
                // this._timeText.visible = false;
                this._maxPower -= com.cardPower;
            } else {
                if (this._chooseCards.length == 5) {
                    return ;
                }
                this._chooseCards.push(com.cardID);
                this._maxPower += com.cardPower;
                com.setChoose(true);
            }
            this._refreshTime();
        this._refreshCamp();

        }
        private async _refreshTime() {
            if (this._chooseCards) {
                    if (this._type != WarMsType.Transport) {
                        if (this._maxPower == 0) {
                            this._timeText.text = Core.StringUtils.TEXT(70270);
                            //this._timeText.text = `${Core.StringUtils.secToString(Utils.warMsType2time(this._type), "hm")}`;
                        } else {
                            this._timeText.text = `${Core.StringUtils.secToString(Math.ceil(Utils.warMsType2time(this._type) / this._maxPower), "hm")}`;
                        }
                    }
                }
        }
        private async _refreshCamp() {
            this._curCamp = Camp.HEROS;
            this._chooseCards.forEach( cardID => {
                let card = CardPool.CardPoolMgr.inst.getCollectCard(cardID);
                if (card.camp != Camp.HEROS) {
                    this._curCamp = card.camp;
                }
            })
            // this._updateHeadList();
            // this._addListItems(this._allCards);
            // this._cardList.numItems = 0;
            this._cardList.numItems = this._allCards.length;
        }
        private async _onConfirmBtn() {
            if (this._chooseCards.length < 5) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70268));
                return;
            }
            let args = null;
            // if (this._mission.Type == pb.CampaignMsType.Transport) {
            //     args = {Type: this._mission.Type, Cards: this._chooseCards, TransportTargetCity: this._mission.TransportTargetCity};
            // } else {
            //     args = {Type: this._mission.Type, Cards: this._chooseCards};
            // }
            args = {Type: this._mission.Type, Cards: this._chooseCards, TransportTargetCity: this._mission.TransportTargetCity};
            let result = await Net.rpcCall(pb.MessageID.C2S_ACCEPT_CAMPAIGN_MISSION, pb.AcceptCampaignMissionArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.AcceptCampaignMissionReply.decode(result.payload);
                let view = Core.ViewManager.inst.getView(ViewName.warQuestPanel) as WarQuestWnd;
                view.getNewMission(this._mission, reply.RemainTime, this._chooseCards);
                view.refesh(reply.Missions);

                
                Core.ViewManager.inst.closeView(this);
            }
        }
        private _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }

        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}