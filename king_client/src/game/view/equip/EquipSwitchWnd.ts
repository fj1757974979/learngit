module Equip {

    export class EquipSwitchWnd extends Core.BaseWindow {

        private _cardID: number;
        private _equipList: fairygui.GList;
        private _nowEquip: EquipData;
        private _nowEquipCom: fairygui.GComponent;
        private _nowEquipIcon: fairygui.GLoader;
        private _nowEquipName: fairygui.GTextField;
        private _nowEquipDesc: fairygui.GRichTextField;
        private _newEquip: EquipData;
        private _newEquipCom: fairygui.GComponent;
        private _newEquipIcon: fairygui.GLoader;
        private _newEquipName: fairygui.GTextField;
        private _newEquipDesc: fairygui.GRichTextField;
        private _closeBtn: fairygui.GButton;
        private _confirmBtn: fairygui.GButton;
        private _jade: number;
        private _seletCom: EquipItem;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;

            this._newEquipCom = this.contentPane.getChild("newEquip").asCom;
            this._newEquipIcon = this._newEquipCom.getChild("equipIcon").asLoader;
            this._newEquipName = this.contentPane.getChild("newEquipName").asTextField;
            this._newEquipDesc = this.contentPane.getChild("newEquipDesc").asRichTextField;
            this._nowEquipCom = this.contentPane.getChild("nowEquip").asCom;
            this._nowEquipIcon = this._nowEquipCom.getChild("equipIcon").asLoader;
            this._nowEquipName = this.contentPane.getChild("nowEquipName").asTextField;
            this._nowEquipDesc = this.contentPane.getChild("nowEquipDesc").asRichTextField;
            this._newEquipDesc.asRichTextField.addEventListener(egret.TextEvent.LINK, htmlClickCallback, this);
            this._nowEquipDesc.asRichTextField.addEventListener(egret.TextEvent.LINK, htmlClickCallback, this);
            this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._closeBtn.addClickListener(() => {
                Core.ViewManager.inst.closeView(this);
            }, this);
            this._confirmBtn.addClickListener(this._onConfirmBtn, this);

            this._equipList = this.contentPane.getChild("equipList").asList;
            this._equipList.itemClass = EquipItem;
            this._equipList.addEventListener(fairygui.ItemEvent.CLICK, this._onEquipItem, this);
            this._nowEquipCom.getChild("cardIcon").visible =false;
            this._nowEquipCom.getChild("cardIconBg").visible =false;
            this._newEquipCom.getChild("cardIcon").visible =false;
            this._newEquipCom.getChild("cardIconBg").visible =false;
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._setNewEquip(null);
            let nowequip = EquipMgr.inst.getEquipData(param[0]);
            this._cardID = param[1];
            this._setNowEquip(nowequip);
            this._refreshEquipList();
            this._setConfirmBtn(false);
        }
        private async _refreshEquipList() {
            this._equipList.removeChildrenToPool();
            //获取武器列表
            let equipIds = EquipMgr.inst.myEquipIds;
            let equiplist = EquipMgr.inst.myEquip;
            for (let i = 0; i < equipIds.length; i++) {
                let com = this._equipList.addItemFromPool().asCom as EquipItem;
                com.setEquip(equiplist.getValue(equipIds[i]));
                com.getController("button").selectedIndex = 0;
            }
            this.contentPane.getChild("emptyHintText").visible = equiplist.size() <= 0;
            // equiplist.forEach((_equipID, _equip) => {
            //     let com = this._equipList.addItemFromPool().asCom as EquipItem;
            //     com.setEquip(_equip);
            // })
        }
        private async _setNewEquip(equip: EquipData) {
            this._newEquip = equip;
            if (this._newEquip == null) {
                this._newEquipDesc.text = "";
                this._newEquipName.text = "";
                this._newEquipIcon.url = "";
            } else {
                this._newEquipDesc.text = this._nowEquip.getSkillDesc();
                this._newEquipName.text = this._newEquip.equipName;
                // this._newEquipIcon.url = "";
            }
        }
        private async _setNowEquip(equip: EquipData) {
            this._nowEquip = equip;
            if (this._nowEquip == null) {
                this._nowEquipDesc.text = "";
                this._nowEquipName.text = Core.StringUtils.format(Core.StringUtils.TEXT(60269));
                this._nowEquipIcon.url = "";
            } else {
                this._nowEquipDesc.text = this._nowEquip.getSkillDesc();
                this._nowEquipName.text = this._nowEquip.equipName;
                this._nowEquipIcon.url = this._nowEquip.equipIcon;
            }

        }
        private async _setConfirmBtn(b: boolean) {
                this._confirmBtn.touchable = b;
                this._confirmBtn.grayed = !b;
        }
        private async _onEquipItem(evt: fairygui.ItemEvent) {
            let item = evt.itemObject as EquipItem;
            if (this._seletCom) {
                this._seletCom.getController("button").selectedIndex = 0;
            }
            item.getController("button").selectedIndex = 3;
            this._seletCom = item;
            if (this._nowEquip == item.equip) {
                this._setConfirmBtn(false);
            } else {
                this._setConfirmBtn(true);
            }
            this._newEquip = item.equip;
            this._newEquipCom.getChild("equipIcon").asLoader.url = item.equip.equipIcon;
            this._newEquipName.text = item.equip.equipName;
            this._newEquipDesc.text = this._newEquip.getSkillDesc();

        }

        private async _onConfirmBtn() {
            if (this._newEquip.ownerCardID != 0) {
                let ownerCard = CardPool.CardPoolMgr.inst.getCollectCard(this._newEquip.ownerCardID);
                if (this._nowEquip != null) {
                    //提示该武将已有装备并且要换上的装备已经被别的武将穿上
                    this._jade = 40;
                Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70185), this._newEquip.equipName, ownerCard.name, 40), this._confirm, null, this);
                } else {
                    //提示该装备已经被别的武将穿上了
                    this._jade = 20;
                    Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70184), this._newEquip.equipName, ownerCard.name, 20), this._confirm, null, this);
                }
            } else if(this._nowEquip != null) {
                //提示该武将已经穿上装备了
                this._jade = 20;
                Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70183), 20), this._confirm, null, this);
            } else {
                this._jade = 0;
                let curCard = CardPool.CardPoolMgr.inst.getCollectCard(this._cardID);
                Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70187), this._newEquip.equipName, curCard.name), this._confirm, null, this);
            }
        }
        private async _confirm() {
            if(!Player.inst.hasEnoughJade(this._jade)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70119));
                return;
            }
            let args = {
                EquipID: this._newEquip.equipID,
                OwnerCardID: this._cardID,
            }
            let result = await Net.rpcCall(pb.MessageID.C2S_WEAR_EQUIP, pb.Equip.encode(args));
            if (result.errcode == 0) {
                //
                if (this._newEquip.ownerCardID != 0) {
                    let newEquiOwnerCard = CardPool.CardPoolMgr.inst.getCollectCard(this._newEquip.ownerCardID);
                    newEquiOwnerCard.equip = "";
                }
                this._newEquip.ownerCardID = this._cardID;
                if (this._nowEquip != null) {
                    this._nowEquip.ownerCardID = 0;
                }
                let curCard = CardPool.CardPoolMgr.inst.getCollectCard(this._cardID);
                curCard.equip = this._newEquip.equipID;
                this._nowEquip = this._newEquip;
                Core.ViewManager.inst.closeView(this);
            }
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}