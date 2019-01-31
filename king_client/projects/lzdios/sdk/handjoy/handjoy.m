//
//  handjoy.m
//  lzdios_handjoy
//
//  Created by elliotlee on 2018/10/19.
//  Copyright © 2018年 egret. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sdk.h"

@implementation HandJoySDK {
    
}

- (void) init:(AppDelegate *)app {
    [super init:app];
    [FBSDKSettings setAppID:@"740714252962921"];
}

- (void) login {
    NSLog(@"[handjoy] login");
    if ([FBSDKAccessToken currentAccessToken]) {
        NSString *userId = [[FBSDKAccessToken currentAccessToken] userID];
        NSString *token = [[FBSDKAccessToken currentAccessToken] tokenString];
        NSDictionary *infos = @{@"channelID":@"", @"channelUserID":userId, @"token":token, @"channelUserName":@"", @"tdChannelID":@"lzd_handjoy", @"loginChannel":@"facebook"};
        NSDictionary *args = @{@"success":@true, @"info":infos};
        NSLog(@"[handjoy] login done: %@", infos);
        [self callToJS:@"loginDone" withArgs:args];
    } else {
        FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
        [login logInWithReadPermissions:@[@"public_profile"] fromViewController:[appInst getViewController] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            if (result == nil) {
                NSDictionary *args = @{@"success":@false, @"reason":NSLocalizedString(@"loginFail", nil)};
                [self callToJS:@"loginDone" withArgs:args];
            } else if ([result isCancelled]) {
                NSDictionary *args = @{@"success":@false, @"reason":NSLocalizedString(@"loginCancel", nil)};
                [self callToJS:@"loginDone" withArgs:args];
            } else {
                if ([result token] == nil) {
                    NSDictionary *args = @{@"success":@false, @"reason":NSLocalizedString(@"loginFail", nil)};
                    [self callToJS:@"loginDone" withArgs:args];
                } else {
                    NSString *userId = [[result token] userID];
                    NSString *token = [[result token] tokenString];
                    NSDictionary *infos = @{@"channelUserID":userId, @"token":token, @"tdChannelID":@"lzd_handjoy", @"loginChannel":@"facebook"};
                    NSDictionary *args = @{@"success":@true, @"info":infos};
                    NSLog(@"[handjoy] login done: %@", infos);
                    [self callToJS:@"loginDone" withArgs:args];
                }
            }
        }];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    
    [AppsFlyerTracker sharedTracker].appsFlyerDevKey = @"RThnuB74b7fC7jyxpkU7sb";
    [AppsFlyerTracker sharedTracker].appleAppID = @"1439678059";
    [AppsFlyerTracker sharedTracker].delegate = self;
    [AppsFlyerTracker sharedTracker].isDebug = false;
    return TRUE;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey] annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)applicationBecomeActive:(UIApplication *)application {
    [[AppsFlyerTracker sharedTracker] trackAppLaunch];
}

- (void) onEnterGame: (NSString *)userId withUserName:(NSString*)userName withLevel:(int)level withServerId:(int)serverId withServerName:(NSString *)serverName {
    [super onEnterGame:userId withUserName:userName withLevel:level withServerId:serverId withServerName:serverName];
    [[AppsFlyerTracker sharedTracker] trackEvent:AFEventLogin withValues:@{AFEventParamCustomerUserId: userId}];
}

- (void) onPaySuccess:(SKProduct *)product {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:product.priceLocale];
    NSString *currency = formatter.currencyCode;
    [[AppsFlyerTracker sharedTracker] trackEvent:AFEventPurchase withValues:@{AFEventParamRevenue:product.price, AFEventParamCurrency:currency}];
}

- (BOOL)shareLink:(NSString*)title withLink:(NSString*)link {
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:link];
    FBSDKShareDialog * dialog = [[FBSDKShareDialog alloc] init];
    dialog.shareContent = content;
    dialog.fromViewController = [appInst getViewController];
    dialog.delegate = self;
    dialog.mode = FBSDKShareDialogModeFeedWeb;
    [dialog show];
    return TRUE;
}

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results {
    NSLog(@"FBShare didCompleteWithResults %@", results);
    NSDictionary *args = @{@"success":@true};
    [self callToJS:@"shareLinkComplete" withArgs:args];
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error {
    NSLog(@"FBShare didFailWithError %@", error);
    NSDictionary *args = @{@"success":@false};
    [self callToJS:@"shareLinkComplete" withArgs:args];
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer {
    NSLog(@"FBShare cancel");
    NSDictionary *args = @{@"success":@false};
    [self callToJS:@"shareLinkComplete" withArgs:args];
}

@end
