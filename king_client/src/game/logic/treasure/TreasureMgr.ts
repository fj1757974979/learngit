// 宝箱管理
module Treasure {
	
	export class TreasureMgr {
		private static _inst: TreasureMgr = null;
		private _treasureItems: Collection.Dictionary<number, TreasureItem>;
		private _dailyTreasureItem: DailyTreasureItem;
		private _curActivatingTreasure: TreasureItem;

		public constructor() {
			this.initData();
		}

		public static inst(): TreasureMgr {
			if (!TreasureMgr._inst) {
				TreasureMgr._inst = new TreasureMgr();
			}
			return TreasureMgr._inst;
		}

		public initData() {
			this._treasureItems = new Collection.Dictionary<number, TreasureItem>();
			this._dailyTreasureItem = null;
			this._curActivatingTreasure = null;
		}

		public get curActivatingTreasure(): TreasureItem {
			return this._curActivatingTreasure;
		}


		private _fireEvent(evType: string, item: TreasureItem, isInit: boolean = false) {
			let ev = new TreasureEvent(evType);
			ev.treasureItem = item;
			ev.isInit = isInit;
			Core.EventCenter.inst.dispatchEvent(ev);
		}

		public addTreasure(item: TreasureItem, isInit: boolean = false): boolean {
			this._treasureItems.setValue(item.id, item);
			this._fireEvent(Core.Event.AddTreasureEvt, item, isInit);
			if (item.isActivating()) {
				this._curActivatingTreasure = item;
			}
			return true;
		}

		public updateDailyTreasureWithData(dailyTreasureData: pb.DailyTreasure) {
			let dailyTreasureItem = new DailyTreasureItem(dailyTreasureData.ID, dailyTreasureData.ModelID);
			dailyTreasureItem.isOpen = dailyTreasureData.IsOpen;
			dailyTreasureItem.nextTime = dailyTreasureData.NextTime;
			dailyTreasureItem.openStarCount = dailyTreasureData.OpenStarCount;
			dailyTreasureItem.isDouble = dailyTreasureData.IsDouble;
			this._dailyTreasureItem = dailyTreasureItem;
			this._fireEvent(Core.Event.UpdateDailyTreasureEvt, dailyTreasureItem);
			return true;
		}

		public addTreasureWithData(treasureData: any, isInit: boolean = false): TreasureItem {
			let treasureItem = new TreasureItem(treasureData.ID, treasureData.ModelID);
			treasureItem.pos = treasureData.Pos;
			treasureItem.openTime = treasureData.OpenTimeout;
			treasureItem.isEffectByPrivilege = true;
			if (this.addTreasure(treasureItem, isInit)) {
				return treasureItem;
			} else {
				return null;
			}
		}

		public popTreasure(id: number): TreasureItem {
			let treasure = this._treasureItems.getValue(id);
			if (treasure) {
				this._fireEvent(Core.Event.DelTreasureEvt, treasure);	
				this._treasureItems.remove(id);
				this._fireEvent(Core.Event.UpdateTreasureEvt,null);
			} 
			return treasure;
		}

		public getTreasure(id: number): TreasureItem {
			if (this._treasureItems.containsKey(id)) {
				return this._treasureItems.getValue(id);
			} else {
				return null;
			}
		}

		public getDailyTreasure(): DailyTreasureItem {
			return this._dailyTreasureItem;
		}

		public onTreasureCountDownDone(item: TreasureItem) {
			this._treasureItems.forEach((_key,_treasure) => {
				if (_treasure.canActivate) {
					return;
				}
			});
			this._curActivatingTreasure = null;
		}

		//检查各个宝箱状态并重置_curActivatingTreasure
		//在matchview对所有宝箱refresh后调用
		public resCurActivatingTreasure() {
			this._curActivatingTreasure = null;
			this._treasureItems.forEach((_key,_treasure) => {
				if (_treasure.isActivating()) {
					this._curActivatingTreasure = _treasure;
				}
			});
		}

