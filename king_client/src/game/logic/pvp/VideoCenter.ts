module Pvp {

	export class VideoFighter {

		private _uid: Long;
		private _name: string;
		private _cards: Array<pb.ISkinGCard>;

		public constructor() {
			this._cards = [];
		}

		public update(pbData: pb.VideoFighter) {
			this._uid = <Long>pbData.Uid;
			this._name = pbData.Name;
			pbData.FightCards.forEach(cardId => {
				this._cards.push(cardId);
			});
		}

		public get uid(): Long {
			return this._uid;
		}

		public get name(): string {
			return this._name;
		}

		public get cards(): Array<pb.ISkinGCard> {
			return this._cards;
		}
	}

	enum VideoType {
		FENG_HUO_TAI = 1,
		ZHAN_JI = 2,
	}

	export class Video {

		private _isSelf: boolean;
		private _id: Long;
		private _hostFighter: VideoFighter;
		private _guestFighter: VideoFighter;
		private _winnerUid: Long;
		private _watchTimes: number;
		private _likeTimes: number;
		private _isShare: boolean;
		private _sharePlayerName: string;
		private _isLike: boolean;
		private _commentsAmount: number;
		private _title: string;
		private _timeStamp: number;
		private _hasWatch: boolean;
		private _type: VideoType;

		public constructor(pbData: pb.VideoItem, isSelf:boolean) {
			this._isSelf = isSelf;
			this._id = <Long>pbData.VideoID;
			this._hasWatch = false;
			this._hostFighter = new VideoFighter();
			this._guestFighter = new VideoFighter();
			this.update(pbData);
		}

		public update(pbData: pb.VideoItem) {
			// console.log(pbData);
			this._hostFighter.update(<pb.VideoFighter>pbData.Fighter1);
			this._guestFighter.update(<pb.VideoFighter>pbData.Fighter2);
			
			this._winnerUid = <Long>pbData.WinnerUid;
			this.watchTimes = pbData.WatchTimes;
			this.likeTimes = pbData.Like;
			this._timeStamp = pbData.Time;
			this._sharePlayerName = pbData.SharePlayerName;
			this.isShare = (this._sharePlayerName && this._sharePlayerName != "");
			this.isLike = pbData.IsLike;
			this.commentsAmount = pbData.CommentsAmount;
			this.title = pbData.Name;
			this._changePlayer();
			
		}

		private _changePlayer() {
			let changePlayer = false;
			if (this._isSelf) {
				if (this._guestFighter.uid == Player.inst.uid) {
					changePlayer = true;
				}
			} else {
				if (this._sharePlayerName == this._guestFighter.name) {
					changePlayer = true;
				}
			}
			if (changePlayer) {
				let f = this._hostFighter;
				this._hostFighter = this._guestFighter;
				this._guestFighter = f;
			}
		}

		public get id(): Long {
			return this._id;
		}

		public get hostFighter(): VideoFighter {
			return this._hostFighter;
		}

		public get guestFighter(): VideoFighter {
			return this._guestFighter;
		}

		public get winner(): Long {
			return this._winnerUid;
		}

		public get watchTimes(): number {
			return this._watchTimes;
		}

		public set watchTimes(time: number) {
			this._watchTimes = time;
		}

		public get likeTimes(): number {
			return this._likeTimes;
		}

		public set likeTimes(time: number) {
			this._likeTimes = time;
		}

		public get timeStamp(): number {
			return this._timeStamp;
		}

		public get sharePlayerName(): string {
			return this._sharePlayerName;
		}

		public set sharePlayerName(s: string) {
			this._sharePlayerName = s;
		}

		public get isShare(): boolean {
			return this._isShare;
		}

		public set isShare(b: boolean) {
			this._isShare = b;
		}

		public get isLike(): boolean {
			return this._isLike;
		}

		public set isLike(b: boolean) {
			this._isLike = b;
		}

		public get commentsAmount(): number {
			return this._commentsAmount;
		}

		public set commentsAmount(c: number) {
			this._commentsAmount = c;
		}

		public get title(): string {
			return this._title;
		}

		public set title(t: string) {
			this._title = t;
		}

		public get hasWatch(): boolean {
			return this._hasWatch;
		}

		public set hasWatch(b: boolean) {
			this._hasWatch = b;
			if (b) {
				VideoCenter.inst.setVideoWatch(this.id, true);
			}
		}

		public initHasWatch(b: boolean) {
			this._hasWatch = b;
		}

		public toLocalString(): string {
			let key = `${this._id}`;
			let data = {
				key : {
					"hasWatch": this._hasWatch,
				}
			}
			return JSON.stringify(data);
		}
	}

	export class VideoCenter {

		private static _inst: VideoCenter = null;

		private readonly _STORE_KEY: string = "videos";
		private _videoData: any;
		private _rankTeamVideoCache: Collection.Dictionary<number, {time: number, videos: Array<Video>}>;

		private _curVideo: Video;
		private _curVideoCom: VideoItemCom;

		public static get inst(): VideoCenter {
			if (!VideoCenter._inst) {
				VideoCenter._inst = new VideoCenter();
			}
			return VideoCenter._inst;
		}

		public constructor() {
			this._loadData();
			this._rankTeamVideoCache = new Collection.Dictionary<number, {time: number, videos: Array<Video>}>();
		}

		private _loadData() {
			let localDataStr = egret.localStorage.getItem(this._STORE_KEY);
			if (!localDataStr || localDataStr == "") {
                localDataStr = "{}";
            }
			this._videoData = JSON.parse(localDataStr);
		}

		private _saveData() {
			let dataStr = JSON.stringify(this._videoData);
            egret.localStorage.setItem(this._STORE_KEY, dataStr);
		}

		private _hasVideoWatched(id: Long) {
			let key = `${id}`;
			if (!this._videoData[key]) {
				return false;
			} else {
				return this._videoData[key]["hasWatch"];
			}
		}

		public setVideoWatch(id: Long, b: boolean) {
			let key = `${id}`;
			if (!this._videoData[key]) {
				this._videoData[key] = {};
			} 
			this._videoData[key]["hasWatch"] = b;
			this._saveData();
		}

		private async _fetchPublishVideos(team: number): Promise<Array<Video>> {
			let args = {Team: team};
			let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_VIDEO_LIST, null);
			if (result.errcode == 0) {
				 let reply = pb.VideoList.decode(result.payload);
				//  console.log(reply);
				 let ret: Array<Video> = [];
				 let shuffle: Array<Video> = [];
				 for (let i = 0; i < reply.Videos.length; ++ i) {
					 let data = reply.Videos[i];
					 let video = new Video(<pb.VideoItem>data, false);
					 if (this._hasVideoWatched(video.id)) {
						video.initHasWatch(true);
					 }
					 if (i == 0) {
						ret.push(video);
					 } else {
						 shuffle.push(video);
					 }
				 }
				 shuffle = Core.RandomUtils.shuffle(shuffle);
				 let collect = ret.concat(shuffle);
				 this._rankTeamVideoCache.setValue(team, {
					 	time: Date.now(),
				 		videos: collect,
					});
				return collect;
			} else {
				return [];
			}
		}

		public async getPublishVideos(team: number, force: boolean = false): Promise<Array<Video>> {
			if (this._rankTeamVideoCache.containsKey(team)) {
				let info = this._rankTeamVideoCache.getValue(team);
				if (Date.now() - info.time > 3600 * 1000 || force) {
					return await this._fetchPublishVideos(team);
				} else {
					if (!info.videos) {
						return [];
					} else {
						return info.videos;
					}
				}
			} else {
				return await this._fetchPublishVideos(team);
			}
		}

		public async getSelfVideos(page: number): Promise<Array<Video>> {
			let args = {Page: page};
			let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_SELF_VIDEO_LIST, pb.FetchSelfVideoListArg.encode(args));
			if (result.errcode == 0) {
				let reply = pb.VideoList.decode(result.payload);
				let ret: Array<Video> = [];
				for (let i = 0; i < reply.Videos.length; ++ i) {
					 let data = reply.Videos[i];
					 let video = new Video(<pb.VideoItem>data, true);
					 if (this._hasVideoWatched(video.id)) {
						video.initHasWatch(true);
					 }
					 ret.push(video);
				}
				return ret;
			} else {
				return [];
			}
		}

		public async setCurVideo(video: Video, videoCom: VideoItemCom) {
			this._curVideo = video;
			this._curVideoCom = videoCom;
		}

		public get curVideo() {
			return this._curVideo;
		}
		public get curVideoCom() {
			return this._curVideoCom;
		}

		public async playVideo(video: Video, videoCom?: VideoItemCom) {
			let args = {VideoID: video.id};
			let result = await Net.rpcCall(pb.MessageID.C2S_WATCH_VIDEO, pb.WatchVideoArg.encode(args));
			if (result.errcode == 0) {
				VideoCenter.inst.setCurVideo(video, videoCom);
				let reply = pb.WatchVideoResp.decode(result.payload);
				let name:string = null;
				if (Core.ViewManager.inst.isShow(ViewName.videoHall)) name = ViewName.videoHall;
				else if (Core.ViewManager.inst.isShow(ViewName.videoRecord)) name = ViewName.videoRecord;
				if (name && name != "") {
					Core.ViewManager.inst.getView(name).setVisible(false);
				}
				try {
					await Battle.VideoPlayer.inst.play(<pb.VideoBattleData>reply.VideoData);
				} catch(e) {
					console.log(e);
				}

				if (name && name != "") {
					Core.ViewManager.inst.getView(name).setVisible(true);
				}

				video.watchTimes = reply.CurWatchTimes;
				video.likeTimes = reply.CurLike;
				video.hasWatch = true;

				return true;
			} else {
				return false;
			}
		}

		public async playVideoById(videoId: Long) {
			// let videoArgs = {
			// 	VideoID: videoId
			// };
			// let videoResult = await Net.rpcCall(pb.MessageID.C2S_FETCH_VIDEO_ITEM, pb.FetchVideoItemArg.encode(videoArgs));
			// if (videoResult.errcode == 0) {
			// 	let videoReply = pb.VideoItem.decode(videoResult.payload);
			// 	let video = new Video(videoReply, false);
			// 	return await this.playVideo(video);
			// } else {
			// 	return false;
			// }
			let video =  await this.getVideoById(videoId);
			if (video) {
				return await this.playVideo(video);
			} else {
				return false;
			}
		}

		public async getVideoById(videoId:Long)
		{
			let videoArgs = {
				VideoID: videoId
			};
			let videoResult = await Net.rpcCall(pb.MessageID.C2S_FETCH_VIDEO_ITEM, pb.FetchVideoItemArg.encode(videoArgs));
			if (videoResult.errcode == 0) {
				let videoReply = pb.VideoItem.decode(videoResult.payload);
				let video = new Video(videoReply, false);
				return video;
			}
		}
	}
}