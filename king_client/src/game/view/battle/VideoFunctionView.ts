module Battle {

    export class VideoFunctionView extends Core.BaseView {
        private _playBtn: fairygui.GButton;
        private _likeBtn: fairygui.GButton;
        private _discussBtn: fairygui.GButton;
        private shareWechatBtn: fairygui.GButton;
        private _likeBtnmsk: fairygui.GObject;

        private _video: Pvp.Video;
        private _videoItem: Pvp.VideoItemCom;

        public initUI() {
            super.initUI();
            this.center();

            this._playBtn = this.getChild("viewBtn").asButton;
            this._likeBtn = this.getChild("likeBtn").asButton;
            this._discussBtn = this.getChild("discussBtn").asButton;
            this.shareWechatBtn = this.getChild("shareWechatBtn").asButton;
            this._likeBtnmsk = this._likeBtn.getChild("icon2");
            this._likeBtnmsk.visible = false;

            this._playBtn.addClickListener(this._onPlay, this);
            this._playBtn.visible = false;
            this._likeBtn.addClickListener(this._onLikeVideo, this);
            this._discussBtn.addClickListener(this._onDiscuss, this);
            this.shareWechatBtn.addClickListener(this._onShareWX, this);
            //Core.LayerManager.inst.topLayer.addChild(this);
            // Core.EventCenter.inst.addEventListener(GameEvent.VideoDataToBattle, this._setView, this);
        }

        private async _onPlay() {
            VideoPlayer.inst.playBattle();
            this._playBtn.visible = false;
            this.getChild("title").visible = false;
            this.getChild("top").visible = false;
        }

        public updatedisNum() {
            this._discussBtn.title = this._video.commentsAmount.toString();
            if (this._videoItem) {
                this._videoItem.updatedisNum();
            }
        } 

        private async _setView() {
            this._video = Pvp.VideoCenter.inst.curVideo;
            this._videoItem = Pvp.VideoCenter.inst.curVideoCom;

            console.log("video function set view");
            this._likeBtn.visible = this._video.isShare;
            this._discussBtn.visible = this._video.isShare;
            this.shareWechatBtn.visible = false;

            this.getChild("functionBg").visible = this._video.isShare;

            if (this._video.isShare) {
                this._likeBtn.text = this._video.likeTimes.toString();
                this._discussBtn.text = this._video.commentsAmount.toString();
                this.getChild("title").text = this._video.title;
                if(this._video.isLike) {
                    this._likeBtn.getController("isLike").selectedIndex = 1;
                } else {
                    this._likeBtn.getController("isLike").selectedIndex = 0;
                }
                if(Core.DeviceUtils.isWXGame()) {
                    this.shareWechatBtn.visible = true;
                }
            }
        }

        private async _onDiscuss() {
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
                this._likeBtn.text = this._video.likeTimes.toString();
                this._likeBtn.getController("isLike").selectedIndex = 1;
				this._likeBtnmsk.visible = true;
				this._likeBtn.getTransition("t0").play();
                if (this._videoItem) {
				    this._videoItem.updateView();   
                } 
			}
		}

        private async _onShareWX() {
            if (this._video && Core.DeviceUtils.isWXGame()) {
                let videoTitle = "";
				if(this._video.title)
				{
					videoTitle = this._video.title;
				}else{
					videoTitle = Core.StringUtils.TEXT(70217);
				}
				WXGame.WXShareMgr.inst.wechatShareBattleVideo(this._video.id,videoTitle,null);
			}
        }

        public async open(...param:any[]) {
            super.open(...param);
            this._setView();
            if (this._video) {
                this.visible = true;
            } else {
                this.visible = false;
            }
            let _battle = param[0] as Battle;
            //Core.LayerManager.inst.topLayer.addChild(this);
            /*
            this._likeBtn.visible = _battle.isPvp();
            this._discussBtn.visible = _battle.isPvp();
            this.shareWechatBtn.visible = false;
            */
            this.toTopLayer();
            //console.log(`video function view to top layer, ispvp = ${_battle.isPvp()}`);
            //this.getChild("functionBg").visible = _battle.isPvp();
            
            let techTimer = new egret.Timer(1000,1);
            techTimer.addEventListener(egret.TimerEvent.TIMER_COMPLETE,() => {
                this.getChild("title").visible = false;
                this.getChild("top").visible = false;
            },this);
            techTimer.start();
        }

        public async close(...param:any[]) {
            // Core.LayerManager.inst.mainLayer.addChild(this);
            super.close(...param);
        }
    }
}