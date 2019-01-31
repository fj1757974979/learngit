module Equip {

    export class EquipItem extends fairygui.GComponent {

        private _equipIcon: fairygui.GLoader;
        private _cardIcon: fairygui.GLoader;
        private _cardIconBg: fairygui.GLoader;

        private _equipData: EquipData;
        private _equipID: string;
        private _cardID: number;

        protected constructFromXML(xml: any): void {
            this._equipIcon = this.getChild("equipIcon").asLoader;
            this._cardIcon = this.getChild("cardIcon").asLoader;
            this._cardIconBg = this.getChild("cardIconBg").asLoader;

            this._cardIcon.visible = false;
            this._cardIconBg.visible = false;
        }
        public setEquip(equip: EquipData) {
            this._equipData = equip;
            this._equipIcon.url = this._equipData.equipIcon;
            if (this._equipData.hasEquip) {
                this.grayed = false;
                if (this._equipData.ownerCardID != 0) {
                    this._cardIcon.visible = true;
                    this._cardIconBg.visible = true;
                    this._cardIcon.url = `avatar_${this._equipData.ownerCardID}_png`;
                } else {
                    this._cardIcon.visible = false;
                    this._cardIconBg.visible = false;
                }
            } else {
                this.grayed = true;
                this._cardIcon.visible = false;
                this._cardIconBg.visible = false;
            }
        }

        public get equip(): EquipData {
            return this._equipData;
        }
    }

    export class EquipBagWnd extends Core.BaseWindow {

        private _equipList: fairygui.GList;

        private _closeBtn: fairygui.GButton;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;

            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._closeBtn.addClickListener(() => {
                Core.ViewManager.inst.closeView(this);
            }, this);

            this._equipList = this.contentPane.getChild("equipList").asList;
            this._equipList.itemClass = EquipItem;
            this._equipList.addEventListener(fairygui.ItemEvent.CLICK, this._onEquipItem, this);
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._refreshEquipList();
        }
        private async _refreshEquipList() {
            this._equipList.removeChildrenToPool();
            //获取武器列表
            let equiplist = EquipMgr.inst.myEquip;
            let equipIds = EquipMgr.inst.myEquipIds;
            equipIds.forEach(_id => {
                let com = this._equipList.addItemFromPool().asCom as EquipItem;
                com.setEquip(equiplist.getValue(_id));
            })
            this.contentPane.getChild("emptyHintText").visible = equiplist.size() <= 0;
        }
        private async _onEquipItem(evt: fairygui.ItemEvent) {
            let com = evt.itemObject as EquipItem ;

            Core.ViewManager.inst.open(ViewName.equipItemWnd, com.equip);

        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}