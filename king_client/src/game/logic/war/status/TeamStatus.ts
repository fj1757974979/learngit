// TypeScript file
module War {

    // export enum TeamStatusName {
    //     ST_NORMAL = 0,            // 正常行走
    //     ST_FIELD_BATTLE = 1,      // 野战中，如果一个队伍变成这个状态，让队伍在地图上停下来，直到变成ST_NORMAL，再继续走
    //     ST_CAN_ATT_CITY = 2,      // 到达敌城，能攻城，但没攻，如果这个队伍是MyTeam，界面需要显示攻城/撤退选项
    //     ST_ATTACKING_CITY = 3,    // 正在攻城
    //     ST_DISAPPEAR = 4,         // 消失
    //     ST_FIELD_BATTLE_END = 5,  // 野战结束，如果是MyTeam，显示继续行军或撤退，如果别人的队伍，在地图上停下来
    //     ST_ATT_CITY = 6,          // 攻城战中
    //     ST_DEF_CITY = 7,          // 守城战中
    //     ST_DEF_BATTLE_END = 8,    // 守城战结束，显示继续守城/取消
    // }

    export class TeamStatusBase extends WarStatusBase {
        protected _team: WarTeam;

        public constructor(host: any) {
            super(host);
            this._team = <WarTeam>host;
        }

        public get host(): WarTeam {
            return this._team;
        }
    }

    export class TeamNormal extends TeamStatusBase {
        public get name(): number {
            return TeamStatusName.ST_NORMAL;
        }

        public async enter(...param: any[]) {
            // 开始寻路
            this._team.resumeRun(true);
            if (this._team.isMyTeam()) {
                if (MyWarPlayer.inst.inStatus(PlayerStatusName.ST_EXPEDITION)){
                    let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
                    fightStatusPanel.visible = true;
                    fightStatusPanel.updateExpeditionStatus();
                } else if (MyWarPlayer.inst.inStatus(PlayerStatusName.ST_SUPPORT)) {
                    let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
                    fightStatusPanel.visible = true;
                    fightStatusPanel.updateSupportStatus();
                } else if (MyWarPlayer.inst.inStatus(PlayerStatusName.ST_DEFEND)) {
                    let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
                    fightStatusPanel.visible = true;
                    fightStatusPanel.updateDefendStatus();
                }
            }
            
        }

        public async leave() {
            this._team.resumeRun(false);
        }
    }

    export class TeamFieldBattle extends TeamStatusBase {
        public get name(): number {
            return TeamStatusName.ST_FIELD_BATTLE;
        }

        public async enter(...param: any[]) {
            if (this._team.char) {
                this._team.char.setInFightMode(true);
            }
        }

        public async leave() {
            if (this._team.char) {
                this._team.char.setInFightMode(false);
            }
        }
    }

    export class TeamCanAttCity extends TeamStatusBase {
        public get name(): number {
            return TeamStatusName.ST_CAN_ATT_CITY;
        }

        public async enter(...param: any[]) {
            if (this._team.isMyTeam()) {
                let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
                fightStatusPanel.updateContinueStatus();
            }
        }

        public async leave() {
            if (this._team.isMyTeam()) {
                let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
                fightStatusPanel.closePanel();
            }
        }
    }

    export class TeamAttackingCity extends TeamStatusBase {
        public get name(): number {
            return TeamStatusName.ST_ATTACKING_CITY;
        }

        public async enter(...param: any[]) {
            if (this._team.char) {
                this._team.char.setInAttCityMode(true, this._team);
            }
            if (this._team.isMyTeam()) {
                let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
                fightStatusPanel.visible = true;
                fightStatusPanel.updateExpeditionStatus();
            }
        }

        public async leave() {
            if (this._team.char) {
                this._team.char.setInAttCityMode(false);
            }
        }
    }

    export class TeamDisappear extends TeamStatusBase {
        public get name(): number {
            return TeamStatusName.ST_DISAPPEAR;
        }

