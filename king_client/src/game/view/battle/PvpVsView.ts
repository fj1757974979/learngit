module Battle {

    export class PvpVsView extends Core.BaseView {
        private _trans: fairygui.Transition;
        private _selfName: fairygui.GTextField;
        private _enemyName: fairygui.GTextField;
        private _selfCountry: fairygui.GLoader;
        private _selfCountryBg: fairygui.GLoader;
        private _enemyCountry: fairygui.GLoader;
        private _enemyCountryBg: fairygui.GLoader;
        private _selfRankIcon: UI.PvpRankBannerCom;
        private _enemyRankIcon: UI.PvpRankBannerCom;
        private _selfHead: Social.HeadCom;
        private _enemyHead: Social.HeadCom;

        public initUI() {
            super.initUI();
            this.adjust(this.getChild("bg"));
            this._trans = this.getTransition("t0");
            this._selfName = this.getChild("selfName").asTextField;
            this._enemyName = this.getChild("enemyName").asTextField;
            this._selfName.textParser = Core.StringUtils.parseColorText;
            this._enemyName.textParser = Core.StringUtils.parseColorText;
            this._selfCountry = this.getChild("selfCountry").asLoader;
            this._selfCountryBg = this.getChild("selfCountryBg").asLoader;
            this._enemyCountry = this.getChild("enemyCountry").asLoader;
            this._enemyCountryBg = this.getChild("enemyCountryBg").asLoader;
            this._selfRankIcon = this.getChild("selfRankIcon") as UI.PvpRankBannerCom;
            this._enemyRankIcon = this.getChild("enemyRankIcon") as UI.PvpRankBannerCom;
            this._selfHead = this.getChild("selfHead") as Social.HeadCom;
            this._enemyHead = this.getChild("enemyHead") as Social.HeadCom;
        }

        public async open(...param:any[]) {
            super.open(...param);
            let battle = param[0] as Battle;
            let ownFighter = battle.getOwnFighter();
            let enemyFighter = battle.getEnemyFighter();
            this._selfName.text = ownFighter.name;
            this._enemyName.text = enemyFighter.name;
            this._selfCountry.url = this._campToResUrl(ownFighter.camp);
            this._enemyCountry.url = this._campToResUrl(enemyFighter.camp);
            this._selfCountryBg.url = this._campToBgResUrl(ownFighter.camp);
            this._enemyCountryBg.url = this._campToBgResUrl(enemyFighter.camp);

            let battleType = battle.battleType;
            if (battleType == BattleType.LEVEL || battleType == BattleType.LevelHelp) {
                this._selfHead.visible = false;
                this._enemyHead.visible = false;
            } else {
                this._selfHead.setAll(ownFighter.headIcon, ownFighter.frameIcon);
                this._enemyHead.setAll(enemyFighter.headIcon, enemyFighter.frameIcon);
            }

            this._selfRankIcon.refresh(ownFighter.pvpScore);
            this._enemyRankIcon.refresh(enemyFighter.pvpScore);
            await new Promise<void>(reslove => {
                this._trans.play(()=>{
                    reslove();
                }, this);
            });
        }

        private _campToResUrl(camp:Camp): string {
            if (camp == Camp.WEI) {
                return "battle_txtWei_png";
            } else if (camp == Camp.SHU) {
                return "battle_txtShu_png";
            } else {
                return "battle_txtWu_png";
            }
        }

        private _campToBgResUrl(camp:Camp): string {
            if (camp == Camp.WEI) {
                return "battle_nameWei_png";
            } else if (camp == Camp.SHU) {
                return "battle_nameShu_png";
            } else {
                return "battle_nameWu_png";
            }
        }
    }

}