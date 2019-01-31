module Reborn {
    
    export class RefineInfoWnd extends Core.BaseWindow {

        private _refineList: fairygui.GList;
        private _closeBtn: fairygui.GButton;
        private _openBtn: fairygui.GButton;

        private _refineFeats: number;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;

            this._refineList = this.contentPane.getChild("n86").asList;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._openBtn = this.contentPane.getChild("openBtn").asButton;

            this._closeBtn.addClickListener(this._onCloseBtn, this);
            this._openBtn.addClickListener(this._onRefineCard, this);

        }

        public async open(...param: any[]) {
            super.open(...param);
            
            let refineRareDic = RebornMgr.inst.refineRareDic;
            let honorKeys = Data.card_caculation.keys;
            for (let i = 1; i <= honorKeys.length; i++) {
                let com = this._refineList.getChild(`lv${i}`).asCom;
                let num = 0;
                if (refineRareDic.containsKey(i)) {
                    num = refineRareDic.getValue(i);
                }
                let rareCom = com.getChild("cardRare").asCom as UI.CardRareCom;
                rareCom.setRare(i);
                com.getChild("cardCnt").asTextField.text = `${num}（x${Data.card_caculation.get(honorKeys[i - 1]).honor}）`;
                let count = num * Data.card_caculation.get(i).honor;
                com.getChild("honorCnt").asTextField.text = `x${count}`;
            }
            let com = this._refineList.getChild(`all`).asCom;
            this._refineFeats = RebornMgr.inst.refineFeats;
            com.getChild("honorCnt").asTextField.text = this._refineFeats.toString();

        }

        private async _onRefineCard() {
            if (this._refineFeats <= 0) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70171));
                return;
            }
            let ok = RebornMgr.inst.onAllRefineCard();
            if (ok) {
                Core.ViewManager.inst.closeView(this);
            }
        }

        private async _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }

        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}