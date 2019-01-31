module Level {

    export class LevelVideoView extends Core.BaseWindow {
        private _title: fairygui.GTextField;
        private _playBtn: fairygui.GButton;
        private _fightBtn: fairygui.GButton;
        private _closeBtn: fairygui.GButton;

        private _levelObj: Level;
        private _videoID: number;

        public initUI() {
            super.initUI();

            this.center();
            this.modal = true;

            this._title = this.getChild("txt2").asTextField;
            this._playBtn = this.getChild("playBtn").asButton;
            this._fightBtn = this.getChild("fightBtn").asButton;
            this._closeBtn = this.getChild("closeBtn").asButton;

            this._playBtn.addClickListener(this._onPlay, this);
            this._fightBtn.addClickListener(this._onFight, this);
            this._closeBtn.addClickListener(this._onClose, this);
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._videoID = param[0];
            this._levelObj = param[1];

            this._title.text = Core.StringUtils.format(Core.StringUtils.TEXT(60108), this._videoID);
        }

        private async _onPlay() {
            if (this._videoID != 0) {
                let args = {VideoID: this._videoID};
				let result = await Net.rpcCall(pb.MessageID.C2S_WATCH_HELP_VIDEO, pb.WatchHelpVideoArg.encode(args));
				if (result.errcode == 0) {
					let reply = pb.VideoBattleData.decode(result.payload);
					try {
                        LevelMgr.inst.curVideoLevel = this._levelObj;
                        await Battle.VideoPlayer.inst.play(reply);
						// await Battle.VideoPlayer.inst.play(reply, this._levelObj.id);
                        
					} catch(e) {
						console.log(e);
					}
                }
            }
            this._onClose();
        }

        private async _onFight() {
            if(this._levelObj) {
                LevelMgr.inst.beginLevelBattle(this._levelObj);
            }
            this._onClose();
        }

        private async _onClose() {
            this._videoID = 0;
            Core.ViewManager.inst.closeView(this);
        }

        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}