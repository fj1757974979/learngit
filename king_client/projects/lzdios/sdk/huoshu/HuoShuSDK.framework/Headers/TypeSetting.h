//
//  TypeSetting.h
//  XJLFirstProject
//
//  Created by zhangjing on 2017/11/15.
//  Copyright © 2017年 萧峰. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TypeSetting : NSObject
{
    //是否需要登录,默认为yes需要
    BOOL isRequireLogin;
    //appid-SDk服务器分配给cp，cp传入给sdk客户端
    NSString *appid;
    //appKey-SDk服务器分配给cp，cp传入给sdk客户端
    NSString *appKey;
    // 游戏版本号
    NSString *gameVer;
    // 游戏的角色ID
    NSString *roleId;
    // 游戏的角色名称
    NSString *roleName;
    // 角色等级
    NSString *rolelevel;
    // 游戏服务器id
    NSString *serverId;
    // webview的宽度
    int webviewWidth;
    // webview的高度
    int webviewHight;
    //苹果支付的商品id，由cp传进来
    NSString *productIdentifier;
    //平台的订单tradeId
    NSString *tradeId;
    // 充值金额，热云统计用到
    NSString *payMoney;
    // 游戏订单号
    NSString *payCallback;
    
}

//是否需要登录,默认为yes需要
@property(assign,nonatomic) BOOL isRequireLogin;
//appid-SDk服务器分配给cp，cp传入给sdk客户端
@property(retain,nonatomic) NSString *appid;
//appKey-SDk服务器分配给cp，cp传入给sdk客户端
@property(retain,nonatomic) NSString *appKey;
// 游戏版本号
@property(retain,nonatomic) NSString *gameVer;
// webview的宽度
@property(assign,nonatomic) int webviewWidth;
// webview的高度
@property(assign,nonatomic) int webviewHight;
//游戏的角色名称，由cp传进来
@property(retain,nonatomic) NSString *roleName;
//游戏的角色ID，由cp传进来
@property(retain,nonatomic) NSString *roleId;
//游戏的角色等级，由cp传进来
@property(retain,nonatomic) NSString *rolelevel;
//游戏的服务器ID，由cp传进来
@property(retain,nonatomic) NSString *serverId;
//苹果支付的商品id，由cp传进来
@property(retain,nonatomic) NSString *productIdentifier;
//平台的订单tradeId
@property(retain,nonatomic) NSString *tradeId;
// 充值金额，热云统计用到
@property(retain,nonatomic) NSString *payMoney;
// 游戏订单号
@property(retain,nonatomic) NSString *payCallback;

+ (TypeSetting *)getInstance;
+ (NSString *)dealWithParam:(NSMutableDictionary *)param;
// md5加密
-(NSString *)md5:(NSString *)str;
// 所有接口都需要传的公共字段
+(NSMutableDictionary *)getParameters;
// 网络状态是否真实可达
//+ (BOOL)socketReachabilityTest;
// 判断网络是否可用
+(BOOL)checkNetworkCanUse;
//-(NSMutableDictionary *)createCachePathWithOrderArray:(NSArray *)orderArray withStatus:(NSString *)orderStatus;
@end
