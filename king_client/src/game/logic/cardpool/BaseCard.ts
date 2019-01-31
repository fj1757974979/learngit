module CardPool {

    export class BaseCard implements UI.ICardObj {
        protected _data: any;
        protected _skillIds: Array<number>;
        private _skill1Name: string;
        private _skill2Name: string;
        private _skill3Name: string;
        private _skill4Name: string;
        private _skillDesc: string;
        protected _amount: number;
        protected _energy: number;
        
        constructor(data:any) {
            this._data = data;
            this._amount = 0;
            this._energy = 0;
        }

        public get data(): any {
            return this._data;
        }
        public set data(val:any) {
            this._data = val;
            this._skillIds = null;
            this._skill1Name = "";
            this._skill2Name = "";
            this._skill3Name = "";
            this._skill4Name = "";
            this._skillDesc = "";
        }

        public get collectCard(): CardPool.Card | Diy.DiyCard {
            return null;
        }

        public get cardId():number {
            return this._data.cardId;
        }

        public get gcardId():number {
            return this._data.__id__;
        }

        public get rare():CardQuality {
            return <CardQuality>(this._data.rare);
        }

        public get camp():Camp {
            return this._data.camp;
        }

        public get state():CardState {
            return CardState.Alive;
        }

        public get amount():number {
            return this._amount;
        }
        public set amount(value:number) {
            this._amount = value;
        }

        public get energy():number {
            return this._energy;
        }
        public set energy(value:number) {
            this._energy = value;
        }

        public get maxAmount():number {
            return this._data.levelupNum;
        }
        public getToLevelAmount(toLevel: number): number[] {
            let toLvNum = 0;
            let toLvGold = 0;
            if (this.rare == CardQuality.LIMITED) {
                return [toLvNum, toLvGold];
            }
            if (this.level < toLevel) {
                let levNum = toLevel - this.level;
                for (let i = 0; i < levNum; i++) {
                    toLvNum += Data.pool.get(this.gcardId + i).levelupNum;
                    toLvGold += Data.pool.get(this.gcardId + i).levelupGold;
                }
                toLvNum -= this.amount;
            }
            return [toLvNum, toLvGold];
        }
        private _countAmount() {
            
        }

        public get maxEnergy():number {
            return this._data.energy;
        }

        public get name(): string {
            return this._data.name;
        }
        public getPower(type: WarMsType): number {
            switch(type) {
                case WarMsType.Irrigation:
                    return this._data.politics;
                case WarMsType.Trade:
                    return this._data.intelligence;
                case WarMsType.Build:
                    return this._data.force;
                default:
                return 0;
            }
        }
        public get skin(): string {
            if (!this._data.skin || this._data.skin == undefined) {
                this._data.skin = "";
            }
            return this._data.skin;
        }
        public set skin(s: string) {
            this._data.skin = s;
        }
        public get equip(): string {
            if (!this._data.equip) {
                this._data.equip = null;
            }
            return this._data.equip;
        }

        public get level(): number {
            return this._data.level;
        }

        public get order(): number {
            return this._data.cardOrder;
        }

        public get skillIds(): Array<number> {
            if (this._skillIds) {
                return this._skillIds;
            }
            let skillIds = [];
            this._skillIds = skillIds;
            let strSkill = this._data.skill as string
            if (!strSkill) {
                return 
            }
            let strSkillIds = strSkill.split(";")
            let index = 0;
            this._skillDesc = "";
            strSkillIds.forEach(strid => {
                let id = parseInt(strid);
                let skillRes = Data.skill.get(id);
                if (skillRes) {
                    skillIds.push(id);
                    if (skillRes.name) {
                        if (index == 0) {
                            this._skill1Name = skillRes.name;
                        } else if (index == 1) {
                            this._skill2Name = skillRes.name;
                        } else if (index == 2) {
                            this._skill3Name = skillRes.name;
                        } else if (index == 3) {
                            this._skill4Name = skillRes.name;
                        }
                        index++;
                    }

                    if (skillRes.desTra) {
                        let s = "";
                        this._skillDesc += CardPoolMgr.inst.formatSkillDesc(skillRes, this.level) + "\n";
                    }
                }
            });

            return skillIds;
        }

        public get skill1Name(): string {
            this.skillIds;
            return this._skill1Name;
        }

        public get skill2Name(): string {
            this.skillIds;
            return this._skill2Name;
        }

        public get skill3Name(): string {
            this.skillIds;
            return this._skill3Name;
        }

        public get skill4Name(): string {
            this.skillIds;
            return this._skill4Name;
        }

        public get skillDesc(): string {
            this.skillIds;
            return this._skillDesc;
        }

        public get icon():number {
            return this._data.icon;
        }

        public get upNum(): number {
            return this._data.up_l;
        }
        public set upNum(val:number) {
            return;
        }

        public get downNum(): number {
            return this._data.down_l;
        }
        public set downNum(val:number) {
            return;
        }

        public get leftNum(): number {
            return this._data.left_l;
        }
        public set leftNum(val:number) {
            return;
        }

        public get rightNum(): number {
            return this._data.right_l;
        }
        public set rightNum(val:number) {
            return;
        }

        public get upNumOffset(): number {
            return this._data.up_u - this._data.up_l;
        }

        public get downNumOffset(): number {
            return this._data.down_u - this._data.down_l;
        }

        public get leftNumOffset(): number {
            return this._data.left_u - this._data.left_l;
        }

        public get rightNumOffset(): number {
            return this._data.right_u - this._data.right_l;
        }

        public get weapon(): string {
            return this._data.weaponEff;
        }

        public get sound(): string {
            return this._data.sound;
        }

        public get isNew(): boolean {
            return false;
        }

        public get isInCampaignMission(): boolean {
            return false;
        }
        public get isInSeason(): boolean {
            return false;
        }

    }

}
