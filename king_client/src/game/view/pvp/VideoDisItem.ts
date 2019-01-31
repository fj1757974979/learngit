module Pvp {
    export class VideoDisItem extends fairygui.GComponent {
        private _disObj: DiscussData;

        private _nameTxt: fairygui.GTextField;
        private _messageTxt: fairygui.GTextField;
        private _likeBtn: fairygui.GButton;
        private _timeTxt: fairygui.GTextField;
        private _headCom: Social.HeadCom;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);

          this._nameTxt = this.getChild("name").asTextField;
          this._nameTxt.textParser = Core.StringUtils.parseColorText;
          this._messageTxt = this.getChild("messageTxt").asTextField;
          this._likeBtn = this.getChild("likeBtn").asButton;
          this._timeTxt = this.getChild("time").asTextField;
          this._headCom = this.getChild("head").asCom as Social.HeadCom;

          this._likeBtn.addClickListener(this._onLikeBtn,this);
          this._headCom.addClickListener(this._onHead, this);
        }

        private async _onLikeBtn() {
            //判断是否已经点赞
            if(this._disObj.isLike) {
                // Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60140));
                return;
            } else {
                let args = {VideoID: this._disObj.videoID, CommentsID:this._disObj.discussID};
			    let result = await Net.rpcCall(pb.MessageID.C2S_LIKE_VIDEO_COMMENTS, pb.LikeVideoCommentsArg.encode(args));
                if(result.errcode == 0) {
                    let reData = pb.LikeVideoCommentsReply.decode(result.payload);
                    this._disObj.isLike = true;
                    this._disObj.likeNum += 1;
                    // Core.TipsUtils.showTipsFromCenter(reData.CurLike.toString());
                    DiscussDataMgr.inst.addDisussData(this._disObj);
                    this._likeBtn.getTransition("t0").play();
                    this._updateCom();
                }
            }
        }

        private _updateCom() {
            this._nameTxt.text = this._disObj.userName;
            this._messageTxt.text = this._disObj.content;
            this._likeBtn.title = this._disObj.likeNum.toString();
            this._headCom.setAll(this._disObj.headImage, this._disObj.frameImage);
            this._timeTxt.text = Core.StringUtils.format(Core.StringUtils.TEXT(60051), Core.StringUtils.secToString(Math.floor(Date.now()/1000 - this._disObj.time), "dhm"));
            if(this._disObj.isLike) {
                this._likeBtn.getController("isLike").selectedIndex = 1;
            } else {
                this._likeBtn.getController("isLike").selectedIndex = 0;
            }
        }

        private async _onHead() {
            if (!this._disObj.uid) {
                return;
            }
            if (this._disObj.uid == Player.inst.uid) {
                await Social.SocialMgr.inst.openSelfInfoView();
            } else {
                let playerInfo = await Social.FriendMgr.inst.fetchPlayerInfo(this._disObj.uid);
				if (playerInfo) {
					Core.ViewManager.inst.open(ViewName.friendInfo, this._disObj.uid, playerInfo);
				}
            }
        }

        public setComValue(o: DiscussData) {
            this._disObj = o;
            this._updateCom();
        }

    }
}
