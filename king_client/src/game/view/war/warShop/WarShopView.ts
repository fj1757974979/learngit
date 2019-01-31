module War {
    export enum WarShopType {
        card = 0,
        skin = 1,
        equip = 2,
        res = 3,
    }


    export class WarShopView extends Core.BaseView {

        private _fightCntText: fairygui.GTextField;

        private _shopList: fairygui.GList;
        private _cardCom: WarShopWindow;
        private _equipCom: WarShopWindow;
        private _skinCom: WarShopWindow;
        private _resCom: WarShopWindow;

        private _closeBtn: fairygui.GButton;

        public initUI() {
            super.initUI();
            this.adjust(this.getChild("bg"), Core.AdjustType.EXCEPT_MARGIN);
            this.y += window.support.topMargin;

            this._fightCntText = this.getChild("fightCnt").asTextField;
            this._shopList = this.getChild("shopList").asList;
            this._shopList.foldInvisibleItems = true;
            this._cardCom = this._shopList.getChild("cardCom").asCom as WarShopWindow;
            this._equipCom = this._shopList.getChild("equipCom").asCom as WarShopWindow;
            this._skinCom = this._shopList.getChild("skinCom").asCom as WarShopWindow;
            this._resCom = this._shopList.getChild("resCom").asCom as WarShopWindow;
            this._cardCom.setType(WarShopType.card);
            this._skinCom.setType(WarShopType.skin);
            this._equipCom.setType(WarShopType.equip);
            this._resCom.setType(WarShopType.res);

            this._closeBtn = this.getChild("closeBtn").asButton;

            this._closeBtn.addClickListener(this._onCloseBtn, this);
        }

        public async open(...param: any[]) {
            super.open(...param);

            this._updateContribution();
            this._refresh();
            Core.EventCenter.inst.addEventListener(WarMgr.RefreshShop, this._refresh, this);
            this._watch();
        }
        
        private async _updateContribution() {
            this._fightCntText.text = MyWarPlayer.inst.contribution.toString();
        }

        private async _refresh() {
            this._cardCom.refresh();
            this._skinCom.refresh();
            this._equipCom.refresh();
            this._resCom.refresh();
        }
        private async _watch() {
            MyWarPlayer.inst.watchProp(MyWarPlayer.PropContribution, this._updateContribution, this);
        }
        private async _unwatch() {
            MyWarPlayer.inst.unwatchProp(MyWarPlayer.PropContribution, this._updateContribution, this);
        }
        public async close(...param: any[]) {
            super.close(...param);
            Core.EventCenter.inst.removeEventListener(WarMgr.RefreshShop, this._refresh, this);
            this._unwatch();
        }
        private async _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }
    }
}