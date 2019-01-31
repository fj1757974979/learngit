module Level {

	export class LevelHelpItemCom extends fairygui.GComponent {

		private _headCom: Social.HeadCom;
		private _nameText: fairygui.GTextField;
		private _titleText: fairygui.GTextField;
		private _vedioBtn: fairygui.GButton;

		private _stateCtrl: fairygui.Controller;

		private _data: pb.LevelHelpRecordItem;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._headCom = this.getChild("head").asCom as Social.HeadCom;
			this._nameText = this.getChild("nameText").asTextField;
			this._nameText.textParser = Core.StringUtils.parseColorText;
			this._titleText = this.getChild("title").asTextField;
			this._vedioBtn = this.getChild("vedioBtn").asButton;
			this._stateCtrl = this.getController("win");

			this._stateCtrl.setSelectedPage("notWin");

			this._vedioBtn.addClickListener(async () => {
				if (this._data) {
					let args = {VideoID: this._data.VideoID};
					let result = await Net.rpcCall(pb.MessageID.C2S_WATCH_HELP_VIDEO, pb.WatchHelpVideoArg.encode(args));
					if (result.errcode == 0) {
						let reply = pb.VideoBattleData.decode(result.payload);
						try {
							await Battle.VideoPlayer.inst.play(reply);
						} catch(e) {
							console.log(e);
						}
					}
				}
			}, this);
		}

		public setData(data: pb.LevelHelpRecordItem) {
			this._nameText.text = data.HelperName;
			if (data.HelperHeadFrame || data.HelperHeadFrame == "") {
				data.HelperHeadFrame = "1";
			}
			this._headCom.setAll(data.HelperHeadImgUrl, `headframe_${data.HelperHeadFrame}_png`);
			this._titleText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60076), data.HelpCnt);
			if (data.IsWin) {
				this._stateCtrl.setSelectedPage("win");
			} else {
				this._stateCtrl.setSelectedPage("notWin");
			}
			this._data = data;
		}
	}

	export class LevelHelpWnd extends Core.BaseWindow {

		private _closeBtn: fairygui.GButton;
		private _helpList: fairygui.GList;
		private _wechatBtn: fairygui.GButton;

		private _levelId: number;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
			this._helpList = this.contentPane.getChild("applyList").asList;
			this._wechatBtn = this.contentPane.getChild("wechatBtn").asButton;

			let self = this;
			this._closeBtn.addClickListener(() => {
				Core.ViewManager.inst.closeView(self);
			}, self);

			this._wechatBtn.addClickListener(this._onWechatHelp, this);
		}

		public async open(...param: any[]) {
			super.open(...param);
			this.contentPane.getChild("emptyHintText").visible = false;
			this._wechatBtn.visible = true;

			let levelId = param[0];
			let args = {LevelID: levelId};
			let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_LEVEL_HELP_RECORD, pb.TargetLevel.encode(args));

			if (result.errcode == 0) {
				let reply = pb.LevelHelpRecord.decode(result.payload);
				if (reply.Records.length > 0) {
					reply.Records.forEach(data => {
						let item = fairygui.UIPackage.createObject(PkgName.level, "appealItem").asCom as LevelHelpItemCom;
						item.setData(<pb.LevelHelpRecordItem>data);
						this._helpList.addChild(item);
						if((<pb.LevelHelpRecordItem>data).IsWin) {
							this._wechatBtn.visible = false;
						}
					})
				} else {
					this.contentPane.getChild("emptyHintText").visible = true;
				}
			}

			this._levelId = levelId;
		}

		private async _onWechatHelp() {
			if (Core.DeviceUtils.isWXGame()) {
				let imageUrl;
                let view = (<Level.LevelView>Core.ViewManager.inst.getView(ViewName.level));
				let levelData = Data.level.get(this._levelId);
				let cpt = LevelMgr.inst.getChapter(levelData.chapter[0]);
				console.log(cpt.id)
				let chapterItem = view.getChild("chapterList").asList.getChildAt(cpt.id - 1);
				let renderTexture:egret.RenderTexture = new egret.RenderTexture();
				let texture = new egret.Texture();
				setTimeout(()=>{
					renderTexture.drawToTexture(chapterItem.displayObject,new egret.Rectangle(0,0,763,610));
					texture._setBitmapData(renderTexture.$bitmapData);
					imageUrl = texture.saveToFile("image/png", WXGame.WXFileSystem.inst.fsRoot + "levelView.png");
				},500)
				setTimeout(()=>{
					WXGame.WXShareMgr.inst.wechatShareLevelHelp(this._levelId,imageUrl);
				}, 500);
			}
		}

		public async close(...param: any[]) {
			super.close(...param);

			this._helpList.removeChildren();
		}
	}
}
