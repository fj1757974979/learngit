module War {
    
    export class CityManageWnd extends Core.BaseWindow {

        private _city: City;

        private _closeBtn: fairygui.GButton;
        private _buildBtn: fairygui.GButton;
        private _fightBtn: fairygui.GButton;

        private _buildCom: CityBuildCom;
        private _fightCom: CityManageFightCom;

        private _viewCtr: fairygui.Controller;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;
            
            this._viewCtr = this.contentPane.getController("page");

            this._buildCom = this.contentPane.getChild("n21").asCom as CityBuildCom;
            this._fightCom = this.contentPane.getChild("n26").asCom as CityManageFightCom;

            this._buildBtn = this.contentPane.getChild("buildChk").asButton;
            this._fightBtn = this.contentPane.getChild("fightChk").asButton;
            this._closeBtn =  this.contentPane.getChild("closeBtn").asButton;          
            this._closeBtn.addClickListener(this._onClose, this);
            this._buildBtn.addClickListener(this._onBuildBtn, this);
            this._fightBtn.addClickListener(this._onFightBtn, this);
        }

        private async _onClose() {
            Core.ViewManager.inst.closeView(this);
        }
        private async _onBuildBtn() {
             if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING) || WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                 Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70250)));
                 this._buildBtn.getController("button").selectedIndex = 0;
                 return;
             }
            let args = {CityID: this._city.cityID};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_CAMPAIGN_MISSION_INFO, pb.TargetCity.encode(args));
            if (result.errcode == 0) {
                let reply = pb.CampaignMissionInfo.decode(result.payload);
                this._viewCtr.selectedIndex = 0;
                this._fightBtn.getController("button").selectedIndex = 0;
                this.refreshMission(reply);
            }
        }
        private async _onFightBtn() {
             if (!WarMgr.inst.inStatus(BattleStatusName.ST_DURING) && !WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                 Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70250)));
                 this._fightBtn.getController("button").selectedIndex = 0;
                 return;
             }
            let ok = WarMgr.inst.fetchMilitaryOrders(this._city);
            if (ok) {
                this._buildBtn.getController("button").selectedIndex = 0;
                this._viewCtr.selectedIndex = 1;
            }
        }
        
        public async open(...param: any[]) {
            super.open(...param);
            this._city = CityMgr.inst.getCity(param[0]);
            this.refreshWnd();
            this._fightCom.openFightWnd(this._city);
            this._fightCom.watch();
            if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING) || WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                this._onFightBtn();
            } else {
                this._onBuildBtn();
            }
        }
        public refreshWnd() {

        }

        public async refreshMission(missions: pb.ICampaignMissionInfo) {
            this._buildCom.refreshMission(missions, this._city);
        }
        public async close(...param: any[]) {
            super.close(...param);
            this._fightCom.unWatch();
        }
    }
}