module Reborn {
    
    export class RebornCardData {

        private _card: CardPool.Card;
        private _feat: number;
        
        public setCardData(card: CardPool.Card) {
            this._card = card;
            this._feat = card.amount * Data.card_caculation.get(card.rare).honor;
        }

        public get card(): CardPool.Card {
            return this._card;
        }
        public get feat(): number {
            return this._feat;
        }
        public get amount(): number {
            return this._card.amount;
        }
    }
    
    export class RebornMgr {
        
        private static _inst: RebornMgr;

        private _refineCards: Collection.Dictionary<number, RebornCardData>;
        private _refineCardIndexs: Array<number>; 
        private _refineRareDic: Collection.Dictionary<number, number>;
        private _refineCardFeats: number;

        private _rebornCards: Collection.Dictionary<number, number>;
        private _rebornCart2Feats: number;
        private _rebornHeroList: Array<number>;
        private _rebornHeroList2: Array<number>; //限定武将
        private _rebornFame: number;
        private _remainDay: number;
        private _rebornCnt: number;
        private _gold: number;
        private _canRebornTeam: number;
        private _team: number;
        private _maxTeam: number;
        private _treasureId: any;

        private _cardKey: number;
        private _privKey: number;
        private _equipKey: number;

        private _levelCardNum = [0,10,50,130,330];

        public static get inst(): RebornMgr {
            if (!RebornMgr._inst) {
                RebornMgr._inst = new RebornMgr();
            }
            return RebornMgr._inst;
        }

        public async refresh() {
            this._refineCardFeats = 0;
            this._rebornCart2Feats = 0;
            this._gold = 0;
            this._canRebornTeam = Data.reborn_treausre.keys[0];
            let ok = await this._fetchRebornData();
            if (ok) {
                this._countCards();
            }
        }

        private async _fetchRebornData() {
            this._rebornFame = 0;
            this._remainDay = 0;
            this._rebornCnt = 0;
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_REBORN_DATA, null);
            if (result.errcode == 0) {
                let reply = pb.RebornData.decode(result.payload);
                this._rebornFame = reply.Prestige;
                this._remainDay = reply.RemainDay;
                this._rebornCnt = reply.Cnt;
                Player.inst.rebornCnt = reply.Cnt;
            }
            return true;
        }

        private async _countCards() {
            this._rebornCards = new Collection.Dictionary<number, number>();
            this._rebornHeroList = new Array<number>();
            this._rebornHeroList2 = new Array<number>();
            this._refineCards = new Collection.Dictionary<number, RebornCardData>();
            this._refineCardIndexs = new Array<number>();
            this._refineRareDic = new Collection.Dictionary<number, number>();
            for (let i = 1; i <= 5; i++) {
                this._rebornCards.setValue(i, 0);
                this._refineRareDic.setValue(i, 0);
            }
            for (let i = 1; i <= 8; i++) {
                let cards = Data.rank.get(i).unlock as Array<number>;
                if (cards.length > 0) {
                   this._rebornHeroList = this._rebornHeroList.concat(cards);
                } 
            }
            
            let cards: Array<CardPool.Card> = [];
			[Camp.WEI, Camp.SHU, Camp.WU, Camp.HEROS].forEach(camp => {
				let collectedCard = CardPool.CardPoolMgr.inst.getCollectCardsByCamp(camp, false);
				cards = cards.concat(collectedCard);
			});

			cards.forEach(card => {
                //reborn
                if (card.level >= 1 && card.rare < 99) {
                    let cardnum = this._rebornCards.getValue(card.rare);
                    cardnum += card.amount + this._levelCardNum[card.level - 1];
                    this._rebornCards.setValue(card.rare, cardnum);
                    let gold = this._coundCardLevelGold(card.gcardId, card.level);
                    // console.log(`卡名${card.name}，星数${card.rare}，等级${card.level}，余卡${card.amount}，共卡${card.amount + this._levelCardNum[card.level - 1]}，金币消耗${gold}`);
                    this._gold += gold;
                } else if (card.rare == 99) {
                    this._rebornHeroList2.push(card.cardId);
                }
                //refine
				if (card.amount > 0 && card.level >= 5) {
                    // console.log(card.name,card.amount);
                    let cardData = new RebornCardData();
                    cardData.setCardData(card);
                    this._refineCards.setValue(card.cardId, cardData);
                    this._refineCardIndexs.push(card.cardId);
                    this._refineCardFeats += cardData.feat;

                    let cardnum = this._refineRareDic.getValue(card.rare);
                    cardnum += card.amount;
                    this._refineRareDic.setValue(card.rare, cardnum);

				}
			});

            this._rebornCards.forEach((_rare, _num) => {
                this._rebornCart2Feats += _num * Data.card_caculation.get(_rare).honor;
            });
            this._refineCardIndexs.sort((a, b) => {
                return this._refineCards.getValue(b).amount - this._refineCards.getValue(a).amount;
            })

            let pvpLev = Pvp.PvpMgr.inst.getPvpLevelByScore(Player.inst.getResource(ResType.T_SCORE));
            this._team = Pvp.Config.inst.getPvpTeam(pvpLev);
            let maxPvpLev = Pvp.PvpMgr.inst.getPvpLevelByScore(Player.inst.getResource(ResType.T_MAX_SCORE));
            this._maxTeam = Pvp.Config.inst.getPvpTeam(maxPvpLev);
            if (this._team >= this.canRebornTeam) {
                this._treasureId = Data.reborn_treausre.get(this._team).treasure;
            } else {
                this._treasureId = null;
            }
            
        }

