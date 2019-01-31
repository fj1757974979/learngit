/**
 * 请在白鹭引擎的Main.ts中调用 platform.login() 方法调用至此处。
 */

var xdSdk = require('./library/xd_wxgame.js')
var md5 = require('./library/md5.js')

class WxgamePlatform {

    name = 'wxgame'

    login() {
        return new Promise((resolve, reject) => {
            wx.login({
                success: (res) => {
                    resolve(res)
                }
            })
        })
    }

    getUserInfo() {
        return new PromPise((resolve, reject) => {
            wx.getUserInfo({
                withCredentials: true,
                success: function (res) {
                    var userInfo = res.userInfo
                    var nickName = userInfo.nickName
                    var avatarUrl = userInfo.avatarUrl
                    var gender = userInfo.gender //性别 0：未知、1：男、2：女
                    var province = userInfo.province
                    var city = userInfo.city
                    var country = userInfo.country
                    resolve(userInfo);
                }
            })
        })
    }

    openDataContext = new WxgameOpenDataContext();
}

class XdgamePlatform {

    userInfo = null;
    appId = 2063;
    gameId = 200078;
    gameKey = "3ad228b0b975a749"
    gameSecret = "069fb6c64bb486fda74f0ffa6b854cb0"
    launchOptions = null;
    pt = 1000;
    userInfoButton = null;
	gameUserInfo = null;
    init() {
		try {
			xdSdk.xdInit();
		} catch (e) {
			console.error(e);
		}
        
        wx.onShow(function(res) {
            // console.log("onShow param: ", res);
            Core.EventCenter.inst.dispatchEventWith("WXGAME_ONSHOW", false, res);
        });
		wx.onHide(function() {
			Core.EventCenter.inst.dispatchEventWith("WXGAME_ONHIDE", false);
		});
		try {
			this.launchOptions = wx.getLaunchOptionsSync();
			// console.log("launchOptions: ", this.launchOptions);
			Core.EventCenter.inst.dispatchEventWith("WXGAME_OPTIONS", false, this.launchOptions);
		} catch (e) {
			console.error(e)
		}
        //var decode = decodeURIComponent(this.launchOptions.scene);
        // console.log(decode);
        
        //if (decode.pt != undefined) {
        //    this.pt = parseInt(decode.pt);
        //    console.log("get pt value: ", this.pt);
        //}
        console.log("XdgamePlatform init done");
    }

    login() {
        if (this.userInfo != null) {
          return;
        }
        return new Promise((resolve, reject) => {
			var systemInfo = wx.getSystemInfoSync();
			var windowWidth = systemInfo.windowWidth;
			var windowHeight = systemInfo.windowHeight;

			this.userInfoButton = wx.createUserInfoButton({
				type:"image",
				image:"res/StartGame.png",
				style: {
					left:(windowWidth - 248)/2,
					top:(windowHeight - 150),
					width:248,
					height:64
				}
			});
			this.userInfoButton.onTap((res) => {
				if (this.userInfoButton == null) {
					return;
				}
				//WXGame.WXGameMgr.inst.showConnectView(true);
				this.userInfoButton.destroy();
				this.userInfoButton = null;
				WXGame.WXGameMgr.duringLogin();
				xdSdk.xdLoginWithNoAuth(this.gameId, (data) => {
					if (data.openid == null) {
						this.userInfo = null;
					} else {
						this.userInfo = {};
						this.userInfo["channel_id"] = data.openid;
						this.userInfo["token"] = data.session_key;
						this.userInfo["channel_userid"] = data.wx_openid;
						if (res.userInfo) {
							this.userInfo["channel_username"] = res.userInfo.nickName || "";
							this.userInfo["avatar"] = res.userInfo.avatarUrl || "";
						} else {
							this.userInfo["channel_username"] = "";
							this.userInfo["avatar"] = "";
						}
						//this.userInfo["pt"] = this.pt;
						this.userInfo["isWhiteList"] = (data.is_w == 1);
						console.log("+++++ " + data.openid, data.is_w);
						//WXGame.WXGameMgr.inst.setSessionKey(data.session_key);
					}

					//WXGame.WXGameMgr.inst.showConnectView(false);
					resolve();
				})
			});
			this.userInfoButton.show();
        });
    }

