//
//  huoshu.m
//  lzdios
//
//  Created by elliotlee on 2018/6/26.
//  Copyright © 2018年 egret. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sdk.h"
#import <HuoShuSDK/HuoShuSDKMgr.h>
#import <HuoShuSDK/HuoShuNotifications.h>

@implementation HuoShuSDK {
    
}

- (void) init:(AppDelegate *)app {
    [super init:app];
    [HuoShuSDKMgr huoShuSDKInitWithApp_id:@"5b30aca556fec812678de442" withAppKey:@"5456ced59694035ce58811d740018d8a" withGameVer:@"1.0" withIsRequireLogin:YES];
}

- (void) initView {
    [super initView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginCallBack:) name:huoshuLoginNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(payCallBack:) name:huoshuPaytNotification object:nil];
}

- (void) login {
    OpenewWebView * view = [appInst getViewController];
    [[HuoShuSDKMgr getInstance] openLoginWithController:view];
    
}
/* info的格式：
 JSONObject obj = new JSONObject();
 obj.put("channelID", channelID);
 obj.put("channelUserID", channelUserID);
 obj.put("token", token);
 obj.put("channelUserName", channelUserName);
 obj.put("timeStamp", timeStamp);
 obj.put("userType", userType);
 */
- (void) loginCallBack: (NSNotification *)notification {
    NSMutableDictionary *dict = [HuoShuSDKMgr getLoginInfo];
//    NSLog(@"login info: %@", dict);
    NSString *openId = [dict objectForKey:@"openId"];
    NSString *timestamp = [dict objectForKey:@"timestamp"];
    NSString *token = [dict objectForKey:@"token"];
    NSDictionary *infos = @{@"channelID":@"", @"channelUserID":openId, @"token":token, @"channelUserName":@"", @"timeStamp":timestamp, @"userType":@"", @"tdChannelID":@"lzd_pkgsdk_ios"};
    NSDictionary *args = @{@"success":@true, @"info":infos};
    [self callToJS:@"loginDone" withArgs:args];
}

- (void) payCallBack: (NSNotification *)notification {
    NSMutableDictionary *dict = [notification object];
    NSString *result = [dict objectForKey:@"result"];
    NSLog(@"payCallBack:%@", dict);
    if ([result isEqualToString:@"paySuccess"]) {
        NSDictionary *args = @{@"success":@true, @"productId":self->lastProductId};
        [self callToJS:@"finishPay" withArgs:args];
    } else {
        NSDictionary *args = @{@"success":@false, @"reason":@"支付失败"};
        [self callToJS:@"finishPay" withArgs:args];
    }
}

- (void) onEnterGame: (NSString *)userId withUserName:(NSString*)userName withLevel:(int)level withServerId:(int)serverId withServerName:(NSString *)serverName {
    NSLog(@"onEnterGame");
    [super onEnterGame:userId withUserName:userName withLevel:level withServerId:serverId withServerName:serverName];
    [[HuoShuSDKMgr getInstance] loginRoleWithServerId:[NSString stringWithFormat:@"%d", serverId] withRoleId:userId withRoleName:userName withRoleLevel:[NSString stringWithFormat:@"%d", level]];
}

- (void) onCreateRole: (NSString *)userId withUserName:(NSString*)userName withServerId:(int)serverId withServerName:(NSString *)serverName {
    NSLog(@"onCreateRole");
    [[HuoShuSDKMgr getInstance] createRoleWithServerId:[NSString stringWithFormat:@"%d", serverId] withRoleId:userId withRoleName:userName];
}

- (void) getProductInfos: (NSArray *)productIdentifiers {
    [self callToJS:@"getProducts" withArgs:@{@"success":@false, @"reason":@"SDK付费请直接读取游戏内配置"}];
}

- (void) pay: (NSString *)productId withPrice:(int)price withCount:(int)count withParam:(NSString *)param {
    self->lastProductId = productId;
    [[HuoShuSDKMgr getInstance] openPayWithServerid:[NSString stringWithFormat:@"%d", serverId] withRoleId:roleId withPayAmount:[NSString stringWithFormat:@"%d", 10*price] withCallBack:param withGoodId:productId withMoney:[NSString stringWithFormat:@"%d", price] withController:[appInst getViewController]];
}

@end
