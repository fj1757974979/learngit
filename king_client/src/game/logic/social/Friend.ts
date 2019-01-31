module Social {

	export class Friend {

		private _uid: Long;
		private _name: string;
		private _pvpScore: number;
		private _pvpCamp: Camp;
		private _isOnline: boolean;
		private _isInBattle: boolean;
		private _headImgUrl: string;
		private _frameUrl: string;
		private _lastOnlineTime: number;
		private _isWeChatFriend: boolean;
		private _rebornCnt: number;

		public constructor(data: pb.FriendItem) {
			this._uid = <Long>data.Uid;
			this._name = data.Name;
			this._pvpScore = data.PvpScore;
			this._pvpCamp = data.PvpCamp;
			this._isOnline = data.IsOnline;
			this._isInBattle = data.IsInBattle;
			this._headImgUrl = data.HeadImgUrl;
			this._frameUrl = data.HeadFrame;
			this._lastOnlineTime = data.LastOnlineTime;
			this._isWeChatFriend = data.IsWechatFriend;
			this._rebornCnt = data.RebornCnt;
		}

		public get uid(): Long {
			return this._uid;
		}

		public get name(): string {
			return this._name;
		}

		public get score(): number {
			return this._pvpScore;
		}

		public get camp(): Camp {
			return this._pvpCamp;
		}

		public get isOnline(): boolean {
			return this._isOnline;
		}

		public get isInBattle(): boolean {
			return this._isInBattle;
		}

		public get headImgUrl(): string {
			return this._headImgUrl;
		}

		public get frameUrl(): string {
			if (!this._frameUrl || this._frameUrl == "") {
				this._frameUrl = "1";
			}
			//console.log(`headframe_${this._frameUrl}_png`);
			return this._frameUrl;
		}

		public get lastOnlineTime(): number {
			return this._lastOnlineTime;
		}

		public get isWeChatFriend(): boolean {
			return this._isWeChatFriend;
		}
		public get rebornCnt(): number {
			return this._rebornCnt;
		}

		public toData(): any {
			return {
				uid: this.uid,
				name: this.name,
				score: this.score,
				camp: this.camp,
				isOnline: this.isOnline,
				isInBattle: this.isInBattle,
				headImgUrl: this.headImgUrl,
				lastOnlineTime: this.lastOnlineTime,
				isWeChatFriend: this.isWeChatFriend,
				rebornCnt: this.rebornCnt,
			}
		}
	}
}