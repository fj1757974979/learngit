module Battle {

    export class CampaignBattle extends Battle {
        public get battleType(): BattleType {
            return BattleType.Campaign;
        }

        public getEndViewName(): string {
            return ViewName.friendBattleEnd;
        }

        public isPvp(): boolean {
            return true;
        }

        public async endBattle(data:any, isReplay:boolean=false) {
            await super.endBattle(data, isReplay);
        }

        protected async _onBattleEnd(evt:egret.Event) {
            super._onBattleEnd(evt);

            if (evt.data != this.getEndViewName()) {
                return;
            }

            // Core.ViewManager.inst.open(ViewName.warHome);
            await War.WarMgr.inst.openWarHome();
            let enterAniView: War.WarEnterAniView = Core.ViewManager.inst.getView(ViewName.enterWarAni) as War.WarEnterAniView;
            if (enterAniView) {
                await enterAniView.dismiss();
                Core.ViewManager.inst.close(ViewName.enterWarAni);
            }
        }
    }

}