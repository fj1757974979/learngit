module Battle {

    export class PvpBattleEnd extends BaseBattleEnd {
        private _pvpExpProgressBar: UI.MaskProgressBar;
        private _pvpLevelTxt: fairygui.GTextField;
        private _showing: Promise<void>;
        private _rewardTitle: fairygui.GTextField;

        public initUI() {
            super.initUI();
            this.adjust(this.getChild("background"));
            this._pvpExpProgressBar = this.getChild("pvpExpProgressBar") as UI.MaskProgressBar;
            this._pvpLevelTxt = this.getChild("pvpLevelTxt").asTextField;
            let rewardTitle = this.getChild("rewardTitle");
            if (rewardTitle) {
                this._rewardTitle = rewardTitle.asTextField;
            }
        }

        public async open(...param:any[]) {
            let isWin = param[0].WinUid == Player.inst.uid;
            this._resultCtrl.selectedPage = isWin ? "win" : "lose";
            
            if (isWin) {
                if (this._rewardTitle) {
                    this._rewardTitle.visible = false;
                }
                this.setRewardResBar(param[0].Res);
            } else if (this._rewardTitle) {
                this._rewardTitle.visible = false;
            }

            this._showing = super.open(isWin);
            this._setPvpScore(param[0].Res);
            await this._showing;
            this._showing = null;
            Pvp.PvpMgr.inst.onEnterPvp();
        }

        private async _setPvpScore(resRewards: Array<any>) {
            let pvpScoreChange = 0;
            for (let data of resRewards) {
                if (data.Type == ResType.T_SCORE) {
                    pvpScoreChange = data.Amount;
                    break;
                }
            }

            let nowScore = Player.inst.getResource(ResType.T_SCORE);
            nowScore = nowScore < 0 ? 0 : nowScore;
            let oldScore = nowScore - pvpScoreChange;
            oldScore = oldScore < 0 ? 0 : oldScore;
            let nowPvpLevel = Pvp.PvpMgr.inst.getPvpLevel();
            let oldPvpLevel = Pvp.PvpMgr.inst.getPvpLevelByScore(oldScore);
            this._pvpLevelTxt.text = `Lv${oldPvpLevel}: `;
            let maxScore = Pvp.PvpMgr.inst.getNextPvpLevelScore();
            this._pvpExpProgressBar.setProgress(oldScore, maxScore);
            if (this._showing) {
                await this._showing;
            }
            await fairygui.GTimers.inst.waitTime(500);
            await this._pvpExpProgressBar.doProgressAnimation(oldScore, nowScore, maxScore);
            this._pvpLevelTxt.text = `Lv${nowPvpLevel}: `;
        }
    }

}