module CardPool {
    
    export enum CardState {
        Lock = 1,
        Alive = 2,
        Dead = 3,
	    Unlock = 4,
    }

    export class Card extends BaseCard {
        // for bind
        public static PropAmount = "amount";
        public static PropEnergy = "energy";
        public static PropLevel = "level";
        public static PropState = "state";
        public static PropIsNew = "isNew";
        public static PropSkin = "skin";
        public static PropEquip = "equip";
        private _level: number;
        private _skin: string;
        private _equip: string;
        private _hasSkins: string[];
        private _isNew: boolean;
        private _state: CardState;
        private _isInCampaignMission: boolean;
        private _isInSeason: boolean;
        
        constructor(data:any) {
            super(data);
            this._state = CardState.Lock;
            this._level = data.level;
            this._isNew = false;
            this._hasSkins = [""];
        }

        /**
         * @param collectData {CardId:1, Level:1, Amount:1, Energy:1}
         */
        public init(collectData:pb.ICardInfo) {
            /*
            if (collectData.Energy <= 0) {
                this._state = CardState.Dead;
                if (collectData.Level > 0) {
                    this.level = collectData.Level;
                }
                this._energy = 0;
            } else {
            */
            this.level = collectData.Level;
            this.skin = collectData.Skin;        
            this.equip = collectData.Equip;
            
            // console.info("init skin ", collectData.Skin);
            
            let data = CardPoolMgr.inst.getCardData(collectData.CardId, collectData.Level);
            if (!data) {
                console.debug("collect card init, no card data %d %d", collectData.CardId, collectData.Level);
                return;
            }
            this._data = data;
            this._state = CardState.Alive;
            this._energy = collectData.Energy;
            this._amount = collectData.Amount;
            this._isInCampaignMission = collectData.State == pb.CardState.InCampaignMs;
            this._isInSeason = collectData.State == pb.CardState.InSeasonPvp;
        }

        public update(collectData:pb.ICardInfo) {
            /*
            if (collectData.Energy <= 0) {
                // dead
                this.state = CardState.Dead;
                this.amount = 0;
                this.energy = 0;
                CardPoolMgr.inst.modifyCampCardHintNum(this.camp, -1);
                return;
            } 
            */
            
            let prevAmount = this.amount;
            let prevMaxAmount = this.maxAmount;
            let prevIsMaxLevel = this.isMaxLevel();
            if (this._state == CardState.Dead) {
                // 复活
                this.state = CardState.Alive;
                if (!this.isMaxLevel() && this.amount >= this.maxAmount) {
                    CardPoolMgr.inst.modifyCampCardHintNum(this.camp, 1);
                }
            } else if (collectData.Level == 0) {
                // 卡被删了
                if (this.state == CardState.Alive) {
                    let data = CardPoolMgr.inst.getCardData(collectData.CardId, 1);
                    if (!data) {
                        console.debug("collect card del, no card data %d %d", collectData.CardId, 1);
                        return;
                    }

                    Core.EventCenter.inst.dispatchEventWith(GameEvent.CardDelEv, false, this);
                    this.data = data;
                    this.level = 1;
                    this._isNew = false;
                    let equipID = this.equip;
                    this.equip = null;
                    this.state = CardState.Lock;
                }
            } else if (this._level != collectData.Level || this._state == CardState.Lock || this._state == CardState.Unlock) {
                let data = CardPoolMgr.inst.getCardData(collectData.CardId, collectData.Level);
                if (!data) {
                    console.debug("collect card update, no card data %d %d", collectData.CardId, collectData.Level);
                    return;
                }
                this.data = data;
                this.level = collectData.Level;

                if (this._state == CardState.Lock || this._state == CardState.Unlock) {
                    this.state = CardState.Alive;
                }
            }

            let isInCampaignMission = this.isInCampaignMission;
            this.isInCampaignMission = collectData.State == pb.CardState.InCampaignMs;
            if (!isInCampaignMission && this.isInCampaignMission) {
                Core.EventCenter.inst.dispatchEventWith(GameEvent.CardInCampaignMsEv, false, this);
            }
            this._isInSeason = collectData.State == pb.CardState.InSeasonPvp;
            this.skin = collectData.Skin;
            this.equip = collectData.Equip;
            this.amount = collectData.Amount;
            this.energy = collectData.Energy;
            if (!prevIsMaxLevel) {
                this._tryAddCardHintNum(prevAmount, prevMaxAmount);
                this._trySubCardHintNum(prevAmount, prevMaxAmount, prevIsMaxLevel);
            }
        }

