module Battle {

    export class GridObj implements IBattleObj {
        private _id: number;
        private _objId: number;
        private _inGridCard: FightCard;
        private _view: GridView;
        private _initEffects: any;

        constructor(id:number, data:any, battle:Battle) {
            this._objId = data.ObjId;
            this._id = id;
            if (data.InGridCard) {
                let card = new FightCard(data.InGridCard, battle.getFighter(data.Owner));
                this._inGridCard = card;
                battle.addBattleObj(card);
            }
            this._initEffects = data.Effect;
        }

        public get id():number {
            return this._id;
        }

        public get objId(): number {
            return this._objId;
        }

        public get inGridCard(): FightCard {
            return this._inGridCard;
        }
        public set inGridCard(card:FightCard) {
            this._inGridCard = card;
        }

        public get view(): GridView {
            return this._view;
        }
        public set view(v:GridView) {
            this._view = v;
        }

        public get initEffects(): any {
            return this._initEffects;
        }

        public playEffect(effectId:string | number, playType:number, visible:boolean, targetCount?:number, value?:number): Promise<void> {
            return this._view.playEffect(effectId, playType, true, targetCount, value);
        }

        public inGridCardToBeCopy(card:FightCard) {
            this._inGridCard = card;
            this.view.inGridCardToBeCopy(card.view);
        }
    }

}