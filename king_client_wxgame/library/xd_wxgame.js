/**
 * 初始化接口
 */
function xdInit() {
  console.log('this is xd_wxgame init 1.0.0926');
  
  var option = wx.getLaunchOptionsSync();
  console.log(option);
  //记录游戏的场景值
  if (option.scene){
    wx.setStorageSync('xd_game_scene', option.scene);
  }

  if (option.scene == 1020
    || option.scene == 1035
    || option.scene == 1036
    || option.scene == 1037
    || option.scene == 1038
    || option.scene == 1043) {
	if (option.referrerInfo && option.referrerInfo.appId) {
		var from_source = option.referrerInfo.appId;
		wx.setStorageSync('xd_game_from_source', from_source);
	}
  }
  
  if (wx.getStorageSync('xd_game_pt') == '') {
    if (option != undefined && option.query) {
      //获取分享的pt号，如果有就保存到缓存中
      var pt = option.query.pt;
      if (pt != undefined) {
        wx.setStorageSync('xd_game_pt', pt);
      } else {
        wx.setStorageSync('xd_game_pt', 1000);
      }
    } else {
      wx.setStorageSync('xd_game_pt', 1000);
    }
  }
  console.log("this query pt:" + wx.getStorageSync('xd_game_pt'));
}

/**小游戏登陆接口,有授权登陆，适合需要微信头像和昵称的产品接入
 * gameId 游戏在火树后台申请时候的游戏id
 */ // 因为微信的更新，已经废弃该方法
function xdLogin(gameId, callback) {
  return new Promise((resolve, reject) => {

    //调用登录接口
    //1.小程序调用wx.login得到code.
    wx.login({
      success: function(res) {
        //先获取缓存的pt号
        var pt = wx.getStorageSync('xd_game_pt');
        var scene = wx.getStorageSync('xd_game_scene');
        var from_source = wx.getStorageSync('xd_game_from_source');
        console.log("login pt:" + pt + " scene：" + scene + " from_source:" + from_source);
        console.log(res)

        var code = res['code'];
        
        //2.小程序调用wx.getUserInfo得到rawData, signatrue, encryptData.
        wx.getUserInfo({
          success: function(info) {

            var rawData = info['rawData'];
            var signature = info['signature'];
            var encryptData = info['encryptData'];
            var encryptedData = info['encryptedData']; //注意是encryptedData不是encryptData...坑啊
            var iv = info['iv'];

            var userInfo = info.userInfo;
            var nickName = userInfo.nickName;
            var avatarUrl = userInfo.avatarUrl;
            var gender = userInfo.gender //性别 0：未知、1：男、2：女

            //2063 代表的是微信小渠道
            var url = 'https://d.fire2333.com/xdpt/weixinminigame/index/2063/' + gameId;
            // console.log("code：" + code);
            // console.log("rawData:" + rawData);
            // console.log("signature:" + signature);
            // console.log("encryptData:" + encryptData);
            // console.log("encryptedData:" + encryptedData);
            // console.log("iv:" + iv);
            // console.log("pt:" + pt);
            // console.log("url:" + url);
            //3.小程序调用server获取token接口, 传入code, rawData, signature, encryptData.
            wx.request({
              url: url,
              data: {
                "code": code,
                "rawData": rawData,
                "signature": signature,
                "encryptData": encryptData,
                "iv": iv,
                "encryptedData": encryptedData,
                "nickName": nickName,
                "avatarUrl": avatarUrl,
                "gender": gender,
                "ad": pt,
                "adposition": pt,
                "pt": pt,
                "scene": scene,
                "fromsource": from_source
              },
              success: function(res) {
                //callback(res.data);
                callback(res.data);
                console.log(res.data);
              }
            });
          },
          fail: function() {
            wx.showModal({
              title: '警告',
              content: '您点击了拒绝授权，可能无法正常体验游戏，您也可以重新进行授权体验游戏。',
              success: function(res) {}
            })
            var url = 'https://d.fire2333.com/xdpt/weixinminigame/index/2063/' + gameId;
            wx.request({
              url: url,
              data: {
                "code": code,
                "ad": pt,
                "adposition": pt,
                "pt": pt,
                "scene": scene,
                "fromsource": from_source
              },
              success: function(res) {
                callback(res.data);
                console.log(res.data);
              },
              fail: function(res) {
                // 临时处理
                callback({
                  wx_openid: '',
                  openid: '',
                  nickname: '',
                  gender: '',
                  avatar: '',
                });
              }
            });
          }
        });
      }
    });
  });
}