        private _coundCardLevelGold(gcardId: number, cardLev: number) {
            let gold = 0;
            if (cardLev > 1) {
                return gold += Data.pool.get(gcardId - 1).levelupGold + this._coundCardLevelGold(gcardId - 1, cardLev - 1);
            } else {
                return gold;
            }
        }

        public async onReborn() {
            if (this._treasureId == null) {
                return false;
            }
            let result = await Net.rpcCall(pb.MessageID.C2S_REBORN, null);
            if (result.errcode == 0) {
                let reply = pb.RebornReply.decode(result.payload);
                Core.EventCenter.inst.dispatchEventWith(GameEvent.ModifyNameEv, false, reply.NewName);
                Player.inst.name = reply.NewName;
                let rewardData = new Pvp.GetRewardData();
                rewardData.addTreasure(reply.TreasureReward);
                rewardData.addTreasureId(this._treasureId)
                rewardData.feat = reply.Feats;
                rewardData.fame = reply.Prestige;
                Core.ViewManager.inst.open(ViewName.getRewardWnd, rewardData);
                RebornMgr.inst.refresh();
                let arr = await Pvp.PvpMgr.inst.onEnterPvp();
                let view = (<Pvp.TeamView>Core.ViewManager.inst.getView(ViewName.team))
                view.refresh(arr[0], arr[1]);
                Core.EventCenter.inst.dispatchEventWith(GameEvent.BuyRebornGoods, false);
                Core.EventCenter.inst.dispatchEventWith(GameEvent.SeasonEnd);
                return true;
            } else if (result.errcode == 4) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70377));
                return false;
            }
            return false;
        }
        public async onAllRefineCard() {
            let cardIds = new Array<number> ();
            this._refineCards.forEach(_cardId => {
                cardIds.push(_cardId);
            })
            let args = {
                "CardIDs":cardIds,
            }
            let result = await Net.rpcCall(pb.MessageID.C2S_REFINE_CARD, pb.RefineCardArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.RefineCardReply.decode(result.payload);
                let rewardData = new Pvp.GetRewardData();
                rewardData.feat = reply.Feats;
                Core.ViewManager.inst.open(ViewName.getRewardWnd, rewardData);
                await this.refresh();
                Core.EventCenter.inst.dispatchEventWith(GameEvent.BuyRebornGoods, false);
                return true;
            }
            return false;
        }
       
        public get rebornCards() {
            return this._rebornCards;
        }
        public get rebornFeats(): number {
            return this._rebornCart2Feats;
        }
        public get rebornHeros() {
            return this._rebornHeroList;
        }
        public get rebornHeros2() {
            return this._rebornHeroList2;
        }
        public get upLevGold(): number {
            return this._gold;
        }
        public get upLevGod2Fame(): number {
            let feat = Math.floor(this._gold / Data.gold_caculation.keys[0]);
            return feat;
        }
        public get reborn2Fame(): number {
            return this._rebornFame;
        }
        public get fames(): number {
            return this.reborn2Fame + this.upLevGod2Fame;
        }
         public get refineFeats(): number {
            return this._refineCardFeats;
        }
        public get refineCards() {
            return this._refineCards;
        }
        public get refineCardIndexs() {
            return this._refineCardIndexs;
        }
        public get refineRareDic() {
            return this._refineRareDic;
        }
        public get canRebornTeam() {
            return this._canRebornTeam;
        }
        public get team() {
            return this._team;
        }
        public get maxTeam() {
            return this._maxTeam;
        }
        public get cardKey() {
            return this._cardKey;
        }
        public get remainDay() {
            return this._remainDay;
        }
        public get rebornCnt() {
            return this._rebornCnt;
        }

        public async openCardInfo(key: number, cardObj:any) {
            this._cardKey = key;
            Core.ViewManager.inst.open(ViewName.featCardInfo, cardObj, null, CardPool.BuyType.Reborn);
        }
        public async onBuyCard() {
            let generalData = Data.sold_general.get(this._cardKey);
            if (!Player.inst.hasEnoughFeat(generalData.honorPrice)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70149));
                return;
            }
            let args = {
                "Type": pb.BuyRebornGoodsArg.GoodsType.Card,
                "GoodsID":this._cardKey,
            }
            let result = await Net.rpcCall(pb.MessageID.C2S_BUY_REBORN_GOODS, pb.BuyRebornGoodsArg.encode(args));
            if (result.errcode == 0) {
                let rewardData = new Pvp.GetRewardData();
                rewardData.addCards(generalData.cardId, 1);
                Core.ViewManager.inst.close(ViewName.featCardInfo);
                Core.ViewManager.inst.open(ViewName.getRewardWnd, rewardData);
                Core.EventCenter.inst.dispatchEventWith(GameEvent.BuyRebornGoods);
            }
        }

        public async openPrivInfo(key: number) {
            this._privKey = key;
            Core.ViewManager.inst.open(ViewName.privInfo, key);
        }

        public async onBuyPriv() {
            let privData = Data.sold_priv.get(this._privKey);
            if (!Player.inst.hasEnoughFame(privData.famePrice)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70165));
                return;
            }
            let args = {
                "Type": pb.BuyRebornGoodsArg.GoodsType.Privilege,
                "GoodsID":this._privKey,
            }
            let result = await Net.rpcCall(pb.MessageID.C2S_BUY_REBORN_GOODS, pb.BuyRebornGoodsArg.encode(args));
            if (result.errcode == 0) {
                Player.inst.addPrivilege(this._privKey);
                let privData = Data.priv_config.get(this._privKey);
                let rewardData = new Pvp.GetRewardData();
                rewardData.addOther(privData.name ,`reborn_${privData.icon}_png`);
                Core.ViewManager.inst.close(ViewName.privInfo);
                Core.ViewManager.inst.open(ViewName.getRewardWnd, rewardData);
                Core.EventCenter.inst.dispatchEventWith(GameEvent.BuyRebornGoods);
            }
        }
        public async openEquipInfo(key: number) {
            this._equipKey = key;
            Core.ViewManager.inst.open(ViewName.rebornEquipInfo, this._equipKey, CardPool.BuyType.Reborn);
        }
        public async onBuyEquip() {
            if (!Player.inst.hasEnoughEquipMoney()) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70186));
                return;
            }
            let args = {
                "Type": pb.BuyRebornGoodsArg.GoodsType.Equip,
                "GoodsID":this._equipKey,
            }
            let result = await Net.rpcCall(pb.MessageID.C2S_BUY_REBORN_GOODS, pb.BuyRebornGoodsArg.encode(args));
            if (result.errcode == 0) {
                let equipData1 = Data.sold_equip.get(this._equipKey);
                let equipData = Equip.EquipMgr.inst.getEquipData(equipData1.equipId);
                equipData.setEquip(equipData1.equipId);
                let rewardData = new Pvp.GetRewardData();
                rewardData.addOther(equipData.equipName , equipData.equipIcon);
                Core.ViewManager.inst.close(ViewName.rebornEquipInfo);
                Core.ViewManager.inst.open(ViewName.getRewardWnd, rewardData);
                Core.EventCenter.inst.dispatchEventWith(GameEvent.BuyRebornGoods);
            }
        }
    }
}