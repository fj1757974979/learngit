module War {
    
    export class CampIconCom extends fairygui.GComponent {

        public static campFlag2Url(flagID: string) {
            if (!flagID || flagID == "" ) {
                return "war_flag1_png";
            }
            return "";
        }
        
        private _createCtr: fairygui.Controller;
        private _campName: fairygui.GTextField;
        private _campFlag: fairygui.GLoader;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._createCtr = this.getController("create");
            this._campName = this.getChild("campName").asTextField;
            this._campFlag = this.getChild("campFlag").asLoader;
            this._createCtr.selectedIndex = 1;
        }
        public setCamp(camp: Country) {
            if (!camp) {
                this._campName.text = "";
                this._campFlag.url = "war_flag0_png";
            } else {
                this._campName.text = camp.countryName;
                if (camp.countryFlag == "") {
                    this._campFlag.url = "war_flag0_png";
                } else {
                    this._campFlag.url = camp.countryFlag;
                }
            }
        }
        public setCampName(name: string) {
            this._campName.text = name;
        }
        public setCampFlag(flag: string) {
            this._campFlag.url = flag;
        }
        public setChoose(bool: boolean) {
            if (bool) {
                this._createCtr.selectedIndex = 1;
            } else {
                this._createCtr.selectedIndex = 0;
            }
        }
    }
}