/**小游戏登陆接口,有授权登陆，适合需要微信头像和昵称的产品接入
 * gameId 游戏在火树后台申请时候的游戏id
 * 
 * info: 小游戏通过UserInfoButton wx.createUserInfoButton(Object object)方法后
 * 在
 * 
 * button.onTap((info) = > {
    console.log(info)
  
    //在这里调用 我们的 xdLogin方法。

})

 * 
 */
function xdButtonLogin(gameId, info, callback) {
  return new Promise((resolve, reject) => {
    //调用登录接口
    //1.小程序调用wx.login得到code.
    wx.login({
      success: function (res) {
        //先获取缓存的pt号
        var pt = wx.getStorageSync('xd_game_pt');
        var scene = wx.getStorageSync('xd_game_scene');
        var from_source = wx.getStorageSync('xd_game_from_source');
        console.log("login pt:" + pt + " scene：" + scene + " from_source:" + from_source);
        console.log(res)

        var code = res['code'];

        //2.button.onTap((info)得到rawData, signatrue, encryptData.
            var rawData = info['rawData'];
            var signature = info['signature'];
            var encryptData = info['encryptData'];
            var encryptedData = info['encryptedData']; //注意是encryptedData不是encryptData...坑啊
            var iv = info['iv'];

            var userInfo = info.userInfo;
            var nickName = userInfo.nickName;
            var avatarUrl = userInfo.avatarUrl;
            var gender = userInfo.gender //性别 0：未知、1：男、2：女

            //2063 代表的是微信小渠道
            var url = 'https://d.fire2333.com/xdpt/weixinminigame/index/2063/' + gameId;
            // console.log("code：" + code);
            // console.log("rawData:" + rawData);
            // console.log("signature:" + signature);
            // console.log("encryptData:" + encryptData);
            // console.log("encryptedData:" + encryptedData);
            // console.log("iv:" + iv);
            // console.log("pt:" + pt);
            // console.log("url:" + url);
            //3.小程序调用server获取token接口, 传入code, rawData, signature, encryptData.
            wx.request({
              url: url,
              data: {
                "code": code,
                "rawData": rawData,
                "signature": signature,
                "encryptData": encryptData,
                "iv": iv,
                "encryptedData": encryptedData,
                "nickName": nickName,
                "avatarUrl": avatarUrl,
                "gender": gender,
                "ad": pt,
                "adposition": pt,
                "pt": pt,
                "scene": scene,
                "fromsource": from_source
              },
              success: function (res) {
                //callback(res.data);
                callback(res.data);
                console.log(res.data);
              }
            });
          },
          fail: function () {
            wx.showModal({
              title: '警告',
              content: '您点击了拒绝授权，可能无法正常体验游戏，您也可以重新进行授权体验游戏。',
              success: function (res) { }
            })
            var url = 'https://d.fire2333.com/xdpt/weixinminigame/index/2063/' + gameId;
            wx.request({
              url: url,
              data: {
                "code": code,
                "ad": pt,
                "adposition": pt,
                "pt": pt,
                "scene": scene,
                "fromsource": from_source
              },
              success: function (res) {
                callback(res.data);
                console.log(res.data);
              },
              fail: function (res) {
                // 临时处理
                callback({
                  wx_openid: '',
                  openid: '',
                  nickname: '',
                  gender: '',
                  avatar: '',
                });
              }
            });
      }
    });
  });
}

/**小游戏登陆接口,不需要授权界面，返回的值只有：openid和sessionkey
 * gameId 游戏在火树后台申请时候的游戏id
 */
