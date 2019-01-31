// TypeScript file
module War {
    // export enum BattleStatusName {
    //     ST_NORMAL = 0,   // 
    //     ST_PREPARE = 1,  // 战前
    //     ST_DURING = 2,  // 战中
    //     ST_END = 3,    // 战后
    //     ST_UNIFIED = 4, // 统一
    // }

    export class BattleStatusBase extends WarStatusBase {
        protected _battle: WarMgr;

        public constructor(host: any) {
            super(host);
            this._battle = <WarMgr>host;
        }

        public get host(): WarMgr {
            return this._battle;
        }
    }

    export class BattleNormal extends BattleStatusBase {
        public get name(): number {
            return BattleStatusName.ST_NORMAL;
        }
        public async enter(...param: any[]) {
            this.startHeartbeat();
            if (WarMgr.inst.warView) {
                WarMgr.inst.warView.updateFightAndQuest();
            }
            if (WarMgr.inst.warView && WarMgr.inst.warView.warTipPanel) {
                let tipPanel = WarMgr.inst.warView.warTipPanel;
                tipPanel.showTipNormal();
                WarMgr.inst.warView.setCloseBtn(true);
            }
        }
        protected heartbeat() {
            if (this.remainTime > 0) {
                this.remainTime -= 1;
                if (this.remainTime < 0) {
                    this.remainTime = 0;
                }
            }
        }
        public async leave() {
            this.stopHeartbeat();
            if (WarMgr.inst.warView && WarMgr.inst.warView.warTipPanel) {
                let tipPanel = WarMgr.inst.warView.warTipPanel;
                tipPanel.closeTip();
            }
        }
    }

    export class BattlePrepare extends BattleStatusBase {
        public get name(): number {
            return BattleStatusName.ST_PREPARE;
        }
        public async enter(...param: any[]) {
            this.startHeartbeat();
            if (WarMgr.inst.warView) {
                WarMgr.inst.warView.updateFightAndQuest();
            }
            if (WarMgr.inst.warView && WarMgr.inst.warView.warTipPanel) {
                let tipPanel = WarMgr.inst.warView.warTipPanel;
                tipPanel.showTipPrePare();
            }
            
        }
        public async leave() {
            this.stopHeartbeat();
            if (WarMgr.inst.warView && WarMgr.inst.warView.warTipPanel) {
                let tipPanel = WarMgr.inst.warView.warTipPanel;
                tipPanel.closeTip();
            }
        }
        protected heartbeat() {
            if (this.remainTime > 0) {
                this.remainTime -= 1;
                if (this.remainTime < 0) {
                    this.remainTime = 0;
                }
            }
        }
    }

    export class BattleDuring extends BattleStatusBase {
        public get name(): number {
            return BattleStatusName.ST_DURING;
        }

        public async enter(...param: any[]) {
            this.startHeartbeat();
            if (WarMgr.inst.warView) {
                WarMgr.inst.warView.updateFightAndQuest();
            }
            if (WarMgr.inst.warView && WarMgr.inst.warView.warTipPanel) {
                let tipPanel = WarMgr.inst.warView.warTipPanel;
                tipPanel.showTipInWar();
            }
            // 设置所有城池组件为国战模式
            let allCities = CityMgr.inst.getAllCities();
            allCities.forEach(city => {
                if (city.cityCom) {
                    city.cityCom.setCityInWarMode(true);
                }
            });
        }

        public async leave() {
            this.stopHeartbeat();
            // 设置所有城池组件为正常模式
            let allCities = CityMgr.inst.getAllCities();
            allCities.forEach(city => {
                if (city.cityCom) {
                    city.cityCom.setCityInWarMode(false);
                }
                city.changeStatus(CityStatusName.ST_NORMAL);
            });
            if (WarMgr.inst.warView && WarMgr.inst.warView.warTipPanel) {
                let tipPanel = WarMgr.inst.warView.warTipPanel;
                tipPanel.closeTip();
            }
        }
        protected heartbeat() {
            if (this.remainTime > 0) {
                this.remainTime -= 1;
                if (this.remainTime < 0) {
                    this.remainTime = 0;
                }
            }
        }
    }

    export class BattleEnd extends BattleStatusBase {
        public get name(): number {
            return BattleStatusName.ST_END;
        }

        public async enter(...param: any[]) {
            let data = <pb.CaStateWarEndArg>param[0];
            this.startHeartbeat();
            await Core.ViewManager.inst.open(ViewName.battleEndView, data, () => {
                this._battle.changeStatus(BattleStatusName.ST_NORMAL);
            });
            if (WarMgr.inst.warView) {
                WarMgr.inst.warView.updateFightAndQuest();
            }
            if (WarMgr.inst.warView && WarMgr.inst.warView.warTipPanel) {
                let warTipPanel = WarMgr.inst.warView.warTipPanel;
                warTipPanel.showTipNormal();
                WarMgr.inst.warView.setCloseBtn(true);
            }
            WarTeamMgr.inst.onDestroy();
        }

        protected heartbeat() {
            if (this.remainTime > 0) {
                this.remainTime -= 1;
                if (this.remainTime < 0) {
                    this.remainTime = 0;
                }
            }
        }

        public async leave() {
            this.stopHeartbeat();
            if (WarMgr.inst.warView && WarMgr.inst.warView.warTipPanel) {
                let warTipPanel = WarMgr.inst.warView.warTipPanel;
                warTipPanel.closeTip();
            }
        }
    }

    export class BattleUnified extends BattleStatusBase {
        public get name(): number {
            return BattleStatusName.ST_UNIFIED;
        }
        public get isWarOver(): boolean {
            return true;
        }
        public async enter(...param: any[]) {
            let data = <pb.CaStateUnifiedArg>param[0];
            await Core.ViewManager.inst.open(ViewName.battleUnifiedView, data);
        }
    }

    export class BattleStatusDelegate extends WarStatusDelegateBase {
        protected _battle: WarMgr;

        public setDelegateHost(host: any) {
            this._battle = <WarMgr>host;    
            super.setDelegateHost(host);
        }

        protected initStatus() {
            this._statusObjs.setValue(BattleStatusName.ST_NORMAL, new BattleNormal(this._battle));
            this._statusObjs.setValue(BattleStatusName.ST_PREPARE, new BattlePrepare(this._battle));
            this._statusObjs.setValue(BattleStatusName.ST_DURING, new BattleDuring(this._battle));
            this._statusObjs.setValue(BattleStatusName.ST_END, new BattleEnd(this._battle));
            this._statusObjs.setValue(BattleStatusName.ST_UNIFIED, new BattleUnified(this._battle));
        }

        public async changeStatus(stName: number, time: number = -1, ...param: any[]) {
            if (this._curStatusObj.name == BattleStatusName.ST_PREPARE && stName == BattleStatusName.ST_DURING) {
                // Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format("国战开始"));
                let com = fairygui.UIPackage.createObject(PkgName.war, "warBegin").asCom;
                com.y = fairygui.GRoot.inst.getDesignStageHeight() / 2;
                Core.EffectUtil.showLeftToRight(com);
            }
            super.changeStatus(stName, time, ...param);
            console.log(`Battle Status change to `, stName, time);
        }

        public get isWarOver(): boolean {
            return this._curStatusObj.isWarOver;
        }
    }
}