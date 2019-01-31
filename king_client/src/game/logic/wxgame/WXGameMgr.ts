module WXGame {

	export class WXGameMgr {
		private static _inst: WXGameMgr = null;
		private _launchOptions: any;
		private _showOptions: any;
		private _lastHandledOption: any;
		private _isSharing: boolean;
		private _curShareType: WXShareType;
		private _curShareId: number;
		private _curShareData: any;
		private _sessionKey: string;
		private _isInHuoShuWhiteList: boolean;
		private _platform: string;
		private _model: string;

		private _isExamineVersion: boolean;

		private _pt: number; // 推广入口标识码

		private _wxConfig: any;
		private _wxSystemInfo: SystemInfo;
		private _hasAuthorized: boolean; // 是否已授权获取用户信息
		private _avatarForNoAuthUser: string = "avatar_64_png";

		private static _openDataContextBitmap: egret.Bitmap = null;

		private _onShowCallbacks: Array<() => void>;

		private static _prepareLoader: fairygui.GLoader;
		private static _prepareHint: fairygui.GLoader;

		public static get inst(): WXGameMgr {
			if (WXGameMgr._inst == null) {
				WXGameMgr._inst = new WXGameMgr();
			}
			return WXGameMgr._inst;
		}


		public static getWebClientHost(): string {
			// return "https://client.lzd.openew.com/king_war_resource";
			// return `https://ctc-hf.fire233.com/${window.gameGlobal.resPrefix}`;
			return `https://client.lzd2.openew.com/king_war_campaign`;	//v3
			//return "https://192.168.1.213:8888";
			//return `https://client.lzd.openew.com/${window.gameGlobal.resPrefix}`;



			// return `https://client.lzd2.openew.com/${window.gameGlobal.resPrefix}`;

			// return `https://yxasgxfresoure.yoximi.com/${window.gameGlobal.resPrefix}`; //zs
		}

		public static getOpenDataContextBitmap(w: number, h: number) {
			if (!this._openDataContextBitmap) {
				this._openDataContextBitmap = (<any>platform).openDataContext.createDisplayObject(1, w, h);
			}
			return this._openDataContextBitmap;
		}

		public constructor() {
			this._isSharing = false;
			this._sessionKey = "";
			this._isExamineVersion = true;
			this._pt = 1000;
			this._lastHandledOption = null;
			let systemInfo = wx.getSystemInfoSync();
			this._platform = systemInfo.platform;
			this._model = systemInfo.model;
			console.log("++++++++ ", this._platform, systemInfo.model);
			let liuhai:Array<string> = ["iPhone X", "PAR-AL00", "MI 8", 
			"ONEPLUS A6000", "COL-AL10", "EML-AL00", "PACM00", "vivo X21A",
			"vivo Y85A"];
			for (let i=0; i<liuhai.length; i++) {
				if (systemInfo.model.indexOf(liuhai[i]) >= 0) {
					window.support.topMargin = 38;
            		window.support.bottomMargin = 10;
					break;
				}
			}
			this._wxSystemInfo = systemInfo;

			this._onShowCallbacks = [];
		}

		public initLaunchOptEvent() {
			Core.EventCenter.inst.addEventListener("WXGAME_OPTIONS", this._onWXGameOptions, this);
		}

		public initMgr() {
			this._wxConfig = RES.getRes("wxconfig_json");
			Core.EventCenter.inst.addEventListener("WXGAME_ONSHOW", this._onWXGameOnShow, this);
			Core.EventCenter.inst.addEventListener("WXGAME_ONHIDE", this._onWXGameOnHide, this);
			Core.EventCenter.inst.addEventListener(GameEvent.WXInviteBattleResEv, this._onInviteBattleResult, this);
			Player.inst.addEventListener(Player.PvpScoreChangeEvt, () => {
				this.cloudStorePvpData();
			}, this);
		}

		public static async prepareLogin() {
			let imageUrl = "res/logo_yxasg.jpg";
			let texture = await WXGame.WXImageProcessor.loadWXLocalImage(imageUrl);
			if (texture) {
				let bgLoader = new fairygui.GLoader();
				bgLoader.texture = <egret.Texture>texture;
				bgLoader.fill = fairygui.LoaderFillType.ScaleFree;
				bgLoader.autoSize = false;
				let screenW = Core.LayerManager.getDesignWidth();
				let screenH = Core.LayerManager.getDesignHeight();
				let w = bgLoader.texture.$bitmapWidth;
				let h = bgLoader.texture.$bitmapHeight;
				let scaleX = screenW / w;
                let scaleY = screenH / h;
                let scale = scaleX > scaleY ? scaleX: scaleY;
				bgLoader.width = w * scale;
				bgLoader.height = h * scale;
				bgLoader.x = screenW / 2 - bgLoader.width / 2;
				bgLoader.y = screenH / 2 - bgLoader.height / 2;
				Core.LayerManager.inst.mainLayer.addChild(bgLoader);
				if (this._prepareLoader) {
					this._prepareLoader.removeFromParent();
				}
				this._prepareLoader = bgLoader;
			}
		}

		public static afterLogin() {
			if (this._prepareLoader) {
				this._prepareLoader.removeFromParent();
				this._prepareLoader = null;
			}
			if (this._prepareHint) {
				this._prepareHint.removeFromParent();
				this._prepareHint = null;
			}
		}

		public static async duringLogin() {
			let imageUrl = "res/loadingCircle.png";
			let texture = await WXGame.WXImageProcessor.loadWXLocalImage(imageUrl);
			console.log("fuck1");
			if (texture) {
				console.log("fuck3", texture);
				
				let hintLoader = new fairygui.GLoader();
				hintLoader.texture = texture;
				hintLoader.autoSize = true;
				hintLoader.setPivot(0.5, 0.5, true);
				let screenW = Core.LayerManager.getDesignWidth();
				let screenH = Core.LayerManager.getDesignHeight();
				console.log("fuck4", screenW, screenH);
				
				hintLoader.setXY(screenW / 2, screenH / 2);
				Core.LayerManager.inst.maskLayer.addChild(hintLoader);
				hintLoader.addRelation(hintLoader.parent, fairygui.RelationType.Center_Center);
				hintLoader.addRelation(hintLoader.parent, fairygui.RelationType.Middle_Middle);
				if (this._prepareHint) {
					this._prepareHint.removeFromParent();
				}
				this._prepareHint = hintLoader;
				console.log("fuck5", hintLoader.x, hintLoader.y, hintLoader.width, hintLoader.height);

				while (true) {
					await new Promise(resolve => {
						egret.Tween.get(hintLoader).to({rotation:360}, 1000).call(()=>{
							resolve();
						}, this); 
					});
					if (!this._prepareHint) {
						break;
					}
				}

				console.log("fuck6");
			}
		}

		public registerOnShowCallback(callback: () => void) {
			this._onShowCallbacks.push(callback);
		}

		public get lastHandledOption(): any {
			return this._lastHandledOption;
		}

		public get isExamineVersion(): boolean {
			return this._isExamineVersion;
		}

		public set isExamineVersion(b: boolean) {
			this._isExamineVersion = b;
		}

		public get curShareId(): number {
			return this._curShareId;
		}

		public get curShareType(): WXShareType {
			return this._curShareType;
		}

		public get isInHuoshuWhiteList(): boolean {
			return this._isInHuoShuWhiteList;
		}

		public get platform(): string {
			return this._platform;
		}

		public get phoneModel(): string {
			return this._model;
		}

		public get wxConfig(): any {
			return this._wxConfig;
		}

		public get wxSystemInfo(): SystemInfo {
			return this._wxSystemInfo;
		}

		public updateWXUserInfo(nickName: string, avatarUrl: string) {
			console.log("onLogin updateWXUserInfo ", nickName, avatarUrl);
			if (this._shouldOverWriteUserInfo() && avatarUrl != Player.inst.avatarUrl) {
				Player.inst.name = nickName;
				Player.inst.avatarUrl = avatarUrl;
				let args = {
					NickName: Player.inst.name,
					HeadImgUrl: Player.inst.avatarUrl,
				}
				if (Player.inst.guideCamp == 0 && this._launchOptions) {
					// 新号
					try {
						let query = this._launchOptions.query;
						if (this._isValidateQuery(query) && query.uid) {
							let uid: Long = Core.StringUtils.stringToLong(<string>query.uid);
							if (uid != Player.inst.uid) {
								args["InviterUid"] = uid;
							}
						}
					} catch (e) {
						console.log(e);
					}
				}
				Net.rpcCall(pb.MessageID.C2S_UPDATE_SDK_USER_INFO, pb.SdkUserInfo.encode(args));
				return true;
			} else {
				return false;
			}
			// let args = {
			// 	NickName: Player.inst.name,
			// 	HeadImgUrl: Player.inst.avatarUrl,
			// }
			// //weixin邀请
			// if (Player.inst.guideCamp == 0 && this._launchOptions) {
			// 	// 新号
			// 	try {
			// 		let query = this._launchOptions.query;
			// 		if (this._isValidateQuery(query) && query.uid) {
			// 			let uid: Long = Core.StringUtils.stringToLong(<string>query.uid);
			// 			if (uid != Player.inst.uid) {
			// 					args["InviterUid"] = uid;
			// 			}
			// 		}
			// 	} catch (e) {
			// 		console.log(e);
			// 	}
			// }
			// Net.rpcCall(pb.MessageID.C2S_UPDATE_SDK_USER_INFO, pb.SdkUserInfo.encode(args));
		}

		private _shouldOverWriteUserInfo() {
			return Player.inst.avatarUrl == "" || 
				Player.inst.avatarUrl == this._avatarForNoAuthUser || 
				Player.inst.isNewbieName(Player.inst.name) ||
				Player.inst.guideCamp == 0;
		}

		public async onLogin(userInfo: any) {
			console.log(`onLogin ${Player.inst.uid} ${Player.inst.avatarUrl} ${Player.inst.name}`);
			let name = userInfo.channel_username;
			let avatar = userInfo.avatar;

			if (name == "" || avatar == "") {
				this._hasAuthorized = false;
				avatar = this._avatarForNoAuthUser;
				name = `微信用户${Player.inst.uid}`;
			} else {
				this._hasAuthorized = true;
				if (!Player.inst.isNewbieName(Player.inst.name) &&
					Player.inst.name != `微信用户${Player.inst.uid}`) {
					name = Player.inst.name;
				}
			}

			if (userInfo.pt) {
				this._pt = userInfo.pt;
			}
			if (userInfo.isWhiteList) {
				this._isInHuoShuWhiteList = userInfo.isWhiteList;
			}

			this.updateWXUserInfo(name, avatar);
			/*
			let result = await Net.rpcCall(pb.MessageID.C2S_UPDATE_SDK_USER_INFO, pb.SdkUserInfo.encode(args));
			if (result.errcode == 0) {
				console.log("update wx info success");
			}
			*/
		}

		public onBattleEnd() {
			wx.triggerGC();
			console.log("triggerGC");
		}

		private _isValidateQuery(query: any): boolean {
			return query && query.tag == "lzd";
		}

		private async _onWXGameOnShow(evt: egret.Event) {
			let onShowParam = evt.data;
			/**
			 * {
			 * 	sessionid: string,
			 * 	clickTimestamp: int,
			 * 	isSticky: boolean,
			 * 	path: string,
			 * 	prescene: int,
			 * 	prescene_not: string,
			 * 	query: {},
			 * 	referrerInfo: {},
			 * 	scene: int,
			 * 	scene_note: string,
			 * 	usedstate: int,
			 * 	shareTicket: string,
			 * }
			 */
			console.log("_onWXGameOnShow", onShowParam);

			this._showOptions = onShowParam;
			if (this._showOptions && this._showOptions.query) {
				// Core.TipsUtils.showTipsFromCenter(JSON.stringify(this._showOptions));
				await this._handleLaunchOptions(this._showOptions);
			}

			setTimeout(() => {
				Core.MaskUtils.forbidTimeout(true);
			}, 1);

			console.log("++++++++ begin onshow callback");

			this._onShowCallbacks.forEach(callback => {
				console.log("++++++++ onshow callback");
				callback();
			})
			this._onShowCallbacks = [];

			console.log("++++++++ end onshow callback");
		}

		private async _onWXGameOnHide() {
			console.log("_onWXGameOnHide");
			Core.MaskUtils.forbidTimeout(true);
		}

		private _onWXGameOptions(evt: egret.Event) {
			let options = evt.data;
			// {scene: xxx, query: {…}}
			console.log("_onWXGameOptions", options);
			this._launchOptions = options;
		}

		public hasLaunchActionToHandle(): boolean {
			if (this._launchOptions && this._isValidateQuery(this._launchOptions.query)) {
				let act = this._launchOptions.query.act;
				if (act == WXShareType.SHARE_FIGHT ||
					act == WXShareType.SHARE_VEDIO) {
					return true;
				}
			}
			return false;
		}

		public async tryHandleLaunchOptions() {
			// Core.TipsUtils.showTipsFromCenter(JSON.stringify(this._launchOptions));
			await this._handleLaunchOptions(this._launchOptions);
		}

		private async _handleLaunchOptions(options: any) {
			if (options && !this._isValidateQuery(options.query)) {
				return;
			}
			let act, shareId,uid,name;
			try {
				act = parseInt(options.query.act);
				shareId = parseInt(options.query.shareId);
				uid = Core.StringUtils.stringToLong(<string>options.query.uid);
				name = options.query.name;
			} catch (e){
				console.log("parse query failed");
				return;
			}
			let data = null;

			if (act == WXShareType.SHARE_GRP_RANK) {
				await this._handleLaunchGroupRank(options.shareTicket);
			} else if (act == WXShareType.SHARE_TREASURE ||
				act == WXShareType.SHARE_DAILY_REWARD_DOUBLE) {
				let treasureId: number = parseInt(options.query.treasureId);
				await this._handleLaunchHelpTreasure(uid, name, treasureId, act);
			} else if (act == WXShareType.SHARE_FIGHT) {
				await this._handleLaunchFight(uid, name);
			} else if (act == WXShareType.SHARE_INVITE) {

			} else if (act == WXShareType.SHARE_REWARD) {
				let hid: number = parseInt(options.query.hid);
				await this._handleLaunchGetShareReward(uid, hid, name);
			} else if (act == WXShareType.SHARE_VEDIO) {
				let battleID: Long = Core.StringUtils.stringToLong(<string>options.query.battleId);
				await this._handleLaunchBattleVedio(name, battleID);
			} else if (act == WXShareType.SHARE_PREVENT_LOSE) {
				await this._handleLaunchHelpBattleLose(uid, name);
			} else if (act == WXShareType.SHARE_LEVEL_HELP) {
				let levelId: number = parseInt(options.query.levelId);
				let time: number = parseInt(options.query.time);
				await this._handleLaunchHelpLevel(uid, name, levelId, time);
			} else if (act == WXShareType.SHARE_FREE_GOLD || act == WXShareType.SHARE_FREE_JADE || act == WXShareType.SHARE_FREE_TREASURE) {
				if (uid == Player.inst.uid) {
					return;
				}
				let ret = await new Promise(resolve => {
					Core.TipsUtils.confirm(`要为<${name}>集赞获得免费礼品吗？`, () => {
						Core.TipsUtils.showTipsFromCenter("你点了个赞，对方获得了免费的商城礼品！");
						resolve(true);
					}, () => {
						resolve(false)
					}, this, "赞", "踩");
				});
				if (!ret) {
					return;
				}
				let freeId: number = parseInt(options.query.freeId);
				let freeType: number = parseInt(options.query.freeType);
				let args = {
				// ShopFreeAdsType: freeType,
					Type: freeType,
					ID: freeId
				};
				data = pb.WatchShopFreeAdsArg.encode(args).finish();
			} else if (act == WXShareType.SHARE_TREASURE_ADD_CARD) {
				if (uid == Player.inst.uid) {
					return;
				}
				let ret = await new Promise(resolve => {
					Core.TipsUtils.confirm(`要助力<${name}>获得更多卡牌吗？`, () => {
						Core.TipsUtils.showTipsFromCenter("对方已获得你的助力，可以开到更多的卡牌。");
						resolve(true);
					}, () => {
						resolve(false)
					}, this, "助力", "算了");
				});
				if (!ret) {
					return;
				}
				let treasureId: number = parseInt(options.query.treasureId);
				let args = {
					TreasureID: treasureId
				}
				data = pb.TargetTreasure.encode(args).finish();
			} else if (act == WXShareType.SHARE_UP_TREASURE) {
				if (uid == Player.inst.uid) {
					return;
				}
				let ret = await new Promise(resolve => {
					Core.TipsUtils.confirm(`要帮助<${name}>升级宝箱吗？`, () => {
						Core.TipsUtils.showTipsFromCenter("已帮助对方宝箱升级。");
						resolve(true);
					}, () => {
						resolve(false)
					}, this, "帮助", "算了");
				});
				if (!ret) {
					return;
				}
			} else if (act == WXShareType.SHARE_DAILY_JADE) {
				if (uid == Player.inst.uid) {
					return;
				}
				let args = {
					ShareTime: options.query.time,
					PlayerName: Player.inst.name,
				} 
				Core.TipsUtils.showTipsFromCenter(`已经帮助<${name}>获得了宝玉`);
				data = pb.WxShareAddJadeArg.encode(args).finish();
			}

			this._lastHandledOption = options;

			if (uid != Player.inst.uid) {
				let args = {
					ShareID: shareId,
					ShareUid: uid,
					ShareType: act
				};
				if (data) {
					args["Data"] = data;
				}
				Net.rpcPush(pb.MessageID.C2S_CLICK_WXGAME_SHARE, pb.ClickWxgameShareArg.encode(args));
			}
		}

		private async _handleLaunchGroupRank(shareTicket: string) {
			if (shareTicket && !Pvp.PvpMgr.inst.isNewbie()) {
				Core.ViewManager.inst.close(ViewName.wxgameFriendRankView);
				Core.ViewManager.inst.open(ViewName.wxgameFriendRankView, "group", shareTicket);
			}
		}

		private async _handleLaunchHelpTreasure(uid: Long, name: string, treasureId: number, act: WXShareType) {
			console.log(`_handleLaunchHelpTreasure ${uid}, ${treasureId}`);
			if (!Pvp.PvpMgr.inst.isNewbie() && uid != null && treasureId != null && uid != Player.inst.uid) {
				let title = "";
				if (act == WXShareType.SHARE_DAILY_REWARD_DOUBLE) {
					title = `要帮助<${name}>加倍每日宝箱的奖励吗？？`
				} else {
					title = `要帮助<${name}>加速宝箱开启吗？`
				}
				Core.TipsUtils.confirm(title, async () => {
					let args = {
						ShareUid: uid,
						TreasureID: treasureId
					}
					let result = await Net.rpcCall(pb.MessageID.C2S_HELP_SHARE_TREASURE, pb.HelpShareTreasureArg.encode(args));
					if (result.errcode == 0) {
						// console.log("help treausre success!");
						Core.TipsUtils.showTipsFromCenter("对方感受到了你的热情。");
					}
				}, null, this, "帮助", "算了");
			}
		}

		private async _handleLaunchFight(uid: Long, name: string) {
			if (uid && name &&
				!Pvp.PvpMgr.inst.isNewbie() &&
				!Battle.BattleMgr.inst.battle &&
				Player.inst.uid != uid) {
				Core.TipsUtils.confirm(`是否接受<${name}>的约战邀请？`, async () => {
					let args = {
						Uid: uid
					};
					let result = await Net.rpcCall(pb.MessageID.C2S_WX_REPLY_INVITE_BATTLE, pb.ReplyWxInviteBattleArg.encode(args), true, false);
					if (result.errcode == 0) {
						Core.TipsUtils.showTipsFromCenter("约战成功！");
					} else {
						Core.TipsUtils.showTipsFromCenter("对方已不再等待");
					}
				}, null, this, "同意", "拒绝");
			}
		}

		private async _handleLaunchGetShareReward(uid: Long, hid: number, name: string) {
			if (Player.inst.uid == uid) {
				return;
			}
			if (hid) {
				Core.ViewManager.inst.close(ViewName.shareGetTreasure);
				Core.ViewManager.inst.open(ViewName.shareGetTreasure, hid, name);
			}
		}

		private async _handleLaunchBattleVedio(name: string, battleId: Long) {
			if (!Pvp.PvpMgr.inst.isNewbie() && !Battle.BattleMgr.inst.battle) {
			// if (!Battle.BattleMgr.inst.battle) {
				Core.TipsUtils.confirm(`是否观看<${name}>分享的一场精彩对局？`, async () => {
					let args = {VideoID: battleId};
					let result = await Net.rpcCall(pb.MessageID.C2S_WATCH_VIDEO, pb.WatchVideoArg.encode(args));
					if (result.errcode == 0) {
						let reply = pb.WatchVideoResp.decode(result.payload);
						try {
							await Battle.VideoPlayer.inst.play(<pb.VideoBattleData>reply.VideoData);
						} catch(e) {
							console.log(e);
						}
					}
				}, null, this, "观看", "算了");
			}
		}

		private async _handleLaunchHelpBattleLose(uid: Long, name: string) {
			if (uid && uid != Player.inst.uid) {
				Core.TipsUtils.confirm(`要帮助一下<${name}>，挽回他的失败吗？`, async () => {
					let args = {
						ShareUid: uid
					};
					let result = await Net.rpcCall(pb.MessageID.C2S_HELP_SHARE_BATTLE_LOSE, pb.HelpShareBattleLoseArg.encode(args));
					if (result.errcode == 0) {
						Core.TipsUtils.showTipsFromCenter("对方避免了掉级的命运。");
					}
				}, null, this, "帮助", "算了");
			}
		}

		private async _handleLaunchHelpLevel(uid: Long, name: string, levelId: number, time: number) {
			if (uid && levelId &&
				uid != Player.inst.uid &&
				!Pvp.PvpMgr.inst.isNewbie() &&
				!Battle.BattleMgr.inst.battle) {
				let levelObj = Level.LevelMgr.inst.getLevel(levelId);
				if (!levelObj) {
					Core.TipsUtils.showTipsFromCenter("分享关卡id错误");
					return;
				}
				if (Date.now() / 1000 - time > 24 * 3600) {
					Core.TipsUtils.showTipsFromCenter("求助信息已经过了太久，求助者不知所踪。");
					return;
				}
				Core.TipsUtils.confirm(`要为<${name}挑战关卡<${levelObj.name}>吗？`, async () => {
					let args = {
						HelpUid: uid,
						LevelID: levelId
					};
					let result = await Net.rpcCall(pb.MessageID.C2S_LEVEL_HELP_OTHER, pb.LevelHelpArg.encode(args));
					if (result.errcode == 0) {
						Core.TipsUtils.showTipsFromCenter("开始挑战！");
					}
				}, null, this, "挑战", "算了");
			}
		}

		public onEnableShareMenuSuccess(res: any) {
			console.log("onEnableShareMenuSuccess", JSON.stringify(res));
		}

		public onDisableShareMenuSuccess(res: any) {
			console.log("onDisableShareMenuSuccess", JSON.stringify(res));
		}

		public onShareAppMessageSuccess(isGrpShare: boolean, res: any) {

			let shareType = this._curShareType;
			if (shareType == WXShareType.SHARE_FIGHT) {
				this._handleShareInviteFight();
			}
			return;

			// console.log("onShareAppMessageSuccess", isGrpShare, JSON.stringify(res));
			let shareResult = null;
			if (isGrpShare) {
				/**
				 * res: {
				 * 	errMsg: string,
				 * 	iv: string,
				 * 	encryptedData: string,
				 * }
				 * 	对称解密使用的算法为 AES-128-CBC，数据采用PKCS#7填充。
					对称解密的目标密文为 Base64_Decode(encryptedData)。
					对称解密秘钥 aeskey = Base64_Decode(session_key), aeskey 是16字节。
					对称解密算法初始向量 为Base64_Decode(iv)，其中iv由数据接口返回。
				 */
				let cipher = CryptoJS.enc.Base64.parse(res.encryptedData);
				let key = CryptoJS.enc.Base64.parse(this._sessionKey);
				let iv = CryptoJS.enc.Base64.parse(res.iv);
				let decryptor = CryptoJS.algo.AES.createDecryptor(key, {
					iv: iv
				});
				let shareInfo = decryptor.process(cipher);
				shareInfo += decryptor.finalize();
				/**
				 * openGId: string,
				 * watermark: {
				 * 	timestamp: number,
				 * 	appid: string
				 * }
				 */
				let shareResultStr = CryptoJS.enc.Latin1.stringify(CryptoJS.enc.Hex.parse(shareInfo));
				// console.log("result: ", shareResultStr);
				shareResult = JSON.parse(shareResultStr);

			}
			if (this._isSharing && this._curShareType) {
				let shareType = this._curShareType;
				let shareId = this._curShareId;
				this._isSharing = false;
				this._curShareType = null;
				this._curShareId = null;
				if (shareType == WXShareType.SHARE_FIGHT) {
					this._handleShareInviteFight();
				} else if (shareType == WXShareType.SHARE_TREASURE ||
					shareType == WXShareType.SHARE_DAILY_REWARD_DOUBLE) {
					if (this.isExamineVersion || isGrpShare) {
						if (isGrpShare) {
							this._handleShareTreasure(shareResult.openGId);
						} else {
							this._handleShareTreasure("");
						}
					} else {
						Core.TipsUtils.alert("分享到群才有效哦！");
					}
				} else if (shareType == WXShareType.SHARE_PREVENT_LOSE) {
					if (this.isExamineVersion || isGrpShare) {
						if (isGrpShare) {
							this._handleSharePreventLoseStar(shareResult.openGId);
						} else {
							this._handleSharePreventLoseStar("");
						}
					} else {
						Core.TipsUtils.alert("分享到群才有效哦！");
					}
				} else if (shareType == WXShareType.SHARE_FREE_GOLD ||
					shareType == WXShareType.SHARE_FREE_JADE ||
					shareType == WXShareType.SHARE_FREE_TREASURE) {
					if (!this.isExamineVersion && !isGrpShare) {
						Core.TipsUtils.alert("分享到群才有效哦！");
					}
				} else if (shareType == WXShareType.SHARE_UP_TREASURE) {
					if (!this.isExamineVersion && !isGrpShare) {
						Core.TipsUtils.alert("分享到群才有效哦！");
					}
				} else if (shareType == WXShareType.SHARE_TREASURE_ADD_CARD) {
					if (!this.isExamineVersion && !isGrpShare) {
						Core.TipsUtils.alert("分享到群才有效哦！");
					}
				} else if (shareType == WXShareType.SHARE_FREE_GOLD ||
					shareType == WXShareType.SHARE_FREE_JADE ||
					shareType == WXShareType.SHARE_FREE_TREASURE) {
					if (!this.isExamineVersion && !isGrpShare) {
						Core.TipsUtils.alert("分享到群才有效哦！");
					}
				} else if (shareType == WXShareType.SHARE_UP_TREASURE) {
					if (!this.isExamineVersion && !isGrpShare) {
						Core.TipsUtils.alert("分享到群才有效哦！");
					}
				} else if (shareType == WXShareType.SHARE_TREASURE_ADD_CARD) {
					if (!this.isExamineVersion && !isGrpShare) {
						Core.TipsUtils.alert("分享到群才有效哦！");
					}
				}

				let wxGroupId = "";
				if (isGrpShare) {
					wxGroupId = shareResult.openGId;
				}
				Net.rpcCall(pb.MessageID.C2S_WXGAME_SHARE, pb.WxgameShareArg.encode({
					ShareID: shareId,
					ShareType: <number>shareType,
					WxGroupID: wxGroupId,
					Data: this._curShareData
				}));

				this._curShareData = null;
			}

			//Quest.QuestMgr.inst.onWxShare();
		}

		public onShareAppMessageFail(res: any, reason: string) {

			return;


			console.log("onShareAppMessageFail", JSON.stringify(res));
			if (reason) {
				Core.TipsUtils.showTipsFromCenter(reason);
			}
		}

		public onShareAppMessageComplete(res: any) {

			return;


			if (res.errMsg != "shareAppMessage:ok") {
				fairygui.GTimers.inst.add(1000, 1, () => {
					//Core.TipsUtils.showTipsFromCenter("分享失败");
				}, this);
			}
			// console.log("onShareAppMessageComplete", JSON.stringify(res));
		}

		private async _handleShareInviteFight() {
			let result = await Net.rpcCall(pb.MessageID.C2S_WX_INVITE_BATTLE, null);
			if (result.errcode == 0) {
				await Core.ViewManager.inst.open(ViewName.inviteWaiting, async () => {
					let _result = await Net.rpcCall(pb.MessageID.C2S_WX_CANCEL_INVITE_BATTLE, null);
					if (_result.errcode == 0) {
						Core.TipsUtils.showTipsFromCenter("约战已取消");
					}
				});
			} else {
				Core.TipsUtils.showTipsFromCenter("分享约战失败");
			}
		}

		private async _onInviteBattleResult(evt: egret.Event) {
			let result = <pb.WxInviteBattleResult.WxInviteResult>evt.data;
			if (result == pb.WxInviteBattleResult.WxInviteResult.Timeout) {
				Core.TipsUtils.showTipsFromCenter("等待超时");
			}
			Core.ViewManager.inst.close(ViewName.inviteWaiting);
		}

		private async _handleShareTreasure(wxGroupId: string) {
			let args = {
				TreasureID: WXShareMgr.inst.shareTreasureId,
				WxGroupID: wxGroupId,
			};
			let result = await Net.rpcCall(pb.MessageID.C2S_SHARE_TREASURE, pb.ShareTreasureArg.encode(args));
			if (result.errcode == 0) {

			} else {
				Core.TipsUtils.alert("不要频繁分享到同一个群哦。");
			}
		}

		private async _handleSharePreventLoseStar(wxGroupId: string) {
			let args = {
				WxGroupID: wxGroupId,
			}
			let result = await Net.rpcCall(pb.MessageID.C2S_SHARE_BATTLE_LOSE, pb.ShareBattleLoseArg.encode(args));
			if (result.errcode == 0) {
				console.log("_handleSharePreventLoseStar success");
			}
		}

		public setSessionKey(sessionKey: string) {
			this._sessionKey = sessionKey;
		}

		public getBaseWXShareQuery(): string {
			return `tag=lzd&uid=${Player.inst.uid}&name=${Player.inst.name}`;
		}

		public shareAppMessage(title: string, image: string, query: string, type: WXShareType, shareId: number, data:any = null) {
			this._isSharing = true;
			this._curShareType = type;
			this._curShareId = shareId;
			this._curShareData = data;
			sharePlatform.shareAppMsg(title, image, query);
		}

		public cloudStorePvpData() {
			let pvpLevel = Pvp.PvpMgr.inst.getPvpLevel();
			let pvpTitle = Pvp.Config.inst.getPvpTitle(pvpLevel);
			let star = Pvp.PvpMgr.inst.getPvpStarCnt(Player.inst.getResource(ResType.T_SCORE));
			wx.setUserCloudStorage(
				{
					KVDataList: [
						{key: "title", value:pvpTitle},
						{key: "star", value:`${star}`},
						{key: "score", value: `${Player.inst.getResource(ResType.T_SCORE)}`}
						],
					success: (res) => {
						console.log("setUserCloudStorage success: ", res);
					},
					fail: (res) => {
						console.log("setUserCloudStorage fail: ", res);
					},
					complete: (res) => {
						console.log("setUserCloudStorage complete: ", res);
					}
				}
			)
		}

		public onEnterGame() {
			let plat = <any>platform;
			plat.onEnterGame(Player.inst.uid, Player.inst.name, 1, 1, "WXGameServer");
		}

		public onCreateRole() {
			let plat = <any>platform;
			plat.onCreateRole(Player.inst.uid, Player.inst.name, 1, "WXGameServer");
		}

		public exitGame() {
			wx.exitMiniProgram({
				success: () => {},
				fail: () => {
					Core.TipsUtils.showTipsFromCenter("退出游戏失败，请重启微信并进入游戏~");
				},
				complete: () => {}
			})
		}

		public showConnectView(show: boolean) {
			if (show) {
				Core.ViewManager.inst.open(ViewName.connectView);
			} else {
				Core.ViewManager.inst.close(ViewName.connectView);
			}
		}

		public async checkAuthStatus() {
			if (this._hasAuthorized) {
				return true;
			}
			let ret = await new Promise<boolean>(resolve => {
				wx.getSetting({
					success: (res) => {
						console.log("checkAuthStatus", res);
						if (!res) {
							resolve(false);
						} else {
							if (!res.authSetting) {
								resolve(false);
							} else {
								if (res.authSetting["scope.userInfo"]) {
									this._hasAuthorized = true;
									resolve(true);
								} else {
									resolve(false);
								}
							}
						}
					},
					fail: (res) => {
						resolve(false);
					},
					complete: (res) => {

					}
				});
			});
			if (!ret) {
				return await new Promise<boolean>(resolve => {
					Core.ViewManager.inst.open(ViewName.wechatAuthTipsView, (success) => {
						resolve(success);
					});
				});
			} else {
				return true;
			}
		}
	}

	export function init() {
		initRpc();
		WXGameMgr.inst.initMgr();

		// Core.ViewManager.inst.registerConstructor(ViewName.shareRewardTreasure, () => {
		// 	let wxShareTreasure = new WXTreasureShareReward();
        // 	wxShareTreasure.contentPane = fairygui.UIPackage.createObject(PkgName.treasure, ViewName.shareRewardTreasure).asCom;
		// 	return wxShareTreasure;
		// });

		Core.ViewManager.inst.registerConstructor(ViewName.shareGetTreasure, () => {
			let wxGetTreasure = new WXTreasureGetReward();
			wxGetTreasure.contentPane = fairygui.UIPackage.createObject(PkgName.treasure, ViewName.shareGetTreasure).asCom;
			return wxGetTreasure;
		});

		Core.ViewManager.inst.registerConstructor(ViewName.wechatAuthTipsView, () => {
			let authTipView = new WXAuthTipsWnd();
			authTipView.contentPane = fairygui.UIPackage.createObject(PkgName.social, ViewName.wechatAuthTipsView).asCom;
			return authTipView;
		});
	}
}
