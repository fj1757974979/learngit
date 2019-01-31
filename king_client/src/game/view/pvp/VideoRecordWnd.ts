module Pvp {

	export class VideoRecordWnd extends Core.BaseView {

		private _page: number;
		private _curTeam: number;
		private _closeBtn: fairygui.GButton;
		private _videoList: fairygui.GList;
		private _videos: Array<Video>;
		private _worldVideos: Array<Video>;
		private _friendChk: fairygui.GButton;
		private _worldChk: fairygui.GButton;
		private _worldList: fairygui.GList;
		private _searchBtn: fairygui.GButton;

		public initUI() {
			super.initUI();
			this.adjust(this.getChild("panel"), Core.AdjustType.EXCEPT_MARGIN);
			this.y += window.support.topMargin/2;
			this._page = 1;
			this._curTeam = Math.max(Pvp.Config.MIN_RANK_TAEM, Pvp.Config.inst.getPvpTeam(Pvp.PvpMgr.inst.getPvpLevel()));

			this._closeBtn = this.getChild("closeBtn").asButton;
			this._videoList = this.getChild("rankList").asList;
			this._friendChk = this.getChild("friendChk").asButton;
			this._worldChk = this.getChild("worldChk").asButton;
			this._worldList = this.getChild("worldList").asList;
			this._searchBtn = this.getChild("searchBtn").asButton;
			this._worldChk.addClickListener( this._onSelfBtn, this);
			this._friendChk.addClickListener(this._onWorldList, this);
			this._closeBtn.addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			}, this);
			this._searchBtn.addClickListener(() => {
				Core.ViewManager.inst.open(ViewName.videoSearch);
			}, this);

			this._videos = [];
			this._worldVideos = [];

			this._videoList.itemClass = VideoRecordItemCom;
			this._videoList.itemRenderer = this._renderVideoRecord;
			this._videoList.callbackThisObj = this;
			this._videoList.setVirtual();

			this._worldList.setVirtual();
			this._worldList.itemRenderer = this._renderWorldRecord;
			this._worldList.callbackThisObj = this;
			this._worldList.itemClass = VideoHallItemCom;

		}

		public async open(...param: any[]) {
			this.setVisible(true);
			super.open(...param);
			this.getController("switch").selectedIndex = 0;

			let videos = await VideoCenter.inst.getSelfVideos(this._page);
			this._videos = videos;
			this._videoList.numItems = this._videos.length;
			this._worldList.numItems = 0;
			
			if (videos.length > 0) {
				this.getChild("emptyHintText").visible = false;
			} else {
				this.getChild("emptyHintText").visible = true;
			}
			// this._renderVideoRecord();
		}

		public beginRefreshItem() {

		}

		public endRefreshItem() {

		}

		private _renderVideoRecord(idx:number, item:fairygui.GObject) {
			let video = this._videos[idx];
			if (video) {
				let com = item as VideoRecordItemCom;
				com.setVideo(video, this);
			}
		}

		private _renderWorldRecord(idx:number, item:fairygui.GObject) {
			let video = this._worldVideos[idx];
			if (video) {
				let com = item as VideoHallItemCom;
				com.setVideo(video, this);
			}
		}

		private async _onSelfBtn() {
			if (this._videos.length > 0) {
				return;
			}
			let videos = await VideoCenter.inst.getSelfVideos(this._page);
			this._videos = videos;
			this._videoList.numItems = this._videos.length;
			this._videoList.refreshVirtualList();
		}

		private _onWorldList() {
			if (this._worldVideos.length > 0) {
				return;
			}
			this._refresh(this._curTeam);
		}

		private async _refresh(team: number) {
			
			let videos = await VideoCenter.inst.getPublishVideos(team, true);
			
			this._worldList.numItems = 0;
			this._worldVideos = videos;
			this._worldList.numItems = videos.length;

			this._curTeam = team;
			this._worldList.refreshVirtualList();
			if (videos.length > 0) {
				this.getChild("emptyHintText2").visible = false;
			} else {
				this.getChild("emptyHintText2").visible = true;
			}
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._page = 1;
			// this._videoList.removeChildren(0, -1, true);
			this._videoList.numItems = 0;
			// this._worldList.removeChildren(0, -1, true);
			this._worldList.numItems = 0;
			this._videos = [];
			this._worldVideos = [];
		}


	}
}