module CardPool {

    export class OtherCardInfo extends CardInfoWnd {

        private _equipBtn: fairygui.GButton;

        public initUI() {
            super.initUI();

            this._equipBtn = this.contentPane.getChild("equipBtn").asButton;
            this._equipBtn.visible = Home.FunctionMgr.inst.isEquipOpen();

            this._card.addClickListener(this._onCard, this);
            this._equipBtn.addClickListener(this._onEquipBtn, this);
        }

        

        private _onEquipBtn() {
            if (this._card.cardObj.equip && this._card.cardObj.equip != "") {
                let equipData = Equip.EquipMgr.inst.getEquipData(this._card.cardObj.equip);
                Core.ViewManager.inst.open(ViewName.equipItemWnd, equipData);
            }
        }
        private _updateEquipBtn() {
            if (!Home.FunctionMgr.inst.isEquipOpen()) {
                return;
            }
            if (this._cardObj.equip == "" || this._cardObj.equip == undefined) {
                this._equipBtn.icon = "";
                    this._equipBtn.visible = false;
            } else {
                let equipData = Equip.EquipMgr.inst.getEquipData(this._cardObj.equip);
                this._equipBtn.icon = equipData.equipIconSmall;
                this._equipBtn.visible = true;
                this._equipBtn.touchable = true;
            }
        }
        private _onCard() {
            Core.ViewManager.inst.open(ViewName.bigCard, this._cardObj);
            let sound:string = this._cardObj.sound;
            if (sound && sound.length > 0)
                SoundMgr.inst.playSoundAsync(`${sound}_mp3`);
        }

        public async open(...param: any[]) {
            await super.open(...param);
            this.contentPane.getChild("imgMaxLevel").visible = false;
            this._updateEquipBtn();
        }

        public async close(...param: any[]) {
            super.close(...param);
        } 
    }
}