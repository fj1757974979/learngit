module Social {
	export class SocialMgr {

		private static _inst: SocialMgr;

		public static get inst(): SocialMgr {
			if (!SocialMgr._inst) {
				SocialMgr._inst = new SocialMgr();
			}
			return SocialMgr._inst;
		}

		private _urlTextureCache: Collection.Dictionary<string, egret.Texture>;
		private _urls: Array<string>;
		private _maxCacheSize: number;

		public constructor() {
			this._urlTextureCache = new Collection.Dictionary<string, egret.Texture>();
			this._urls = [];
			this._maxCacheSize = 200;
		}

		public async getTextureByResUrl(url: string) {
			if (this._urlTextureCache.containsKey(url)) {
				return this._urlTextureCache.getValue(url);
			} else {
				if (url.indexOf("http") < 0 && url.indexOf("https") < 0) {
					try {
						let texture = await RES.getResAsync(url);
						return texture;
					} catch (e) {
						console.error(e);
						return null;
					}
				} else {
					let imageLoader = new egret.ImageLoader();
					return await new Promise<egret.Texture>(resolve => {
						try {
							let imageLoader = new egret.ImageLoader();
							imageLoader.addEventListener(egret.Event.COMPLETE, (event: egret.Event) => {
								let loader = <egret.ImageLoader>event.currentTarget;
								let texture = new egret.Texture();
								texture._setBitmapData(loader.data);
								this._urlTextureCache.setValue(url, texture);
								this._urls.push(url);
								if (this._urls.length > this._maxCacheSize) {
									let del = this._urlTextureCache.getValue(this._urls[0]);
									if (del) {
										del.dispose();
										this._urlTextureCache.remove(this._urls[0]);
									}
									// [begin, end)
									this._urls = this._urls.slice(1, this._urls.length);
								}
								resolve(texture);
							}, this);
							imageLoader.crossOrigin = "anonymous";
							imageLoader.load(url);
						} catch (e) {
							console.error(e);
							resolve(null);
						}
					});
				}
			}
		}

		public async openSelfInfoView() {
			if (Core.DeviceUtils.isWXGame()) {
                if (!await WXGame.WXGameMgr.inst.checkAuthStatus()) {
                    return;
                }
            }
			let playerInfo = await Social.FriendMgr.inst.fetchPlayerInfo(Player.inst.uid);
            if (playerInfo) {
                await Core.ViewManager.inst.open(ViewName.selfInfo, Player.inst.uid, playerInfo);
            } else {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60202));
			}
		}
	}

	function onLogin() {
		FriendMgr.inst.fetchAddFriendApplies(true);
		ChatMgr.inst.initPrivateChat();
	}

	export function init() {
		Social.initRpc();
		// ChatMgr.inst.initPrivateChat();

		Player.inst.addEventListener(Player.LoginEvt, onLogin, null);
		
        let registerView = Core.ViewManager.inst.registerView.bind(Core.ViewManager.inst);
        let createObject = fairygui.UIPackage.createObject;

		registerView(ViewName.social, () => {
			return createObject(PkgName.social, ViewName.social, SocialView);
		});   

		
		registerView(ViewName.friendInfo, () => {
			let friendInfoWnd = new FriendInfoWnd();
			friendInfoWnd.contentPane = createObject(PkgName.social, ViewName.friendInfo).asCom;
			return friendInfoWnd;
		});

		registerView(ViewName.selfInfo, () => {
			let selfInfoWnd = new SelfInfoWnd();
			selfInfoWnd.contentPane = createObject(PkgName.social, ViewName.selfInfo).asCom;
			return selfInfoWnd;
		});

		registerView(ViewName.haedBig,() =>{
			let haedBigWnd = new HaedBigWnd();
			haedBigWnd.contentPane = createObject(PkgName.social,ViewName.haedBig).asCom;
			return haedBigWnd;
		})

		registerView(ViewName.applyInfo, () => {
			let friendApplyWnd = new FriendApplyWnd();
			friendApplyWnd.contentPane = createObject(PkgName.social, ViewName.applyInfo).asCom;
			return friendApplyWnd;
		});

		
		registerView(ViewName.friendSearch, () => {
			let friendSearchWnd = new FriendSearchWnd();
			friendSearchWnd.contentPane = createObject(PkgName.social, ViewName.friendSearch).asCom;
			return friendSearchWnd;
		});

		registerView(ViewName.friendOption, () => {
			let friendOptionWnd = new FriendOptionWnd();
			friendOptionWnd.contentPane = createObject(PkgName.social, ViewName.friendOption).asCom;
			return friendOptionWnd;
		});

		registerView(ViewName.friendOptionList, () => {
			let friendOptionListWnd = new FriendListOptionWnd();
			friendOptionListWnd.contentPane = createObject(PkgName.social, ViewName.friendOptionList).asCom;
			return friendOptionListWnd;
		});

		registerView(ViewName.privateChatWnd, () => {
			let privateChatWnd = new PrivateChatWnd();
			privateChatWnd.contentPane = createObject(PkgName.social, ViewName.privateChatWnd).asCom;
			return privateChatWnd;
		});
		registerView(ViewName.privPanelWnd, () => {
			let privPanelWnd = new PrivPanelWnd();
			privPanelWnd.contentPane = createObject(PkgName.social, ViewName.privPanelWnd).asCom;
			return privPanelWnd;
		});
		registerView(ViewName.privView, () => {
			let privViewWnd = new PrivViewWnd();
			privViewWnd.contentPane = createObject(PkgName.social, ViewName.privView).asCom;
			return privViewWnd;
		});

		registerView(ViewName.inviteWaiting, () => {
			return createObject(PkgName.social, ViewName.inviteWaiting, InviteWaitingWnd);
		});

		registerView(ViewName.avatarChangeWnd, () => {
			let avatarWnd = new AvatarWnd();
			avatarWnd.contentPane = createObject(PkgName.social, ViewName.avatarChangeWnd).asCom;
			return avatarWnd;
		});
		
		registerView(ViewName.inviteRewardWnd, () => {
			return createObject(PkgName.social, ViewName.inviteRewardWnd, InviteRewardWnd);
		});

		registerView(ViewName.shareReward, () => {
			return createObject(PkgName.social, ViewName.shareReward, ShareRewardWnd);
		});

		registerView(ViewName.shareFacebookReward, () => {
			return createObject(PkgName.social, ViewName.shareFacebookReward, ShareFacebookRewardWnd);
		});
	}
}