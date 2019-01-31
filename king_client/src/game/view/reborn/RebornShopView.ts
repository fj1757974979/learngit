module Reborn {
    export class RebornShopView extends Core.BaseView {

        private _closeBtn: fairygui.GButton;
        private _rebornBtn: fairygui.GButton;
        private _refineBtn: fairygui.GButton;

        private _honoText: fairygui.GTextField;
        private _fameText: fairygui.GTextField;

        private _shopList: fairygui.GList;
        private _cardList: fairygui.GList;
        private _privList: fairygui.GList;
        private _equipList: fairygui.GList;

        private _equipNum: fairygui.GTextField;
        
        private _cardCom: fairygui.GComponent;
        private _privCom: fairygui.GComponent;

        public initUI() { 
            super.initUI();
            this.adjust(this.getChild("bg"), Core.AdjustType.EXCEPT_MARGIN);
            this.y += window.support.topMargin;

            this._shopList = this.getChild("shopList").asList;
            this._closeBtn = this.getChild("closeBtn").asButton;
            this._honoText = this.getChild("honorCnt").asTextField;
            this._fameText = this.getChild("fameCnt").asTextField;
            

            this._closeBtn.addClickListener(this._onCloseBtn, this);
            //
            this._shopList.foldInvisibleItems =true;
            let btnCom = fairygui.UIPackage.createObject(PkgName.reborn, "rebornFunction").asCom;
            this._shopList.addChild(btnCom);
            this._rebornBtn = btnCom.getChild("list").asList.getChild("reborn").asButton;
            this._refineBtn = btnCom.getChild("list").asList.getChild("refine").asButton;
            this._rebornBtn.addClickListener(this._onRebornBtn, this);
            this._refineBtn.addClickListener(this._onRefineBtn, this);
            // btnCom.visible = false;
            //
            let cardCom = fairygui.UIPackage.createObject(PkgName.reborn, "card").asCom;
            this._cardList = cardCom.getChild("list").asList;
            this._shopList.addChild(cardCom);
            //
            let privCom = fairygui.UIPackage.createObject(PkgName.reborn, "priv").asCom;
            this._privList = privCom.getChild("list").asList;
            this._shopList.addChild(privCom);
            //
            let equipCom = fairygui.UIPackage.createObject(PkgName.reborn, "equip").asCom;
            this._equipList = equipCom.getChild("list").asList;
            this._shopList.addChild(equipCom);
            this._equipNum = equipCom.getChild("n9").asTextField;
            this._cardList.itemClass = FeatCardItem;
            this._privList.itemClass = PrivItem;
            this._equipList.itemClass = EquipItem;

            
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._shopList._scrollPane.scrollTop();
            await RebornMgr.inst.refresh();
            this._refresh();
            Core.EventCenter.inst.addEventListener(GameEvent.BuyRebornGoods, this._refresh, this);
        }
        private async _refresh() {
            this._honoText.text = Player.inst.getResource(ResType.T_FEAT).toString();
            this._fameText.text = Player.inst.getResource(ResType.T_FAME).toString();

            let rebornBtnLab = this._rebornBtn.getChild("n1").asTextField;
            this._rebornBtn.getChild("cnt").asTextField.text = `${RebornMgr.inst.rebornCnt} / 6`;
            if (RebornMgr.inst.remainDay > 0) {
                rebornBtnLab.visible = true;
                this._rebornBtn.getChild("n1").asTextField.text = Core.StringUtils.format(Core.StringUtils.TEXT(70166), RebornMgr.inst.remainDay);
            } else {
                rebornBtnLab.visible = false;
            }
            this._rebornBtn.getChild("honorText").asTextField.text = RebornMgr.inst.rebornFeats.toString();
            this._rebornBtn.getChild("fameText").asTextField.text = RebornMgr.inst.fames.toString();
            this._refineBtn.getChild("honorText").asTextField.text = RebornMgr.inst.refineFeats.toString();

            this._cardList.removeChildrenToPool();
            this._privList.removeChildrenToPool();
            this._equipList.removeChildrenToPool();
            let cardKeys = Data.sold_general.keys;
            cardKeys.forEach(_key => {
                let com = this._cardList.addItemFromPool().asCom as FeatCardItem;
                com.setCard(_key);
            })
            let privKeys = Data.sold_priv.keys;
            privKeys.forEach(_key => {
                let com = this._privList.addItemFromPool() as PrivItem;
                com.setPriv(_key);
            })
            let equipKesy = Data.sold_equip.keys;
            equipKesy.forEach(_key => {
                let com = this._equipList.addItemFromPool() as EquipItem;
                com.setEquip(_key);
            })
            this._equipNum.text = Core.StringUtils.format(Core.StringUtils.TEXT(70181), Player.inst.getResource(ResType.T_EQUIP));
            
        }

        private async _onRebornBtn() {
            if (RebornMgr.inst.maxTeam < RebornMgr.inst.canRebornTeam) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70148));
                return;
            }
            if (RebornMgr.inst.rebornCnt >= 6) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70376));
                return;
            }
            Core.ViewManager.inst.open(ViewName.rebornWnd);
        }

        private async _onRefineBtn() {
            Core.ViewManager.inst.open(ViewName.refineInfoWnd);
        }

        private async _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }

        public async close(...param: any[]) {
            Core.EventCenter.inst.removeEventListener(GameEvent.BuyRebornGoods, this._refresh, this);
            super.close(...param);
        }
    }
}