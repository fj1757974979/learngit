module Social {

	let _PRIVATE_CHAT_KEY: string = "p";
	let _PRIVATE_HINT_NUM: string = "pn";
	let _PRIVATE_CHAT_MAX_ID: string = "pmid";

	export class ChatMgr {

		private static _inst: ChatMgr = null;

		public static get inst(): ChatMgr {
			if (!ChatMgr._inst) {
				ChatMgr._inst = new ChatMgr();
			}
			return ChatMgr._inst;
		}

		private _STORE_KEY: string = "chat";
		
		private _MAX_WORLD_CHAT_CNT: number = 50;
		private _chatData: any;
		private _privateChatData: {[index: string]: any[]};
		private _privateChatMaxID: number;
		private _privateChatHints: {[index: string]: number};
		private _privateChatHintTotalNum: number;

		private _currentChatUid: Long;

		private _channelChatlets: Collection.Dictionary<pb.ChatChannel, Array<IChatlet>>;
		private _privateChatlets: Collection.Dictionary<string, Array<PrivateChatlet>>;
		private _privateChatInited: boolean;

		private _privateChatInitPromise: Promise<void>

		private _WORLD_CHAT_CD: number;
		private _lastWorldSendTime: number;

		public constructor() {
			this._channelChatlets = new Collection.Dictionary<pb.ChatChannel, Array<IChatlet>>();
			this._privateChatlets = new Collection.Dictionary<string, Array<PrivateChatlet>>();
			this._privateChatHintTotalNum = 0;
			this._loadData();
			let key = `${Player.inst.uid}`;
			this._privateChatData = this._chatData[key][_PRIVATE_CHAT_KEY];
			this._privateChatHints = this._chatData[key][_PRIVATE_HINT_NUM];
			this._privateChatMaxID = this._chatData[key][_PRIVATE_CHAT_MAX_ID];
			this._privateChatInited = false;
			this._WORLD_CHAT_CD = 5;
			this._lastWorldSendTime = 0;
		}

		private _loadData() {
			let key = `${Player.inst.uid}`;
			let localDataStr = egret.localStorage.getItem(this._STORE_KEY);
			if (localDataStr && localDataStr != "") {
				this._chatData = JSON.parse(localDataStr);
				if (!this._chatData[key]) {
					this._chatData[key] = {}
					this._chatData[key][_PRIVATE_CHAT_KEY] = {};	
					this._chatData[key][_PRIVATE_HINT_NUM] = {};
					this._chatData[key][_PRIVATE_CHAT_MAX_ID] = 0;
				}
				try {
					if (typeof this._chatData[key][_PRIVATE_CHAT_MAX_ID] != "number") {
						this._chatData[key][_PRIVATE_CHAT_MAX_ID] = 0;
					}
				} catch (e) {
					this._chatData[key][_PRIVATE_CHAT_MAX_ID] = 0;
				}
				let privateChat: {[index: string]: any} = this._chatData[key][_PRIVATE_CHAT_KEY];
				for (let uid in privateChat) {
					let chatlets: Array<PrivateChatlet> = [];
					let info: any[] = privateChat[uid];
					info.forEach(_info => {
						let chatlet = new PrivateChatlet(ChatChannel.PRIVATE, _info);
						chatlets.push(chatlet);
					});
					this._privateChatlets.setValue(uid, chatlets);
				}
				if (!this._chatData[key][_PRIVATE_HINT_NUM]) {
					this._chatData[key][_PRIVATE_HINT_NUM] = {};
				}
				let hintNumInfo: {[index: string]: number} = this._chatData[key][_PRIVATE_HINT_NUM];
				for (let uid in hintNumInfo) {
					this._privateChatHintTotalNum += hintNumInfo[uid];
				}
				if (!this._chatData[key][_PRIVATE_CHAT_MAX_ID]) {
					this._chatData[key][_PRIVATE_CHAT_MAX_ID] = 0;
				}
            } else {
				this._chatData = {};
				this._chatData[key] = {};
				this._chatData[key][_PRIVATE_CHAT_KEY] = {};	
				this._chatData[key][_PRIVATE_HINT_NUM] = {};
				this._chatData[key][_PRIVATE_CHAT_MAX_ID] = 0;
			}
		}

		private _saveData() {
			let dataStr = JSON.stringify(this._chatData);
			console.debug("_saveData +++++ : ", dataStr);
            egret.localStorage.setItem(this._STORE_KEY, dataStr);
		}

		public addChannelChatlet(channel:pb.ChatChannel, pbInfo: pb.Chatlet): IChatlet {
			// let info: any[] = [
			// 	`${pbInfo.Uid}`, 
			// 	pbInfo.Name,
			// 	pbInfo.HeadImgUrl,
			// 	`${pbInfo.Time}`,
			// 	pbInfo.Msg,
			// 	pbInfo.PvpLevel,
			// 	pbInfo.HeadFrame,
			// 	"",
			// 	pbInfo.CityJob,
			// 	pbInfo.CountryJob,
			// ];
			// let city = War.CityMgr.inst.getCity(pbInfo.CityID);
			// if (city) {
			// 	info[7] = city.cityName;
			// }
			return this._doChannelChatlet(channel, pbInfo);
		}

		private _doChannelChatlet(channel:pb.ChatChannel, pbInfo: pb.Chatlet): IChatlet {
			let chatlet = null;
			if (pbInfo.Type == pb.Chatlet.TypeEnum.Normal) {
				chatlet = new ChannelMessageChatlet(channel, pbInfo);
				let chat = <ChannelMessageChatlet>chatlet;
				UserLocalCache.inst.setUserCountry(chat.uid, chat.country);
			} else if (pbInfo.Type == pb.Chatlet.TypeEnum.CampaignNotice) {
				chatlet = new CampaignNoticeChatlet(channel, pbInfo);
			}
			let chatlets = this._channelChatlets.getValue(channel);
			if (!chatlets) {
				chatlets = [];
				this._channelChatlets.setValue(channel, chatlets);
			}
			chatlets.push(chatlet);
			return chatlet;
		}

		public addPrivateChatlets(pbInfo: pb.PrivateChatItem): Array<PrivateChatlet> {
			let uid = <Long>pbInfo.Uid;
			let infos = [];
			pbInfo.Msgs.forEach(data => {
				let info: any[] = [
					`${pbInfo.Uid}`, 
					pbInfo.Name,
					pbInfo.HeadImgUrl,
					`${data.Time}`,
					data.Msg,
					pbInfo.ID,
					pbInfo.Name,
					pbInfo.HeadImgUrl,
					pbInfo.PvpLevel,
					pbInfo.HeadFrame,
				];
				infos.push(info);
			});
			UserLocalCache.inst.setUserCountry(<Long>pbInfo.Uid, pbInfo.Country);
			
			return this._doAddPrivateChatlets(uid, infos);
		}

		private _doAddPrivateChatlets(uid: Long, infos: any[]): Array<PrivateChatlet> {
			let toret: Array<PrivateChatlet> = [];
			let uidKey = `${uid}`;
			if (!this._privateChatData[uidKey]) {
				this._privateChatData[uidKey] = [];
			}
			infos.forEach(info => {
				this._privateChatData[uidKey].push(info);
				let chatlet = new PrivateChatlet(ChatChannel.PRIVATE, info);
				toret.push(chatlet);
				if (this._privateChatMaxID < chatlet.id) {
					this._privateChatMaxID = chatlet.id;
				}
			});
			let key = `${Player.inst.uid}`;
			this._chatData[key][_PRIVATE_CHAT_KEY] = this._privateChatData;
			this._chatData[key][_PRIVATE_CHAT_MAX_ID] = this._privateChatMaxID;
			this._saveData();
			let pchatlets = this._privateChatlets.getValue(uidKey);
			if (!pchatlets) {
				this._privateChatlets.setValue(uidKey, toret);
			} else {
				this._privateChatlets.setValue(uidKey, pchatlets.concat(toret));
			}
			return toret;
		}

		public drainWorldChatlets(channel:pb.ChatChannel): Array<IChatlet> {
			let chatlets = this._channelChatlets.getValue(channel);
			this._channelChatlets.remove(channel);
			if (!chatlets) {
				chatlets = [];
			}
			return chatlets;
		}

		public get currentChatUid(): Long {
			return this._currentChatUid;
		}

		public set currentChatUid(uid: Long) {
			this._currentChatUid = uid;
		}

		public addPrivateHintsNum(uid: Long, num: number) {
			if (this._currentChatUid == uid) {
				return;
			}
			let key = `${uid}`;
			if (!this._privateChatHints[key]) {
				this._privateChatHints[key] = 0;
			}
			let cnt = this._privateChatHints[key];
			this._privateChatHints[key] = cnt + num;
			this._privateChatHintTotalNum += num;
			this._chatData[`${Player.inst.uid}`][_PRIVATE_HINT_NUM] = this._privateChatHints;
			this._saveData();
			Core.EventCenter.inst.dispatchEventWith(GameEvent.PrivateChatHintEv, false, uid);
		}

		public cleanPrivateHintsNum(uid: Long) {
			let key = `${uid}`;
			let num = this._privateChatHints[key];
			this._privateChatHints[key] = 0;
			if (num) {
				this._privateChatHintTotalNum = Math.max(0, this._privateChatHintTotalNum - num);
			}
			this._chatData[`${Player.inst.uid}`][_PRIVATE_HINT_NUM] = this._privateChatHints;
			this._saveData();
			Core.EventCenter.inst.dispatchEventWith(GameEvent.PrivateChatHintEv, false, uid);
		}

		public getPrivateHintsNum(uid?: Long): number {
			if (uid) {
				let key = `${uid}`;
				if (!this._privateChatHints[key]) {
					return 0;
				} else {
					return this._privateChatHints[key];
				}
			} else {
				return this._privateChatHintTotalNum;
			}
		}

		public async initPrivateChat() {
			await this._initPrivateChat();
			// if (this._privateChatInitPromise) {
			// 	await this._privateChatInitPromise;
			// 	return;
			// } else {
			// 	this._privateChatInitPromise = this._initPrivateChat.apply(this);
			// 	await this._privateChatInitPromise;
			// 	this._privateChatInitPromise = null;
			// }
		}

		private async _initPrivateChat() {
			let args = {
				MaxID: this._privateChatMaxID,
			}
			let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_PRIVATE_CHAT, pb.FetchPrivateChatArg.encode(args));
			if (result.errcode == 0) {
				let reply = pb.PrivateChatList.decode(result.payload);
				// console.debug(JSON.stringify(reply));
				reply.PrivateChatItems.forEach(chatItem => {
					let chatlets = this.addPrivateChatlets(<pb.PrivateChatItem>chatItem);
					this.addPrivateHintsNum(chatlets[0].uid, chatlets.length);
				});
				this._privateChatInited = true;
			}
		}

		public async getPrivateChatlets(uid: Long): Promise<Array<PrivateChatlet>> {
			if (!this._privateChatInited) {
				await this.initPrivateChat();
			}
			let key = `${uid}`;
			return this._privateChatlets.getValue(`${uid}`);
		}

		public async getLatestPrivateChatlet(uid: Long): Promise<PrivateChatlet> {
			let chatlets = await this.getPrivateChatlets(uid);
			if (!chatlets) {
				return null;
			} else {
				return chatlets[chatlets.length - 1];
			}
		}

		public async getPrivateUidKeys(): Promise<Array<string>> {
			if (!this._privateChatInited) {
				await this.initPrivateChat();
			}
			return this._privateChatlets.keys();
		}

		public async subscribeChat(channel: number) {
			let args = {Channel: channel};
			let result = await Net.rpcCall(pb.MessageID.C2S_SUBSCRIBE_CHAT, pb.TargetChatChannel.encode(args));

			if (result.errcode == 0) {
				this._channelChatlets.remove(channel);
				let reply = pb.ChatList.decode(result.payload);
				reply.Chatlets.forEach(pbChatlet => {
					this.addChannelChatlet(channel, <pb.Chatlet>pbChatlet);
				});
				return true;
			} else {
				return false;
			}
		}

		public async unsubscribeChat(channel: number) {
			let args = {Channel: channel};
			let result = await Net.rpcCall(pb.MessageID.C2S_UNSUBSCRIBE_CHAT, pb.TargetChatChannel.encode(args));
			if (result.errcode == 0) {
				this._channelChatlets.remove(channel);
				return true;
			} else {
				return false;
			}
		}

		public async sendChat(channel: number, msg: string): Promise<boolean> {
			if (channel == ChatChannel.WORLD) {
				if (Date.now() / 1000 - this._lastWorldSendTime < this._WORLD_CHAT_CD) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60219));
					return false;
				}
			}
			let args = {Channel: channel, Msg: msg};
			let result = await Net.rpcCall(pb.MessageID.C2S_SEND_CHAT, pb.SendChatArg.encode(args));
			if (result.errcode == 0) {
				/*
				let info: any[] = [
					`${Player.inst.uid}`, 
					Player.inst.name,
					Player.inst.avatarUrl,
					`${Date.now()/1000}`,
					msg
				];
				return this._doAddWorldChatlet(info);
				*/
				if (channel == ChatChannel.WORLD) {
					this._lastWorldSendTime = Date.now() / 1000;
				}
				return true;
			} else {
				if (result.errcode == 101) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60208));
				} else if (result.errcode == 1) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60123));
				} else {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60077));
				}
				return false;
			}
		}

		public async sendPrivateChat(uid: Long, name: string, headUrl: string, msg: string): Promise<Array<PrivateChatlet>> {
			let args = {ToUid: uid, Msg: msg};
			let result = await Net.rpcCall(pb.MessageID.C2S_SEND_PRIVATE_CHAT, pb.SendPrivateChatArg.encode(args));
			if (result.errcode == 0) {
				let info: any[] = [
					`${Player.inst.uid}`,
					Player.inst.name,
					Player.inst.avatarUrl,
					`${Date.now()/1000}`,
					msg,
					-1,
					name,
					headUrl,
					Pvp.PvpMgr.inst.getPvpLevel(),
					Player.inst.frameID,
				];
				let infos = [];
				infos.push(info);
				return this._doAddPrivateChatlets(uid, infos);
			} else {
				if (result.errcode == 101) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60208));
				}
				return null;
			}
		}

		public static secToChatDate(sec: number): string {
            let date = new Date(sec * 1000);
            let year = date.getFullYear();
            let month = date.getMonth() + 1;
            let day = date.getDate();
			let weekday = date.getDay();
            let hour = date.getHours();
            let minutes = date.getMinutes();

            let now = new Date();
			let nowYear = now.getFullYear();
			let nowMonth = now.getMonth() + 1;
			let nowDay = now.getDate();
			let nowWeekday = now.getDay();

			function assembleTime(h: number, m: number): string {
				function formatNum(n: number): string {
					if (n < 10) {
						return `0${n}`;
					} else {
						return `${n}`;
					}
				}
				if (h == 0) {
					return Core.StringUtils.TEXT(60031)+`00:${formatNum(m)}`;
				} else if (h < 12) {
					return `${formatNum(h)}:${formatNum(m)}`;
				} else if (h == 12) {
					return `${formatNum(h)}:${formatNum(m)}`;
				} else {
					return `${formatNum(h)}:${formatNum(m)}`;
				}
			}

			function weekDayToStr(wd: number) {
				if (LanguageMgr.inst.isChineseLocale()) {
					return Core.StringUtils.TEXT(60026) + "天一二三四五六".charAt(wd);
				} else {
					return ["Sun", "Mon.", "Tues.", "Wed.", "Thur.", "Fri.", "Sat."][wd];
				}
			}

			if (year == nowYear && month == nowMonth && day == nowDay) {
				// 同一天
				return assembleTime(hour, minutes);
			} else if (year == nowYear && month == nowMonth) {
				if (nowDay - day == 1) {
					// 一天前
					return Core.StringUtils.TEXT(60033)+`${assembleTime(hour, minutes)}`;
				} else {
					if (nowWeekday > weekday && nowDay - day < 7) {
						// 同一周
						return `${weekDayToStr(weekday)} ${assembleTime(hour, minutes)}`;
					} else {
						return `${year}`+Core.StringUtils.TEXT(60015)+`${month}`+Core.StringUtils.TEXT(60004)+`${day}`+Core.StringUtils.TEXT(60012)+` ${assembleTime(hour, minutes)}`;
					}
				}
			} else {
				return `${year}`+Core.StringUtils.TEXT(60015)+`${month}`+Core.StringUtils.TEXT(60004)+`${day}`+Core.StringUtils.TEXT(60012)+` ${assembleTime(hour, minutes)}`;
			}
        }
	}
}