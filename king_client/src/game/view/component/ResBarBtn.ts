module UI {

    export class ResBarBtn extends fairygui.GButton {
        private static _exchangeWnd: ExchangeResWnd;
        private _resType: ResType;

        public setup_beforeAdd(xml: any): void {
            super.setup_beforeAdd(xml, 0);
            this._resType = parseInt(this.data);
            Player.inst.addEventListener(Player.ResUpdateEvt, this._onResUpdate, this);
            this.addClickListener(this._onClick, this);
            this._onResUpdate();
        }

        private _onResUpdate() {
            let amount = Player.inst.getResource(this._resType);
            if (amount <= 0) {
                amount = 0
                this.titleColor = Core.TextColors.red;
            } else {
                this.titleColor = Core.TextColors.green;
            }
            this.title = amount.toString();
        }

        private _onClick() {
            if (!ResBarBtn._exchangeWnd) {
                ResBarBtn._exchangeWnd = fairygui.UIPackage.createObject(PkgName.common, "exchangeRes", ExchangeResWnd) as ExchangeResWnd;
            }
            ResBarBtn._exchangeWnd.show(this._resType, this);
        }
    }

}
