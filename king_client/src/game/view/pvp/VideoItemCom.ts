module Pvp {

	export class VideoItemCom extends fairygui.GComponent {

		protected _videoId: fairygui.GTextField;
		protected _hostNameText: fairygui.GTextField;
		protected _guestNameText: fairygui.GTextField;
		protected _hostResultText: fairygui.GLoader;
		protected _guestResultText: fairygui.GLoader;
		protected _watchTimeText: fairygui.GTextField;
		protected _timeText: fairygui.GTextField;
		protected _playBtn: fairygui.GButton;
		// protected _hostInfo: fairygui.GLoader;
		// protected _guestInfo: fairygui.GLoader;
		protected _video: Pvp.Video;
		protected _hostCardComs: Array<VideoCardCom>;
		protected _guestCardComs: Array<VideoCardCom>;
		protected _shareWechatBtn: fairygui.GButton;
		protected _discussBtn: fairygui.GButton;
		protected _titleText: fairygui.GTextField;
		protected _likeBtn: fairygui.GButton;
		protected _likeBtnmsk: fairygui.GObject;

		protected _hostWnd: VideoHallWnd | VideoRecordWnd;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._videoId = this.getChild("id").asTextField;
			this._hostNameText = this.getChild("name1").asTextField;
			this._guestNameText = this.getChild("name2").asTextField;
			this._hostNameText.textParser = Core.StringUtils.parseColorText;
			this._guestNameText.textParser = Core.StringUtils.parseColorText;
			this._hostResultText = this.getChild("resultTxt1").asLoader;
			this._guestResultText = this.getChild("resultTxt2").asLoader;
			this._watchTimeText = this.getChild("viewNum").asTextField;
			this._timeText = this.getChild("time").asTextField;
			this._playBtn = this.getChild("viewBtn").asButton;
			// this._hostInfo = this.getChild("hostInfo").asLoader;
			// this._guestInfo = this.getChild("guestInfo").asLoader;
			this._shareWechatBtn = this.getChild("shareWechatBtn").asButton;
			this._discussBtn = this.getChild("discussBtn").asButton;
			this._likeBtn = this.getChild("likeBtn").asButton;
			this._titleText = this.getChild("titleTxt").asTextField;
			this._likeBtnmsk = this._likeBtn.getChild("n9");
			
			// if (Core.DeviceUtils.isWXGame()) {
			// 	this._shareWechatBtn.visible = true;
			// } else {
			// 	this._shareWechatBtn.visible = false;
			// }


			this._hostCardComs = [];
			this._guestCardComs = [];

			this._likeBtnmsk.visible = false;

			// this._hostInfo.addClickListener(this._onHostDetail, this);
			// this._guestInfo.addClickListener(this._onGuestDetail,this);
			this._discussBtn.addClickListener(this._onDiscuss, this);
			this._likeBtn.addClickListener(this._onLikeVideo, this);



			for (let i = 1; i <= 5; ++ i) {
				let com = this.getChild(`card${i}`).asCom as VideoCardCom;
				this._hostCardComs.push(com);
			}
			for (let i = 6; i <= 10; ++ i) {
				let com = this.getChild(`card${i}`).asCom as VideoCardCom;
				this._guestCardComs.push(com);
			}

			this._video = null;

			this._playBtn.addClickListener(this._onPlayVideo, this);

			this._shareWechatBtn.addClickListener(() => {
				if (this._video) {
					// console.log("++++ ", fairygui.GRoot.contentScaleFactor);
					let point = this._shareWechatBtn.localToGlobal(0, 0);
					let x = point.x / fairygui.GRoot.contentScaleFactor + 30;
					let y = point.y / fairygui.GRoot.contentScaleFactor - 30;
					Core.ViewManager.inst.openPopup(ViewName.videoShareOption, this._video, x, y);
				}
				// if (this._video && Core.DeviceUtils.isWXGame()) {
				// 	WXGame.WXShareMgr.inst.wechatShareBattleVideo(this._video.id);
				// }
			}, this);

			this._shareWechatBtn.visible = Home.FunctionMgr.inst.isVideoToChatOpen();
		}

		public updatedisNum() {
			this._discussBtn.title = this._video.commentsAmount.toString();
		}

		public setVideo(video: Video, host: VideoHallWnd | VideoRecordWnd) {
			this._hostWnd = host;
			this.displayObject.cacheAsBitmap = false;
			this._video = video;
			this._videoId.text = `${video.id}`;
			let hostCards = video.hostFighter.cards;
			let hostWin = false;
			if (this._video.winner == this._video.hostFighter.uid) {
				this._hostResultText.url = "cards_base1_s_png";
				this._guestResultText.url = "cards_base2_s_png";
				hostWin = true;
			} else {
				this._hostResultText.url = "cards_base2_s_png";
				this._guestResultText.url = "cards_base1_s_png";
				hostWin = false;
			}
			for (let i = 0; i < hostCards.length; ++ i) {
				let card = hostCards[i];
				if (this._hostCardComs[i]) {
					this._hostCardComs[i].setCardId(card, hostWin);
					
				}
			}
			let guestCards = video.guestFighter.cards;
			for (let i = 0; i < guestCards.length; ++ i) {
				let card = guestCards[i];
				if (this._guestCardComs[i]) {
					this._guestCardComs[i].setCardId(card, !hostWin);
				}
			}
			
			this._updateVideoInfo();
		}

		protected _updateVideoInfo() {
			if (this._hostWnd != null) {
				this._hostWnd.beginRefreshItem();
			}
			this.displayObject.cacheAsBitmap = false;
			this._setName(this._hostNameText , this._video.hostFighter.name);
			this._setName(this._guestNameText , this._video.guestFighter.name);
			// this._hostNameText.text = this._video.hostFighter.name;
			// this._guestNameText.text = this._video.guestFighter.name;
			this._watchTimeText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60050), this._video.watchTimes);
			this._timeText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60051), Core.StringUtils.secToString(Math.floor(Date.now()/1000 - this._video.timeStamp), "dhm"));
			if(this._video.isShare) {
				this._discussBtn.title = this._video.commentsAmount.toString();
				this._likeBtn.title = this._video.likeTimes.toString();
				this._titleText.text = this._video.title;
			} else {
				this._titleText.text = Core.StringUtils.TEXT(60067);
				this._discussBtn.title = "0";
				this._likeBtn.title = "0";
			}
			if(this._video.isLike) {
				this._likeBtn.getController("isLike").selectedIndex = 1;
			} else {
				this._likeBtn.getController("isLike").selectedIndex = 0;
			}
			this._likeBtn.getChild("n9").visible = this._video.isLike;
			
			this.displayObject.cacheAsBitmap = true;

			if(this._hostWnd != null)
			{
				this._hostWnd.endRefreshItem();
			}
		}

		private async _onPlayVideo() {
			if (this._video) {
				if (await VideoCenter.inst.playVideo(this._video, this)) {
					this._updateVideoInfo();
				}
			}
		}

		private async _onDiscuss() {
			VideoCenter.inst.setCurVideo(this._video, this);
			let args = {VideoID: this._video.id,CurAmount:0};
			let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_VIDEO_COMMENTS, pb.FetchVideoCommentsArg.encode(args));
			if (result.errcode == 0) {
				let comments = pb.FetchVideoCommentsReply.decode(result.payload);
				Core.ViewManager.inst.open(ViewName.videoDiscuss, comments);
			}
		}

		private async _onLikeVideo() {
			if (this._video.isLike) {
				// Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60140));
				return;
			}
			let args = {VideoID: this._video.id};
			let result = await Net.rpcCall(pb.MessageID.C2S_LIKE_VIDEO, pb.LikeVideoArg.encode(args));
			if (result.errcode == 0) {
				let reply = pb.LikeVideoResp.decode(result.payload);
				this._video.watchTimes = reply.CurWatchTimes;
				this._video.likeTimes = reply.CurLike;
				this._video.isLike = true;
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60110));
				this._likeBtnmsk.visible = true;
				this._likeBtn.getTransition("t0").play();
				this._updateVideoInfo();    
			}
		}

		private async _setName(nameCom: fairygui.GTextField, nametxt: string) {
			nameCom.text = nametxt;
			if (nametxt != this._video.sharePlayerName) {
				nameCom.stroke = 1;

			} else {
				nameCom.stroke = 2;
			}

		}

		//@ overwrite
		public dispose(): void {
			this._video = null;
			this._hostWnd = null;
			super.dispose();
		}

		public updateView() {
			this._updateVideoInfo();
		}
	}
	
	export class VideoRecordItemCom extends VideoItemCom {

		private _shareBtn: fairygui.GButton;
		// private _discussBtn: fairygui.GButton;
		// private _likeBtn: fairygui.GButton;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			this._shareBtn = this.getChild("shareBtn").asButton;
			// this._shareWechatBtn.visible = false;
			this._shareBtn.addClickListener(this._onShareVideo, this);

		}

		private async _onShareVideo() {
			if (this._video.isShare) {
				// Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60139));
				return;
			}
			Core.ViewManager.inst.open(ViewName.videoUpload,this._video,this);
		}

		public shareOK(title: string) {
			this._video.isShare = true;
			Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60199));
			this._video.title = title;
			this._updateVideoInfo();
		}

		protected _updateVideoInfo() {
			super._updateVideoInfo();
			if(this._hostWnd != null)
			{
				this._hostWnd.beginRefreshItem();
			}
			this.displayObject.cacheAsBitmap = false;
			if (this._video.isShare) {
				this._shareBtn.title = Core.StringUtils.TEXT(60049);
				this._shareBtn.getController("button").setSelectedPage("down");
				this.getController("share").selectedIndex = 1;
			} else {
				this._shareBtn.title = Core.StringUtils.TEXT(60017);
				this.getController("share").selectedIndex = 0;
			}
			this.displayObject.cacheAsBitmap = true;
			if(this._hostWnd != null)
			{
				this._hostWnd.endRefreshItem();
			}
		}

	}

	export class VideoHallItemCom extends VideoItemCom {

		// private _likeBtn: fairygui.GButton;
		// private _likeMarkImg: fairygui.GLoader;
		// private _trans0: fairygui.Transition;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			this._likeBtn = this.getChild("likeBtn").asButton;
			// this._likeBtn.addClickListener(this._onLikeVideo, this);
			// this._likeMarkImg = this.getChild("likeMarkImg").asLoader;
			// this._trans0 = this.getTransition("t0");
		}
		/*
		private async _onLikeVideo() {
			if (this._video.isLike) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60140));
				return;
			}
			let args = {VideoID: this._video.id};
			let result = await Net.rpcCall(pb.MessageID.C2S_LIKE_VIDEO, pb.LikeVideoArg.encode(args));
			if (result.errcode == 0) {
				let reply = pb.LikeVideoResp.decode(result.payload);
				this._video.watchTimes = reply.CurWatchTimes;
				this._video.likeTimes = reply.CurLike;
				this._video.isLike = true;
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60110));
				this._updateVideoInfo();
				await this._trans0.play();
			}
		}
		*/
		/*
		protected _updateVideoInfo() {
			super._updateVideoInfo();
			this._hostWnd.beginRefreshItem();
			this._likeBtn.title = `${this._video.likeTimes}`;
			if (this._video.isLike) {
				// this._likeMarkImg.url = `pvp_likeIcon2_png`;
			} else {
				// this._likeMarkImg.url = `pvp_likeIcon1_png`;
			}
			this._hostResultText.visible = this._video.hasWatch;
			this._guestResultText.visible = this._video.hasWatch;
			if (this._video.hasWatch) {
				this.getController("view").setSelectedIndex(1);
			} else {
				this.getController("view").setSelectedIndex(0);
			}
			this._hostWnd.endRefreshItem();
		}
		*/
	}

	export class VideoShareItemCom extends VideoItemCom {

		private _shareBtn: fairygui.GButton;
		private _bgImg1: fairygui.GLoader;
		private _bgImg2: fairygui.GLoader;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			this._bgImg1 = this.getChild("bg1").asLoader;
			this._bgImg2 = this.getChild("bg2").asLoader;
			this._shareWechatBtn.visible = false;
			this._likeBtn.visible = false;
			this._discussBtn.visible = false;
			this.scaleX = 0.78;
			this.scaleY = 0.78;
			this._hostNameText.y = this._hostNameText.y - 7;
			this._guestNameText.y = this._guestNameText.y - 7;
			this._bgImg1.scaleY = 0.82;
			this._bgImg1.setXY(0,20);
			this._bgImg2.visible = false;
			this._titleText.visible = false;
			this._timeText.setXY(180,210);
		}
	}
}