//
//  ads.h
//  lzdios
//
//  Created by elliotlee on 2018/7/26.
//  Copyright © 2018年 egret. All rights reserved.
//

#pragma once

#import "AppDelegate.h"

@interface AdsBase: NSObject {
    AppDelegate *appInst;
}

- (void) init: (AppDelegate *)app;
- (void) preload;
- (BOOL) isAdsReady;
- (void) showRewardAds;
- (void) callToJS: (NSString *)msg withArgs: (NSDictionary *)args;
+ (AdsBase *) getAdsInstance;
@end