        public async enter(...param: any[]) {
            let data = param[0];
            if (data && this._team.isMyTeam()) {
                WarTeam.showTeamDisappearTipsByPayload(data, true);
            }
            if (!this._team.isMyTeam()) {
                WarTeamMgr.inst.delOtherTeam(this._team.teamID);
            } else {
                WarTeamMgr.inst.cleanMyTeam();
            }
            this._team.onDestroy();
        }
    }

    export class TeamFieldBattleEnd extends TeamStatusBase {
        public get name(): number {
            return TeamStatusName.ST_FIELD_BATTLE_END;
        }

        public async enter(...param: any[]) {
            if (this._team.isMyTeam()) {
                let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
                fightStatusPanel.updateContinueStatus();
            }
        }
        public async leave() {
            if (this._team.isMyTeam()) {
                let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
                fightStatusPanel.closePanel();
            }
        }
    }

    export class TeamAttCity extends TeamStatusBase {
        public get name(): number {
            return TeamStatusName.ST_ATT_CITY;
        }

        public async enter(...param: any[]) {
            if (this._team.char) {
                this._team.char.setInFightMode(true);
            }
            if (this._team.isMyTeam()) {
                let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
                fightStatusPanel.visible = true;
                fightStatusPanel.updateExpeditionStatus();
            }
        }

        public async leave() {
            if (this._team.char) {
                this._team.char.setInFightMode(false);
            }
        }
    }

    export class TeamDefCity extends TeamStatusBase {
        public get name(): number {
            return TeamStatusName.ST_DEF_CITY;
        }
    }

    export class TeamDefBattleEnd extends TeamStatusBase {
        public get name(): number {
            return TeamStatusName.ST_DEF_BATTLE_END;
        }

        public async enter(...param: any[]) {
            if (this._team.isMyTeam()) {
                let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
                fightStatusPanel.updateContinueStatus();
            }
        }
        public async leave() {
            if (this._team.isMyTeam()) {
                let fightStatusPanel = WarMgr.inst.warView.fightStatusPanel;
                fightStatusPanel.closePanel();
            }
        }
    }

    export class TeamStatusDelegate extends WarStatusDelegateBase {

        protected _team: WarTeam;

        public setDelegateHost(host: any) {
            this._team = <WarTeam>host; 
            super.setDelegateHost(host);
        }

        protected initStatus() {
            this._statusObjs.setValue(TeamStatusName.ST_NORMAL, new TeamNormal(this._team));
            this._statusObjs.setValue(TeamStatusName.ST_ATT_CITY, new TeamAttCity(this._team));
            this._statusObjs.setValue(TeamStatusName.ST_ATTACKING_CITY, new TeamAttackingCity(this._team));
            this._statusObjs.setValue(TeamStatusName.ST_CAN_ATT_CITY, new TeamCanAttCity(this._team));
            this._statusObjs.setValue(TeamStatusName.ST_DEF_BATTLE_END, new TeamDefBattleEnd(this._team));
            this._statusObjs.setValue(TeamStatusName.ST_DEF_CITY, new TeamDefCity(this._team));
            this._statusObjs.setValue(TeamStatusName.ST_DISAPPEAR, new TeamDisappear(this._team));
            this._statusObjs.setValue(TeamStatusName.ST_FIELD_BATTLE, new TeamFieldBattle(this._team));
            this._statusObjs.setValue(TeamStatusName.ST_FIELD_BATTLE_END, new TeamFieldBattleEnd(this._team));
            
        }

        public isAttCity() {
            if (this._team.inStatus(TeamStatusName.ST_ATT_CITY) || this._team.inStatus(TeamStatusName.ST_ATTACKING_CITY) || this._team.inStatus(TeamStatusName.ST_CAN_ATT_CITY)) {
                return true;
            }
            return false;
        }

        public async changeStatus(stName: number, time: number = -1, ...param: any[]) {
            if (stName != TeamStatusName.ST_DISAPPEAR &&
                stName != TeamStatusName.ST_DEF_CITY &&
                stName != TeamStatusName.ST_DEF_BATTLE_END) {
                this._team.genCharCom();
            }
            await super.changeStatus(stName, time, ...param);
            console.log(`Team ${this._team.teamID} Status change to `, stName);
        }
    }
}