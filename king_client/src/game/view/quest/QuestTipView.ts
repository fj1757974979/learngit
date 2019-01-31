module Quest {
    
    export class QuestTipView extends Core.BaseView {

        private _isShow: boolean;

        private _tipList: fairygui.GList;
        private _tipItemList: Array<QuestTipItem>;

        public initUI() {
            super.initUI();
            
            this.center();
            this.y = 0;

            this._isShow = false;

            this._tipList = this.getChild("n0").asList;
            this._tipList.removeChildrenToPool();

            QuestMgr.inst.addEventListener(QuestMgr.ShowTip,this._showTip,this);
            this._tipItemList = new Array<QuestTipItem>();
        }

        private async _showTipView(questData: QuestData) {
            if(Core.ViewManager.inst.isShow(ViewName.battle)) {
                // console.log("battle view is open");
                fairygui.GTimers.inst.add(500,1,()=> {
                    this._showTipView(questData);
                },this);
            } else {
                // console.log("battle view is close");
                if(this._isShow) {
                    fairygui.GTimers.inst.remove(this._closeView,this);
                }
                await fairygui.GTimers.inst.add(3000,1,this._closeView,this);
                this._isShow = true;
                // fairygui.GRoot.inst.bringToFront(this);
                // this.bringToFront();
                if(this._tipItemList.length < 1) {
                    let _item = this._tipList.addItemFromPool() as QuestTipItem;
                    _item.setQuest(questData);
                    this._tipItemList.push(_item);
                    return;
                } else {
                    this._tipItemList.forEach(_item => {
                        if(_item.visible && _item.getID == questData.getID) {
                            _item.setQuest(questData);
                            return;
                        }
                    });
                    this._tipItemList.forEach(_item => {
                        if(!_item.visible) {
                            _item.setQuest(questData);
                            return;
                        }
                    });
                    let _item = this._tipList.addItemFromPool() as QuestTipItem;
                    _item.setQuest(questData);
                    this._tipItemList.push(_item);
                }
            }
        }

        private async _showTip(evt: egret.Event) {
            let questData = evt.data as QuestData;
            this._showTipView(questData);
        }

        private _closeView() {
            Core.ViewManager.inst.closeView(this);
            this._tipList.removeChildrenToPool();
            this._isShow = false;
        }

         public async open(...param:any[]) {
            super.open(...param);
        }

        public async colse(...param:any[]) {
            super.close(...param);
            
        }
    }
}