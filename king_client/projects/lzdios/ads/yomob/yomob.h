//
//  yomob.h
//  lzdios
//
//  Created by elliotlee on 2018/7/26.
//  Copyright © 2018年 egret. All rights reserved.
//
#pragma once

#import "sdk.h"
#import "include/TGSDK/TGSDK.h"

@interface YomobAds: AdsBase<TGPreloadADDelegate, TGADDelegate> {
    BOOL hasGiveReward;
}
- (void) init: (AppDelegate *)app;
- (void) preload;
- (BOOL) isAdsReady;
- (void) showRewardAds;
@end
