module UI {

    export class TipsCom extends fairygui.GComponent implements Core.ITipsCom {
        private _text: fairygui.GTextField;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._text = this.getChild("text").asTextField;
            this._text.textParser = Core.StringUtils.parseColorText;
        }

        public show(msg:string): Promise<void> {
            this._text.text = msg;
            this.y = fairygui.GRoot.inst.height / 2;
            this.x = fairygui.GRoot.inst.width / 2 - this.width / 2;
            return new Promise<void>(resovle => {
                this.getTransition("t0").play(()=>{
                    resovle();
                }, this);
            });
        }

    }

}