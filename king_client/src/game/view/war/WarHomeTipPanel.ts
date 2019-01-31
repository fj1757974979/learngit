module War {
    export enum WarTipType {
        JoinCity,
        ReadyWar,
        InWar,
    }
    export class WarHomeTipPanel extends fairygui.GComponent {

        private _titleText: fairygui.GTextField;
        private _descText: fairygui.GTextField;
        private _time: number;
        private _title: string;
        private _desc: string;
        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._titleText = this.getChild("n1").asTextField;
            this._descText = this.getChild("txt2").asTextField;
            this._title = "";
            this._desc = "";
        }
        
        public showTipNormal() {
            this.visible = true;
            if (MyWarPlayer.inst.cityID == 0) {
                this._title = Core.StringUtils.TEXT(70308);
                this._desc = Core.StringUtils.TEXT(70309);
            } else {
                this._title = Core.StringUtils.TEXT(70310);
                this._desc = "{0}";
            }
            this._titleText.text = Core.StringUtils.format(this._title, Core.StringUtils.secToString(WarMgr.inst.getCurStatusRemainTime(), "hms")) ;
            this._descText.text = Core.StringUtils.format(this._desc, Core.StringUtils.secToString(WarMgr.inst.getCurStatusRemainTime(), "hms")) ;
            this._startTimer();
        }
        public showTipPrePare() {
            this.visible = true;
            if (MyWarPlayer.inst.countryID != 0) {
                this._title = Core.StringUtils.TEXT(70311);
                this._desc = Core.StringUtils.TEXT(70312);
                this._titleText.text = Core.StringUtils.format(this._title, Core.StringUtils.secToString(WarMgr.inst.getCurStatusRemainTime(), "hms")) ;
                this._descText.text = Core.StringUtils.format(this._desc);
            } else {
                this._title = Core.StringUtils.TEXT(70311);
                this._desc = Core.StringUtils.TEXT(70314);
                this._titleText.text = `${Core.StringUtils.secToString(WarMgr.inst.getCurStatusRemainTime(), "hms")}`
                this._descText.text = this._desc;
            }
            this._startTimer();
            
        }
        public showTipInWar() {
            this.visible = true;
            if (MyWarPlayer.inst.countryID != 0) {
                this._title = Core.StringUtils.TEXT(70315);
                this._desc = Core.StringUtils.TEXT(70316);
                this._titleText.text = Core.StringUtils.format(this._title, Core.StringUtils.secToString(WarMgr.inst.getCurStatusRemainTime(), "hms")) ;
                this._descText.text = Core.StringUtils.format(this._desc);
            } else {
                this._title = Core.StringUtils.TEXT(70315);
                this._desc = Core.StringUtils.TEXT(70314);
                this._titleText.text = `${Core.StringUtils.secToString(WarMgr.inst.getCurStatusRemainTime(), "hms")}`
                this._descText.text = this._desc;
            }
            this._startTimer();
        }
        private _startTimer() {
            fairygui.GTimers.inst.add(1000, -1, this._updateTimer, this);
        }
        private _updateTimer() {
            this._time -= 1;
            if (this._time <= 0) {
                this.closeTip();
            } else {
                this._titleText.text = Core.StringUtils.format(this._title, Core.StringUtils.secToString(WarMgr.inst.getCurStatusRemainTime(), "hms")) ;
                this._descText.text = Core.StringUtils.format(this._desc, Core.StringUtils.secToString(WarMgr.inst.getCurStatusRemainTime(), "hms"));
            }
        }
        public closeTip() {
            fairygui.GTimers.inst.remove(this._updateTimer, this);
            this.visible = false;
        }
    }
}