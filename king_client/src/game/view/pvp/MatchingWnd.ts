module Pvp {

    export class MatchingWnd extends Core.BaseWindow {
        private _cancelMatchBtn: fairygui.GButton;

        public initUI() {
            super.initUI();
            this.adjust(this.getChild("background"));
            //this.adjust(this, Core.AdjustType.NO_BORDER);
            this.center();
            this.modal = true;
            this._cancelMatchBtn = this.getChild("cancelMatchBtn").asButton;
            this._cancelMatchBtn.addClickListener(PvpMgr.inst.cancelMatch, PvpMgr.inst);
        }

        public async open(...param:any[]) {
            SoundMgr.inst.playBgMusic("matching_mp3");
            super.open(...param);
            this._cancelMatchBtn.visible = true;
            await fairygui.GTimers.inst.waitTime(1);
            this.getTransition("shake").play(null, null, null, -1);
        }

        public async close(...param:any[]) {
            //SoundMgr.inst.playBgMusic("bg_mp3");
            // await Core.PopUpUtils.removePopUp(this, 7);
            await new Promise<void>(resolve => {
                egret.Tween.get(this).to({ scaleX: 0, scaleY: 0 }, 300, egret.Ease.backIn).call(function () {
                    resolve();
                }, this);
            })
            // super.close(...param);
            await super.close(...param);
            this.getTransition("shake").stop();
        }

        public async readyFight() {
            this._cancelMatchBtn.visible = false;
            await fairygui.GTimers.inst.waitTime(2000);
            this.getTransition("shake").stop();
            this.getTransition("open").play(()=>{
                    Core.ViewManager.inst.closeView(this);
            }, this);           
            await fairygui.GTimers.inst.waitTime(1000);
        }
    }
}
