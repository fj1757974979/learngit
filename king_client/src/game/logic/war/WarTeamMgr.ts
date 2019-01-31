module War {

    export class WarTeamMgr {
        private static _inst: WarTeamMgr;

        private _teamList: Collection.Dictionary<number, WarTeam>;
        private _myTeam: WarTeam = null;

        public static get inst(): WarTeamMgr {
            if (!WarTeamMgr._inst) {
                WarTeamMgr._inst = new WarTeamMgr();
            }
            return WarTeamMgr._inst;
        }

        public constructor() {
            this._teamList = new Collection.Dictionary<number, WarTeam>();
            this._myTeam = null;
        }

        public setMyTeam(team: WarTeam) {
            if (this._myTeam) {
                this._myTeam.onDestroy();
            }
            this._myTeam = team;
            console.log("setMyTeam ", this._myTeam.teamID);
            WarMgr.inst.warView.setCloseBtn(false);
        }

        public newMyTeam(teamData: pb.TeamData) {
            let myTeam = new WarTeam(teamData, false);
            this.setMyTeam(myTeam);
            myTeam.changeStatus(teamData.State);
        }

        public addOtherTeam(team: WarTeam) {
            if (team.isMyTeam()) {
                return;
            }
            console.log("addOtherTeam ", team.teamID);
            this._teamList.setValue(team.teamID, team);
        }

        public delOtherTeam(teamId: number) {
            let team = this._teamList.getValue(teamId);
            if (team) {
                console.log("delOtherTeam ", teamId);
                team.onDestroy();
                this._teamList.remove(teamId);
            }
        }

        public getOtherTeam(teamId: number) {
            return this._teamList.getValue(teamId);
        }

        public get myTeam() {
            return this._myTeam;
        }

        public cleanMyTeam() {
            if (this._myTeam) {
                this._myTeam.onDestroy();
                this._myTeam = null;
                console.log("cleanMyTeam");
            }
            WarMgr.inst.warView.setCloseBtn(true);
        }

        public get otherTeam() {
            return this._teamList;
        }

        public get allOtherTeams(): Array<WarTeam> {
            return this._teamList.values();
        }

        public onDestroy() {
            if (this._myTeam) {
                this._myTeam.onDestroy();
                this._myTeam = null;
            }
            this._teamList.forEach((teamId, team) => {
                team.onDestroy();
            });
            this._teamList.clear();
        }
    }
}