    getUserInfo() {
        return this.userInfo;
    }

    pay(productId, price, count, isSDK, desc, orderId, callbackUrl) {
		if (!this.userInfo) {
			return {success: false, reason: "登录已过期"};
		}
		var uid = this.gameUserInfo.uid;
		var openId = this.userInfo.channel_id;
		var timestamp = Math.floor(Date.now() / 1000);
		var paymentAmount = parseFloat(price).toFixed(2);
		var signature = md5.hex_md5(this.gameId + this.gameKey + openId + paymentAmount + orderId + timestamp + uid + this.gameSecret);
		//var callbackUrl = "http://ctc-main.fire233.com:6668/recharge/lzd_pkgsdk";
		var nonce = Math.floor(Math.random() * 10000000);
		console.log("uid:", uid, ",paymentAmount:",paymentAmount, "url:", callbackUrl);
		var payInfo = {
			game_id: this.gameId,
			game_key: this.gameKey,
			open_id: this.userInfo.channel_id,
			payment_amount: parseFloat(price).toFixed(2),
			object_name: productId,
			game_payorder: orderId,
			signature: signature,
			callback_url: callbackUrl,
			desc: desc,
			timestamp: timestamp,
			nonce: nonce,
			game_area: this.gameUserInfo.serverName,
			game_server: this.gameUserInfo.serverName,
			role_id: uid,
			role_level: this.gameUserInfo.level,
			vip_level: 0,
			nickname: this.gameUserInfo.name,
		};
		var payFunc = null;
		if (wx.getSystemInfoSync().platform == "android") {
			payFunc = xdSdk.xdPay;
		} else {
			payFunc = xdSdk.xdiOSPay;
		}
		return new Promise((resolve, reject) => {
			payFunc(payInfo, (success) => {
				var result = {
					success: success
				}
				if (!success) {
					result["reason"] = "充值失败";
				} else {
					result["orderId"] = orderId;
				}
				resolve(result);
			});
		});
    }

    canMakePay() {
		return true;
    }

    onEnterGame(uid, name, level, serverId, serverName) {
		console.log("+++++++++++++++++ onEnterGame, ", uid, name, level, serverId, serverName);
		if (!this.gameUserInfo) {
			this.gameUserInfo = {};
		}
		this.gameUserInfo["uid"] = uid;
		this.gameUserInfo["name"] = name;
		this.gameUserInfo["level"] = level;
		this.gameUserInfo["serverId"] = serverId;
		this.gameUserInfo["serverName"] = serverName;

		var timestamp = Math.floor(Date.now() / 1000);
		console.log("+++++++++++++++++ ", this.gameKey, this.userInfo["channel_id"], timestamp, this.gameSecret);
		console.log("+++++++++++++++++ ", this.gameKey + this.userInfo["channel_id"] + timestamp + this.gameSecret);
		var signature = md5.hex_md5(this.gameKey + this.userInfo["channel_id"] + timestamp + this.gameSecret);
		console.log("+++++++++++++++++ signature", signature);
		var enterGameData = {
			game_id: "" + this.gameId,
			game_key: this.gameKey,
			app_id: this.appId,
			open_id: this.userInfo["channel_id"],
			timestamp: timestamp,
			role_id: uid,
			nickname: name,
			level: level,
			vip_level: 0,
			role_ext: "",
			score: 0,
			area: serverName,
			server_id: serverId,
			is_new: 0,
			signature: signature
		}
		xdSdk.xdEnterGameLog(enterGameData);
    }

