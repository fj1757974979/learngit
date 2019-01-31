module Diy {

    export class DiyCard implements UI.ICardObj {
        private _data: any;
        private _skill1Name: string;
        private _skill2Name: string;
        private _skill3Name: string;
        private _skill4Name: string;
        private _skillDesc: string;
        
        constructor(data:any) {
            this._data = data;
        }

        public get collectCard(): CardPool.Card | Diy.DiyCard {
            return this;
        }

        public get sound(): string {
            return null;    
        }

	// fix-me
	public get skillIds(): Array<number> {
	    return null;
	}

        public get data(): any {
            return this._data;
        }

        public get cardId():number {
            return this._data.CardId;
        }

        public get gcardId():number {
            return this._data.CardId;
        }

        public get camp():Camp {
            return Camp.HEROS;
        }

        public get state():CardPool.CardState {
            return CardPool.CardState.Alive;
        }

        public get amount():number {
            return 0;
        }

        public get maxAmount():number {
            return 0;
        }

        public get energy():number {
            return 0;
        }

        public get maxEnergy():number {
            return 0;
        }

        public get rare():CardQuality {
            return CardQuality.NORMAL;
        }

        public get name(): string {
            let level = this.getLevel();
            let nameColor = "#cg";
            if(level >= 5) {
                nameColor = "#cp";
            } else if (level >= 3) {
                nameColor = "#cb";
            }
            return nameColor + this._data.Name + "#n";
        }

        public get skill1Name(): string {
            if (!this._skill1Name) {
                this._skill1Name = DiyMgr.inst.getDiySkillName(this._data.DiySkillId1);
            }
            return this._skill1Name;
        }

        public get skill2Name(): string {
            if (!this._skill2Name) {
                this._skill2Name = DiyMgr.inst.getDiySkillName(this._data.DiySkillId2);
            }
            return this._skill2Name;
        }

        public get skill3Name(): string {
            return "";
        }

        public get skill4Name(): string {
            return "";
        }

        public get skillDesc(): string {
            if (!this._skillDesc) {
                this._skillDesc = DiyMgr.inst.getDiySkillDesc(this._data.DiySkillId1);
                this._skillDesc += "\n" + DiyMgr.inst.getDiySkillDesc(this._data.DiySkillId2);
            }
            return this._skillDesc;
        }

        public get icon():number {
            return this.cardId
        }
        public get skin(): string {
            return ""
        }
        public get equip(): string {
            return ""
        }

        public get upNum(): number {
            return this._data.MinUp;
        }
        public set upNum(val:number) {
            return;
        }

        public get downNum(): number {
            return this._data.MinDown;
        }
        public set downNum(val:number) {
            return;
        }

        public get leftNum(): number {
            return this._data.MinLeft;
        }
        public set leftNum(val:number) {
            return;
        }

        public get rightNum(): number {
            return this._data.MinRight;
        }
        public set rightNum(val:number) {
            return;
        }

        public get upNumOffset(): number {
            return this._data.MaxUp - this._data.MinUp;
        }

        public get downNumOffset(): number {
            return this._data.MaxDown - this._data.MinDown;
        }

        public get leftNumOffset(): number {
            return this._data.MaxLeft - this._data.MinLeft;
        }

        public get rightNumOffset(): number {
            return this._data.MaxRight - this._data.MinRight;
        }

        public get weapon(): string {
            if (this._data.Weapon) {
                return this._data.Weapon;
            } else {
                return "gun";
            }
        }

        public update(data:any) {
            this._data = data;
            this._skill1Name = null;
            this._skill2Name = null;
            this._skillDesc = null;
        }

        public get level(): number {
            return 1;
        }

        public get isNew(): boolean {
            return false;
        }

        public getLevel(): number {
            let diyData1 = Data.diy.get(this._data.DiySkillId1);
            let lv1 = 0;
            if (!diyData1) {
                lv1 = diyData1.level;
            }

            let diyData2 = Data.diy.get(this._data.DiySkillId2);
            let lv2 = 0;
            if (!diyData2) {
                lv2 = diyData2.level;
            }

            if (lv1 > lv2) {
                return lv1;
            } else {
                return lv2;
            }
        }

        public get isInCampaignMission(): boolean {
            return false;
        }
        public get isInSeason(): boolean {
            return false;
        }
    }

}
