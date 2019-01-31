//
//  sdk.h
//  lzdios
//
//  Created by elliotlee on 2018/6/26.
//  Copyright © 2018年 egret. All rights reserved.
//

#pragma once

#import "AppDelegate.h"
#import "OpenewWebView.h"
#import <StoreKit/StoreKit.h>

@interface SDKBase : NSObject {
    AppDelegate *appInst;
    int serverId;
    NSString *serverName;
    NSString *roleId;
    NSString *roleName;
    int level;
    NSString *lastProductId;
}
- (void) init: (AppDelegate *)app;
- (void) login;
- (void) initView;
- (void) onEnterGame: (NSString *)userId withUserName:(NSString*)userName withLevel:(int)level withServerId:(int)serverId withServerName:(NSString *)serverName;
- (void) onCreateRole: (NSString *)userId withUserName:(NSString*)userName withServerId:(int)serverId withServerName:(NSString *)serverName;
- (void) callToJS: (NSString *)msg withArgs: (NSDictionary *)args;
- (void) pay: (NSString *)productId withPrice:(int)price withCount:(int)count withParam:(NSString *)param;
- (void) onPaySuccess:(SKProduct *)product;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options;
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;
- (void)applicationBecomeActive:(UIApplication *)application;
- (BOOL)shareLink:(NSString*)title withLink:(NSString*)link;
+ (SDKBase *) getSdkInstance;
@end

#ifdef XUANDONG
@interface HuoShuSDK : SDKBase {
    
}
- (void) init: (AppDelegate *)app;
- (void) login;
- (void) initView;
- (void) onEnterGame: (NSString *)userId withUserName:(NSString*)userName withLevel:(int)level withServerId:(int)serverId withServerName:(NSString *)serverName;
- (void) onCreateRole: (NSString *)userId withUserName:(NSString*)userName withServerId:(int)serverId withServerName:(NSString *)serverName;
- (void) pay: (NSString *)productId withPrice:(int)price withCount:(int)count withParam:(NSString *)param;
@end
#endif

#ifdef HANDJOY

#import <AppsFlyerLib/AppsFlyerTracker.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

@interface HandJoySDK: SDKBase<AppsFlyerTrackerDelegate, FBSDKSharingDelegate> {
    
}
- (void) init: (AppDelegate *)app;
- (void) login;
- (void) onEnterGame: (NSString *)userId withUserName:(NSString*)userName withLevel:(int)level withServerId:(int)serverId withServerName:(NSString *)serverName;
//- (void) onCreateRole: (NSString *)userId withUserName:(NSString*)userName withServerId:(int)serverId withServerName:(NSString *)serverName;
//- (void) pay: (NSString *)productId withPrice:(int)price withCount:(int)count withParam:(NSString *)param;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options;
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;
- (void)applicationBecomeActive:(UIApplication *)application;
- (BOOL)shareLink:(NSString*)title withLink:(NSString*)link;
@end
#endif


