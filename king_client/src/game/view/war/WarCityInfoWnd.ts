module War {

    export class WarCityInfoWnd extends BaseCityInfoWnd {

        private _cityID: number;
        private _page: number;

        private _banFightBtn: fairygui.GButton;
        private _enterBtn: fairygui.GButton;
        

        public initUI() {
            super.initUI();
            this._banFightBtn = this.contentPane.getChild("banFightBtn").asButton;
            this._enterBtn = this.contentPane.getChild("enterBtn").asButton;

            // this._enterBtn.addClickListener(this._onEnterBtn, this);
        }
        public async open(...param: any[]) {
            super.open(...param);
            this._cityID = param[0];
            this._updateCanEnter();
            this._updateCanAttack();

            this._emptyHint.visible = (this._city.playerNum <= 0);
            this.refreshPlayers();
        }
        private _updateCanEnter() {
            if (MyWarPlayer.inst.isMyCountryCity(this._cityID)) {
                this._enterBtn.visible = !(MyWarPlayer.inst.locationCityID == this._cityID);
            } else {
                this._enterBtn.visible = false;
            }
        }
        private _updateCanAttack() {
            // let attackCmd = MyWarPlayer.inst.isMyAttackCity(this._cityID);
            // if (attackCmd != 0) {
            //     this._banFightBtn.visible = true;
            //     if (attackCmd == 1) {
            //         this._banFightBtn.title = "禁止攻击";
            //     } else {
            //         this._banFightBtn.title = "允许攻击";
            //     }
            // } else {
            //     this._banFightBtn.visible = false;
            // }
        }
        private async refreshPlayers() {
            this._playerList.removeChildrenToPool();
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
        //入驻
        // private async _onEnterBtn() {
        //     let args = {CityID: this._cityID};
        //     let result = await Net.rpcCall(pb.MessageID.C2S_SUPPORT_CITY, pb.TargetCity.encode(args));
        //     if (result.errcode == 0) {
        //         //
        //         this._city.playerNum += 1;
        //         this._enterBtn.visible = false;
        //         Core.TipsUtils.showTipsFromCenter(`已到达并支援${this._city.cityName}`);
        //     }
        // }
        //禁止攻打 需要新的协议
        private async _onbanFightBtn() {

        }
    }
}