module Guide {

    export class GuideHome extends Core.BaseView {
        private _btnWei: fairygui.GButton;
        private _btnShu: fairygui.GButton;
        private _btnWu: fairygui.GButton;
        private _enterT :fairygui.Transition;

        private _guideCamp: Camp;
        private _callback: (camp: Camp) => void;
        
        public initUI() {
            super.initUI();
            this._myParent = Core.LayerManager.inst.maskLayer;
            this.adjust(this.getChild("bg"));
            this._btnWei = this.getChild("btnWei").asButton;
            this._btnShu = this.getChild("btnShu").asButton;
            this._btnWu = this.getChild("btnWu").asButton;
            //this._enterT = this.getTransition("t0");

            this._btnWei.addClickListener(this._onChooseWei, this);
            this._btnShu.addClickListener(this._onChooseShu, this);
            this._btnWu.addClickListener(this._onChooseWu, this);
        }

        public async open(...param:any[]) {
            super.open(...param);
            this._callback = param[0];
        }

        public async close(...param:any[]) {
            super.close(...param);
            this._callback = null;
            //this._enterT.stop();
        }

        private async _onChooseWei() {
            // let ok = await GuideMgr.inst.beginGuideBattle(Camp.WEI);
            // if (ok) {
            //     Core.ViewManager.inst.closeView(this);
            // }
            if (this._callback) {
                this._callback(Camp.WEI);
            }
            Core.ViewManager.inst.closeView(this);
            this._onCreateRole();
        }

        private async _onChooseShu() {
            // let ok = await GuideMgr.inst.beginGuideBattle(Camp.SHU);
            // if (ok) {
            //     Core.ViewManager.inst.closeView(this);
            // }
            if (this._callback) {
                this._callback(Camp.SHU);
            }
            Core.ViewManager.inst.closeView(this);
            this._onCreateRole();
        }

        private async _onChooseWu() {
            // let ok = await GuideMgr.inst.beginGuideBattle(Camp.WU);
            // if (ok) {
            //     Core.ViewManager.inst.closeView(this);
            // }
            if (this._callback) {
                this._callback(Camp.WU);
            }
            Core.ViewManager.inst.closeView(this);
            this._onCreateRole();
        }

        private _onCreateRole() {
            Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.ON_CREATE_ROLE, {
                "userId": `${Player.inst.uid}`,
                "userName": Player.inst.name,
                "level": 1,
                "serverId": 1,
                "serverName": "commonServer"
            });
        }
    }

}