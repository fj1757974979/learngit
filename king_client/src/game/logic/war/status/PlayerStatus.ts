// TypeScript file
module War {
    // export enum PlayerStatusName {
    //     ST_NORMAL = 0,         // 正常
    //     ST_ARREST = 1,         // 被抓
    //     ST_KICKOUT = 2,        // 驱逐
    //     ST_SUPPORT = 3,        // 支援
    //     ST_EXPEDITION = 4,     // 出征
    //     ST_DEFEND = 5,         // 守城
    //     ST_RECTIFY = 6,        // 整顿
    //     ST_REST = 7,           // 休养
    // }

    export class PlayerStatusBase extends WarStatusBase {
        protected _player: MyWarPlayer;

        public constructor(host: any) {
            super(host);
            this._player = <MyWarPlayer>host;
        }

        public get host(): MyWarPlayer {
            return this._player;
        }
    }

    export class PlayerNormal extends PlayerStatusBase {
        public get name(): number {
            return PlayerStatusName.ST_NORMAL;
        }
    }

    export class PlayerExpedition extends PlayerStatusBase {
        public get name(): number {
            return PlayerStatusName.ST_EXPEDITION;
        }
        public async enter(...param: any[]) {
            let team = WarTeamMgr.inst.myTeam;
            if (team) {
                let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
                fightStatusPanel.visible = true;
                if (team.inStatus(TeamStatusName.ST_CAN_ATT_CITY) || team.inStatus(TeamStatusName.ST_DEF_BATTLE_END) || team.inStatus(TeamStatusName.ST_FIELD_BATTLE_END)) {
                    fightStatusPanel.updateContinueStatus();
                } else {
                    fightStatusPanel.updateExpeditionStatus();
                }
                
            }
        }
        public async leave() {
            let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
            fightStatusPanel.closePanel();
        }
        private async _updateAttackForUI() {
            let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
            fightStatusPanel.updateAcctakCityStatus();
        }
    }

    export class PlayerSupport extends PlayerStatusBase {
        public get name(): number {
            return PlayerStatusName.ST_SUPPORT;
        }
        public async enter(...param: any[]) {
            if (WarTeamMgr.inst.myTeam) {
                let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
                fightStatusPanel.visible = true;
                fightStatusPanel.updateSupportStatus();
            }
        }
        public async leave() {
            let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
            fightStatusPanel.closePanel();
        }
    }

    export class PlayerDefend extends PlayerStatusBase {
        public get name(): number {
            return PlayerStatusName.ST_DEFEND;
        }
        public async enter(...param: any[]) {
            let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
            let team = WarTeamMgr.inst.myTeam;
            if (team) {
                if (team.inStatus(TeamStatusName.ST_CAN_ATT_CITY) || team.inStatus(TeamStatusName.ST_DEF_BATTLE_END) || team.inStatus(TeamStatusName.ST_FIELD_BATTLE_END)) {
                    fightStatusPanel.updateContinueStatus();
                } else {
                    fightStatusPanel.updateDefendStatus();
                }
            }        
        }
        public async leave() {
            let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
            fightStatusPanel.closePanel();
        }
    }

    export class PlayerArrest extends PlayerStatusBase {
        public get name(): number {
            return PlayerStatusName.ST_ARREST;
        }
        public async enter(...param: any[]) {
            let data = pb.CpStateBeCaptiveArg.decode(param[0]);
            this.remainTime = data.RemainTime;
            // this.startHeartbeat();
            let gameOverPanel = WarMgr.inst.warView.arrestPanel;
            gameOverPanel.showPanel();
        }
        public async leave() {
            // this.stopHeartbeat();
            let gameOverPanel = WarMgr.inst.warView.arrestPanel;
            gameOverPanel.closePanel();
        }
        protected heartbeat() {
            if (this.remainTime > 0) {
                this.remainTime -= 1;
                if (this.remainTime <= 0) {
                    this.remainTime = 0;
                }
            }
        }
    }

    export class PlayerRectify extends PlayerStatusBase {
        private _maxTime: number;