        private _tryAddCardHintNum(prevAmount: number, prevMaxAmount: number) {
            if (this.isMaxLevel() && this.rare != CardQuality.LIMITED) {
                return;
            }
            if (this.order <= 0) {
                return;
            }
            if (prevAmount <= 0 && this.amount > 0 && this.level <= 1) {
                this.isNew = true;
            }
            if (this.rare != CardQuality.LIMITED) {
                if (prevAmount < prevMaxAmount && this.amount >= this.maxAmount) {
                    CardPoolMgr.inst.modifyCampCardHintNum(this.camp, 1);
                }
            }
        }

        private _trySubCardHintNum(prevAmount: number, prevMaxAmount: number, prevIsMaxLevel: boolean) {
            if (this.order <= 0) {
                return;
            }
            if (this.rare != CardQuality.LIMITED) {
                if (prevAmount >= prevMaxAmount && 
                    (this.isMaxLevel() || this.amount < this.maxAmount)) {
                    CardPoolMgr.inst.modifyCampCardHintNum(this.camp, -1);
                }
            }
        }

        public get collectCard(): CardPool.Card | Diy.DiyCard {
            return this;
        }

        public get isNew(): boolean {
            return this._isNew;
        }

        public set isNew(isNew:boolean) {
            if (this._isNew && !isNew) {
                CardPoolMgr.inst.modifyCampCardHintNum(this.camp, -1);
                CardPoolMgr.inst.setCardNew(this.cardId, false);
            } else if (!this._isNew && isNew) {
                CardPoolMgr.inst.modifyCampCardHintNum(this.camp, 1);
                CardPoolMgr.inst.setCardNew(this.cardId, true);
                // 初始化头像
                if (!Core.DeviceUtils.isWXGame()) {
                    if (Player.inst.avatarUrl == "") {
                        let cardId = this.cardId;
                        Player.inst.saveAvatarUrl(`avatar_${cardId}_png`);
                    }
                    CardPoolMgr.inst.setAvatarNew(this.cardId, true);
                }
            }
            this._isNew = isNew;
        }

        public initIsNew(isNew: boolean) {
            this._isNew = isNew;
        }

        public get level():number {
            return this._level;
        }
        public set level(value:number) {
            this._level = value;
        }

        public get skin():string {
            return this._skin;
        }

        public set skin(s: string) {
            this._skin = s;
        }
        public addSkin(skinId: string) {
            this._hasSkins.push(skinId);
        }
        public get hasSkins(): string[] {
            return this._hasSkins;
        }
        public set equip(str: string) {
            this._equip = str;
        }
        public get equip(): string {
            return this._equip;
        }
        public get state():CardState {
            return this._state;
        }
        public set state(value:CardState) {
            this._state = value;
        }

        public getLevelObj(level:number): Card {
            if (level <= 0) {
                return null;
            }
            if (level == this.level) {
                return this;
            }
            let _data = CardPoolMgr.inst.getCardData(this.cardId, level);
            if (!_data) {
                return null;
            }
            let card = new Card(_data);
            card.skin = this.skin;
            return card;
        }

        public copyObj(level? :number): any {
            if (level == null) {
                level = this.level;
            }
            let obj = this.getLevelObj(level);
            if (obj) {
                obj.state = this._state;
                obj.amount = this._amount;
            }
            return obj;
        }

        public isMaxLevel(): boolean {
            return this.maxAmount <= 0;
        }

        public canLevelUp(): boolean {
            return this.amount >= this.maxAmount && !this.isMaxLevel();
        }

        public get isInCampaignMission(): boolean {
            return this._isInCampaignMission;
        }
        public set isInCampaignMission(val: boolean) {
            this._isInCampaignMission = val;
        }
        public get isInSeason(): boolean {
            return this._isInSeason;
        }
        public set isInSeason(b: boolean) {
            this._isInSeason = b;
        }
    }

}
