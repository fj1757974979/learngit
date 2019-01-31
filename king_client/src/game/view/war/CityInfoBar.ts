module War {

    export class CityInfoBar extends fairygui.GComponent {

        private _bar: UI.MaskProgressBar;
        private _icon: fairygui.GLoader;
        private _numText: fairygui.GTextField;

        private _type: WarResType;
        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);

            this._bar = this.getChild("pro").asCom as UI.MaskProgressBar;
            this._icon = this.getChild("icon").asLoader;
            this._numText = this.getChild("pro").asCom.getChild("text").asTextField;
            this._numText.textParser = Core.StringUtils.parseColorText;
        }

        public setProgress(cur: number, max: number) {
            this._bar.setProgress(cur, max);
            this._numText.text = `${cur}/${max}`
        }
        public setProgress2(cur: number, max: number) {
            this._bar.setProgress2(cur, max);
        }
        public setText(cur:number, max:number, add: number){
            if (add > 0){
                this._numText.text = `${cur}#cg+${add}#n/${max}`;
            } else {
                this._numText.text = `${cur}/${max}`;
            }
        }
        public setTextAlign(align: fairygui.AlignType) {
            this._numText.align = align;
        }
        public setIconUrl(url: string) {
            this._icon.url = url;
        }
        public openClick(type: WarResType) {
            this._type = type;
            this.addClickListener(this._onResCom, this);
        }
        private _onResCom() {
            // let com = fairygui.UIPackage.createObject(PkgName.cards, ViewName.skillInfo).asCom;
            // com.getChild("skillDescTxt").asRichTextField.text = Utils.warResType2desc(this._type);;
            // this._parent.addChild(com);
            // let onTouch;
            // onTouch = function() {
            //     com.parent.removeChild(com);
            //     egret.MainContext.instance.stage.removeEventListener(egret.TouchEvent.TOUCH_END, onTouch, com);
            // }
            // egret.MainContext.instance.stage.addEventListener(egret.TouchEvent.TOUCH_END, onTouch, com);
            // com.center();
            // com.y = this.y + this.height;
            Core.ViewManager.inst.openPopup(ViewName.descTipsWnd, Utils.warResType2desc(this._type));
        }
    }
}