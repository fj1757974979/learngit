module UI {

    export class ResLabel extends fairygui.GLabel {
        private _defColor: number;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._defColor = this.titleColor;
        }

        public setData(res:any) {
            this.icon = Utils.resType2Icon(res.Type);
            if (res.Amount < 0) {
                this.title = "x" + (- res.Amount);
                this.titleColor = Core.TextColors.red;
            } else {
                this.title = "x" + res.Amount;
                this.titleColor = this._defColor;
            }
            this.width = this._titleObject.x + this._titleObject.width;
        }
    }

}