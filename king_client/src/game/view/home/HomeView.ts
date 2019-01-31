module Home {

    export class HomeView extends Core.BaseView {
        private _backBtn: fairygui.GButton;
        private _setupBtn: fairygui.GButton;
        private _campignBtn: fairygui.GButton;
        private _levelBtn: fairygui.GButton;
        private _matchBtn: fairygui.GButton;
        private _cardPoolBtn: fairygui.GButton;

        public initUI() {
            super.initUI();
            this.adjust(this.getChild("bg"));
            this._backBtn = this.getChild("backBtn").asButton;
            this._setupBtn = this.getChild("setupBtn").asButton;
            this._campignBtn = this.getChild("campignBtn").asButton;
            this._levelBtn = this.getChild("levelBtn").asButton;
            this._matchBtn = this.getChild("matchBtn").asButton;
            this._cardPoolBtn = this.getChild("cardPoolBtn").asButton;

            this._levelBtn.addClickListener(Level.LevelMgr.inst.onEnterLevel, Level.LevelMgr.inst);
            this._cardPoolBtn.addClickListener(CardPool.CardPoolMgr.inst.onEnterCardPool, CardPool.CardPoolMgr.inst);
            this._matchBtn.addClickListener(this._onEnterPvp, this);
            this._campignBtn.addClickListener(this._onEnterCampign, this);
            this._setupBtn.addClickListener(this._onSetup, this);
            this._backBtn.addClickListener(this._onPlayerLogout, this);


            if (!window.gameGlobal.debug) {
                this._setupBtn.visible = false;
            }
        }

        public async open(...param:any[]) {
            super.open(...param);
            //if (Campign.CampignMgr.inst.isOpen()) {
            //    this._campignBtn.grayed = false;
            //} else {
            //    this._campignBtn.grayed = true;
            //}

            if (Pvp.PvpMgr.inst.isOpen()) {
                this._matchBtn.grayed = false;
            } else {
                this._matchBtn.grayed = true;
            }
        }

        private _onSetup() {
            Core.ViewManager.inst.open(ViewName.cmdWnd);
        }

        private _onEnterCampign() {
            //Campign.CampignMgr.inst.onEnterCampign();
        }

        private _onEnterPvp() {
            Pvp.PvpMgr.inst.onEnterPvp();
        }

        private _onPlayerLogout() {
            HomeMgr.inst.onPlayerLogout();
        }

    }

}