        public get name(): number {
            return PlayerStatusName.ST_RECTIFY;
        }
        public async enter(...param: any[]) {
            let data = pb.CpStateLoadingArg.decode(param[0]);
            this.remainTime = data.RemainTime;
            console.log(`Player begin rectify, remain ${data.RemainTime}s, max ${data.MaxTime}`);
            this._maxTime = data.MaxTime;
            let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
            fightStatusPanel.visible = true;
            this.startHeartbeat();
            this._updateRectifyForUI();
            Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70364));
        }

        public async leave() {
            this.stopHeartbeat();
            let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
            fightStatusPanel.visible = false;
        }

        private _updateRectifyForUI() {
            let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
            fightStatusPanel.updateRectifyStatus(this.remainTime, this._maxTime);
        }

        protected heartbeat() {
            if (this.remainTime > 0) {
                this.remainTime -= 1;
                if (this.remainTime <= 0) {
                    this.remainTime = 0;
                    let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
                    fightStatusPanel.updateContinueStatus();
                }
            }
            this._updateRectifyForUI();
        }
    }

    export class PlayerRest extends PlayerStatusBase {
        private _maxTime: number;
        public get name(): number {
            return PlayerStatusName.ST_REST;
        }
        
        public async enter(...param: any[]) {
            let data = pb.CpStateLoadingArg.decode(param[0]);
            this.remainTime = data.RemainTime;
            this._maxTime = data.MaxTime;
            console.log(`Player begin Rest, remain ${data.RemainTime}s, max ${data.MaxTime}`);
            let fightBtn = WarMgr.inst.warView.fightBtn;
            fightBtn.touchable = false;
            fightBtn.getChild("time").visible = true;
            this.startHeartbeat();
            this._updateRestForUI();
            Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70365));
            WarTeamMgr.inst.cleanMyTeam();
        }

        public async leave() {
            this.stopHeartbeat();
            let fightBtn = WarMgr.inst.warView.fightBtn;
            fightBtn.touchable = true;
            fightBtn.grayed = false;
            fightBtn.getChild("time").visible = false;
        }
        
        protected heartbeat() {
            if (this.remainTime > 0) {
                this.remainTime -= 1;
                if (this.remainTime <= 0) {
                    this.remainTime = 0;
                }
            }
            this._updateRestForUI();
        }

        private async _updateRestForUI() {
            let fightBtn = WarMgr.inst.warView.fightBtn;
            fightBtn.touchable = false;
            fightBtn.grayed = true;
            fightBtn.getChild("time").visible = true;
            fightBtn.getChild("time").asTextField.text = Core.StringUtils.format(Core.StringUtils.TEXT(70366), this.remainTime);
        }

    }

    export class PlayerKickOut extends PlayerStatusBase {
        public get name(): number {
            return PlayerStatusName.ST_KICKOUT;
        }
        public async enter(...param: any[]) {
            let data = pb.CpStateKickOutArg.decode(param[0]);
            let fightBtn = WarMgr.inst.warView.fightBtn;
            let questBtn = WarMgr.inst.warView.questBtn;
            fightBtn.touchable = false;
            fightBtn.grayed = true;
            questBtn.touchable = false;
            questBtn.grayed = true;
        }
        public async leave() {
            let fightBtn = WarMgr.inst.warView.fightBtn;
            let questBtn = WarMgr.inst.warView.questBtn;
            fightBtn.touchable = true;
            fightBtn.grayed = false;
            questBtn.touchable = true;
            questBtn.grayed = false;
        }
    }

    export class PlayerStatusDelegate extends WarStatusDelegateBase {

        protected _player: MyWarPlayer;

        public setDelegateHost(host: any) {
            this._player = <MyWarPlayer>host; 
            super.setDelegateHost(host);
        }

        public async changeStatus(stName: number, time: number = -1, ...param: any[]) {
            super.changeStatus(stName, time, ...param);
            console.log("Player Status change to ", stName);
        }

        protected initStatus() {
            this._statusObjs.setValue(PlayerStatusName.ST_NORMAL, new PlayerNormal(this._player));
            this._statusObjs.setValue(PlayerStatusName.ST_EXPEDITION, new PlayerExpedition(this._player));
            this._statusObjs.setValue(PlayerStatusName.ST_SUPPORT, new PlayerSupport(this._player));
            this._statusObjs.setValue(PlayerStatusName.ST_DEFEND, new PlayerDefend(this._player));
            this._statusObjs.setValue(PlayerStatusName.ST_ARREST, new PlayerArrest(this._player));
            this._statusObjs.setValue(PlayerStatusName.ST_RECTIFY, new PlayerRectify(this._player));
            this._statusObjs.setValue(PlayerStatusName.ST_REST, new PlayerRest(this._player));
            this._statusObjs.setValue(PlayerStatusName.ST_KICKOUT, new PlayerKickOut(this._player));
        }
    }
}