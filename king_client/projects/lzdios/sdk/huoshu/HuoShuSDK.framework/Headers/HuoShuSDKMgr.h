//

//
//  Created by 莫 东荣 on 13-4-9.
//  Copyright (c) 2013年 莫 东荣. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HuoShuSDKMgr : NSObject
{
    NSString* appId_;
    NSString* appKey_;
    NSString* inviterCode_;
}
@property bool isApplePaying;
+(NSMutableDictionary *)getLoginInfo;
+ (HuoShuSDKMgr *)getInstance;
+ (NSString *)toJSONData:(id)theData;
//启动应用时调用
+(void)huoShuSDKInitWithApp_id:(NSString *)appId
                    withAppKey:(NSString *)appKey
                   withGameVer:(NSString *)gameVer
            withIsRequireLogin:(BOOL)isRequireLogin;
//- (void)setServerUrl:(NSString *)serverUrl;//
- (void)openLoginWithController: (UIViewController *)controller;
// 查看用户中心
- (void)openCenter: (UIViewController *)controller;
-(void)aaaaaa;
// 支付
-(void)openPayWithServerid:(NSString *)serverId
                withRoleId:(NSString *)roleId
             withPayAmount:(NSString *)payAmount
              withCallBack:(NSString *)callBack
                withGoodId:(NSString *)goodId
                 withMoney:(NSString *)money
            withController:(UIViewController *)controller;
// 创建角色接口
-(void)createRoleWithServerId:(NSString *)server_id
                   withRoleId:(NSString *)role_id
                 withRoleName:(NSString *)role_name;
// 角色登录接口
-(void)loginRoleWithServerId:(NSString *)server_id
                  withRoleId:(NSString *)role_id
                withRoleName:(NSString *)role_name
               withRoleLevel:(NSString *)role_level;
// 角色升级接口
-(void)upgradeRoleWithServerId:(NSString *)serverId
                    withRoleId:(NSString *)role_id
                  withRoleName:(NSString *)role_name
                 withRoleLevel:(NSString *)role_level;

@end





