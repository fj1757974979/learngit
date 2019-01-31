module Home {

	export class CmdWnd extends Core.BaseWindow {
		private _cmdText: fairygui.GTextField;
		private _soundVolumeBtn: fairygui.GButton;
		private _musicVolumeBtn: fairygui.GButton;
		private _codeText: fairygui.GTextField;
		private _errorText: fairygui.GTextField;
		private _languageBtn: fairygui.GButton;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;
			this._cmdText = this.getChild("cmdText").asTextField;
			this._soundVolumeBtn = this.getChild("soundVolumeBtn").asButton;
			this._musicVolumeBtn = this.getChild("musicVolumeBtn").asButton;
			this._codeText = this.getChild("codText").asTextField;
			this._errorText = this.getChild("warning").asTextField;
			this._languageBtn = this.getChild("languageBtn").asButton;
			this._languageBtn.title = LanguageMgr.inst.getLanguageDescription(LanguageMgr.inst.cur);

			this.getChild("closeBtn").asButton.addClickListener(this._onClose, this);
			this.getChild("confirmBtn").asButton.addClickListener(this._onConfirm, this);

			this._soundVolumeBtn.addClickListener(this._onSoundChange, this);
			this._musicVolumeBtn.addClickListener(this._onMusicChange, this);

			this.setSound(SoundMgr.inst.soundLevel);
			this.setMusic(SoundMgr.inst.musicLevel);

			//this.getChild("qqtext").asRichTextField.addEventListener(egret.TextEvent.LINK, this.onClickLink, this);

			if (Data.text.get(13145) && Data.text.get(13145)["cn"] == "版署版本") {
				this.getChild("qqtext").visible = false;
				this._cmdText.visible = false;
			}
			if (Core.DeviceUtils.isWXGame() || 
				(Core.DeviceUtils.isiOS() && !IOS_EXAMINE_VERSION) ||
				Core.DeviceUtils.isAndroid()) {
				this.getChild("cmdBg").visible = true;
				this._codeText.visible = true;
				this.getChild("qqtext").visible = true;
				this.setSize(400,430);
				this._cmdText.visible = false;
			}
			if (!window.gameGlobal.debug) {
				this._cmdText.visible = false;
			}

			if (Core.DeviceUtils.isWXGame() && WXGame.WXGameMgr.inst.isExamineVersion) {
				this._cmdText.visible = true;
			}

			if (Core.DeviceUtils.isiOS() && IOS_EXAMINE_VERSION) {
				this._cmdText.visible = true;
			}

			this._cmdText.visible = true;

			if (!window.gameGlobal.isMultiLan) {
				this._languageBtn.visible = false;
				if (Player.inst.isNewVersionPlayer()) {
					this.getChild("qqtext").asRichTextField.text = "欢迎加玩家交流QQ群\n1群：<font color=\"#0000ff\"><u>461744818</u></font>";
				}
			} else {
				this._languageBtn.visible = true;
				this._languageBtn.addClickListener(this._onSwitchLanguage, this);
				
				if (window.gameGlobal.channel == "lzd_handjoy" && !IOS_EXAMINE_VERSION) {
					this.getChild("qqtext").visible = true;
					this.getChild("qqtext").asRichTextField.text = Core.StringUtils.TEXT(70199);
					this.setSize(400, 460);
				} else {
					this.getChild("qqtext").visible = false;
					this.setSize(400, 300);
				}
			}

			this.pivotX = 0.5;
			this.pivotY = 0.5;
		}

		private onClickLink(event: egret.TextEvent) {
			console.debug(event.text);
		}
		private setSound(val: number) {
			val = Math.floor(val);
			for (let i = 0; i < 4; i++) {
				this._soundVolumeBtn.getChild("icon" + i).visible = false;
			}
			this._soundVolumeBtn.getChild("icon" + val).visible = true;
		}

		private setMusic(val: number) {
			val = Math.floor(val);
			for (let i = 0; i < 4; i++) {
				this._musicVolumeBtn.getChild("icon" + i).visible = false;
			}
			this._musicVolumeBtn.getChild("icon" + val).visible = true;
		}


		public async open(...param: any[]) {
			await super.open(...param);
			this._codeText.text = "";
			if (Core.DeviceUtils.isWXGame()) {
				let model = WXGame.WXGameMgr.inst.phoneModel;
				this.getChild("phoneModel").asTextField.text = Core.StringUtils.format("手机型号：{0}", model);
				this.height = 450;
			}
			await Core.PopUpUtils.addPopUp(this, 7);
		}

		public async close(...param: any[]) {
			// await Core.PopUpUtils.removePopUp(this, 7);
            await new Promise<void>(resolve => {
                egret.Tween.get(this).to({ scaleX: 0, scaleY: 0 }, 300, egret.Ease.backIn).call(function () {
                    resolve();
                }, this);
            })
			await super.close(...param);
		}

		private _onSoundChange() {
			var level = SoundMgr.inst.soundLevel + 1;
			if (level > 3) level = 0;
			SoundMgr.inst.soundLevel = level;
			this.setSound(level);
			SoundMgr.inst.playSoundAsync("click_mp3");
		}

		private _onMusicChange() {
			var level = SoundMgr.inst.musicLevel + 1;
			if (level > 3) level = 0;
			SoundMgr.inst.musicLevel = level;
			this.setMusic(level);
		}

		private _onSwitchLanguage() {
			Core.ViewManager.inst.open(ViewName.switchLanWnd);
		}

		private _onClose() {
			Core.ViewManager.inst.closeView(this);
		}

		private async _onConfirm() {
			if (this._codeText.text != "") {
				let errcode = await HomeMgr.inst.exchangeGiftCode(this._codeText.text);
				if (errcode == 0) {
					this._onClose();
				} else if (errcode == 2) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60168));
				} else if (errcode == 3) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60152));
				} else {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60098));
				}
				return;
			}

			if (this._cmdText.text == "") {
				this._onClose();
				return;
			} else if (this._cmdText.text == "addcard all"){
				let keys = Data.hero_say.keys;
				for (let i=0; i<keys.length; i++) {
					await HomeMgr.inst.doGmCommand(`addcard ${keys[i]} 330`);
				}
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60106));
			} else if (this._cmdText.text == "share app") {
				Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.SHARE_APP2WECHAT, {
					"title":Core.StringUtils.TEXT(60059),
					"description":Core.StringUtils.TEXT(60247),
					"url":"https://itunes.apple.com/cn/app/id1371944201?mt=8",
					"scene":0
				});
			} else {
				let ok = await HomeMgr.inst.doGmCommand(this._cmdText.text);
			}

		}
	}

}
