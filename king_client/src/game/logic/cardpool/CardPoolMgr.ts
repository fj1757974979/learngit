module CardPool {

    export class CardPoolMgr {
        private static _inst: CardPoolMgr;

        private readonly _STORE_KEY: string = "hintNums";
        private _camp2CardHintNums: any;
        // {cardid: {level:cardData}}
        private _cardId2CardData: Collection.Dictionary<number, Collection.Dictionary<number, any>>;
        private _camp2Cards: Collection.Dictionary<Camp, Array<Card>>;
        // {cardId: Card}
        private _collectCards: Collection.Dictionary<number, Card>;
        private _upLevelWnd: Battle.RewardNewCard;

        private _avatarHintNum: number;

        public static get inst(): CardPoolMgr {
            if (!CardPoolMgr._inst) {
                CardPoolMgr._inst = new CardPoolMgr();
            }
            return CardPoolMgr._inst;
        }

        constructor() {
            this.initData();
        }

        public initData() {
            if (this._upLevelWnd) {
                this._upLevelWnd.hide();
            }
            this._cardId2CardData = new Collection.Dictionary<number, Collection.Dictionary<number, any>>();
            this._camp2Cards = new Collection.Dictionary<Camp, Array<Card>>();
            this._collectCards = new Collection.Dictionary<number, Card>();
            let allgids = Data.pool.keys;
            allgids.sort((a, b):number => {
                let aData = Data.pool.get(a);
                let bData = Data.pool.get(b);
                return aData.cardOrder > bData.cardOrder? 1 : -1;
            });
            allgids.forEach(gcardid => {
                let cardData = Data.pool.get(gcardid);
                if (this.isSystemCard(cardData)) {
                    return;
                }
                let level2Card = this._cardId2CardData.getValue(cardData.cardId);
                if (!level2Card) {
                    level2Card = new Collection.Dictionary<number, any>();
                    this._cardId2CardData.setValue(cardData.cardId, level2Card);
                }
                level2Card.setValue(cardData.level, cardData);

                if (!this._collectCards.containsKey(cardData.cardId) && cardData.level == 1) {
                    let card = new Card(cardData);
                    this._collectCards.setValue(cardData.cardId, card);
                    let campCardList = this._camp2Cards.getValue(card.camp);
                    if (!campCardList) {
                        campCardList = [];
                        this._camp2Cards.setValue(card.camp, campCardList);
                    }
                    campCardList.push(card);
                }
            });
        }

        public isSystemCard(cardData:any) {
            return cardData.cardId == 0 || cardData.campaign == 1;
        }

        public onLogin(collectCards:Array<any>) {
            if (!collectCards) {
                return;
            }

            collectCards.forEach(collectData => {
                let card = this.getCollectCard(collectData.CardId);
                if (!card) {
                    console.error("onLogin no card %d %d", collectData.CardId, collectData.Level);
                    return;
                }
                card.init(collectData);
            });
            this._loadCardHintNumData();
        }

        public updateCollectCards(collectCards:Array<pb.ICardInfo>) {
            if (!collectCards) {
                return;
            }

            collectCards.forEach(collectData => {
                let card = this.getCollectCard(collectData.CardId);
                if (!card) {
                    console.debug("updateCollectCards no card %d %d", collectData.CardId, collectData.Level);
                    return;
                }
                let preAmount = card.amount;
                card.update(collectData);

                if (collectData.Level > 0) {
                    let aftAmount = card.amount;
                    if (card.rare == CardQuality.LIMITED && preAmount <= 0 && aftAmount > 0) {
                        Core.EventCenter.inst.dispatchEventWith(GameEvent.AddLimitedCardEv, false, card.camp);
                    }
                }
            })
        }

        public getCardData(cardId:number, level:number): any {
            level = level <= 0 ? 1 : level;
            let level2CardData = this._cardId2CardData.getValue(cardId);
            if (level2CardData) {
                return level2CardData.getValue(level);
            }
            return null;
        }

        public getCollectCardsByCamp(camp:Camp, showHide:boolean = true): Array<Card> {
            if (showHide) {
                return this._camp2Cards.getValue(camp);
            } else {
                let cards = this._camp2Cards.getValue(camp);
                let ret: Array<Card> = [];
                cards.forEach(card => {
                    if(card.order > 0) {
                        if (card.rare == CardQuality.LIMITED) {
                            if (card.amount > 0) {
                                ret.push(card);
                            }
                        } else {
                            ret.push(card);
                        }
                    }
                });
                return ret;
            }
        }
        public getHasCollectCardsByCamp(camp: Camp): Array<Card> {
            let cards = this._camp2Cards.getValue(camp);
            let ret: Array<Card> = [];
            cards.forEach(card => {
                    if(card.order > 0) {
                        if (card.rare == CardQuality.LIMITED) {
                            if (card.amount > 0) {
                                ret.push(card);
                            }
                        } else if (card.amount > 0 || card.level > 1) {
                            ret.push(card);
                        }
                    }
                });
                return ret;
        }
        
        public getCollectCard(cardId:number): Card {
            return this._collectCards.getValue(cardId);
        }

        public async onEnterCardPool() {
            let viewMgr = Core.ViewManager.inst;
            await viewMgr.open(ViewName.cardpool);
            //viewMgr.close(ViewName.home);
        }

        public treatCard(cardId: number) {
            Net.rpcCall(pb.MessageID.C2S_CARD_TREAT, pb.TargetCard.encode({"CardId": cardId}));
        }

        public reliveCard(cardId: number) {
            Net.rpcCall(pb.MessageID.C2S_CARD_RELIVE, pb.TargetCard.encode({"CardId": cardId}));
        }

        public async upLevelCard(cardId: number, useJade: boolean) {
            let result = await Net.rpcCall(pb.MessageID.C2S_UPLEVEL_CARD, pb.UpLevelCardArg.encode({"CardId": cardId, "IsConsumeJade": useJade}));
	        
            if (result.errcode != 0) {
                return false;
            }

            fairygui.GTimers.inst.callDelay(100, CardInfoWnd.inst.playUplevelEffect, CardInfoWnd.inst, null);
            return true;
        }

        private _loadCardHintNumData() {
            let localDataStr = egret.localStorage.getItem(this._STORE_KEY);
            
            if (!localDataStr || localDataStr == "") {
                localDataStr = "{}";
            }
            this._camp2CardHintNums = JSON.parse(localDataStr);
            let uid = `${Player.inst.uid}`;
            if (!this._camp2CardHintNums[uid]) {
                this._camp2CardHintNums[uid] = {"newCards":{}, "newAvatars":{}};
            }
                this._camp2CardHintNums[uid]["campNums"] = {};
                [Camp.WEI, Camp.SHU, Camp.WU, Camp.HEROS].forEach(camp => {
                    this._camp2CardHintNums[uid]["campNums"][`${camp}`] = 0;
                });
                let cardIds = this._collectCards.keys();
                for (let cardId of cardIds) {
                    let card = this._collectCards.getValue(cardId);
                    if (!card.isMaxLevel() && 
                        card.amount >= card.maxAmount && 
                        card.order > 0 && 
                        card.rare != CardQuality.LIMITED) {
                        let camp = card.camp;
                        let num = this._camp2CardHintNums[uid]["campNums"][`${camp}`];
                        this._camp2CardHintNums[uid]["campNums"][`${camp}`] = num + 1;
                    }
                }
                // this._saveCardHintNumData();
            // }
            console.debug(`====================== ${JSON.stringify(this._camp2CardHintNums[uid])}`);

            // 兼容下老号
            if (!this._camp2CardHintNums[uid]["newCards"]) {
                this._camp2CardHintNums[uid]["newCards"] = {};
                this._saveCardHintNumData();
            }

            if (!this._camp2CardHintNums[uid]["newAvatars"]) {
                this._camp2CardHintNums[uid]["newAvatars"] = {};
                this._saveCardHintNumData();
            }

            let newCardsInfo = this._camp2CardHintNums[uid]["newCards"];
            for (let strCardId in newCardsInfo) {
                let cardId = parseInt(strCardId);
                let card = this.getCollectCard(cardId);
                if (card) {
                    if (card.amount > 0) {
                        card.initIsNew(newCardsInfo[`${cardId}`]);
                        if (newCardsInfo[`${cardId}`]) {
                            let camp = card.camp;
                            let num = this._camp2CardHintNums[uid]["campNums"][`${camp}`];
                            this._camp2CardHintNums[uid]["campNums"][`${camp}`] = num + 1;
                        }
                    } else {
                        newCardsInfo[`${cardId}`] = false;
                        card.initIsNew(false);
                    }
                }
            }

            // this._saveCardHintNumData();

            this._avatarHintNum = 0;
            let newAvatars = this._camp2CardHintNums[uid]["newAvatars"];
            for (let strCardId in newAvatars) {
                if (newAvatars[strCardId]) {
                    ++ this._avatarHintNum;
                }
            }
        }

        private _saveCardHintNumData() {
            let dataStr = JSON.stringify(this._camp2CardHintNums);
            egret.localStorage.setItem(this._STORE_KEY, dataStr);
        }

        public getCampCardHintNum(camp: Camp = 0) {
            if (camp == 0) {
                let ret = 0;
                [Camp.WEI, Camp.SHU, Camp.WU, Camp.HEROS].forEach(camp => {
                    ret += this._camp2CardHintNums[`${Player.inst.uid}`]["campNums"][`${camp}`];
                });
                return ret;
            } else {
                return this._camp2CardHintNums[`${Player.inst.uid}`]["campNums"][`${camp}`];
            }
        }

        public modifyCampCardHintNum(camp: Camp, mod: number) {
            let num = this._camp2CardHintNums[`${Player.inst.uid}`]["campNums"][`${camp}`];
            num = mod + num < 0 ? 0 : mod + num;
            this._camp2CardHintNums[`${Player.inst.uid}`]["campNums"][`${camp}`] = num;
            // this._saveCardHintNumData();
            Core.EventCenter.inst.dispatchEventWith(Core.Event.CardHintNumChangeEv, false, camp);
        }

        public isCardNew(cardId: number): boolean {
            let uid = `${Player.inst.uid}`;
            return this._camp2CardHintNums[uid]["newCards"][`${cardId}`] == true;
        }

        public isAvatarNew(cardId: number): boolean {
            let uid = `${Player.inst.uid}`;
            return this._camp2CardHintNums[uid]["newAvatars"][`${cardId}`] == true;
        }

        public setCardNew(cardId: number, isNew: boolean) {
            let uid = `${Player.inst.uid}`;
            let old = this._camp2CardHintNums[uid]["newCards"][`${cardId}`];
            if (old == null) {
                old = false;
            }
            if (!(isNew && old)) {
                this._camp2CardHintNums[uid]["newCards"][`${cardId}`] = isNew;
                this._saveCardHintNumData();
            }
        }

        public setAvatarNew(cardId: number, isNew: boolean) {
            let uid = `${Player.inst.uid}`;
            let old = this._camp2CardHintNums[uid]["newAvatars"][`${cardId}`];
            if (old == null) {
                old = false;
            }
            if (!(isNew && old)) {
                this._camp2CardHintNums[uid]["newAvatars"][`${cardId}`] = isNew;
                this._saveCardHintNumData();
                if (isNew) {
                    this._setAvatarHintNum(this._avatarHintNum + 1);
                } else {
                    this._setAvatarHintNum(Math.max(0, this._avatarHintNum - 1));
                }
            }
        }

        private _setAvatarHintNum(num: number) {
            this._avatarHintNum = num;
            Core.EventCenter.inst.dispatchEventWith(Core.Event.AvatarHintNumChangeEv);
        }

        public clearAvatarHintNum() {
            this._avatarHintNum = 0;
            this._camp2CardHintNums[`${Player.inst.uid}`]["newAvatars"] = {};
            this._saveCardHintNumData();
            Core.EventCenter.inst.dispatchEventWith(Core.Event.AvatarHintNumChangeEv);
        }

        public get avatarHintNum(): number {
            return this._avatarHintNum;
        }

        public formatSkillDesc(skillData:any, cardLevel:number, ) {
            return "<font strokecolor=0x000000 stroke=2><b><i>" + skillData.name + ":</i> </b></font>" + parse2html(skillData.desTra, cardLevel);
        }
    }

    function onLogout() {
        try {
            CardPoolMgr.inst.initData();
        } catch (e) {
            console.error(e);
        }
    }

    export function init() {
        initRpc();
        Player.inst.addEventListener(Player.LogoutEvt, onLogout, null);

        let registerView = Core.ViewManager.inst.registerView.bind(Core.ViewManager.inst);
        let createObject = fairygui.UIPackage.createObject;

        registerView(ViewName.cardInfo, () => {
            let cardInfoWnd = new MyCardInfoWnd();
            cardInfoWnd.contentPane = createObject(PkgName.cardpool, ViewName.cardInfo).asCom;
            return cardInfoWnd;
        });
        
        registerView(ViewName.cardpool, () => {
            return createObject(PkgName.cardpool, ViewName.cardpool, CardPoolView);
        });

        registerView(ViewName.cardInfoOther, () => {
            let cardInfoOtherWnd = new OtherCardInfo();
            cardInfoOtherWnd.contentPane = createObject(PkgName.cardpool, ViewName.cardInfoOther).asCom;
            return cardInfoOtherWnd;
        });
	    registerView(ViewName.skillFaq, () => {
	        let skillFaqWnd = new SkillFaqWnd();
            skillFaqWnd.contentPane = createObject(PkgName.cardpool, ViewName.skillFaq).asCom;
            return skillFaqWnd;
	    });
        registerView(ViewName.skinView, () => {
            let skinWnd = new SkinWnd();
            skinWnd.contentPane = createObject(PkgName.cards, ViewName.skinView).asCom;
            return skinWnd;
        })
        registerView(ViewName.cardUpWnd, () => {
            let cardUpWnd = new CardUpWnd();
            cardUpWnd.contentPane = createObject(PkgName.cards, ViewName.cardUpWnd).asCom;
            return cardUpWnd;
        })
    }
}
