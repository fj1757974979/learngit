module Pvp {
	export class WXGameFriendRankView extends Core.BaseWindow {

		private _titleImg: fairygui.GLoader;
		private _closeBtn: fairygui.GButton;
		private _list: fairygui.GList;
		private _pageUpBtn: fairygui.GButton;
		private _pageDownBtn: fairygui.GButton;
		private _inviteBtn: fairygui.GButton;
		private _groupRankBtn: fairygui.GButton;
		private _rankBitmapImage: fairygui.GImage;
		private _rankBitmap: egret.Bitmap;

		public initUI() {
            super.initUI();
			this.center();
			this.modal = true;

			this._titleImg = this.contentPane.getChild("titleImg").asLoader;
			this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
			this._list = this.contentPane.getChild("wechatList").asList;
			this._pageUpBtn = this.contentPane.getChild("rightBtn").asButton;
			this._pageDownBtn = this.contentPane.getChild("leftBtn").asButton;
			this._inviteBtn = this.contentPane.getChild("inviteBtn").asButton;
			this._groupRankBtn = this.contentPane.getChild("groupRankBtn").asButton;

			this._closeBtn.addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			}, this);

			this._pageUpBtn.addClickListener(() => {
				wx.getOpenDataContext().postMessage({
					cmd:"pageUp",
				});
			}, this);

			this._pageDownBtn.addClickListener(() => {
				wx.getOpenDataContext().postMessage({
					cmd:"pageDown",
				});
			}, this);

			this._inviteBtn.addClickListener(() => {
				WXGame.WXShareMgr.inst.wechatInvite();
			}, this);

			this._groupRankBtn.addClickListener(() => {
				WXGame.WXShareMgr.inst.wechatGrpRank();
			}, this);
		}

		public async open(...param: any[]) {
			super.open(...param);
			let openParam: string = param[0];
			try {
				let userInfo = await platform.getUserInfo();
				if (openParam == "friends") {
					this._titleImg.url = `pvp_wechatTitle_png`;
					wx.getOpenDataContext().postMessage({
						cmd:"display",
						type:openParam,
						show: true,
						openId: userInfo.channel_userid
					});
				} else if (openParam == "group") {
					this._titleImg.url = `pvp_wechatGroupTitle_png`;
					let shareTicket: string = param[1];
					wx.getOpenDataContext().postMessage({
						cmd:"display",
						type:openParam,
						show:true,
						shareTicket: shareTicket,
						openId: userInfo.channel_userid
					});
				}
				
				if (!this._rankBitmap) {
					let w = this._list.width;
					let sysData = wx.getSystemInfoSync();
					let ww = sysData.windowWidth;
					let wh = sysData.windowHeight;
					let h = wh / ww * w;
					this._rankBitmap = WXGame.WXGameMgr.getOpenDataContextBitmap(w, h);
				}
                
				let texture = new egret.Texture();
				texture._setBitmapData(this._rankBitmap.$bitmapData);
				
				let image = new fairygui.GImage();
				image.texture = texture;
				image.x = this._list.x;
				image.y = this._list.y;
				image.width = this._rankBitmap.width;
				image.height = this._rankBitmap.height;
				this._rankBitmapImage = image;
				this.addChild(this._rankBitmapImage);
				this._rankBitmapImage.blendMode = egret.BlendMode.NORMAL;
			} catch (e) {
				console.log(e);
			}
			
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._rankBitmapImage.parent && this._rankBitmapImage.parent.removeChild(this._rankBitmapImage);
			wx.getOpenDataContext().postMessage({
				cmd:"display",
				show: false,
			});
		}
	}
}
