module Level {

    export class LevelItem extends fairygui.GComponent {
        private _bgImg: fairygui.GLoader;
        private _levelNameTxt: fairygui.GTextField;
        private _left: fairygui.GLoader;
        private _right: fairygui.GLoader;
        private _helpBtn: fairygui.GButton;

        private _t0: fairygui.Transition;

        private _levelObj: Level;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._bgImg = this.getChild("levelBtn").asCom.getChild("bgImg").asLoader;
            this._levelNameTxt = this.getChild("levelBtn").asCom.getChild("levelNameTxt").asTextField;
            this._left = this.getChild("left").asLoader;
            this._right = this.getChild("right").asLoader;
            this._helpBtn = this.getChild("appealBtn").asButton;
            this._t0 = this.getTransition("t0");

            this.getChild("levelBtn").asButton.addClickListener(this._onLevel, this);

            if (Core.DeviceUtils.isWXGame()) {
                this._helpBtn.addClickListener(() => {
                    Core.ViewManager.inst.open(ViewName.levelHelpWnd, this._levelObj.id);
                }, this);
                this._helpBtn.visible = true;
            } else {
                this._helpBtn.visible = false;
            }

            if (window.gameGlobal.isMultiLan) {
                if (!LanguageMgr.inst.isChineseLocale()) {
                    this._levelNameTxt.fontSize = 20;
                }
            }

            if (!LanguageMgr.inst.isChineseLocale()) {
				this._levelNameTxt.x = 46;
                this._levelNameTxt.setSize(387, 41);
                this._levelNameTxt.fontSize = 20;
			}
        }

        public get levelObj() {
            return this._levelObj;
        }

        public setData(idx:number, levelObj:Level) {
            this._levelNameTxt.text = Core.StringUtils.format(Core.StringUtils.TEXT(60090), Core.StringUtils.getZhNumber(idx+1), levelObj.name);
            //this._levelNameTxt.displayObject.cacheAsBitmap = true;
            this._updateState(levelObj.state);
            this._levelObj = levelObj;
            this._helpBtn.visible = levelObj.help && Core.DeviceUtils.isWXGame();
        }

        private async _onLevel() {
            if (this._levelObj) {
                let pvpMaxScore = Player.inst.getResource(ResType.T_MAX_SCORE);
                let pvpLevel = Pvp.PvpMgr.inst.getPvpLevel(pvpMaxScore);
                if (pvpLevel < this.levelObj.unlockPvpLevel) {
                    let hint = Core.StringUtils.format(Core.StringUtils.TEXT(60231), Pvp.Config.inst.getPvpTitle(this.levelObj.unlockPvpLevel));
                    Core.TipsUtils.showTipsFromCenter(hint);
                    return;
                }
                if(this._levelObj.state == LevelState.Clear && Home.FunctionMgr.inst.isLevelVideoOpen()) {
                    let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_LEVEL_VIDEO_ID, pb.FetchLevelVideoIDArg.encode({LevelID: this._levelObj.id}));
                    if (result.errcode == 0) {
                        let reply = pb.FetchLevelVideoIDRely.decode(result.payload);
                        if (reply.VideoID) {
                            Core.ViewManager.inst.open(ViewName.levelVideo, reply.VideoID, this.levelObj);
                            return;
                        }
                    }
                }
                LevelMgr.inst.beginLevelBattle(this.levelObj);
            }
        }

        private _updateState(state:LevelState) {
            this.touchable = true;
            this._levelNameTxt.color = Core.TextColors.black;
            switch(state) {
            case LevelState.Lock:
                this._levelNameTxt.color = 0x575151;
                this.touchable = false;
                this._left.visible = false;
                this._right.visible = false;
                if (this._t0.playing) {
                    this._t0.stop();
                }
                break;
            case LevelState.UnLock:
                this._levelNameTxt.color = 0xffffff;
                this._bgImg.url = "level_levelItemBg3_png"
                this._left.visible = true;
                this._right.visible = true;
                this._t0.play(null, null, null, -1);
                break;
            case LevelState.Clear:
                this._levelNameTxt.color = 0xffffff;
                this._bgImg.url = "level_levelItemBg2_png"
                this._left.visible = false;
                this._right.visible = false;
                if (this._t0.playing) {
                    this._t0.stop();
                }
                break;
            default:
                break;
            }
        }
    }

}