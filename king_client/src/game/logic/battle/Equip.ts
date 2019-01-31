module Battle {

    export class Equip {
        private _equipID:string;
        private _skills:Array<SkillGroup>;
        private _owner: FightCard;

        constructor(data:pb.IBattleEquip, owner:FightCard) {
            this._equipID = data.EquipID;
            this._owner = owner;
            this._skills = SkillGroup.getGroupsFromSkillIDs(data.Skills, true, this._owner.level);
        }

        public get equipID(): string {
            return this._equipID;
        }

        public async triggerSkill(skillID: number) {
            for (let skill of this._skills) {
                if (skill.isEffective && skill.isSkillInGroup(skillID)) {
                    await this._owner.view.equipBlink();
                    return;
                }
            }
        }

        public getSkillDesc(): string {
            for (let skGroup of this._skills) {
                let desc = skGroup.desc;
                if (desc && desc != "") {
                    return desc;
                }
            }
            return "";
        }
    }

}