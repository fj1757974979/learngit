module War {

    export class CityInfoCom extends fairygui.GComponent {

        private _icon: fairygui.GLoader;
        private _numText: fairygui.GTextField;
        private _type: WarResType;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);

            this._numText = this.getChild("time").asTextField;
            this._icon = this.getChild("icon").asLoader;
        }

        public setNum(num: number) {
            this._numText.text = num.toString();
        }
        public setStr(str: string) {
            this._numText.text = str;
        }
        public setIconUrl(type: WarResType) {
            this._type = type;
            this._icon.url = Utils.warResType2Url(type);
        }
        public setInfo(type: WarResType, num:number) {
            this.setIconUrl(type);
            this.setNum(num);
        }
        public setTextAlign(align: fairygui.AlignType) {
            this._numText.align = align;
        }
        public openClick() {
            this._icon.addClickListener(this._onResCom, this);
        }
        private _onResCom() {
            // let com = fairygui.UIPackage.createObject(PkgName.cards, ViewName.skillInfo).asCom;
            // com.getChild("skillDescTxt").asRichTextField.text = Utils.warResType2desc(this._type);
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