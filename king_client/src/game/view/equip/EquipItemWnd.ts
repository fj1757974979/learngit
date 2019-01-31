module Equip {

    export class EquipItemWnd extends Core.BaseWindow {

        private _equipList: fairygui.GList;
        private _equipCom: fairygui.GComponent;
        private _equipDesc: fairygui.GRichTextField;

        public initUI() {
            super.initUI();
            this.toTopLayer();
            this.center();
            this.adjust(this.contentPane.getChild("closeBg"));
            this.contentPane.getChild("closeBg").addClickListener(() => {
                Core.ViewManager.inst.closeView(this);
            }, this);

            // this._equipList = this.contentPane.getChild("list").asList;
            // this._equipList.touchable = false;
            // this._equipCom = this._equipList.addItemFromPool().asCom;
            this._equipCom = this.contentPane.getChild("equip").asCom;
            this._equipDesc = this._equipCom.getChild("desc").asRichTextField;
            this._equipDesc.addEventListener(egret.TextEvent.LINK, htmlClickCallback, this);

        }
        public async open(...param: any[]) {
            super.open(...param);
            this.toTopLayer();
            let equipData = param[0] as EquipData;
            this._refresh(equipData);
        } 

        private _refresh(equipData: EquipData) {
            // let allEquipKeys = EquipMgr.inst.allEquip;
            // allEquipKeys.forEach((_quipID, _quip) => {
            //     let com = this._equipList.addItemFromPool().asCom;
            //     let hasEquip = _quip.hasEquip;
            //     com.grayed = !hasEquip;
            //     com.getChild("light").visible = hasEquip;
            //     //设置武器图标
            //     // com.getChild("icon").asLoader.url = 
            //     com.getChild("name").asTextField.text = _quip.equipName;
            //     com.getChild("desc").asTextField.text = _quip.skillDesc;
            // })
            this._equipCom.getChild("icon").asLoader.url = equipData.equipIcon;
            this._equipCom.getChild("name").asTextField.text = equipData.equipName;
            
            this._equipDesc.text = equipData.getSkillDesc();
        }

        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}