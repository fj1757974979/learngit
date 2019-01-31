module UI {

    export class ResList extends fairygui.GComponent {
        private _list: fairygui.GList;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._list = this.getChild("list").asList;
        }

        public setData(rewardRes:Array<any>) {
            if (!rewardRes) {
                return;
            }
            rewardRes.sort((a, b):number => {
                if (Utils.resTypePriority(a.Type) < Utils.resTypePriority(b.Type)) {
                    return -1;
                } else {
                    return 1;
                }
            });
            this._list.removeChildren();
            rewardRes.forEach(resData => {
                if (resData.Type == ResType.T_SCORE) {
                    return;
                }
                let resLabel = this._list.addItem() as UI.ResLabel;
                resLabel.setData(resData)
            });
            this._list.resizeToFit();
            this.width = this._list.width * this._list.scaleX;
        }
    }

}