function xdLoginWithNoAuth(gameId, callback) {
  return new Promise((resolve, reject) => {
    //调用登录接口
    //1.小程序调用wx.login得到code.
    wx.login({
      success: function(res) {
        //先获取缓存的pt号
		var pt = 1000;
		var scene = 1006;
		var from_source = undefined;
		try {
			pt = wx.getStorageSync('xd_game_pt');
			scene = wx.getStorageSync('xd_game_scene');
			from_source = wx.getStorageSync('xd_game_from_source');
			console.log("login pt:" + pt + " scene：" + scene + " from_source:" + from_source);
		} catch (e) {
			console.error(e);
		}

        var code = res['code'];
        console.log("login code:" + code);
        //2063 代表的是微信小渠道
        var url = 'https://d.fire2333.com/xdpt/weixinminigame/index/2063/' + gameId;
        wx.request({
          url: url,
          data: {
            "code": code,
            "ad": pt,
            "adposition": pt,
            "pt": pt,
            "scene": scene,
            "fromsource": from_source
          },
          success: function(res) {
            //callback(res.data);
            callback(res.data);
            console.log(res.data);
          }
        });
      }
    });
  });
}

/**
 * 充值接口
 * var payInfo = {
          "game_id": game_id, //平台传入参数的游戏Id
          "game_key": game_key,//平台传入参数的key
          "open_id": open_id,//登录验证获取的open_id
          "payment_amount": payment_amount, //支付金额（元），精确到小数点后两位
          "game_payorder": game_payorder,//游戏方服务器创建的订单号（最大64位）
          "object_name": object_name,//游戏内购买的项目名称，不同充值档请勿重名
          "desc": desc,//游戏内购买的项目描述
          "timestamp": timestamp,//unix时间戳
          "nonce": nonce,//平台传入参数的nonce
          "game_area": game_area,//游戏所在区名称（1区）
          "game_server": game_server,//游戏所在区服务器（1服）
          "role_id": role_id,//角色id
          "role_level": role_level,//角色等级
          "callback_url": callback_url,//游戏方回调地址（充值成功，平台会回调该地址，需要透传参数的，请在此依需带上）
          "signature": signature,//签名校验
          "vip_level": vip_level,//玩家当前vip等级
          "nickname": nickname,//角色名
        }
 */
function xdPay(payInfo, callback) {
  return new Promise((resolve, reject) => {
    payInfo['pay_name'] = 'pay_weixinminigame';
    payInfo['callback'] = 'prepayCallback';
    payInfo['adposition'] = wx.getStorageSync('xd_game_pt');
    payInfo['app_id'] = '2063';
    //充值方法
    wx.request({
      url: 'https://d.fire2333.com/preparepay',
      data: payInfo,
      success: function(d) {
        var res = d.data;
        console.log("pay:" + res);
        var callbackUrl = res.callbackUrl
        //充值游戏币 {"mode":"game","env":1,"offerId":"1450016314","currencyType":"CNY","platform":"android","buyQuantity":60,"zoneId":"1","orderno":"20180723170542127941792000559973","callbackUrl":"https:\/\/d.fire2333.com\/xdpt\/weixinminigame\/pay"}
        wx.requestMidasPayment({
          mode: res.mode,
          env: res.env,
          offerId: res.offerId,
          currencyType: res.currencyType,
          platform: res.platform,
          buyQuantity: res.buyQuantity,
          zoneId: res.zoneId,

          success() {
            // 支付成功
            console.log('success，' + callbackUrl);
            wx.request({
              url: callbackUrl
            })
			callback(true);
          },
          fail(){
            // 支付失败
            console.log('fail，' + res.callbackUrlFail);
            wx.request({
              url: res.callbackUrlFail
            })
			callback(false);
          }
        })
      }
    })

  });
}

