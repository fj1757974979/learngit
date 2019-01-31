module WXGame {

	export class WXShareType {
		public static SHARE_FIGHT = 1;	// 约战(done)
		public static SHARE_INVITE = 2;	// 邀请(done)
		public static SHARE_TREASURE = 3;	// 宝箱加速(done)
		public static SHARE_REWARD = 4;	// 限定宝箱(done)
		public static SHARE_GRP_RANK = 5;	// 群排行(done)
		public static SHARE_PREVENT_LOSE = 6; // 战斗失败防止调星(done)
		public static SHARE_VEDIO = 7; // 分享录像(done)
		public static SHARE_SHOWOFF_TREASURE = 8;	// 宝箱炫耀(done)
		public static SHARE_DAILY_REWARD_DOUBLE = 9; // 每日宝箱翻倍(done)
		public static SHARE_GAME = 10; // 分享游戏(done)
		public static SHARE_LEVEL_HELP = 11; // 关卡求助分享
		public static SHARE_FREE_GOLD = 12; // 免费金币
		public static SHARE_FREE_JADE = 13; // 免费宝玉
		public static SHARE_FREE_TREASURE = 14; // 免费宝箱
		public static SHARE_UP_TREASURE = 15; // 宝箱升级
		public static SHARE_TREASURE_ADD_CARD = 16; // 宝箱加卡
		public static SHARE_DAILY_JADE = 17; // 微信每日分享得宝玉
	}

	export class WXShareMgr {

		private static _inst: WXShareMgr = null;

		public static get inst():WXShareMgr {
			if (!WXShareMgr._inst) {
				WXShareMgr._inst = new WXShareMgr();
			}
			return WXShareMgr._inst;
		}

		private _shareType2IDS: Collection.Dictionary<number, Array<number>>;
		private _shareTreasureId: number;

		public constructor() {
			this._shareType2IDS = new Collection.Dictionary<number, Array<number>>();
			let shareIds = Data.share_config.keys;
			shareIds.forEach(shareId => {
				let conf = Data.share_config.get(shareId);
				let type = conf.type;
				if (!this._shareType2IDS.containsKey(type)) {
					this._shareType2IDS.setValue(type, []);
				}
				let ids = this._shareType2IDS.getValue(type);
				ids.push(shareId);
			});
		}

		public get shareTreasureId(): number {
			return this._shareTreasureId;
		}
		
		public set shareTreasureId(treasureId: number) {
			this._shareTreasureId = treasureId;
		}

		private _filterText(content: string, from: string, to: string) {
			if (content.indexOf(from) >= 0) {
				return content.replace(from, to);
			} else {
				return content;
			}
		}

		private _randomShareId(type: number) {
			let ids = this._shareType2IDS.getValue(type);
			if (ids) {
				return ids[Core.RandomUtils.randInt(ids.length)];
			} else {
				return -1;
			}
		}

		private _getShareTitle(shareId: number) {
			let conf = Data.share_config.get(shareId);
			if (conf) {
				return this._filterText(conf.text, "NAME", Player.inst.nameWithNoColor);
			} else {
				return "";
			}
		}

		private _getShareImageUrl(shareId: number) {
			let conf = Data.share_config.get(shareId);
			if (conf) {
				let imageName = conf.img;
				return `${WXGameMgr.getWebClientHost()}/resource/king_ui/assets/society/${imageName}?${Date.now()}`;
			} else {
				return "";
			}
		}

		public async enableShareMenu(b: boolean) {
			let act = WXShareType.SHARE_GAME;
			let shareId = this._randomShareId(act);
			let title = this._getShareTitle(shareId);
			let image = this._getShareImageUrl(shareId);
			let query = WXGameMgr.inst.getBaseWXShareQuery() + `&act=${act}&shareId=${shareId}`;
			await sharePlatform.enableShareMenu(true, title, image, query);
		}

		/**
		 * 邀请分享（关联邀请奖励玩法，所有的分享都额外附带分享者参数）
		 */
		public wechatInvite() {
			let act = WXShareType.SHARE_INVITE;
			let shareId = this._randomShareId(act);
			let title = this._getShareTitle(shareId);
			let imageUrl = this._getShareImageUrl(shareId);
			let query = WXGameMgr.inst.getBaseWXShareQuery() + `&act=${act}&shareId=${shareId}`;
			WXGameMgr.inst.shareAppMessage(title, imageUrl, query, act, shareId);
		}

		/**
		 * 约战分享
		 */
		public wechatFight() {
			let act = WXShareType.SHARE_FIGHT;
			let shareId = this._randomShareId(act);
			let title = this._getShareTitle(shareId);
			let imageUrl = this._getShareImageUrl(shareId);
			let query = WXGameMgr.inst.getBaseWXShareQuery() + `&act=${act}&shareId=${shareId}`;
			WXGameMgr.inst.shareAppMessage(title, imageUrl, query, act, shareId);
		}

		/**
		 * 群排名分享
		 */
		public wechatGrpRank() {
			let act = WXShareType.SHARE_GRP_RANK;
			let shareId = this._randomShareId(act);
			let title = this._getShareTitle(shareId);
			let imageUrl = this._getShareImageUrl(shareId);
			let query = WXGameMgr.inst.getBaseWXShareQuery() + `&act=${act}&shareId=${shareId}`;
			WXGameMgr.inst.shareAppMessage(title, imageUrl, query, act, shareId);
		}

		/**
		 * 获得奖励分享（关联宝箱系统）
		 */
		public wechatShowOffTreasure(cardName: string) {
			let act = WXShareType.SHARE_SHOWOFF_TREASURE;
			let shareId = this._randomShareId(act);
			let title = this._filterText(this._getShareTitle(shareId), "CARD", cardName);
			let imageUrl = this._getShareImageUrl(shareId);
			let query = WXGameMgr.inst.getBaseWXShareQuery() + `&act=${act}&shareId=${shareId}`;
			WXGameMgr.inst.shareAppMessage(title, imageUrl, query, act, shareId);
		}

		/**
		 * 获得奖励+赠送分享（在上一个基础上再深化）
		 */
		public wechatShareReward(hid: number) {
			let act = WXShareType.SHARE_REWARD;
			let shareId = this._randomShareId(act);
			let title = this._getShareTitle(shareId);
			let imageUrl = this._getShareImageUrl(shareId);
			let query = WXGameMgr.inst.getBaseWXShareQuery() + `&hid=${hid}&act=${act}&shareId=${shareId}`;
			WXGameMgr.inst.shareAppMessage(title, imageUrl, query, act, shareId);
		}

		/**
		 * （广告功能替代）对战宝箱分享加速
		 */
		public wechatShareTreasure(treasureId: number) {
			this.shareTreasureId = treasureId;
			let act = WXShareType.SHARE_TREASURE;
			let shareId = this._randomShareId(act);
			let title = this._getShareTitle(shareId);
			let imageUrl = this._getShareImageUrl(shareId);
			let query = WXGameMgr.inst.getBaseWXShareQuery() + `&treasureId=${treasureId}&act=${act}&shareId=${shareId}`;
			WXGameMgr.inst.shareAppMessage(title, imageUrl, query, act, shareId);
		}

		/**
		 * （广告功能替代）每日宝箱分享
		 */
		public wechatShareDailyTreasure(treasureId: number) {
			this.shareTreasureId = treasureId;
			let act = WXShareType.SHARE_DAILY_REWARD_DOUBLE;
			let shareId = this._randomShareId(act);
			let title = this._getShareTitle(shareId);
			let imageUrl = this._getShareImageUrl(shareId);
			let query = WXGameMgr.inst.getBaseWXShareQuery() + `&treasureId=${treasureId}&act=${act}&shareId=${shareId}`;
			WXGameMgr.inst.shareAppMessage(title, imageUrl, query, act, shareId);
		}

		/**
		 * 战斗结算分享（录像系统已做：指定播放录像ID）
		 */
		public async wechatShareBattleVideo(battleId: Long,videoTitle:string,url:any) {
			let act = WXShareType.SHARE_VEDIO;
			let shareId = this._randomShareId(act);
			let title;
			let imageUrl;
			if (videoTitle == null)
			{
				title = this._getShareTitle(shareId);
				if(url == null)
				{
					imageUrl = this._getShareImageUrl(shareId);
				}
			}
			else{
				title = videoTitle;
				if(url)
				{
					imageUrl = url;
				}
				else{
					imageUrl = this._getShareImageUrl(shareId);
				}
			}
			let query = WXGameMgr.inst.getBaseWXShareQuery() + `&battleId=${battleId}&act=${act}&shareId=${shareId}`;
			WXGameMgr.inst.shareAppMessage(title, imageUrl, query, act, shareId);
		}

		/**
		 * （广告功能替代）战斗失败分享
		 */

		public wechatSharePreventLoseStar() {
			let act = WXShareType.SHARE_PREVENT_LOSE;
			let shareId = this._randomShareId(act);
			let title = this._getShareTitle(shareId);
			let imageUrl = this._getShareImageUrl(shareId);
			let query = WXGameMgr.inst.getBaseWXShareQuery() + `&act=${act}&shareId=${shareId}`;
			WXGameMgr.inst.shareAppMessage(title, imageUrl, query, act, shareId);
		}

		public async cancelPreventLoseStar() {
			let result = await Net.rpcCall(pb.MessageID.C2S_END_SHARE_BATTLE_LOSE, null);
			if (result.errcode == 0) {
				console.log("cancelPreventLoseStar success");
			}
		}

		/**
		 * （关卡求助分享）
		 */
		public wechatShareLevelHelp(levelId: number,url:any) {
			let act = WXShareType.SHARE_LEVEL_HELP;
			let shareId = this._randomShareId(act);
			let title = this._getShareTitle(shareId);
			let imageUrl;
			let levelObj = Level.LevelMgr.inst.getLevel(levelId);
			if (levelObj) {
				let name = levelObj.name;
				title = this._filterText(title, "LEVEL", name);
			}
			// let imageUrl = this._getShareImageUrl(shareId);
			if(url){
				console.log("brucelog","url true")
				imageUrl = url;
			}
			else{
				console.log("brucelog","url false")
				imageUrl = this._getShareImageUrl(shareId);
			}
			let timeStamp = Math.floor(Date.now() / 1000);
			let query = WXGameMgr.inst.getBaseWXShareQuery() + `&time=${timeStamp}&levelId=${levelId}&act=${act}&shareId=${shareId}`;
			WXGameMgr.inst.shareAppMessage(title, imageUrl, query, act, shareId);
		}

		/**
		 *  金币赞助分享（类型12，提示：要为<玩家名>集赞获得免费礼品吗？<赞><踩>。响应：你点了个赞，对方获得了免费的商城礼品！
		 *  宝玉赞助分享（类型13，提示：要为<玩家名>集赞获得免费礼品吗？<赞><踩>。响应：你点了个赞，对方获得了免费的商城礼品！
		 *  宝箱赞助分享（类型14，提示：要为<玩家名>集赞获得免费礼品吗？<赞><踩>。响应：你点了个赞，对方获得了免费的商城礼品！
		 */
		public wechatShareFreeItem(freeId: number, freeType: number, shareType: WXShareType) {
			console.log("wechatShareFreeItem", freeId, freeType);
			let act = <number>shareType; //WXShareType.SHARE_FREE_GOLD;
			let shareId = this._randomShareId(act);
			let title = this._getShareTitle(shareId);
			let imageUrl = this._getShareImageUrl(shareId);
			let query = WXGameMgr.inst.getBaseWXShareQuery() + `&act=${act}&shareId=${shareId}&freeId=${freeId}&freeType=${freeType}&name=${Player.inst.name}`;
			let args = {
				Type: freeType,
				ID: freeId
			};
			let data = pb.WatchShopFreeAdsArg.encode(args).finish();
			WXGameMgr.inst.shareAppMessage(title, imageUrl, query, act, shareId, data);
			return shareId;
		}

		/**
		 *  宝箱升级分享，类型15，提示：要帮助<玩家名>升级宝箱吗？<升级><算了>。响应：已帮助对方宝箱升级。
		 */
		public wechatShareUpTreasure() {
			let act = WXShareType.SHARE_UP_TREASURE;
			let shareId = this._randomShareId(act);
			let title = this._getShareTitle(shareId);
			let imageUrl = this._getShareImageUrl(shareId);
			let query = WXGameMgr.inst.getBaseWXShareQuery() + `&act=${act}&shareId=${shareId}`;
			WXGameMgr.inst.shareAppMessage(title, imageUrl, query, act, shareId);
			return shareId;
		}

		/**
		 *  宝箱卡牌分享，类型16，提示：要助力<玩家名>获得更多卡牌吗？<助力><算了>。响应：对方已获得你的助力，可以开到更多的卡牌。
		 */
		public wechatShareAddTreasureCard(treasureId: number) {
			let act = WXShareType.SHARE_TREASURE_ADD_CARD;
			let shareId = this._randomShareId(act);
			let title = this._getShareTitle(shareId);
			let imageUrl = this._getShareImageUrl(shareId);
			let query = WXGameMgr.inst.getBaseWXShareQuery() + `&act=${act}&shareId=${shareId}&treasureId=${treasureId}`;
			let args = {
				TreasureID: treasureId
			};
			let data = pb.TargetTreasure.encode(args).finish();
			WXGameMgr.inst.shareAppMessage(title, imageUrl, query, act, shareId, data);
			return shareId;
		}
		/**
		 * 微信每日分享好友得宝玉，类型17
		 */
		public wechatShareDailyJade() {
			let act = WXShareType.SHARE_DAILY_JADE;
			let shareId = this._randomShareId(act);
			let title = this._getShareTitle(shareId);
			let imageUrl = this._getShareImageUrl(shareId);
			let time = Math.floor(Date.now()/1000);
			let query = WXGameMgr.inst.getBaseWXShareQuery() + `&act=${act}&shareId=${shareId}&time=${time}`;
			WXGameMgr.inst.shareAppMessage(title, imageUrl, query, act, shareId);
		}

		public shareBeHelped(arg: pb.WxShareBeHelpArg) {
			console.log("=++++++++++ shareBeHelped");
			let act = arg.ShareType;
			if (act == WXShareType.SHARE_FREE_GOLD || 
				act == WXShareType.SHARE_FREE_JADE ||
				act == WXShareType.SHARE_FREE_TREASURE) {
				// let shopView = <Shop.ShopView>Core.ViewManager.inst.getView(ViewName.shopView);
				// if (shopView && shopView.isShow()) {
				// 	let data = pb.WatchShopFreeAdsArg.decode(arg.Data);
				// 	shopView.updateFreeItemCanGetState(data.ID, data.Type);
				// }
				// let name = "";
				// if (act == WXShareType.SHARE_FREE_GOLD) {
				// 	name = "金币";
				// } else if (act == WXShareType.SHARE_FREE_JADE) {
				// 	name = "宝玉";
				// } else {
				// 	name = "宝箱";
				// }
				// Core.TipsUtils.showTipsFromCenter(`你得到了好友的帮助，可以领取免费#cg${name}#n啦`);
			} else if (act == WXShareType.SHARE_UP_TREASURE) {
				let upview = <Battle.AdvertUpTreasureWnd>Core.ViewManager.inst.getView(ViewName.advertUpTreasureWnd);
				if (upview && upview.isShow()) {
					Core.ViewManager.inst.close(ViewName.advertUpTreasureWnd);
				}
				let data = pb.Treasure.decode(arg.Data);
				Core.EventCenter.inst.dispatchEventWith(GameEvent.UpTreasureRareEv, false, data);
				Core.TipsUtils.showTipsFromCenter("你得到了好友的帮助，宝箱变得更棒啦！");
			} else if (act == WXShareType.SHARE_TREASURE_ADD_CARD) {
				let data = pb.WatchTreasureAddCardAdsReply.decode(arg.Data);
				Core.EventCenter.inst.dispatchEventWith(GameEvent.AddTreasureCardEv, false, data);
				Core.TipsUtils.showTipsFromCenter("你得到了好友的帮助，宝箱打开了更多的卡牌");
			} else if (act == WXShareType.SHARE_DAILY_JADE) {
				let data = pb.WxShareAddJadeReply.decode(arg.Data);
				Player.inst.isIOSShared = true;
				Core.EventCenter.inst.dispatchEventWith(GameEvent.ShareIOSOK, false, true);
				Core.TipsUtils.showTipsFromCenter(`${data.PlayerName}已通过你的分享进入游戏，恭喜你获得${data.Jade}宝玉`);
			}
		}

		public async cancelCurShare() {
			let args = {
				ShareID: WXGameMgr.inst.curShareId,
				ShareType: <number>WXGameMgr.inst.curShareType
			};
			Net.rpcCall(pb.MessageID.C2S_CANCEL_WX_SHARE, pb.CancelWxShareArg.encode(args));
		}

		public get shareDelayOpTime() {
			return 3000;
		}
	}
}