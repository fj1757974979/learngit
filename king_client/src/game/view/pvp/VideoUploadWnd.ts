module Pvp {
    
    export class VideoUploadWnd extends Core.BaseWindow {

        private _parentVideo: VideoRecordItemCom;

        private _closeBtn: fairygui.GButton;
        private _confirmBtn: fairygui.GButton;
        private _searchInput: fairygui.GTextInput;
        private _hostCardComs: Array<VideoCardCom>;
		private _guestCardComs: Array<VideoCardCom>;
        private _hostResultText: fairygui.GLoader;
		private _guestResultText: fairygui.GLoader;
        private _hostNameText: fairygui.GTextField;
		private _guestNameText: fairygui.GTextField;

        private _video: Video;

        public initUI() {
            super.initUI();

            this.center();
            this.modal = true;

            this._closeBtn = this.getChild("closeBtn").asButton;
            this._confirmBtn = this.getChild("confirmBtn").asButton;
            this._searchInput = this.getChild("searchInput").asTextInput;
            this._hostResultText = this.getChild("resultTxt1").asLoader;
			this._guestResultText = this.getChild("resultTxt2").asLoader;
            this._hostNameText = this.getChild("name1").asTextField;
			this._guestNameText = this.getChild("name2").asTextField;
            this._hostNameText.textParser = Core.StringUtils.parseColorText;
            this._guestNameText.textParser = Core.StringUtils.parseColorText;

            this._closeBtn.addClickListener(this._onClose,this);
            this._confirmBtn.addClickListener(this._onShareVideo,this);

            this._hostCardComs = [];
			this._guestCardComs = [];


			for (let i = 1; i <= 5; ++ i) {
				let com = this.getChild(`card${i}`).asCom as VideoCardCom;
				this._hostCardComs.push(com);
			}
			for (let i = 6; i <= 10; ++ i) {
				let com = this.getChild(`card${i}`).asCom as VideoCardCom;
				this._guestCardComs.push(com);
			}

            
        }

        public async open(...param: any[]) {
			super.open(...param);
            this._setVideo(param[0]);
            this._parentVideo = param[1];

		}

		public async close(...param: any[]) {
			super.close(...param);
		}

        private _setVideo(video: Video) {
            this._video = video;
            // console.log(video);
            let hostCards = video.hostFighter.cards;
            let hostWin = false;
            if (video.winner == video.hostFighter.uid) {
                hostWin = true;
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

            if (this._video.winner == this._video.hostFighter.uid) {
				this._hostResultText.url = "cards_base1_s_png";
				this._guestResultText.url = "cards_base2_s_png";
			} else {
				this._hostResultText.url = "cards_base2_s_png";
				this._guestResultText.url = "cards_base1_s_png";
			}

            this._hostNameText.text = this._video.hostFighter.name;
			this._guestNameText.text = this._video.guestFighter.name;
        }

        private async _onShareVideo() {
            let inputText = this._searchInput.text;
            inputText = inputText.trim();
            if (inputText.length <= 0) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60169));
                return;
            }

            let args = {VideoID: this._video.id,
                        Name: inputText};
			let result = await Net.rpcCall(pb.MessageID.C2S_SHARE_VIDEO, pb.ShareVideoArg.encode(args));
			if (result.errcode == 0) {
				this._parentVideo.shareOK(inputText);
                this._searchInput.text = "";
                this._onClose();
			} else if (result.errcode == 101) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60209));
            }
        }

        private _onClose() {
            Core.ViewManager.inst.close(ViewName.videoUpload);
        }
    }
}