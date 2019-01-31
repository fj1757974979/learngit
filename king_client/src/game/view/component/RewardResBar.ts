module UI {

    export class RewardResBar extends fairygui.GLabel {
        private _resList: ResList;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._resList = this.getChild("resList") as ResList;
        }

        public setData(rewardRes:Array<any>) {
            if (!rewardRes) {
                return;
            }
            this._resList.setData(rewardRes);
            this.width = this._resList.x + this._resList.width;
        }
    }

}