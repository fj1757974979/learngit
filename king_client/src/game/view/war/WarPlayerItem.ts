module War {

    export class WarPlayerItem extends fairygui.GComponent {
        
        private _nameText: fairygui.GTextField;
        private _headCom: Social.HeadCom;
        private _jobText: fairygui.GRichTextField;
        private _info: CampaignPlayer;

        protected constructFromXML(xml: any): void {
            this._nameText = this.getChild("nameText").asTextField;
            this._nameText.textParser = Core.StringUtils.parseColorText;
            this._headCom = this.getChild("lordHead").asCom as Social.HeadCom;
            this._jobText = this.getChild("job").asRichTextField;
            this._jobText.textParser = Core.StringUtils.parseColorText;
            this._jobText.funcParser = Core.StringUtils.parseFuncText;
        }

        public setInfo(player: CampaignPlayer) {
            this._info = player;
            this._nameText.text = player.name;
            this._jobText.text = player.employee.doubleJobName(true);
            this._headCom.setAll(player.headImg, player.headFrame);
            this._headCom.addClickListener(this._onDetail, this);
        }

        private async _onDetail() {
            let playerInfo = await Social.FriendMgr.inst.fetchPlayerInfo(<Long>this._info.uID);
			if (playerInfo) {
			    Core.ViewManager.inst.open(ViewName.friendInfo, <Long>this._info.uID, playerInfo);
			}
		}
    }
}