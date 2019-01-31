module Pvp {

    export class VideoDiscussWnd extends Core.BaseView {

        private _chatletList: fairygui.GList;
        // private _scrollPane: fairygui.ScrollPane;

        private _inputText: fairygui.GTextInput;
        private _sendBtn: fairygui.GButton;
        private _discussCnt: fairygui.GTextField;
        private _titleTxt: fairygui.GTextField;
        private _itemNum: number;
        private _video: Video;
        private _parentCom: any;

        private _curAmount: number;
        private _more: boolean;


        public initUI() {
            super.initUI();
            // this.modal = true;
            this.adjust(this.getChild("bg"));

            this._sendBtn = this.getChild("sendBtn").asButton;
            this._inputText = this.getChild("inputText").asTextInput;
            this._discussCnt = this.getChild("discussCnt").asTextField;
            this._titleTxt = this.getChild("titleTxt").asTextField;

            this._chatletList = this.getChild("chatletList").asList;
            this._chatletList.itemRenderer = this._renderListItem;
            //this._chatletList.setVirtual();
            this._chatletList.numItems = 0;


            this._chatletList._scrollPane.addEventListener(fairygui.ScrollPane.PULL_UP_RELEASE,this._releaseList,this);
            this.getChild("bg").addClickListener(this._close,this);
            this.getChild("closeBtn").asButton.addClickListener(this._close,this)
            this._sendBtn.addClickListener(this._onSendBtn,this);

        }

        public async open(...param: any[]) {
			super.open(...param);
            if (Core.ViewManager.inst.isShow(ViewName.battle)) {
                Core.LayerManager.inst.topLayer.addChild(this);
            } else {
                Core.LayerManager.inst.mainLayer.addChild(this);
            }

            
            DiscussDataMgr.inst.reDisussDataMgr();
            this._itemNum = 0;
            this._curAmount = 0;
            this._more = true;
            this._chatletList.numItems = 0;
            this._video = VideoCenter.inst.curVideo;
            this._parentCom = VideoCenter.inst.curVideoCom;

            this._discussCnt.text = Core.StringUtils.format(Core.StringUtils.TEXT(60060), this._video.commentsAmount);
            this._titleTxt.text = this._video.title;
            this._updateDiscuss(param[0]);

		}

		public async close(...param: any[]) {
			super.close(...param);
		}

        private async _releaseList() {
            if(this._more) {
                let args = {VideoID: this._video.id,CurAmount:this._curAmount};
                let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_VIDEO_COMMENTS, pb.FetchVideoCommentsArg.encode(args));
                if (result.errcode == 0) {
                    let comments = pb.FetchVideoCommentsReply.decode(result.payload);
                    this._updateDiscuss(comments);
                }
            }
        }

        private async _updateDiscuss(comments: pb.FetchVideoCommentsReply) {
            let _count = 0;
            comments.CommentsList.forEach((_value) => {
                let disData = new DiscussData(this._video.id,_value);
                DiscussDataMgr.inst.addDisussData(disData);
                _count += 1;
            });
            this._itemNum = DiscussDataMgr.inst.discussNum;
            this._chatletList.numItems = this._itemNum;
            if (this._itemNum <= 0) {
                this.getChild("emptyHintText").asTextField.visible = true;
            } else {
                this.getChild("emptyHintText").asTextField.visible = false;
            }

            this._curAmount += _count;
            this._more = comments.HasMore;
        }

        private async _renderListItem(index: number, obj: fairygui.GObject) {
            let item = obj as VideoDisItem ;
		    // // 设置
            await item.setComValue(DiscussDataMgr.inst.getDiscussData4Index(index));
        }

        private async _onSendBtn() {
            let messageTxt = this._inputText.text;
            messageTxt = messageTxt.trim();
            if(messageTxt.length <= 0) {
                return;
            }

            let args = {VideoID: this._video.id, Content:messageTxt};
            let result = await Net.rpcCall(pb.MessageID.C2S_COMMENTS_VIDEO, pb.CommentsVideoArg.encode(args));
            if (result.errcode == 0) {
                this._inputText.text = "";
                let reData = pb.CommentsVideoReply.decode(result.payload);
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60074));

                let _commentData = new pb.VideoComments();
                _commentData.Content = messageTxt;
                _commentData.HeadImgUrl = Player.inst.avatarUrl;
                _commentData.ID = reData.CommentsID;
                _commentData.Name = Player.inst.name;
                _commentData.IsLike = false;
                _commentData.Like = 0;
                _commentData.Time = Date.now();
                _commentData.Uid = Player.inst.uid;
                _commentData.HeadFrame = Player.inst.frameID;
                let _comment = new DiscussData(this._video.id,_commentData);
                DiscussDataMgr.inst.addDisussData(_comment);
                this._itemNum = DiscussDataMgr.inst.discussNum;
                this._chatletList.numItems = this._itemNum;
                this._video.commentsAmount += 1;
                this._discussCnt.text = Core.StringUtils.format(Core.StringUtils.TEXT(60060), this._video.commentsAmount);
                this._parentCom.updatedisNum();
                this.getChild("emptyHintText").asTextField.visible = false;
            } else if (result.errcode == 101) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60210));
            }
        }

        private _close() {
            Core.ViewManager.inst.close(ViewName.videoDiscuss);
        }
    }

}
