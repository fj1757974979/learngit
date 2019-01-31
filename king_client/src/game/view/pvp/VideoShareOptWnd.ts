module Pvp {
	export class VideoShareOptWnd extends Core.BaseWindow {

		private _video: Pvp.Video;
		private _shareToFriendBtn: fairygui.GButton;
		private _shareToWorld: fairygui.GButton;
		private _shareToWeChat: fairygui.GButton;
		private _shareText: string;

		public initUI() {
			super.initUI();
			this._shareToFriendBtn = this.contentPane.getChild("privateChatBtn").asButton;
			this._shareToWorld = this.contentPane.getChild("worldChatBtn").asButton;
			this._shareToWeChat = this.contentPane.getChild("wechatBtn").asButton;

			this._shareToFriendBtn.addClickListener(this._onShareToFriend, this);
			this._shareToWorld.addClickListener(this._onShareToWorld, this);
			this._shareToWeChat.addClickListener(this._onShareToWeChat, this);

			if (!Core.DeviceUtils.isWXGame()) {
				this._shareToWeChat.visible = false;
				this._shareToWeChat.enabled = false;
				this.contentPane.getChild("bottom").asLoader.height = 133;
			}
		}

		private async _onShareToFriend() {
			Core.ViewManager.inst.open(ViewName.friendOptionList, async (friend?: Social.Friend) => {
				if (friend) {
					await Social.ChatMgr.inst.sendPrivateChat(friend.uid, friend.name, friend.headImgUrl, this._shareText);
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60256));
					Core.ViewManager.inst.close(ViewName.videoShareOption);
				}
			});
		}

		private async _onShareToWorld() {
			let success = await Social.ChatMgr.inst.sendChat(Social.ChatChannel.WORLD, this._shareText);
			if (success) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60256));
				Core.ViewManager.inst.close(ViewName.videoShareOption);
			}
		}

		private async _onShareToWeChat() {
			if (this._video && Core.DeviceUtils.isWXGame()) {
				let videoTitle = "";
				if(this._video.title)
				{
					videoTitle = this._video.title;
				}else{
					videoTitle = Core.StringUtils.TEXT(70217);
				}
				let imageUrl;
				let renderTexture:egret.RenderTexture = new egret.RenderTexture();
				let texture = new egret.Texture();
				let shareCom = fairygui.UIPackage.createObject(PkgName.pvp,"videoItem",Pvp.VideoShareItemCom).asCom as Pvp.VideoShareItemCom;
				shareCom.setVideo(this._video,null);
				setTimeout(()=>{
					renderTexture.drawToTexture(shareCom.displayObject);
					texture._setBitmapData(renderTexture.$bitmapData);
					imageUrl = texture.saveToFile("image/png", WXGame.WXFileSystem.inst.fsRoot + "battleVideo.png");
				},500)
				setTimeout(()=>{
					WXGame.WXShareMgr.inst.wechatShareBattleVideo(this._video.id,videoTitle,imageUrl);
				}, 500);
			}
			Core.ViewManager.inst.closeView(this);
		}

		public async open(...param: any[]) {
			await super.open(...param);
			this._video = param[0];
			this.x = param[1];
			this.y = param[2];
			if (this.y + this.height > fairygui.GRoot.inst.getDesignStageHeight()) {
				this.y = fairygui.GRoot.inst.getDesignStageHeight() - this.height;
			}
			// let title = "";
			// if (this._video.title) {
			// 	title = this._video.title;
			// }
			// this._shareText = Core.StringUtils.format(
			// 	Core.StringUtils.TEXT(60255),
			// 	title,
			// 	this._video.hostFighter.name,
			// 	this._video.guestFighter.name,
			// 	this._video.id
			// );
			let videoTitle = "";
			if(this._video.title)
			{
				videoTitle = this._video.title;
			}else{
				videoTitle = Core.StringUtils.TEXT(70217);
			}
			this._shareText = `${videoTitle}\n#fcom,${this._video.id}(100,175)#e`;
		}

		public async close(...param: any[]) {
			await super.close(...param);
		}
	}
}