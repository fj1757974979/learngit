//
//  sdk.m
//  lzdios
//
//  Created by elliotlee on 2018/6/26.
//  Copyright © 2018年 egret. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sdk.h"
#import "payment.h"

@implementation SDKBase {
    
}

static SDKBase *sdkInstance = nil;

- (void) init:(AppDelegate *)app {
    appInst = app;
}

- (void) login {
    
}

- (void) initView {
}

- (void) onEnterGame: (NSString *)userId withUserName:(NSString*)userName withLevel:(int)level withServerId:(int)serverId withServerName:(NSString *)serverName {
    self->roleId = [NSString stringWithString:userId];
    self->roleName = [NSString stringWithString:userName];
    self->level = level;
    self->serverId = serverId;
    self->serverName = [NSString stringWithString:serverName];
}

- (void) onCreateRole: (NSString *)userId withUserName:(NSString*)userName withServerId:(int)serverId withServerName:(NSString *)serverName {
    self->roleId = [NSString stringWithString:userId];
    self->roleName = [NSString stringWithString:userName];
    self->serverId = serverId;
    self->serverName = [NSString stringWithString:serverName];
}

- (void) pay: (NSString *)productId withPrice:(int)price withCount:(int)count withParam:(NSString *)param
{
    NSDictionary *args = @{@"success":@false, @"productId":productId, @"reason":@"SDK付费未开启"};
    [self callToJS:@"finishPay" withArgs:args];
}

- (void) onPaySuccess:(SKProduct *)product {
    
}

- (void) callToJS: (NSString *)msg withArgs: (NSDictionary *)args {
    NSError *parseError = nil;
    NSDictionary *param = @{@"msg":msg, @"args":args};
//    NSLog(@"callToJS: %@ %@", msg, args);
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:param options:0 error:&parseError];
    NSString *strArgs =  [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    NSLog(@"callToJS: %@", strArgs);
    [appInst callJS:strArgs];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return TRUE;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return TRUE;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return TRUE;
}

- (void)applicationBecomeActive:(UIApplication *)application
{
    
}

- (BOOL)shareLink:(NSString*)title withLink:(NSString*)link {
    return FALSE;
}

+ (SDKBase *) getSdkInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sdkInstance == nil) {
#ifdef XUANDONG
            sdkInstance = [HuoShuSDK new];
#endif

#ifdef HANDJOY
            sdkInstance = [HandJoySDK new];
#endif
        }
    });
    return sdkInstance;
}

@end
