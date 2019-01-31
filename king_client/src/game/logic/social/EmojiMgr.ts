module Social {

	export class EmojiTeam {
		private _id: number;
		private _eids: Array<string>;
		private _isUnlock: boolean;
		private _eidToConfig: Collection.Dictionary<string, any>;
		private _teamName: string;
		private _icon: string;

		public constructor(id: number) {
			this._isUnlock = false;
			this._id = id;
			this._eids = [];
			this._eidToConfig = new Collection.Dictionary<string, any>();
			this._teamName = null;
			this._icon = null;
		}

		public addEmoji(eid: string, conf: any) {
			this._eids.push(eid);
			this._eidToConfig.setValue(eid, conf);
			if (!this._teamName) {
				this._teamName = conf["teamName"];
			}
			if (!this._icon) {
				this._icon = conf["emojiPackIcon"];
			}
		}

		public get isUnlock(): boolean {
			return this._isUnlock;
		}

		public set isUnlock(b: boolean) {
			this._isUnlock = b;
		}

		public get teamId(): number {
			return this._id;
		}

		public get name(): string {
			return this._teamName;
		}

		public get icon(): string {
			return this._icon
		}

		public get emojiIds(): Array<string> {
			return this._eids;
		}
	}

	export class EmojiMgr {

		private static _inst: EmojiMgr = null;

		public static get inst(): EmojiMgr {
			if (!EmojiMgr._inst) {
				EmojiMgr._inst = new EmojiMgr();
			}
			return EmojiMgr._inst;
		}

		private _emojiTeams: Collection.Dictionary<number, EmojiTeam>;
		private _initialized: boolean;

		public constructor() {
			this._emojiTeams = new Collection.Dictionary<number, EmojiTeam>();
			this._initialized = false;

			let keys = Data.emoji_config.keys;
			keys.forEach(eid => {
				let conf = Data.emoji_config.get(eid);
				if (conf) {
					let teamId = conf["team"];
					if (!this._emojiTeams.containsKey(teamId)) {
						this._emojiTeams.setValue(teamId, new EmojiTeam(teamId));
					}
					let team = this._emojiTeams.getValue(teamId);
					team.addEmoji(eid.toString(), conf);
				}
			});
		}

		public async initEmojis() {
			let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_EMOJI, null);
			if (result.errcode == 0) {
				let reply = pb.EmojiData.decode(result.payload);
				reply.EmojiTeams.forEach(teamId => {
					let team = this._emojiTeams.getValue(teamId);
					if (team) {
						team.isUnlock = true;
					}
				});
				this._initialized = true;
			}
		}

		public async getEmojiTeams() {
			if (!this._initialized) {
				await this.initEmojis();
			}
			let emojiTeams = this._emojiTeams.values();
			emojiTeams = emojiTeams.sort((t1: EmojiTeam, t2: EmojiTeam): number => {
				if (t1.teamId < t2.teamId) {
					return -1;
				} else {
					return 1;
				}
			});
			return emojiTeams;
		}

		public getEmojiTeam(teamId: number) {
			return this._emojiTeams.getValue(teamId);
		}
	}
}