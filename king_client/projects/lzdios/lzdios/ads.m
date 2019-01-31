//
//  ads.m
//  lzdios
//
//  Created by elliotlee on 2018/7/26.
//  Copyright © 2018年 egret. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ads.h"

#ifdef XUANDONG
#import "yomob.h"
#endif

@implementation AdsBase {
    
}

static AdsBase *instance = NULL;

- (void) init: (AppDelegate *)app {
    appInst = app;
}
- (void) preload {
    
}
- (BOOL) isAdsReady {
    return FALSE;
}
- (void) showRewardAds {
    
}

- (void) callToJS: (NSString *)msg withArgs: (NSDictionary *)args {
    NSError *parseError = nil;
    NSDictionary *param = @{@"msg":msg, @"args":args};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:param options:0 error:&parseError];
    NSString *strArgs =  [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [appInst callJS:strArgs];
}

+ (AdsBase *) getAdsInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
#ifdef XUANDONG
            instance = [YomobAds new];
#else
            instance = [AdsBase new];
#endif
        }
    });
    return instance;
}
@end
