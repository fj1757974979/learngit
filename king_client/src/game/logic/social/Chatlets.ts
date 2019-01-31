// TypeScript file
module Social {
    export class ChatChannel {
		public static WORLD = pb.ChatChannel.World;
		public static CampaignCountry = pb.ChatChannel.CampaignCountry;
		public static PRIVATE = ChatChannel.CampaignCountry + 1;
	}

    export class ChatType {
        public static Normal = 0;
        public static CampaignNotice = 1;
    }

    export interface IChatlet {
        uid: Long;
        name: string;
        headUrl: string;
        timeStamp: number;
        msg: string;
        id: number;
        fromName: string;
        fromHeadUrl: string;
        frameUrl: string;
        pvpLevel: number;
        isMyselfChat(): boolean;
        type: ChatType;
    }

	export class PrivateChatlet implements IChatlet {
		private _data: any[];
		private _channel: number;

		public constructor(channel:number, data: any[]) {
			this._data = data;
			this._channel = channel;
		}

		public get uid(): Long {
			return <Long>this._data[0];
		}

		public get name(): string {
			if (this._channel != ChatChannel.CampaignCountry) {
				return this._data[1];
			} else {
				let name = "";
				if (this._data[9] != pb.CampaignJob.UnknowJob) {
					name = `【${Utils.job2Text(this._data[9])}】`;
				}
				name += `【${this._data[7]}`;
				if (this._data[8] != pb.CampaignJob.UnknowJob) {
					name += `${Utils.job2Text(this._data[8])}】`;
				} else {
					name += "】";
				}
				return name + this._data[1];
			}
		}

		public get headUrl(): string {
			return this._data[2];
			// return "society_headicon1_png"
		}

		public get timeStamp(): number {
			return parseInt(this._data[3]);
		}

		public get msg(): string {
			return this._data[4];
		}

		public get id(): number {
			return this._data[5];
		}

		public get fromName(): string {
			if (this._channel == ChatChannel.PRIVATE) {
				return this._data[6];
			} else {
				return "";
			}
		}
		public set fromName(n: string) {
			if (this._channel == ChatChannel.PRIVATE) {
				this._data[6] = n;
			}
		}

		public get fromHeadUrl(): string {
			return this._data[7] || "";
			// return "society_headicon1_png";
		}
		public set fromHeadUrl(url: string) {
			if (this._channel == ChatChannel.PRIVATE) {
				this._data[7] = url;
			}
		}
		public get pvpLevel(): number {
			if (this._channel != ChatChannel.PRIVATE) {
				return this._data[5] || 1;
			} else {
				return this._data[8] || 1;
			}
			
		}
		public set frameUrl(url: string) {
			if (this._channel != ChatChannel.PRIVATE) {
				this._data[6] = url;
			} else {
				this._data[9] = url;
			}
		}

		public get frameUrl(): string {
			let frameID = "";
			if (this._channel != ChatChannel.PRIVATE) {
				frameID = this._data[6];
			} else {
				frameID = this._data[9];
			}
			if (!frameID || frameID == "" || frameID == undefined) {
				frameID = "1";
			}
			return frameID;
		}

		public isMyselfChat(): boolean {
			return this.uid == Player.inst.uid;
		}

        public get type(): ChatType {
            return ChatType.Normal;
        }
	}

	export class ChannelMessageChatlet implements IChatlet {
		private _data: pb.ChatItem;
		private _channel: number;

        public constructor(channel: number, pbData: pb.Chatlet) {
			this._channel = channel;
			this.parseData(pbData.Data);
		}

		protected parseData(data: any) {
			this._data = pb.ChatItem.decode(data);
		}

        public isMyselfChat(): boolean {
            return this._data.Uid == Player.inst.uid;
        }

        public get timeStamp(): number {
            return this._data.Time;
        }

        public get uid(): Long {
            return <Long>this._data.Uid;
        }

        public get name(): string {
			if (this._channel == ChatChannel.CampaignCountry) {
				let name = "";
				if (this._data.CountryJob != pb.CampaignJob.UnknowJob) {
					name = `${Utils.job2Color(this._data.CountryJob)}【${Utils.job2Text(this._data.CountryJob)}】#n`;
				}
				let city = War.CityMgr.inst.getCity(this._data.CityID);
				let cityName = "";
				if (city) {
					cityName = `【${city.cityName}`;
				}
				if (this._data.CityJob != pb.CampaignJob.UnknowJob) {
					name = name + Utils.job2Color(this._data.CityJob) + cityName + `${Utils.job2Text(this._data.CityJob)}】#n`;
				} else {
					name = name + cityName + "】";
				}
				return name + this._data.Name;
			} else {
				return this._data.Name;
			}
        }

        public get headUrl(): string {
            return this._data.HeadImgUrl;
        }

        public get msg(): string {
            return this._data.Msg;
        }

        public get id(): number {
            return 0;
        }

        public get fromName(): string {
            return this.name;
        }

        public get fromHeadUrl(): string {
            return this.headUrl;
        }

        public get frameUrl(): string {
            return this._data.HeadFrame;
        }

        public get pvpLevel(): number {
            return this._data.PvpLevel;
        }

        public get type(): ChatType {
            return ChatType.Normal;
        }

		public get country(): string {
			return this._data.Country;
		}
	}

	export class CampaignNoticeChatlet implements IChatlet{
		private _data: pb.CampaignNotice;
        private _noticeData: War.NoticeData;
		private _channel: number;

        public constructor(channel: number, pbData: pb.Chatlet) {
			this._channel = channel;
			this.parseData(pbData.Data);
		}

		protected parseData(data: any) {
			this._data = pb.CampaignNotice.decode(data);
            this._noticeData = new War.NoticeData(this._data);
		}

        public getNoticeRawData(): pb.CampaignNotice {
            return this._data;
        }

        public get timeStamp(): number {
            return this._data.Time;
        }

        public get uid(): Long {
            return null;
        }

        public get name(): string {
            return this._noticeData.title;
        }

        public get headUrl(): string {
            return "";
        }

        public get msg(): string {
            return this._noticeData.content;
        }

        public get id(): number {
            return this._data.ID;
        }

        public get fromName(): string {
            return this.name;
        }

        public get fromHeadUrl(): string {
            return this.headUrl;
        }

        public get frameUrl(): string {
            return "";
        }

        public get pvpLevel(): number {
            return 0;
        }

        public get type(): ChatType {
            return ChatType.CampaignNotice;
        }

        public isMyselfChat(): boolean {
            return false;
        }
	}
}