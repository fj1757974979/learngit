module Huodong {
	export class Huodong {
		protected _type: HuodongType;
		protected _remainTime: number;

		public constructor(proto: pb.HuodongData) {
			this._type = <number>proto.Type;
			this._remainTime = proto.RemainTime;
		}

		public get type(): HuodongType {
			return this._type;
		}
		
		public get remainTime(): number {
			return this._remainTime;
		}
		
		public heartbeat() {
			if (this._remainTime > 0) {
				this._remainTime = Math.max(0, this._remainTime - 1);
			}
		}

		public async onStart() {

		}

		public async onStop() {

		}
	}

	/////////////////////////////////////////////////////////////////////
	// 兑换活动

	export class ExchangeHuodong extends Huodong {
		protected _exchangeData: Collection.Dictionary<number, number>;
		protected _remainExchangeTime: number;
		protected _isDetailInitialized: boolean;

		public constructor(proto: pb.HuodongData) {
			super(proto);
			this._exchangeData = new Collection.Dictionary<number, number>();
			this._remainExchangeTime = proto.RemainExchangeTime;
			this._isDetailInitialized = false;
			this._initExchangeDataFromConf();
		}

		protected _initExchangeDataFromConf() {
			throw Error("not implemented");
		}

		protected _initExchangeDataFromProto(payload: any) {
			throw Error("not implemented");
		}

		public getConf(): any {
			throw Error("not implemented");
		}

		public async getExchangeCnt(goodsId: number) {
			if (!this._isDetailInitialized) {
				await this.getExchangeDetail();
			}
			return this._exchangeData.getValue(goodsId);
		}

		public async onExchange(goodsId: number, cnt: number) {
			let oldCnt = await this.getExchangeCnt(goodsId);
			this._exchangeData.setValue(goodsId, oldCnt + cnt);
		}

		public get remainExchangeTime(): number {
			return this._remainExchangeTime;
		}

		public async getExchangeDetail() {
			if (!this._isDetailInitialized) {
				let args = {
					Type: <number>this.type
				}
				let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_HUODONG_DETAIL, pb.TargetHuodong.encode(args));
				if (result.errcode == 0) {
					let reply = pb.HuodongDetail.decode(result.payload);
					this._initExchangeDataFromProto(reply.Data);
					this._isDetailInitialized = true;
				} else {
					return null;
				}
			}
			return this._exchangeData;
		}

		public heartbeat() {
			super.heartbeat();
			if (this._remainExchangeTime > 0) {
				this._remainExchangeTime = Math.max(0, this._remainExchangeTime - 1);
			}
		}

		public getItemIcon(): string {
			return "";
		}
	}

	// 春节兑换
	export class SpringExchangeHuodong extends ExchangeHuodong {

		public getConf(): any {
			if (window.gameGlobal.channel == "lzd_handjoy") {
				return Data.event_reward_handjoy;
			} else {
				return Data.event_reward;
			}
		}

		protected _initExchangeDataFromConf() {
			let conf = this.getConf();
			conf.keys.forEach(goodsId => {
				this._exchangeData.setValue(goodsId, 0);
			});
		}

		protected _initExchangeDataFromProto(payload: any) {
			let detail = pb.SpringHuodong.decode(payload);
			console.log("===== ", detail);
			detail.ExchangeDatas.forEach(data => {
				this._exchangeData.setValue(data.GoodsID, data.ExchangeCnt);
			});
		}

		public getItemIcon(): string {
			return "common_yanhua_png";
		}

		public async onStart() {
			
		}

		public async onStop() {
			this._remainTime = 0;
			this._remainExchangeTime = 0;
			let view = Core.ViewManager.inst.getView(ViewName.match);
			if (view) {
				let matchView = <Pvp.MatchView>view;
				let entryBtn = matchView.getHudongEntryCom();
				if (entryBtn) {
					entryBtn.visible = false;
				}
			}
		}

		public heartbeat() {
			super.heartbeat();
			if (this._remainTime > 0 || this._remainExchangeTime > 0) {
				let view = Core.ViewManager.inst.getView(ViewName.match);
				if (view) {
					let matchView = <Pvp.MatchView>view;
					let entryBtn = matchView.getHudongEntryCom();
					if (entryBtn) {
						if (Player.inst.isInGuide()) {
							entryBtn.visible = false;
						} else if (this.remainTime > 0) {
							entryBtn.getChild("time").asTextField.text = Core.StringUtils.secToString(this.remainTime, "dhm");
							entryBtn.visible = true;
						} else if (this.remainExchangeTime > 0) {
							entryBtn.getChild("time").asTextField.text = Core.StringUtils.secToString(this._remainExchangeTime, "dhm");
							entryBtn.visible = true;
						}
					}
				}
			}
		}
	}

	/////////////////////////////////////////////////////////////////////

	export function genHuodong(proto: pb.HuodongData) {
		let t = <number>proto.Type;
		if (t == HuodongType.T_SPRING_EXCHANGE) {
			return new SpringExchangeHuodong(proto);
		} else {
			return null;
		}
	}
}