    onCreateRole(uid, name, serverId, serverName) {
		console.log("+++++++++++++++++ onCreateRole");
		if (!this.gameUserInfo) {
			this.gameUserInfo = {};
		}
		this.gameUserInfo["uid"] = uid;
		this.gameUserInfo["name"] = name;
		this.gameUserInfo["serverId"] = serverId;
		this.gameUserInfo["serverName"] = serverName;

		var timestamp = Math.floor(Date.now() / 1000);
		var signature = md5.hex_md5(this.gameKey + this.userInfo["channel_id"] + timestamp + this.gameSecret);
		var roleData = {
			game_id: "" + this.gameId,
			game_key: this.gameKey,
			app_id: this.appId,
			open_id: this.userInfo["channel_id"],
			timestamp: timestamp,
			role_id: uid,
			nickname: name,
			area: serverName,
			server_id: serverId,
			signature: signature
		}
		xdSdk.xdCreateRoleLog(roleData);
    }

	getFloatIconInfo() {
		return new Promise((resolve, reject) => {
			xdSdk.xdPreviewImage(this.gameId, (res) => {
				resolve(res);
			});
		});
	}

	drawImage(image, x, y) {
	}

    openDataContext = new WxgameOpenDataContext();
}

class WxgameOpenDataContext {

    createDisplayObject(type, width, height) {
        const bitmapdata = new egret.BitmapData(sharedCanvas);
        bitmapdata.$deleteSource = false;
        const texture = new egret.Texture();
        texture._setBitmapData(bitmapdata);
        const bitmap = new egret.Bitmap(texture);
        bitmap.width = width;
        bitmap.height = height;
        if (egret.Capabilities.renderMode == "webgl") {
            const renderContext = egret.wxgame.WebGLRenderContext.getInstance();
            const context = renderContext.context;
            ////需要用到最新的微信版本
            ////调用其接口WebGLRenderingContext.wxBindCanvasTexture(number texture, Canvas canvas)
            ////如果没有该接口，会进行如下处理，保证画面渲染正确，但会占用内存。
            if (!context.wxBindCanvasTexture) {
                egret.startTick((timeStarmp) => {
                    egret.WebGLUtils.deleteWebGLTexture(bitmapdata.webGLTexture);
                    bitmapdata.webGLTexture = null;
                    return false;
                }, this);
            } else {
                context.wxBindCanvasTexture(texture, sharedCanvas);
            }
        }
        return bitmap;
    }


    postMessage(data) {
        const openDataContext = wx.getOpenDataContext();
        openDataContext.postMessage(data);
    }
}

class WXSharePlatform {

    common_share_title = "";
    common_share_image = "";
    common_share_query = "";

    init() {

    }

	getShareType() {
		return 1;
	}

	getShareLink() {
		return "";
	}

    enableShareMenu(b, title, image, query) {
		console.log("enableShareMenu", b, title, image, query);
		xdSdk.xdonShare(title, image, (res) => {
			if (res.code == 0) {
				WXGame.WXGameMgr.inst.onShareAppMessageSuccess(false);
			} else {
				WXGame.WXGameMgr.inst.onShareAppMessageFail(null, res.message);
			}
		}, query);
    }

    shareAppMsg(title, image, query) {
		xdSdk.xdShare(title, image, (res) => {
			if (res.code == 0) {
				var shareTickets = res.shareTickets;
				if (shareTickets && shareTickets.length > 0) {
					var shareTicket = shareTickets[0];
					wx.getShareInfo({
						shareTicket: shareTicket,
						success: function(res1) {
							WXGame.WXGameMgr.inst.onShareAppMessageSuccess(true, res1);
						},
						fail: function(res1) {
							WXGame.WXGameMgr.inst.onShareAppMessageFail(res, "获取分享信息失败");
						},
						complete: function(res1) {

						}
					});
				} else {
					WXGame.WXGameMgr.inst.onShareAppMessageSuccess(false, res);
				}
			} else {
				WXGame.WXGameMgr.inst.onShareAppMessageFail(res, "分享失败");
			}
		}, query);
    }
}


// window.platform = new WxgamePlatform();
window.platform = new XdgamePlatform();
window.sharePlatform = new WXSharePlatform();
