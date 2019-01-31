module Pvp {
	//烽火台功能已经合并到个人战绩里，这个应该可以删除了···
	export class VideoHallWnd extends Core.BaseWindow {

		private _closeBtn: fairygui.GButton;
		private _leftBtn: fairygui.GButton;
		private _rightBtn: fairygui.GButton;
		private _videoList: fairygui.GList;
		private _searchBtn: fairygui.GButton;
		private _videos: Array<Video>;
		private _curTeam: number;

		public initUI() {
			super.initUI();
			this.adjust(this.getChild("panel"), Core.AdjustType.EXCEPT_MARGIN);
			this.y += window.support.topMargin/2;

			this._closeBtn = this.getChild("closeBtn").asButton;
			this._leftBtn = this.getChild("leftBtn").asButton;
			this._rightBtn = this.getChild("rightBtn").asButton;
			this._videoList = this.getChild("rankList").asList;
			this._searchBtn = this.getChild("searchBtn").asButton;

			this._curTeam = Math.max(Pvp.Config.MIN_RANK_TAEM, Pvp.Config.inst.getPvpTeam(Pvp.PvpMgr.inst.getPvpLevel()));

			this._leftBtn.addClickListener(this._onFetchPrevTeam, this);
			this._rightBtn.addClickListener(this._onFetchNextTeam, this);

			this._closeBtn.addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			}, this);
			this._searchBtn.addClickListener(() => {
				Core.ViewManager.inst.open(ViewName.videoSearch);
			}, this);

			this._videoList.itemClass = VideoHallItemCom;
			this._videoList.itemRenderer = this._renderVideoRecord;
			this._videoList.callbackThisObj = this;
			this._videoList.setVirtual();

			this._videos = [];

		}

		public async open(...param: any[]) {
			this.setVisible(true);
			super.open(...param);
			this._refresh(this._curTeam);
		}

		private async _refresh(team: number) {
			
			this.getChild("rankImg").asLoader.url = `common_rank${team}_png`;
			this.getChild("rankImg1").asLoader.url = `common_rank${team}_png`;
			this.getChild("rankTitleText").asTextField.text = 
						Pvp.Config.inst.getPvpTeamName(Pvp.Config.inst.getMiniLevelInPvpTeam(team));

			let videos = await VideoCenter.inst.getPublishVideos(team, true);
			// this._videoList.cacheContent(false);
			this._videoList.numItems = 0;
			this._videos = videos;
			this._videoList.numItems = videos.length;

			// this._videoList.cacheContent(true);

			this._curTeam = team;
			if (this._curTeam >= Pvp.Config.MAX_RANK_TEAM) {
				this._rightBtn.visible = false;
			} else {
				this._rightBtn.visible = true;
			}

			if (this._curTeam <= Pvp.Config.MIN_RANK_TAEM) {
				this._leftBtn.visible = false;
			} else {
				this._leftBtn.visible = true;
			}

			if (videos.length > 0) {
				this.getChild("emptyHintText").visible = false;
			} else {
				this.getChild("emptyHintText").visible = true;
			}
		}

		public beginRefreshItem() {
			// this._videoList.cacheContent(false);
		}

		public endRefreshItem() {
			// this._videoList.cacheContent(true);
		}

		private _renderVideoRecord(idx:number, item:fairygui.GObject) {
			let video = this._videos[idx];
			if (video) {
				let com = item as VideoHallItemCom;
				com.setVideo(video, this);
			}
		}

		private async _onFetchNextTeam() {
			SoundMgr.inst.playSoundAsync("page_mp3");
			let team = Math.min(this._curTeam + 1, Pvp.Config.MAX_RANK_TEAM);
			if (team != this._curTeam) {
				await this._refresh(team);
			}
		}

		private async _onFetchPrevTeam() {
			SoundMgr.inst.playSoundAsync("page_mp3");
			let team = Math.max(this._curTeam - 1, Pvp.Config.MIN_RANK_TAEM);
			if (team != this._curTeam) {
				await this._refresh(team);
			}
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._videoList.numItems = 0;
		}
	}
}