//ioS 系统，判断用户是否是白名单，如果是白名单用户，则可以展示游戏的充值界面，
//然后调用该接口实现充值功能。
function xdiOSPay(payInfo, callback) {
  return new Promise((resolve, reject) => {
    payInfo['pay_name'] = 'pay_weixin_kefu_qr';
    payInfo['adposition'] = wx.getStorageSync('xd_game_pt');
    payInfo['app_id'] = '2063';
    //充值方法
    wx.request({
      url: 'https://d.fire2333.com/preparepay',
      data: payInfo,
      success: function (d) {
        // 支付成功
         console.log(d.data);
        // var url = 'http:\/\/d.fire2333.com\/qrcode.php?data=https%3A%2F%2Fgame.fire2333.com%2Fhome%2Fac%3Faction%3D%2Fhome%2FkefuPay%26orderno%3D20180911144851127941792000555108';
        console.log();
        if(d.data != undefined){
          var paydata = JSON.parse(d.data.substring(1, d.data.length - 2));
          if (paydata.data){
            wx.showModal({
              title: '亲',
              content: '截图或保存二维码，识别二维码充值',
              success: function (res) {
                if (res.confirm) {
                  wx.previewImage({
                    urls: [paydata.data]
                  });
				  callback(true);
                } else {
					callback(false);
				}
              }
            })  
          }else{
            wx.showToast({
              title: '订单获取失败',
              icon: 'loading',
              duration: 1000
            })  
			callback(false);
          }
        }
      }
    })
  });
}

/**
 * 浮标广告图片的接口
 * gameId：游戏id
 */
function xdPreviewImage(gameId, callback) {
  return new Promise((resolve, reject) => {
    var serverUrl = 'https://d.fire2333.com/xdpt/weixinminigame/previewImage/' + gameId;
    wx.request({
      url: serverUrl,
      success: function(res) {
        console.log(res.data);
        // wx.previewImage({
        //   // urls: [res.data.url]
        //   urls: [res.data[0]]
        // });
        callback(res.data);
      }
    });
  })
}

/**
 * 返回是否需要关注公众号，返回的数据有{android_focus:1,iOS_focus:0}标示 android需要关注公众功能，iOS不需要关注公众号功能
 * gameId：游戏id
 */
function xdhasFocus(gameId, callback) {
  return new Promise((resolve, reject) => {
    var serverUrl = 'https://d.fire2333.com/xdpt/weixinminigame/hasFocus/' + gameId;
    wx.request({
      url: serverUrl,
      success: function (res) {
        console.log(res.data);
        callback(res.data);
      }
    });
  })
}

/**
 * 主动分享给朋友/群
 */
function xdShare(title, imageUrl, callback, gameinfo) {
  return new Promise((resolve, reject) => {
    wx.showShareMenu({
      withShareTicket: true
    });
    var pt = wx.getStorageSync('xd_game_pt');
    pt = parseInt(pt);
    if (pt < 10000000) {
      pt = 10000000 + parseInt(pt);
    }

    var ext = "pt=" + pt;
    if (gameinfo) {
      ext = ext + "&" + gameinfo;
    }
    console.log("ext:" + ext);
    wx.shareAppMessage({
      title: title,
      query: ext,
      imageUrl: imageUrl,
      success: function(res) {
        console.log("转发成功" + res.shareTickets);
        var p = {
          "code": 0,
          "message": "share success",
          "shareTickets": res.shareTickets
        };
        callback(p);
      },
      fail: function(res) {
        var p = {
          "code": -1,
          "message": "share fail"
        };
        callback(p);
        console.log("转发失败");
      },
      complete: function(res) {
        console.log(wx.getLaunchOptionsSync().query);
      }
    });
  })
}

/**
 * 被动分享给朋友/群，监听menu建
 */
function xdonShare(title, imageUrl, callback, gameinfo, cbBeforeShare) {
  return new Promise((resolve, reject) => {
    wx.showShareMenu({
      withShareTicket: false
    });
    var pt = wx.getStorageSync('xd_game_pt');
    pt = parseInt(pt);
    if (pt < 10000000) {
      pt = 10000000 + parseInt(pt);
    }

    var ext = "pt=" + pt;
    if (gameinfo) {
      ext = ext + "&" + gameinfo;
    }
    console.log("ext:" + ext);

    wx.onShareAppMessage(function() {
      // 用户点击了“转发”按钮
      if (cbBeforeShare){
        cbBeforeShare()
      }
      return {
        title: title,
        query: ext,
        imageUrl: imageUrl,
        success: function(res) {
          console.log("转发成功" + res);
          wx.showShareMenu({
            withShareTicket: true
          });
          var p = {
            "code": 0,
            "message": "share success",
            "shareTickets": res.shareTickets
          };
          callback(p);
        },
        fail: function(res) {
          var p = {
            "code": -1,
            "message": "share fail"
          };
          callback(p);
          console.log("转发失败");
        },
        complete: function(res) {
          console.log(wx.getLaunchOptionsSync().query);
        }
      }
    })
  })
}