		public async openTreasure(id: number) {
			let result = await Net.rpcCall(pb.MessageID.C2S_OPEN_TREASURE, pb.OpenTreasureArg.encode({"TreasureID":id}));
			if (result.errcode != 0) {
				return null;
			}

			let reply = pb.OpenTreasureReply.decode(result.payload);
			if (!reply.OK) {
				return null;
			}
			
			let reward = new TreasureReward();
			reward.setRewardForOpenReply(reply);
			if (reply.CanWatchAddCardAds) {
				await new Promise<void>(resolve => {
					Core.ViewManager.inst.open(ViewName.advertAddTreasureCardWnd, id, async (ok: boolean, jade: boolean, cnt: number = 0) => {
						if (ok) {
							let args = {
								TreasureID: id,
								IsConsumeJade: jade
							}
							let result = await Net.rpcCall(pb.MessageID.C2S_WATCH_TREASURE_ADD_CARD_ADS, pb.WatchTreasureAddCardAdsArg.encode(args));
							if (result.errcode == 0) {
								let reply = pb.WatchTreasureAddCardAdsReply.decode(result.payload);
								reward.addAllCardByAmount(reply.AddCardAmount);
							}
						} else if (cnt > 0) {
							reward.addAllCardByAmount(cnt);
						} 
						resolve();
					});
				});
				// if (Core.DeviceUtils.isWXGame()) {
				// 	await new Promise<void>(resolve => {
				// 		Core.ViewManager.inst.open(ViewName.advertAddTreasureCardWnd, id, async (cnt: number, jade: boolean) => {
				// 			if (jade) {
				// 				let args = {
				// 					TreasureID: id,
				// 					IsConsumeJade: true
				// 				}
				// 				let result = await Net.rpcCall(pb.MessageID.C2S_WATCH_TREASURE_ADD_CARD_ADS, pb.WatchTreasureAddCardAdsArg.encode(args));
				// 				if (result.errcode == 0) {
				// 					let reply = pb.WatchTreasureAddCardAdsReply.decode(result.payload);
				// 					reward.addAllCardByAmount(reply.AddCardAmount);
				// 				}
				// 			} else {
				// 				if (cnt > 0) {
				// 					reward.addAllCardByAmount(cnt);
				// 				}
				// 			}
				// 			resolve();
				// 		});
				// 	});
				// } else if (adsPlatform.isAdsOpen()) {
				// 	await new Promise<void>(resolve => {
				// 		Core.ViewManager.inst.open(ViewName.advertAddTreasureCardWnd, id, async (b: boolean, jade: boolean) => {
				// 			if (b) {
				// 				let args = {
				// 					TreasureID: id,
				// 					IsConsumeJade: jade
				// 				}
				// 				let result = await Net.rpcCall(pb.MessageID.C2S_WATCH_TREASURE_ADD_CARD_ADS, pb.WatchTreasureAddCardAdsArg.encode(args));
				// 				if (result.errcode == 0) {
				// 					let reply = pb.WatchTreasureAddCardAdsReply.decode(result.payload);
				// 					reward.addAllCardByAmount(reply.AddCardAmount);
				// 				}
				// 			}
				// 			resolve();
				// 		});
				// 	});
				// }
			}
			return reward;
		}

		public async activateTreasure(id: number) {
			if (this._curActivatingTreasure) {
				return false;
			}
			let result = await Net.rpcCall(pb.MessageID.C2S_ACTIVATE_REWARD_TREASURE, 
				pb.ActivateRewardTreasureArg.encode({"TreasureID": id}));
			if (result.errcode != 0) {
				return false;
			}	

			let reply = pb.ActivateRewardTreasureReply.decode(result.payload);
			let ok = reply.OK;
			if (ok) {
				let treasureItem = this.getTreasure(id);
				if (treasureItem) {
					treasureItem.openTime = reply.OpenTimeout;
					this._curActivatingTreasure = treasureItem;
				}
			}
			return ok;
		}

		public async fetchTreasures(rtype: number) {
			let result = await Net.rpcCall(pb.MessageID.C2S_GET_TREASURES, null);
			let ret: Array<TreasureItem> = [];
			if (result.errcode != 0) {
				return ret;
			}

			let reply = pb.GetTreasuresReply.decode(result.payload);
			reply.Treasures.forEach(treasureData => {
				let treasureItem = this.addTreasureWithData(treasureData, true);
				if (treasureItem) {
					ret.push(treasureItem);
				}
			});
			let dailyData = reply.DailyTreasure1;
			if (dailyData) {
				this.updateDailyTreasureWithData(<pb.DailyTreasure>dailyData);
			}
			return ret;
		}

		private _onLogout() {
			try {
				this.initData();
			} catch (e) {
				console.error(e);
			}
		}
	}

	function onLogout() {
		try {
			TreasureMgr.inst().initData();
		} catch (e) {
			console.error(e);
		}
	}

	export function init() {
		initRpc();
		Player.inst.addEventListener(Player.LogoutEvt, onLogout, null);


        let registerView = Core.ViewManager.inst.registerView.bind(Core.ViewManager.inst);
        let createObject = fairygui.UIPackage.createObject;

        registerView(ViewName.treasureInfo, ()=> {
			let treasureInfoWnd = new TreasureInfoWnd();
        	treasureInfoWnd.contentPane = createObject(PkgName.treasure, ViewName.treasureInfo).asCom;
			return treasureInfoWnd;
		});

		registerView(ViewName.treasureReview, ()=> {
			let treasureInfoWnd = new TreasureInfoReviewWnd();
        	treasureInfoWnd.contentPane = createObject(PkgName.treasure, ViewName.treasureReview).asCom;
			return treasureInfoWnd;
		});

        registerView(ViewName.dailyTreasureInfo, () => {
			let dailyTreasureInfoWnd = new DailyTreasureInfoWnd();
        	dailyTreasureInfoWnd.contentPane = createObject(PkgName.pvp, ViewName.dailyTreasureInfo).asCom;
			return dailyTreasureInfoWnd;
		});
	
        registerView(ViewName.dailyTreasureDouble, () => {
			let dailyTreasureDoubleWnd = new DailyTreasureDoubleWnd();
        	dailyTreasureDoubleWnd.contentPane = createObject(PkgName.pvp, ViewName.dailyTreasureDouble).asCom;
			return dailyTreasureDoubleWnd;
		});

		registerView(ViewName.treasureRewardInfo, () => {
			return createObject(PkgName.treasure, ViewName.treasureRewardInfo, TreasureRewardView).asCom;
		});

		registerView(ViewName.treasureRewardResult, () => {
			return createObject(PkgName.treasure, ViewName.treasureRewardResult, TreasureRewardResultView).asCom;
		});

        registerView(ViewName.advertAddTreasureCardWnd, () => {
			let advertAddTreasureWnd = new AdvertAddTreasureCardWnd();
        	advertAddTreasureWnd.contentPane = createObject(PkgName.common, ViewName.advertAddTreasureCardWnd).asCom;
			return advertAddTreasureWnd;
		});

	}
}