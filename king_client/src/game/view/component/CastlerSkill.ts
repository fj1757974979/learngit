module UI {

    export class CastlerSkill extends fairygui.GComponent {
        private _icon: fairygui.GLoader;
        private _skillText: fairygui.GRichTextField;
        private _skillGroup: fairygui.GGroup;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._icon = this.getChild("skillIcon").asLoader;
            this._skillText = this.getChild("skillText").asRichTextField;
            this._skillGroup = this.getChild("skillGroup").asGroup;
        }

        public setData(skillIds:Array<number>) {
            if (!skillIds || skillIds.length <= 0) {
                return;
            }
            for (let skillId of skillIds) {
                let skillData = Data.skill.get(skillId);
                if (skillData && skillData.desTra && skillData.desTra != "") {
                    this._skillText.text = CardPool.CardPoolMgr.inst.formatSkillDesc(skillData, 1);
                    break;
                }
            }
            this._skillGroup.width = this._skillText.width + this._skillText.x - this._icon.x;
        }
    }

}