/**
 * 创建角色日志
 * 
 * var roleData = {
 *    game_id:	string	游戏Id
      game_key:	string	游戏key
      app_id:	string	渠道Id
      open_id:	string	平台唯一用户id
      timestamp:	int	unix时间戳
      role_id:	string	角色Id
      nickname:	string	角色名
      area:	string	所在区：默认为fire233
      server_id:	int	服务器Id
      signature:	string	签名校验,md5(game_key + open_id + timestamp + key)key为平台方给游戏方的key
}
 */
function xdCreateRoleLog(roleData) {
  console.log(wx.getStorageSync('xd_game_pt'));
  roleData['adPosition'] = wx.getStorageSync('xd_game_pt');
  roleData['app_id'] = '2063';
  //创建角色请求
  wx.request({
    url: 'https://d.fire2333.com/log/createRoleLog',
    data: {
      data: roleData
    },
    success: function(res) {
      console.log(res);
    }
  });
}

/**
 * 升级日志
 * 
 * var roleData = {
 *    game_id	：string	游戏Id
      game_key	：	string	游戏key
      app_id	：	string	渠道Id
      open_id		：string	平台唯一用户id
      timestamp	：	int	unix时间戳
      role_id		：string	角色Id
      nickname	：string	角色名
      area		：string	所在区：默认为fire233
      server_id	：	int	服务器Id
      level		：int	玩家等级
      vip_level		：int	vip等级
      score		：int	战力
      signature		：string	签名校验
}
 */
function xdLevelUpLog(roleData) {
  console.log(wx.getStorageSync('xd_game_pt'));
  roleData['adPosition'] = wx.getStorageSync('xd_game_pt');
  roleData['app_id'] = '2063';
  //升级日志
  wx.request({
    url: 'https://d.fire2333.com/log/levelUpLog',
    data: {
      data: roleData
    },
    success: function(res) {
      console.log(res);
    }
  });
}


/**
 * 登陆游戏日志
 * 
 * var enterGameData = {
 *    game_id	：string	游戏Id
      game_key	：	string	游戏key
      app_id	：	string	渠道Id
      open_id		：string	平台唯一用户id
      timestamp	：	int	unix时间戳
      role_id		：string	角色Id
      nickname	：string	角色名
      level		：int	玩家等级
      vip_level		：int	vip等级
      role_ext:string 角色额外信息
      score		：int	战力
      area:string 所在区：默认为fire233
      server_id	：	int	服务器Id
      is_new:int 新创建角色第一次登录进游戏为1，其他为0
      signature		：string	签名校验
      
      签名方法：
      md5(game_key + open_id + timestamp + gamesecret)
gamesecret为平台方给游戏方的密钥
}
 */
function xdEnterGameLog(enterGameData) {
  console.log(wx.getStorageSync('xd_game_pt'));
  enterGameData['adPosition'] = wx.getStorageSync('xd_game_pt');
  enterGameData['app_id'] = '2063';
  //登陆游戏日志
  wx.request({
    url: 'https://d.fire2333.com/log/enterGameLog',
    data: {
      data: enterGameData
    },
    success: function(res) {
      console.log(res);
    }
  });
}

module.exports.xdInit = xdInit;
exports.xdLogin = xdLogin;
exports.xdLoginWithNoAuth = xdLoginWithNoAuth;
exports.xdButtonLogin = xdButtonLogin;
exports.xdPay = xdPay;
exports.xdiOSPay = xdiOSPay;
exports.xdPreviewImage = xdPreviewImage;
exports.xdhasFocus = xdhasFocus;
exports.xdShare = xdShare;
exports.xdonShare = xdonShare;
exports.xdCreateRoleLog = xdCreateRoleLog;
exports.xdLevelUpLog = xdLevelUpLog;
exports.xdEnterGameLog = xdEnterGameLog;
