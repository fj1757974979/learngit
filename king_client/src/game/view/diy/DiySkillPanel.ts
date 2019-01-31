module Diy {

    export class DiySkillPanel extends Core.BaseWindow {
        private _levelTxt: fairygui.GTextField;
        private _levelList: fairygui.GList;
        private _skillDescTxt: fairygui.GTextField;
        private _pvpLevelCtrl: fairygui.Controller;

        private _skillIdx: number;
        private _curViewLevel: number;
        private _curDiySkillId: number;

        public initUI() {
            super.initUI();
            this.modal = true;
            this._levelTxt = this.getChild("levelTxt").asTextField;
            this._levelList = this.getChild("levelList").asList;
            this._skillDescTxt = this.getChild("skillDescTxt").asTextField;
            this._skillDescTxt.textParser = Core.StringUtils.parseColorText;
            this._pvpLevelCtrl = this.getController("pvpLevel");

            this.getChild("preListBtn").asButton.addClickListener(this._onPreSkillList, this);
            this.getChild("nextListBtn").asButton.addClickListener(this._onNextSkillList, this);
            this.getChild("confirmBtn").asButton.addClickListener(this._onConfirm, this);
            this.getChild("cancelBtn").asButton.addClickListener(this._onCancel, this);
            this._pvpLevelCtrl.addEventListener(fairygui.StateChangeEvent.CHANGED, this._onPvpLevelChanged, this);
            this._pvpLevelCtrl.addAction(SoundMgr.inst.playSoundAction("page_mp3", true));
        }

        public async open(...param:any[]) {
            this._skillIdx = param[0];
            this._curViewLevel = 1;
            let curSelectedSkillId = param[1] as number;
            let otherSelectedSkillId = param[2] as number;
            let pvpLevel = Pvp.PvpMgr.inst.getPvpLevel();
            this._skillDescTxt.text = "";
            for (let level=1; level<=pvpLevel; level++) {
                let diySkillDatas = DiyMgr.inst.getLevelDiySkills(level);
                let diyList = this._levelList.addItem().asCom.getChild("list").asList;
                this._pvpLevelCtrl.addPage(level.toString());
                this._renderSkillList(diyList, curSelectedSkillId, otherSelectedSkillId, diySkillDatas);
            }
            this._updateLevelText();
            await super.open(...param);
            this.x = this.parent.width / 2 - this.width / 2 + 10;
            this.y = 402;
            Core.PopUpUtils.addPopUp(this, 3);
        }

        public async close(...param:any[]) {
            await Core.PopUpUtils.removePopUp(this, 4);
            super.close(...param);
            this._levelList.removeChildren();
            this._pvpLevelCtrl.clearPages();
        }

        private _updateLevelText() {
            this._levelTxt.text = `${Core.StringUtils.getZhNumber(this._curViewLevel)}阶`
        }

        private _is2SkillBan(mySkillId:number, otherSkillId:number): boolean {
            if (mySkillId == otherSkillId) {
                return true;
            }

            let myDiyData = Data.diy.get(mySkillId);
            let otherDiyData = Data.diy.get(otherSkillId);
            if (!myDiyData || !otherDiyData) {
                return false;
            }

            for (let i=0; i < myDiyData.ban.length; i++) {
                if (otherSkillId == myDiyData.ban[i]) {
                    return true;
                }
            }

            for (let i=0; i < otherDiyData.ban.length; i++) {
                if (mySkillId == otherDiyData.ban[i]) {
                    return true;
                }
            }

            if (myDiyData.min_single > otherDiyData.max_single) {
                return true;
            }
            if (myDiyData.min_total > otherDiyData.max_total) {
                return true;
            }
            if (otherDiyData.min_single > myDiyData.max_single) {
                return true;
            }
            if (otherDiyData.min_total > myDiyData.max_total) {
                return true;
            }
            return false;
        }

        private _renderSkillList(diyList:fairygui.GList, curSelectedSkillId:number, otherSelectedSkillId:number, diySkillDatas:Array<any>) {
            diySkillDatas.forEach(data => {
                let item = diyList.addItem().asButton;
                item.data = data;
                let mySkillId = data.__id__ as number;
                item.title = DiyMgr.inst.getDiySkillName(mySkillId);
                if (mySkillId == curSelectedSkillId) {
                    item.selected = true;
                    this._curDiySkillId = item.data.__id__;
                    this._skillDescTxt.text = DiyMgr.inst.getDiySkillDesc(this._curDiySkillId);
                } else if (mySkillId == otherSelectedSkillId) {
                    item.touchable = false;
                    item.getController("button").selectedPage = "otherSelected";
                } else if (otherSelectedSkillId && otherSelectedSkillId != 0) {
                    if (this._is2SkillBan(mySkillId, otherSelectedSkillId)) {
                        item.disabled = true;
                    }
                }
            })

            diyList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickSkillItem, this);
        }

        private _onClickSkillItem(evt:fairygui.ItemEvent) {
            let skillItem = evt.itemObject.asButton;
            this._curDiySkillId = skillItem.data.__id__;
            this._skillDescTxt.text = DiyMgr.inst.getDiySkillDesc(this._curDiySkillId);
        }

        private _onCancel() {
            Core.ViewManager.inst.closeView(this);
        }

        private _onPreSkillList() {
            if (this._curViewLevel <= 1) {
                return;
            }
            this._curViewLevel -= 1;
            this._levelList.scrollToView(this._curViewLevel - 1, true);
        }

        private _onNextSkillList() {
            if (this._curViewLevel >= this._levelList.numItems) {
                return;
            }
            this._curViewLevel += 1;
            this._levelList.scrollToView(this._curViewLevel - 1, true);
        }

        private _onPvpLevelChanged() {
            this._curViewLevel = parseInt(this._pvpLevelCtrl.selectedPage);
            this._updateLevelText();
        }

        private _onConfirm() {
            (<DiyView>Core.ViewManager.inst.getView(ViewName.diy)).onConfirmChoiceSkill(this._skillIdx, this._curDiySkillId);
            Core.ViewManager.inst.closeView(this);
        }
    }

}
